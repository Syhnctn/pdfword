import 'package:pdfword_pro/features/shared/models/app_file_item.dart';
import 'package:pdfword_pro/features/shared/models/conversion_history_item.dart';
import 'package:pdfword_pro/features/shared/repositories/conversion_repository.dart';

class MockConversionRepository implements ConversionRepository {
  @override
  List<AppFileItem> seedSelectedFiles() {
    return const [];
  }

  @override
  List<ConversionHistoryItem> seedRecentConversions() {
    return const [];
  }
}
