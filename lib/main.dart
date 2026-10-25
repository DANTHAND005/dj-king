import 'package:flutter/material.dart';

import 'app.dart';
import 'services/game_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(DjKingApp(signIn: GameService().signIn));
}
