import 'package:flutter/material.dart';

import '../services/game_service.dart';
import '../widgets/logo.dart';
import 'lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.game});

  final GameService game;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _enter(Future<String> Function(String nickname) action) async {
    final nickname = _name.text.trim();
    if (nickname.isEmpty || nickname.length > 20) {
      setState(() => _error = 'Enter a nickname of 1 to 20 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = await action(nickname);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LobbyScreen(game: widget.game, code: code),
        ),
      );
      _code.clear(); // a finished game's code should not linger
    } on GameException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not reach the game. Check your connection.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _join() {
    if (!_busy) {
      _enter((nickname) => widget.game.joinRoom(_code.text, nickname));
    }
  }

  @override
  Widget build(BuildContext context) {
    const bigText = TextStyle(
      fontFamily: 'Lilita',
      fontSize: 22,
      color: Colors.black87,
    );
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Logo(),
                  const SizedBox(height: 4),
                  const Text(
                    'The song battle party game',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(width: 3),
                      boxShadow: const [
                        BoxShadow(offset: Offset(6, 6), color: Colors.black),
                      ],
                    ),
                    child: Theme(
                      data: ThemeData(
                        useMaterial3: true,
                        textTheme: Typography.material2021().black.apply(
                          fontFamily: 'Lilita',
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _code,
                            maxLength: 4,
                            textAlign: TextAlign.center,
                            textCapitalization: TextCapitalization.characters,
                            style: bigText,
                            decoration: const InputDecoration(
                              hintText: 'Room code',
                              counterText: '',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _name,
                            maxLength: 20,
                            onSubmitted: (_) => _join(),
                            textAlign: TextAlign.center,
                            style: bigText,
                            decoration: const InputDecoration(
                              hintText: 'Nickname',
                              counterText: '',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFFC93C),
                              foregroundColor: Colors.black,
                              side: const BorderSide(width: 3),
                              minimumSize: const Size.fromHeight(52),
                              textStyle: const TextStyle(
                                fontFamily: 'Lilita',
                                fontSize: 22,
                              ),
                            ),
                            onPressed: _busy ? null : _join,
                            child: Text(_busy ? 'Joining...' : 'Join'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_error case final message?) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(message, textAlign: TextAlign.center),
                    ),
                  ],
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _enter(widget.game.createRoom),
                    child: const Text('Host a game'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
