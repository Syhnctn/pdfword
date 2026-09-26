import 'package:pdfword_pro/features/shared/models/conversion_history_item.dart';
import 'package:pdfword_pro/features/shared/repositories/history_repository.dart';

class MockHistoryRepository implements HistoryRepository {
  @override
  List<ConversionHistoryItem> seedHistory() {
    return const [
      ConversionHistoryItem(
        id: 'h-1',
        name: 'Contract_Final_v2.docx',
        subtitle: '10:42 AM',
        sizeLabel: '1.2 MB',
        group: HistoryGroup.today,
        status: ConversionJobStatus.succeeded,
        outputDocxPath: 'mock/contract_final_v2.docx',
        showDownload: true,
      ),
      ConversionHistoryItem(
        id: 'h-2',
        name: 'Resume_2024_Update.docx',
        subtitle: '09:15 AM',
        sizeLabel: '450 KB',
        group: HistoryGroup.today,
        status: ConversionJobStatus.processing,
      ),
      ConversionHistoryItem(
        id: 'h-3',
        name: 'Marketing_Brief_Q3.docx',
        subtitle: '4:20 PM',
        sizeLabel: '2.8 MB',
        group: HistoryGroup.yesterday,
        status: ConversionJobStatus.failed,
      ),
      ConversionHistoryItem(
        id: 'h-4',
        name: 'Invoice_TEMPLATE_Oct.docx',
        subtitle: 'Oct 20, 2023',
        sizeLabel: '156 KB',
        group: HistoryGroup.lastWeek,
        status: ConversionJobStatus.succeeded,
        outputDocxPath: 'mock/invoice_template_oct.docx',
        showDownload: true,
      ),
      ConversionHistoryItem(
        id: 'h-5',
        name: 'Study_Notes_Bio.docx',
        subtitle: 'Oct 18, 2023',
        sizeLabel: '5.8 MB',
        group: HistoryGroup.lastWeek,
        status: ConversionJobStatus.queued,
      ),
    ];
  }
}
