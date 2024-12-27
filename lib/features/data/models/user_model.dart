class UserModel {
  final String uid;
  final String email;
  final String? username;
  final String? displayName;
  final DateTime createdAt;
  final DateTime lastLogin;
  final Map<String, dynamic> preferences;

  UserModel({
    required this.uid,
    required this.email,
    this.username,
    this.displayName,
    required this.createdAt,
    required this.lastLogin,
    this.preferences = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'displayName': displayName ?? username,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'preferences': preferences,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      username: map['username'],
      displayName: map['displayName'],
      createdAt: DateTime.parse(map['createdAt']),
      lastLogin: DateTime.parse(map['lastLogin']),
      preferences: map['preferences'] ?? {},
    );
  }
}
