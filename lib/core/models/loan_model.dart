import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class LoanModel {
  final String id;
  final String itemId;
  final String itemName;
  final String itemImageUrl;
  final String borrowerId;
  final String borrowerName;
  final String ownerId;
  final String ownerName;
  final String status; // pending, approved, rejected, active, completed, cancelled
  final int days;
  final double totalPrice;
  final String message;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? returnedAt;
  final DateTime? dueDate;

  const LoanModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.itemImageUrl,
    required this.borrowerId,
    required this.borrowerName,
    required this.ownerId,
    required this.ownerName,
    required this.status,
    required this.days,
    required this.totalPrice,
    this.message = '',
    required this.requestedAt,
    this.approvedAt,
    this.returnedAt,
    this.dueDate,
  });

  bool get isPending => status == AppConstants.loanStatusPending;
  bool get isActive => status == AppConstants.loanStatusActive;
  bool get isCompleted => status == AppConstants.loanStatusCompleted;

  factory LoanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoanModel(
      id: doc.id,
      itemId: data['itemId'] ?? '',
      itemName: data['itemName'] ?? '',
      itemImageUrl: data['itemImageUrl'] ?? '',
      borrowerId: data['borrowerId'] ?? '',
      borrowerName: data['borrowerName'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      status: data['status'] ?? AppConstants.loanStatusPending,
      days: data['days'] ?? 1,
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      message: data['message'] ?? '',
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      returnedAt: (data['returnedAt'] as Timestamp?)?.toDate(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'itemName': itemName,
        'itemImageUrl': itemImageUrl,
        'borrowerId': borrowerId,
        'borrowerName': borrowerName,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'status': status,
        'days': days,
        'totalPrice': totalPrice,
        'message': message,
        'requestedAt': FieldValue.serverTimestamp(),
        'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
        'returnedAt': returnedAt != null ? Timestamp.fromDate(returnedAt!) : null,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      };
}
