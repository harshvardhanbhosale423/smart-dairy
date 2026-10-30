class UserModel {
  final String uid;
  final String phone;
  final String role; // 'owner' or 'customer'
  final String? name;
  final String? dairyId;
  final String? customerId; // Linked document ID in 'customers' collection if role == 'customer'
  final String? fcmToken;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.phone,
    required this.role,
    this.name,
    this.dairyId,
    this.customerId,
    this.fcmToken,
    required this.createdAt,
  });

  bool get isOwner => role == 'owner';
  bool get isCustomer => role == 'customer';

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'customer',
      name: map['name'],
      dairyId: map['dairyId'],
      customerId: map['customerId'],
      fcmToken: map['fcmToken'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'role': role,
      'name': name,
      'dairyId': dairyId,
      'customerId': customerId,
      'fcmToken': fcmToken,
      'createdAt': createdAt,
    };
  }
}

