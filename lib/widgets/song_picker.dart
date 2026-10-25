import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/youtube_search_service.dart';

class SongPicker extends StatefulWidget {
  const SongPicker({
    super.key,
    required this.search,
    required this.onSelected,
    this.selectedId,
  });

  final Future<List<Song>> Function(String) search;
  final ValueChanged<Song> onSelected;
  final String? selectedId;

  @override
  State<SongPicker> createState() => _SongPickerState();
}

class _SongPickerState extends State<SongPicker> {
  final _query = TextEditingController();
  final _form = GlobalKey<FormState>();
  Future<List<Song>>? _results;

  void _search() {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _results = Future.sync(() => widget.search(_query.text.trim()));
      // Handle fast failures before FutureBuilder subscribes on the next frame.
      _results!.ignore();
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FutureBuilder<List<Song>>(
            future: _results,
            builder: (context, snapshot) {
              final loading =
                  snapshot.connectionState == ConnectionState.waiting;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Search YouTube',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: _form,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _query,
                            decoration: const InputDecoration(
                              labelText: 'Song or artist',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            textInputAction: TextInputAction.search,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Enter a song or artist.'
                                : null,
                            onFieldSubmitted: (_) {
                              if (!loading) _search();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: 'Search YouTube',
                          onPressed: loading ? null : _search,
                          icon: const Icon(Icons.search),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: _content(snapshot)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _content(AsyncSnapshot<List<Song>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Searching YouTube'),
      );
    }
    if (snapshot.hasError) {
      final error = snapshot.error;
      return Center(
        child: SingleChildScrollView(
          child: Semantics(
            liveRegion: true,
            child: Text(
              error is YoutubeSearchException
                  ? error.message
                  : 'Search failed. Please try again.',
            ),
          ),
        ),
      );
    }
    if (_results == null) {
      return const Center(
        child: Text('Find a song or artist, then pick a video.'),
      );
    }
    final songs = snapshot.requireData;
    if (songs.isEmpty) {
      return const Center(child: Text('No videos found. Try another search.'));
    }
    return ListView.separated(
      itemCount: songs.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final song = songs[index];
        final selected = widget.selectedId == song.videoId;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              song.thumbnailUrl,
              width: 88,
              height: 50,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => const SizedBox(
                width: 88,
                height: 50,
                child: Icon(Icons.music_note),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.channel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  TextButton(
                    onPressed: selected ? null : () => widget.onSelected(song),
                    child: Text(selected ? 'Selected' : 'Pick this song'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
