import 'package:pdfword_pro/features/shared/models/conversion_history_item.dart';

abstract class HistoryRepository {
  List<ConversionHistoryItem> seedHistory();
}
