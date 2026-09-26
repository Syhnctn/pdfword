import { createClient } from "https://esm.sh/@supabase/supabase-js@2.56.0";
import { corsHeaders } from "../_shared/cors.ts";

type IncomingFile = {
  file_id?: string;
  name?: string;
  size_mb?: number;
  mime_type?: string;
  state?: string;
};

type StoredInputFile = IncomingFile & {
  bucket: string;
  path: string;
  file_name: string;
};

const DAILY_FREE_LIMIT = 3;

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse(405, { error: "method_not_allowed" });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse(500, { error: "missing_supabase_env" });
    }

    const admin = createClient(supabaseUrl, serviceRoleKey);

    const authHeader = req.headers.get("Authorization") ?? "";
    const jwt = authHeader.replace("Bearer ", "").trim();
    let userId: string | null = null;

    if (jwt) {
      const authResult = await admin.auth.getUser(jwt);
      userId = authResult.data.user?.id ?? null;
    }

    const body = (await req.json().catch(() => ({}))) as {
      files?: IncomingFile[];
      source?: string;
      device_id_hash?: string;
    };

    const files = Array.isArray(body.files) ? body.files : [];
    if (files.length === 0) {
      return jsonResponse(400, { error: "files_required" });
    }

    const source = body.source?.toString() || "flutter_app";
    const deviceIdHash = body.device_id_hash?.toString() ?? null;
    const inputBucket = Deno.env.get("OCR_INPUT_BUCKET") ?? "ocr-inputs";
    const totalSizeMb = files.reduce((sum, file) => {
      const size = Number(file.size_mb ?? 0);
      return sum + (Number.isFinite(size) ? size : 0);
    }, 0);

    const usageKey = userId ?? deviceIdHash ?? "anonymous";
    const todayIso = new Date().toISOString().slice(0, 10);
    const usageRes = await admin
      .from("daily_usage")
      .select("id, docs_used")
      .eq("usage_date", todayIso)
      .eq(userId ? "user_id" : "device_id_hash", usageKey)
      .maybeSingle();

    if (usageRes.error && usageRes.error.code !== "PGRST116") {
      return jsonResponse(500, { error: "usage_lookup_failed" });
    }

    const docsUsed = usageRes.data?.docs_used ?? 0;
    if (docsUsed >= DAILY_FREE_LIMIT) {
      return jsonResponse(429, {
        error: "quota_exceeded",
        daily_limit: DAILY_FREE_LIMIT,
      });
    }

    if (usageRes.data?.id) {
      await admin
        .from("daily_usage")
        .update({ docs_used: docsUsed + 1 })
        .eq("id", usageRes.data.id);
    } else {
      await admin.from("daily_usage").insert({
        user_id: userId,
        device_id_hash: userId ? null : usageKey,
        usage_date: todayIso,
        docs_used: 1,
      });
    }

    const insertRes = await admin
      .from("ocr_jobs")
      .insert({
        user_id: userId,
        device_id_hash: userId ? null : usageKey,
        source,
        status: "queued",
        progress_pct: 0,
        input_meta: files,
        total_size_mb: totalSizeMb,
      })
      .select("id")
      .single();

    if (insertRes.error || !insertRes.data) {
      return jsonResponse(500, {
        error: "job_insert_failed",
        detail: insertRes.error?.message,
      });
    }

    const uploadTargets: Array<Record<string, string>> = [];
    const storedInputMeta: StoredInputFile[] = [];
    for (let index = 0; index < files.length; index += 1) {
      const file = files[index];
      const fileId = file.file_id?.toString().trim() || `file-${index}`;
      const originalName = (file.name?.toString().trim() || `input-${index}.pdf`)
        .replace(/[^a-zA-Z0-9._-]/g, "_");
      const path = `${insertRes.data.id}/input/${index
        .toString()
        .padStart(2, "0")}_${originalName}`;

      const signedRes = await admin.storage
        .from(inputBucket)
        .createSignedUploadUrl(path);

      if (signedRes.error || !signedRes.data) {
        return jsonResponse(500, {
          error: "signed_upload_url_failed",
          detail: signedRes.error?.message,
        });
      }

      uploadTargets.push({
        file_id: fileId,
        file_name: originalName,
        bucket: inputBucket,
        path,
        token: signedRes.data.token,
      });

      storedInputMeta.push({
        ...file,
        file_id: fileId,
        file_name: originalName,
        bucket: inputBucket,
        path,
      });
    }

    const metaUpdateRes = await admin
      .from("ocr_jobs")
      .update({ input_meta: storedInputMeta })
      .eq("id", insertRes.data.id);

    if (metaUpdateRes.error) {
      return jsonResponse(500, {
        error: "job_meta_update_failed",
        detail: metaUpdateRes.error.message,
      });
    }

    return jsonResponse(200, {
      job_id: insertRes.data.id,
      status: "queued",
      upload_targets: uploadTargets,
    });
  } catch (error) {
    return jsonResponse(500, {
      error: "unexpected_error",
      detail: error instanceof Error ? error.message : "unknown",
    });
  }
});
