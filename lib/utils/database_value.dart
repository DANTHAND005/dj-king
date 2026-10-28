Map<String, dynamic> databaseMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
