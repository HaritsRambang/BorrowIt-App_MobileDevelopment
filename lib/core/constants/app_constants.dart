/// App-wide constants
class AppConstants {
  // Firestore collections — prefixed to avoid collision with other Firebase projects
  static const String itemsCollection = 'borrowit_items';
  static const String usersCollection = 'borrowit_users';
  static const String loansCollection = 'borrowit_loans';
  static const String chatsCollection = 'borrowit_chats';
  static const String messagesSubcollection = 'messages';
  static const String notificationsCollection = 'borrowit_notifications';

  // Firebase Storage paths
  static const String itemImagesPath = 'borrowit/items';
  static const String avatarsPath = 'borrowit/avatars';

  // Item categories
  static const List<String> categories = [
    'Semua',
    'Perkakas',
    'Elektronik',
    'Dapur',
    'Pembersih',
    'Olahraga',
    'Hiburan',
    'Lainnya',
  ];

  // Item conditions
  static const List<String> conditions = [
    'Seperti Baru',
    'Baik',
    'Cukup',
  ];

  // Loan status
  static const String loanStatusPending = 'pending';
  static const String loanStatusApproved = 'approved';
  static const String loanStatusRejected = 'rejected';
  static const String loanStatusActive = 'active';
  static const String loanStatusCompleted = 'completed';
  static const String loanStatusCancelled = 'cancelled';
}
