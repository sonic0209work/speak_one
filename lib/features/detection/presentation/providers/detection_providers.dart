import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:speak_one_linux_accessibility/speak_one_linux_accessibility.dart';

import '../../../../core/services/isolate_service.dart';
import '../../domain/services/selection_filter_service.dart';

final isolateServiceProvider = Provider<IsolateService>(
  (_) => GetIt.I<IsolateService>(),
);

final filteredSelectionProvider = StreamProvider<TextSelectionEvent>((ref) {
  final service = ref.watch(isolateServiceProvider);
  final filter = SelectionFilterService();
  ref.onDispose(filter.dispose);
  return filter.filter(service.events);
});
