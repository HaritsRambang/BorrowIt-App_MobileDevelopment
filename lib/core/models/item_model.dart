import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String ownerId;
  final String ownerName;
  final String ownerAvatar;
  final String category;
  final String condition;
  final double pricePerDay; // 0 = gratis
  final int maxDays;
  final String location; // e.g., "Kamar 12, Lantai 1"
  final String kosName;  // e.g., "Kos Mawar"
  final bool isAvailable;
  final double rating;
  final int ratingCount;
  final DateTime createdAt;
  final GeoPoint? geoPoint;

  const ItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.ownerId,
    required this.ownerName,
    this.ownerAvatar = '',
    required this.category,
    required this.condition,
    required this.pricePerDay,
    this.maxDays = 3,
    required this.location,
    this.kosName = '',
    this.isAvailable = true,
    this.rating = 0.0,
    this.ratingCount = 0,
    required this.createdAt,
    this.geoPoint,
  });

  String get priceLabel =>
      pricePerDay <= 0 ? 'Gratis' : 'Rp${(pricePerDay / 1000).toStringAsFixed(0)}k/hari';

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      ownerAvatar: data['ownerAvatar'] ?? '',
      category: data['category'] ?? 'Lainnya',
      condition: data['condition'] ?? 'Baik',
      pricePerDay: (data['pricePerDay'] ?? 0).toDouble(),
      maxDays: data['maxDays'] ?? 3,
      location: data['location'] ?? '',
      kosName: data['kosName'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      rating: (data['rating'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      geoPoint: data['geoPoint'] as GeoPoint?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'ownerAvatar': ownerAvatar,
        'category': category,
        'condition': condition,
        'pricePerDay': pricePerDay,
        'maxDays': maxDays,
        'location': location,
        'kosName': kosName,
        'isAvailable': isAvailable,
        'rating': rating,
        'ratingCount': ratingCount,
        'createdAt': FieldValue.serverTimestamp(),
        'geoPoint': geoPoint,
      };

  ItemModel copyWith({bool? isAvailable}) => ItemModel(
        id: id,
        name: name,
        description: description,
        imageUrl: imageUrl,
        ownerId: ownerId,
        ownerName: ownerName,
        ownerAvatar: ownerAvatar,
        category: category,
        condition: condition,
        pricePerDay: pricePerDay,
        maxDays: maxDays,
        location: location,
        kosName: kosName,
        isAvailable: isAvailable ?? this.isAvailable,
        rating: rating,
        ratingCount: ratingCount,
        createdAt: createdAt,
        geoPoint: geoPoint,
      );
}
