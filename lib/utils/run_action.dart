import 'package:flutter/material.dart';

import '../services/game_service.dart';

/// Runs a game action and shows any failure as a snackbar.
Future<void> runAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
  } on GameException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Something went wrong. Check your connection and try again.',
        ),
      ),
    );
  }
}
