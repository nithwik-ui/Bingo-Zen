import 'enums.dart';

/// Lightweight user representation used for both self and opponent views.
class User {
  const User({
    required this.id,
    required this.displayName,
    this.handle,
    this.avatarUrl,
    this.elo = 1000,
    this.xp = 0,
    this.level = 1,
    this.presence = PlayerPresence.online,
    this.bio,
  });

  final String id;
  final String displayName;
  final String? handle;
  final String? avatarUrl;
  final int elo;
  final int xp;
  final int level;
  final PlayerPresence presence;
  final String? bio;

  User copyWith({
    String? displayName,
    String? handle,
    String? avatarUrl,
    int? elo,
    int? xp,
    int? level,
    PlayerPresence? presence,
    String? bio,
  }) {
    return User(
      id: id,
      displayName: displayName ?? this.displayName,
      handle: handle ?? this.handle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      elo: elo ?? this.elo,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      presence: presence ?? this.presence,
      bio: bio ?? this.bio,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      handle: json['handle'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      elo: (json['elo'] as num?)?.toInt() ?? 1000,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      presence: _parsePresence(json['presence']),
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'handle': handle,
        'avatarUrl': avatarUrl,
        'elo': elo,
        'xp': xp,
        'level': level,
        'presence': presence.name,
        'bio': bio,
      };
}

PlayerPresence _parsePresence(dynamic v) {
  if (v is! String) return PlayerPresence.offline;
  for (final p in PlayerPresence.values) {
    if (p.name == v) return p;
  }
  return PlayerPresence.offline;
}