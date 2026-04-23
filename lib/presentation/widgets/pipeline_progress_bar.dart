import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              message!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
