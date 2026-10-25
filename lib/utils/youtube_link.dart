String? youtubeVideoId(String input) {
  try {
    final uri = Uri.tryParse(input.trim());
    if (uri == null || uri.scheme != 'https' || uri.userInfo.isNotEmpty) {
      return null;
    }

    String? id;
    if (uri.host == 'youtu.be') {
      if (uri.pathSegments.length == 1) id = uri.pathSegments.single;
    } else if (const {
      'youtube.com',
      'www.youtube.com',
      'm.youtube.com',
      'music.youtube.com',
    }.contains(uri.host)) {
      if (uri.path == '/watch') {
        id = uri.queryParameters['v'];
      } else if (uri.pathSegments.length == 2 &&
          const {'shorts', 'embed'}.contains(uri.pathSegments.first)) {
        id = uri.pathSegments.last;
      }
    }

    return id != null && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id)
        ? id
        : null;
  } on FormatException {
    return null;
  }
}
