import 'package:flutter/material.dart';

import '../models/room.dart';

const genresToPick = 10;

/// Host picks exactly 10 genres. Returns them, an empty list for "random from all", or null if cancelled.
Future<List<String>?> pickGenres(BuildContext context, List<String> current) {
  final picked = {...current};
  return showDialog<List<String>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Pick $genresToPick genres (${picked.length})'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 6,
              children: [
                for (final genre in gameGenres)
                  FilterChip(
                    label: Text(genre),
                    selected: picked.contains(genre),
                    onSelected: (on) => setState(() {
                      if (!on) {
                        picked.remove(genre);
                      } else if (picked.length < genresToPick) {
                        picked.add(genre);
                      }
                    }),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, <String>[]),
            child: Text('Random from all ${gameGenres.length}'),
          ),
          TextButton(
            onPressed: picked.length == genresToPick
                ? () => Navigator.pop(context, picked.toList())
                : null,
            child: const Text('Use these'),
          ),
        ],
      ),
    ),
  );
}

/// A small list dialog; returns the value of the tapped option, or null if dismissed.
Future<T?> choose<T>(
  BuildContext context,
  String title,
  List<(T, String)> options,
) => showDialog<T>(
  context: context,
  builder: (context) => SimpleDialog(
    title: Text(title),
    children: [
      for (final (value, label) in options)
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, value),
          child: Text(label, style: const TextStyle(fontSize: 20)),
        ),
    ],
  ),
);
