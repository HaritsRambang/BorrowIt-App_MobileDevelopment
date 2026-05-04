import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/item_model.dart';
import '../../../core/models/loan_model.dart';

class ItemService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Real-time stream of all available items — no composite index needed
  /// Filtering & sorting done client-side to avoid Firestore index errors.
  Stream<List<ItemModel>> getItems({String? category}) {
    // Simple single-field query — no composite index required
    Query<Map<String, dynamic>> query = _db
        .collection(AppConstants.itemsCollection)
        .where('isAvailable', isEqualTo: true);

    return query.snapshots().map((snap) {
      var items = snap.docs.map(ItemModel.fromFirestore).toList();

      // Client-side category filter
      if (category != null && category != 'Semua') {
        items = items.where((i) => i.category == category).toList();
      }

      // Client-side sort: newest first
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  /// Stream of items owned by the current user (client-side sort)
  Stream<List<ItemModel>> getMyItems() {
    final uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection(AppConstants.itemsCollection)
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final items = snap.docs.map(ItemModel.fromFirestore).toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  /// Upload image and create item document
  Future<void> addItem({
    required File imageFile,
    required String name,
    required String description,
    required String category,
    required String condition,
    required double pricePerDay,
    required int maxDays,
    required String location,
    String kosName = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // 1. Upload image to Storage
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage
        .ref()
        .child(AppConstants.itemImagesPath)
        .child(user.uid)
        .child(fileName);
    await ref.putFile(imageFile);
    final imageUrl = await ref.getDownloadURL();

    // 2. Fetch owner name from Firestore
    final userDoc = await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();
    final ownerName =
        (userDoc.data()?['name'] as String?) ?? user.displayName ?? 'Anonymous';
    final ownerAvatar = (userDoc.data()?['avatarUrl'] as String?) ?? '';

    // 3. Save item to Firestore
    final item = ItemModel(
      id: '',
      name: name,
      description: description,
      imageUrl: imageUrl,
      ownerId: user.uid,
      ownerName: ownerName,
      ownerAvatar: ownerAvatar,
      category: category,
      condition: condition,
      pricePerDay: pricePerDay,
      maxDays: maxDays,
      location: location,
      kosName: kosName,
      createdAt: DateTime.now(),
    );
    await _db.collection(AppConstants.itemsCollection).add(item.toMap());
  }

  /// Toggle item availability
  Future<void> toggleAvailability(String itemId, bool isAvailable) async {
    await _db
        .collection(AppConstants.itemsCollection)
        .doc(itemId)
        .update({'isAvailable': isAvailable});
  }

  /// Delete item document and its storage image
  Future<void> deleteItem(ItemModel item) async {
    if (item.imageUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(item.imageUrl).delete();
      } catch (_) {}
    }
    await _db.collection(AppConstants.itemsCollection).doc(item.id).delete();
  }

  // ─── Seed Data ─────────────────────────────────────────────────────────────

  /// Populate Firestore with sample items if collection is empty.
  Future<void> seedSampleItems() async {
    // 1. Clean up old incorrect seed data (ownerId == 'seed')
    final oldSeeds = await _db
        .collection(AppConstants.itemsCollection)
        .where('ownerId', isEqualTo: 'seed')
        .get();
    
    final batch = _db.batch();
    for (final doc in oldSeeds.docs) {
      batch.delete(doc.reference);
    }

    // 2. Check if new distinct seeds exist
    final check = await _db
        .collection(AppConstants.itemsCollection)
        .where('ownerId', isEqualTo: 'seed_budi')
        .limit(1)
        .get();
    
    if (check.docs.isNotEmpty && oldSeeds.docs.isEmpty) return;

    final now = DateTime.now();
    final uid = _auth.currentUser?.uid;
    final userName = _auth.currentUser?.displayName ?? 'Pengguna';

    final seedItems = <Map<String, dynamic>>[
      {
        'name': 'Bor Listrik Bosch',
        'description':
            'Bor listrik multifungsi untuk berbagai keperluan. Lengkap dengan mata bor berbagai ukuran. Sangat cocok untuk pemasangan lemari, rak, atau furnitur.',
        'imageUrl': 'https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&w=500&q=80',
        'ownerId': 'seed_budi',
        'ownerName': 'Pak Budi',
        'ownerAvatar': 'https://i.pravatar.cc/150?u=budi',
        'category': 'Perkakas',
        'condition': 'Baik',
        'pricePerDay': 15000.0,
        'maxDays': 3,
        'location': 'Kamar 8, Lantai 2',
        'kosName': 'Kos Bahagia',
        'isAvailable': true,
        'rating': 4.8,
        'ratingCount': 12,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
      },
      {
        'name': 'Setrika Uap Philips',
        'description':
            'Setrika uap dengan teknologi terbaru, hasil setrikaan lebih rapi dan cepat. Kapasitas tangki air 300ml.',
        'imageUrl': 'https://images.unsplash.com/photo-1517677129300-07b130802f46?auto=format&fit=crop&w=500&q=80',
        'ownerId': 'seed_sari',
        'ownerName': 'Mbak Sari',
        'ownerAvatar': 'https://i.pravatar.cc/150?u=sari',
        'category': 'Elektronik',
        'condition': 'Sangat Baik',
        'pricePerDay': 8000.0,
        'maxDays': 2,
        'location': 'Kamar 3, Lantai 1',
        'kosName': 'Kos Sejahtera',
        'isAvailable': true,
        'rating': 4.5,
        'ratingCount': 8,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      },
      {
        'name': 'Rice Cooker Cosmos 1L',
        'description':
            'Rice cooker ukuran 1 liter, cocok untuk memasak 2-4 porsi nasi. Dilengkapi mode warm otomatis.',
        'imageUrl': 'https://images.unsplash.com/photo-1585032226651-759b368d7246?auto=format&fit=crop&w=500&q=80',
        'ownerId': 'seed_dian',
        'ownerName': 'Mas Dian',
        'ownerAvatar': 'https://i.pravatar.cc/150?u=dian',
        'category': 'Dapur',
        'condition': 'Baik',
        'pricePerDay': 0.0,
        'maxDays': 5,
        'location': 'Kamar 12, Lantai 3',
        'kosName': 'Kos Bahagia',
        'isAvailable': true,
        'rating': 4.2,
        'ratingCount': 5,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      },
      {
        'name': 'Laptop Stand Ergonomis',
        'description':
            'Stand laptop aluminium adjustable, mendukung laptop 10-17 inch. Mengurangi pegal leher saat belajar online.',
        'imageUrl': 'https://images.unsplash.com/photo-1621252179027-94459d278660?auto=format&fit=crop&w=500&q=80',
        'ownerId': 'seed_rina',
        'ownerName': 'Kak Rina',
        'ownerAvatar': 'https://i.pravatar.cc/150?u=rina',
        'category': 'Elektronik',
        'condition': 'Sangat Baik',
        'pricePerDay': 5000.0,
        'maxDays': 7,
        'location': 'Kamar 6, Lantai 2',
        'kosName': 'Kos Makmur',
        'isAvailable': true,
        'rating': 4.9,
        'ratingCount': 20,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 5))),
      },
      {
        'name': 'Matras Lipat Camping',
        'description':
            'Matras lipat tebal 5cm, nyaman untuk tidur tamu atau camping. Ukuran 180x60cm saat dibentangkan.',
        'imageUrl': 'https://images.unsplash.com/photo-1523987355523-c7b5b0dd90a7?auto=format&fit=crop&w=500&q=80',
        'ownerId': 'seed_budi',
        'ownerName': 'Pak Budi',
        'ownerAvatar': 'https://i.pravatar.cc/150?u=budi',
        'category': 'Lainnya',
        'condition': 'Baik',
        'pricePerDay': 10000.0,
        'maxDays': 7,
        'location': 'Kamar 8, Lantai 2',
        'kosName': 'Kos Bahagia',
        'isAvailable': true,
        'rating': 4.0,
        'ratingCount': 3,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      },
      {
        'name': 'Panci Presto 5L',
        'description':
            'Panci presto kapasitas 5 liter. Cocok untuk memasak daging empuk, rendang, atau sayur lodeh dalam waktu singkat.',
        'imageUrl': 'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?auto=format&fit=crop&w=500&q=80',
        'ownerId': 'seed_sari',
        'ownerName': 'Mbak Sari',
        'ownerAvatar': 'https://i.pravatar.cc/150?u=sari',
        'category': 'Dapur',
        'condition': 'Baik',
        'pricePerDay': 12000.0,
        'maxDays': 3,
        'location': 'Kamar 3, Lantai 1',
        'kosName': 'Kos Sejahtera',
        'isAvailable': true,
        'rating': 4.6,
        'ratingCount': 9,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 4))),
      },
      {
        'name': 'Tangga Lipat Aluminium',
        'description':
            'Tangga lipat 3 step, kapasitas hingga 150kg. Cocok untuk mengganti lampu, cat tembok, atau pasang barang di atas lemari.',
        'imageUrl': 'https://images.unsplash.com/photo-1533256050519-20df11a2f9cb?auto=format&fit=crop&w=500&q=80',
        'ownerId': 'seed_dian',
        'ownerName': 'Mas Dian',
        'ownerAvatar': 'https://i.pravatar.cc/150?u=dian',
        'category': 'Perkakas',
        'condition': 'Baik',
        'pricePerDay': 20000.0,
        'maxDays': 2,
        'location': 'Kamar 12, Lantai 3',
        'kosName': 'Kos Bahagia',
        'isAvailable': true,
        'rating': 4.7,
        'ratingCount': 6,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 12))),
      },
      {
        'name': 'Blender Portable Kecil',
        'description':
            'Blender portable 350ml, bisa langsung diminum dari botolnya. USB rechargeable, praktis dibawa kemana-mana.',
        'imageUrl': 'https://images.unsplash.com/photo-1570222094114-d054a817e56b?auto=format&fit=crop&w=500&q=80',
        'ownerId': 'seed_rina',
        'ownerName': 'Kak Rina',
        'ownerAvatar': 'https://i.pravatar.cc/150?u=rina',
        'category': 'Dapur',
        'condition': 'Sangat Baik',
        'pricePerDay': 0.0,
        'maxDays': 3,
        'location': 'Kamar 6, Lantai 2',
        'kosName': 'Kos Makmur',
        'isAvailable': true,
        'rating': 4.3,
        'ratingCount': 7,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 6))),
      },
    ];

    if (uid != null) {
      final myItemId1 = _db.collection(AppConstants.itemsCollection).doc().id;
      final myItemId2 = _db.collection(AppConstants.itemsCollection).doc().id;

      seedItems.addAll([
        {
          '_id': myItemId1,
          'name': 'Kamera Mirrorless Sony',
          'description': 'Kamera mirrorless lengkap dengan lensa kit.',
          'imageUrl': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=500&q=80',
          'ownerId': uid,
          'ownerName': userName,
          'ownerAvatar': '',
          'category': 'Elektronik',
          'condition': 'Sangat Baik',
          'pricePerDay': 50000.0,
          'maxDays': 5,
          'location': 'Kamar Saya',
          'kosName': 'Kos Saya',
          'isAvailable': true,
          'rating': 5.0,
          'ratingCount': 2,
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        },
        {
          '_id': myItemId2,
          'name': 'Proyektor Mini',
          'description': 'Proyektor mini cocok buat nobar di kamar.',
          'imageUrl': 'https://images.unsplash.com/photo-1626307416415-30eb49987a02?auto=format&fit=crop&w=500&q=80',
          'ownerId': uid,
          'ownerName': userName,
          'ownerAvatar': '',
          'category': 'Elektronik',
          'condition': 'Baik',
          'pricePerDay': 25000.0,
          'maxDays': 2,
          'location': 'Kamar Saya',
          'kosName': 'Kos Saya',
          'isAvailable': true,
          'rating': 4.5,
          'ratingCount': 4,
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        }
      ]);

      // Generate a fake incoming request
      final fakeLoan = {
        'itemId': myItemId1,
        'itemName': 'Kamera Mirrorless Sony',
        'itemImageUrl': '',
        'borrowerId': 'seed_dian',
        'borrowerName': 'Mas Dian',
        'ownerId': uid,
        'ownerName': userName,
        'status': AppConstants.loanStatusPending,
        'days': 2,
        'totalPrice': 100000.0,
        'message': 'Halo kak, mau pinjam kameranya buat tugas akhir besok, bisa?',
        'requestedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
      };
      batch.set(_db.collection(AppConstants.loansCollection).doc(), fakeLoan);
    }

    for (final item in seedItems) {
      final docId = item.remove('_id') as String? ?? _db.collection(AppConstants.itemsCollection).doc().id;
      batch.set(_db.collection(AppConstants.itemsCollection).doc(docId), item);
    }
    
    await batch.commit();
  }

  // ─── Loan requests ──────────────────────────────────────────────────────────

  /// Submit a loan request (creates a pending loan document)
  Future<void> requestLoan({
    required ItemModel item,
    required int days,
    String message = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final userDoc = await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();
    final borrowerName =
        (userDoc.data()?['name'] as String?) ?? user.displayName ?? 'Anonymous';

    final loan = LoanModel(
      id: '',
      itemId: item.id,
      itemName: item.name,
      itemImageUrl: item.imageUrl,
      borrowerId: user.uid,
      borrowerName: borrowerName,
      ownerId: item.ownerId,
      ownerName: item.ownerName,
      status: AppConstants.loanStatusPending,
      days: days,
      totalPrice: item.pricePerDay * days,
      message: message,
      requestedAt: DateTime.now(),
    );
    await _db.collection(AppConstants.loansCollection).add(loan.toMap());
  }

  /// Stream loans for the current user as borrower (client-side sort)
  Stream<List<LoanModel>> getMyLoansAsBorrower() {
    final uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection(AppConstants.loansCollection)
        .where('borrowerId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final loans = snap.docs.map(LoanModel.fromFirestore).toList();
      loans.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return loans;
    });
  }

  /// Stream loans for the current user as owner (incoming requests) — client-side sort
  Stream<List<LoanModel>> getIncomingRequests() {
    final uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection(AppConstants.loansCollection)
        .where('ownerId', isEqualTo: uid)
        .where('status', isEqualTo: AppConstants.loanStatusPending)
        .snapshots()
        .map((snap) {
      final loans = snap.docs.map(LoanModel.fromFirestore).toList();
      loans.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return loans;
    });
  }

  /// Update loan status (approve / reject / complete)
  Future<void> updateLoanStatus(String loanId, String newStatus,
      {DateTime? dueDate}) async {
    final update = <String, dynamic>{'status': newStatus};
    if (newStatus == AppConstants.loanStatusApproved) {
      update['approvedAt'] = FieldValue.serverTimestamp();
      if (dueDate != null) update['dueDate'] = Timestamp.fromDate(dueDate);
    }
    if (newStatus == AppConstants.loanStatusCompleted) {
      update['returnedAt'] = FieldValue.serverTimestamp();
    }
    await _db
        .collection(AppConstants.loansCollection)
        .doc(loanId)
        .update(update);
  }
}
