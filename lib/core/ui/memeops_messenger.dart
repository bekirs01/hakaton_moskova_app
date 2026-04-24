import 'package:flutter/material.dart';

/// Zamanlanmış arşiv gönderimi gibi [BuildContext] olmayan durumlarda SnackBar için.
class MemeopsMessenger {
  MemeopsMessenger._();

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(debugLabel: 'memeops_messenger');
}
