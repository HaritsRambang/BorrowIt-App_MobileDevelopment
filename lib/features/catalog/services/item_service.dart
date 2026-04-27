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

  /// Real-time stream of all available items, newest first
  Stream<List<ItemModel>> getItems({String? category}) {
    Query<Map<String, dynamic>> query = _db
        .collection(AppConstants.itemsCollection)
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true);

    if (category != null && category != 'Semua') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map(
          (snap) => snap.docs.map(ItemModel.fromFirestore).toList(),
        );
  }

  /// Stream of items owned by the current user
  Stream<List<ItemModel>> getMyItems() {
    final uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection(AppConstants.itemsCollection)
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ItemModel.fromFirestore).toList());
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
    final ownerName = (userDoc.data()?['name'] as String?) ?? user.displayName ?? 'Anonymous';
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

  // ─── Loan requests ────────────────────────────────────────────────────────

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
    final borrowerName = (userDoc.data()?['name'] as String?) ?? user.displayName ?? 'Anonymous';

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

  /// Stream loans for the current user as borrower
  Stream<List<LoanModel>> getMyLoansAsBorrower() {
    final uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection(AppConstants.loansCollection)
        .where('borrowerId', isEqualTo: uid)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(LoanModel.fromFirestore).toList());
  }

  /// Stream loans for the current user as owner (incoming requests)
  Stream<List<LoanModel>> getIncomingRequests() {
    final uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection(AppConstants.loansCollection)
        .where('ownerId', isEqualTo: uid)
        .where('status', isEqualTo: AppConstants.loanStatusPending)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(LoanModel.fromFirestore).toList());
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
