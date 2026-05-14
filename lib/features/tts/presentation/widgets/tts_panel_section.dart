import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../panel/presentation/providers/panel_providers.dart';
import '../providers/tts_providers.dart';

class TtsPanelSection extends ConsumerWidget {
  const TtsPanelSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(currentSelectionProvider);
    final ttsState = ref.watch(ttsStateProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selection?.text ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          ttsState.when(
            data: (_) => const Icon(Icons.volume_up, size: 18),
            loading: () =>
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            error: (e, stack) => const Icon(Icons.error_outline, size: 18, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
