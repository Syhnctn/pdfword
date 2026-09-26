import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pdfword_pro/core/config/app_env.dart';
import 'package:pdfword_pro/features/shared/models/app_file_item.dart';
import 'package:pdfword_pro/features/shared/models/conversion_history_item.dart';
import 'package:pdfword_pro/features/shared/models/upload_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobUploadTarget {
  const JobUploadTarget({
    required this.fileId,
    required this.bucket,
    required this.path,
    required this.token,
    required this.fileName,
  });

  final String fileId;
  final String bucket;
  final String path;
  final String token;
  final String fileName;
}

class CreateJobResult {
  const CreateJobResult({
    required this.jobId,
    required this.uploadTargets,
  });

  final String jobId;
  final List<JobUploadTarget> uploadTargets;
}

/// Outcome of a direct (bytes) conversion call to the OCR worker.
class DirectConvertResult {
  const DirectConvertResult({
    required this.started,
    this.jobId,
    this.outputDocxPath,
    this.docxBytes,
  });

  /// True when the worker accepted the conversion request.
  final bool started;

  /// Job id reported by the worker (may be null in pure local mode).
  final String? jobId;

  /// Storage path when the worker persisted the result to Supabase.
  final String? outputDocxPath;

  /// Inline DOCX payload when the worker has no Supabase credentials.
  final Uint8List? docxBytes;

  bool get isLocalResult => docxBytes != null && docxBytes!.isNotEmpty;
}

class JobStatusInfo {
  const JobStatusInfo({
    required this.jobId,
    required this.status,
    required this.progressPct,
    this.errorCode,
    this.errorMessage,
    this.outputDocxPath,
  });

  final String jobId;
  final String status;
  final int progressPct;
  final String? errorCode;
  final String? errorMessage;
  final String? outputDocxPath;

  bool get isDone => status == 'succeeded' || status == 'failed';
  bool get isSuccess => status == 'succeeded';
}

class SupabaseOcrService {
  SupabaseOcrService(this._client);

  final SupabaseClient _client;

  Future<CreateJobResult?> createJob(
    List<AppFileItem> files, {
    String? deviceIdHash,
  }) async {
    try {
      final payload = {
        'files': files
            .map(
              (file) => {
                'file_id': file.id,
                'name': file.name,
                'size_mb': file.sizeMb,
                'mime_type': file.mimeType ?? _guessMimeType(file.name),
                'state': file.state.name,
              },
            )
            .toList(growable: false),
        'source': 'flutter_app',
        if (deviceIdHash != null && deviceIdHash.isNotEmpty)
          'device_id_hash': deviceIdHash,
      };

      final createResponse = await _client.functions.invoke(
        'create_job',
        headers: _functionHeaders(),
        body: payload,
      );
      final data = createResponse.data;
      if (data is! Map<String, dynamic>) return null;

      final jobId = data['job_id']?.toString();
      if (jobId == null || jobId.isEmpty) return null;

      final rawTargets = data['upload_targets'];
      if (rawTargets is! List) return null;

      final uploadTargets =
          rawTargets.whereType<Map<dynamic, dynamic>>().map((raw) {
        final map = raw.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        return JobUploadTarget(
          fileId: map['file_id']?.toString() ?? '',
          bucket: map['bucket']?.toString() ?? 'ocr-inputs',
          path: map['path']?.toString() ?? '',
          token: map['token']?.toString() ?? '',
          fileName: map['file_name']?.toString() ?? '',
        );
      }).where((target) {
        return target.fileId.isNotEmpty &&
            target.path.isNotEmpty &&
            target.token.isNotEmpty;
      }).toList(growable: false);

      if (uploadTargets.isEmpty) return null;

      return CreateJobResult(
        jobId: jobId,
        uploadTargets: uploadTargets,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> uploadFileToSignedUrl({
    required JobUploadTarget target,
    required AppFileItem file,
  }) async {
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return false;

    try {
      await _client.storage.from(target.bucket).uploadBinaryToSignedUrl(
            target.path,
            target.token,
            bytes,
            FileOptions(
              upsert: true,
              contentType: file.mimeType ?? _guessMimeType(file.name),
            ),
          );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> enqueueJob(String jobId) async {
    // Prefer the direct worker endpoint (real conversion pipeline); fall back
    // to the hosted enqueue_job function when the worker is unreachable.
    if (await _callWorkerProcess(jobId)) return true;

    try {
      final response = await _client.functions.invoke(
        'enqueue_job',
        headers: _functionHeaders(),
        body: {'job_id': jobId},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) return false;
      final status = data['status']?.toString();
      return status == 'processing' || status == 'succeeded';
    } catch (_) {
      return false;
    }
  }

  /// Warms the worker up with a cheap `GET /healthz` before posting a job.
  ///
  /// Render's free plan parks the container between requests, and returns
  /// `503` for the first call while it spins back up. Paying that cost on a
  /// health probe (which carries no conversion work) keeps the real
  /// `/internal/process` call from being the one that gets the `503`.
  Future<void> _ensureWorkerWarm(String baseUrl) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 60);
    try {
      final request = await client
          .getUrl(Uri.parse('$baseUrl/healthz'))
          .timeout(const Duration(seconds: 60));
      final response = await request
          .close()
          .timeout(const Duration(seconds: 60));
      await response.drain<void>();
    } catch (_) {
      // Unreachable here is fine: the job call below reports the real error.
    } finally {
      client.close(force: true);
    }
  }

  /// Whether a status code represents a transient worker failure that is
  /// worth retrying (container spin-up, gateway timeout, rate limiting).
  static bool _isRetryableStatus(int statusCode) {
    return statusCode == 408 ||
        statusCode == 429 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  /// Sends the job to the local/remote OCR worker directly (bypasses the
  /// hosted webhook). Returns false when the worker is unreachable.
  ///
  /// The worker processes the job synchronously, so the request is held open
  /// for the whole OCR run. A single scanned page already takes ~65s on the
  /// free tier, hence the generous timeout; polling the job afterwards is what
  /// actually reports progress to the user.
  Future<bool> _callWorkerProcess(String jobId) async {
    if (kIsWeb) return false;
    final baseUrl = AppEnv.ocrWorkerUrl;
    if (baseUrl.isEmpty) return false;

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      await _ensureWorkerWarm(baseUrl);

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 60);
      try {
        final request = await client.postUrl(
          Uri.parse('$baseUrl/internal/process'),
        );
        final secret = AppEnv.ocrWorkerSecret;
        if (secret.isNotEmpty) {
          request.headers.set('Authorization', 'Bearer $secret');
        }
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode({'job_id': jobId}));
        final response = await request
            .close()
            .timeout(const Duration(minutes: 15));
        await response.drain<void>();
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return true;
        }
        if (!_isRetryableStatus(response.statusCode) ||
            attempt == maxAttempts) {
          return false;
        }
      } catch (_) {
        if (attempt == maxAttempts) return false;
      } finally {
        client.close(force: true);
      }

      // Back off so a parked container has time to finish starting up.
      await Future<void>.delayed(Duration(seconds: 4 * attempt));
    }
    return false;
  }

