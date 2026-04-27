import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream of the current Firebase user
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in user (nullable)
  User? get currentUser => _auth.currentUser;

  /// Register with email, password, name, kos info
  Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
    String kosName = '',
    String room = '',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(name);
    final user = UserModel(
      id: credential.user!.uid,
      name: name,
      email: email,
      kosName: kosName,
      room: room,
      createdAt: DateTime.now(),
    );
    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.id)
        .set(user.toMap());
    return user;
  }

  /// Login with email & password
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Sign out
  Future<void> signOut() => _auth.signOut();

  /// Fetch UserModel for given uid
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Update FCM token in Firestore
  Future<void> updateFcmToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'fcmToken': token});
  }
}
