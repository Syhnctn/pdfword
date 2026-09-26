import 'package:pdfword_pro/features/shared/models/app_file_item.dart';
import 'package:pdfword_pro/features/shared/models/conversion_history_item.dart';

abstract class ConversionRepository {
  List<AppFileItem> seedSelectedFiles();

  List<ConversionHistoryItem> seedRecentConversions();
}