  /// Uploads raw file bytes to the worker's direct conversion endpoint.
  ///
  /// Used when the signed storage upload fails (storage outage, oversized
  /// file) or when the job could not be created in Supabase.
  Future<DirectConvertResult?> convertViaWorker({
    required List<AppFileItem> files,
    String? jobId,
  }) async {
    if (kIsWeb) return null;
    final baseUrl = AppEnv.ocrWorkerUrl;
    if (baseUrl.isEmpty) return null;

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final result = await _convertViaWorkerOnce(baseUrl, files, jobId: jobId);
      if (result != null) return result;

      if (attempt == maxAttempts) return null;
      // Back off so a parked (spun-down) container can finish starting up.
      await Future<void>.delayed(Duration(seconds: 4 * attempt));
    }
    return null;
  }

  Future<DirectConvertResult?> _convertViaWorkerOnce(
    String baseUrl,
    List<AppFileItem> files, {
    String? jobId,
  }) async {
    await _ensureWorkerWarm(baseUrl);

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 60);
    try {
      final request = await client.postUrl(
        Uri.parse('$baseUrl/internal/convert'),
      );
      final secret = AppEnv.ocrWorkerSecret;
      if (secret.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $secret');
      }

      final boundary = 'pdfword-${DateTime.now().microsecondsSinceEpoch}';
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );

      final body = BytesBuilder(copy: false);
      void writeText(String value) => body.add(utf8.encode(value));

      if (jobId != null && jobId.isNotEmpty) {
        writeText('--$boundary\r\n');
        writeText('Content-Disposition: form-data; name="job_id"\r\n\r\n');
        writeText('$jobId\r\n');
      }
      writeText('--$boundary\r\n');
      writeText('Content-Disposition: form-data; name="source"\r\n\r\n');
      writeText('flutter_app\r\n');

      var wroteFile = false;
      for (final file in files) {
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) continue;
        final mime = file.mimeType ?? 'application/pdf';
        final safeName = file.name.replaceAll('"', '_');
        writeText('--$boundary\r\n');
        writeText(
          'Content-Disposition: form-data; name="files"; filename="$safeName"\r\n',
        );
        writeText('Content-Type: $mime\r\n\r\n');
        body.add(bytes);
        writeText('\r\n');
        wroteFile = true;
      }
      if (!wroteFile) return null;

      writeText('--$boundary--\r\n');
      request.add(body.takeBytes());

      final response = await request.close().timeout(
            const Duration(minutes: 5),
          );
      final raw = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      dynamic data;
      try {
        data = jsonDecode(raw);
      } catch (_) {
        return const DirectConvertResult(started: true);
      }
      if (data is! Map<String, dynamic>) {
        return const DirectConvertResult(started: true);
      }

      final base64Docx = data['docx_base64']?.toString() ?? '';
      Uint8List? docxBytes;
      if (base64Docx.isNotEmpty) {
        try {
          docxBytes = base64Decode(base64Docx);
        } catch (_) {
          docxBytes = null;
        }
      }

      return DirectConvertResult(
        started: true,
        jobId: data['job_id']?.toString(),
        outputDocxPath: data['output_docx_path']?.toString(),
        docxBytes: docxBytes,
      );
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<JobStatusInfo?> getJobStatus(String jobId) async {
    try {
      final response = await _client.functions.invoke(
        'get_job_status',
        headers: _functionHeaders(),
        body: {'job_id': jobId},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      final rawJob = data['job'];
      if (rawJob is! Map<dynamic, dynamic>) return null;
      final map = rawJob.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      final status = map['status']?.toString() ?? 'queued';
      final progressRaw = map['progress_pct'];
      final progressPct = progressRaw is num
          ? progressRaw.toInt()
          : int.tryParse(progressRaw?.toString() ?? '') ?? 0;

      return JobStatusInfo(
        jobId: map['id']?.toString() ?? jobId,
        status: status,
        progressPct: progressPct,
        errorCode: map['error_code']?.toString(),
        errorMessage: map['error_message']?.toString(),
        outputDocxPath: map['output_docx_path']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<JobStatusInfo?> pollJobUntilDone(
    String jobId, {
    Duration interval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 15),
    void Function(JobStatusInfo status)? onTick,
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      final status = await getJobStatus(jobId);
      if (status == null) {
        await Future<void>.delayed(interval);
        continue;
      }
      onTick?.call(status);
      if (status.isDone) return status;
      await Future<void>.delayed(interval);
    }
    return null;
  }

  Future<String?> getSignedDownloadUrl(String jobId) async {
    try {
      final response = await _client.functions.invoke(
        'get_download_url',
        headers: _functionHeaders(),
        body: {'job_id': jobId},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      final signed = data['signed_url']?.toString();
      if (signed == null || signed.isEmpty) return null;
      return signed;
    } catch (_) {
      return null;
    }
  }

  Future<List<ConversionHistoryItem>> fetchRecent({int limit = 20}) async {
    try {
      final rows = await _client
          .from('ocr_jobs')
          .select(
            'id, output_docx_path, created_at, status, total_size_mb, output_md_path',
          )
          .order('created_at', ascending: false)
          .limit(limit);

      final now = DateTime.now();
      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => _mapHistoryRow(row, now))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  ConversionHistoryItem _mapHistoryRow(Map<String, dynamic> row, DateTime now) {
    final id = row['id']?.toString() ?? 'job-unknown';
    final createdAtRaw = row['created_at']?.toString();
    final createdAt = DateTime.tryParse(createdAtRaw ?? '');
    final outputPath = row['output_docx_path']?.toString();
    final statusRaw = row['status']?.toString() ?? UploadState.ready.name;
    final status = _toJobStatus(statusRaw);
    final sizeRaw = row['total_size_mb'];
    final sizeMb = sizeRaw is num ? sizeRaw.toDouble() : 0.0;

    final name = _filenameFromPath(outputPath) ?? 'converted_$id.docx';
    final subtitle =
        createdAt == null ? statusRaw : _formatSubtitle(createdAt, now);
    final group = _resolveGroup(createdAt, now);

    return ConversionHistoryItem(
      id: id,
      name: name,
      subtitle: subtitle,
      sizeLabel: sizeMb <= 0 ? '-' : '${sizeMb.toStringAsFixed(1)} MB',
      group: group,
      status: status,
      outputDocxPath: outputPath,
      showDownload: outputPath != null && outputPath.isNotEmpty,
    );
  }

  ConversionJobStatus _toJobStatus(String raw) {
    switch (raw) {
      case 'queued':
        return ConversionJobStatus.queued;
      case 'processing':
        return ConversionJobStatus.processing;
      case 'succeeded':
        return ConversionJobStatus.succeeded;
      case 'failed':
        return ConversionJobStatus.failed;
      default:
        return ConversionJobStatus.unknown;
    }
  }

  HistoryGroup _resolveGroup(DateTime? createdAt, DateTime now) {
    if (createdAt == null) return HistoryGroup.lastWeek;
    final local = createdAt.toLocal();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfYesterday = startOfToday.subtract(const Duration(days: 1));

    if (local.isAfter(startOfToday)) return HistoryGroup.today;
    if (local.isAfter(startOfYesterday)) return HistoryGroup.yesterday;
    return HistoryGroup.lastWeek;
  }

  String _formatSubtitle(DateTime createdAt, DateTime now) {
    final local = createdAt.toLocal();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) {
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    return '${local.month}/${local.day}/${local.year}';
  }

  String? _filenameFromPath(String? path) {
    if (path == null || path.isEmpty) return null;
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  String _guessMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return 'application/octet-stream';
  }

  Map<String, String> _functionHeaders() {
    // Prefer the signed-in user token so RLS-scoped reads/writes line up with
    // the job owner; otherwise fall back to the anon key (guest mode).
    final sessionToken = _client.auth.currentSession?.accessToken;
    final token = (sessionToken != null && sessionToken.isNotEmpty)
        ? sessionToken
        : AppEnv.supabaseAnonKey.trim();
    return {'Authorization': 'Bearer $token'};
  }
}
