import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String kosName;
  final String room;
  final String fcmToken;
  final DateTime createdAt;
  final double rating;
  final int ratingCount;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.kosName = '',
    this.room = '',
    this.fcmToken = '',
    required this.createdAt,
    this.rating = 0.0,
    this.ratingCount = 0,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      kosName: data['kosName'] ?? '',
      room: data['room'] ?? '',
      fcmToken: data['fcmToken'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'kosName': kosName,
        'room': room,
        'fcmToken': fcmToken,
        'createdAt': FieldValue.serverTimestamp(),
        'rating': rating,
        'ratingCount': ratingCount,
      };
}
