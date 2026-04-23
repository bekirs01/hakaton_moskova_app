import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';

/// One shared progress line for all flows. [value] in 0.0..1.0, [message] is the active step.
class PipelineProgressBar extends StatelessWidget {
  const PipelineProgressBar({
    super.key,
    required this.value,
    this.message,
  });

  final double value;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              message!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(MemeopsRadii.sm),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            color: scheme.primary,
          ),
        ),
      ],
    );
  }
}
