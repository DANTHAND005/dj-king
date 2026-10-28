import 'package:flutter/material.dart';

import 'app.dart';
import 'services/game_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final game = GameService();
  runApp(DjKingApp(signIn: game.signIn, game: game));
}
