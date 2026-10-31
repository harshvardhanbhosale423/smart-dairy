class UserModel {
  final String uid;
  final String phone;
  final String username;
  final String password;
  final String role; // 'owner' or 'customer'
  final String status; // 'approved', 'pending', 'rejected'
  final String? name;
  final String? dairyId;
  final String? customerId; // Linked document ID in 'customers' collection if role == 'customer'
  final String? fcmToken;
  final double? morningQuota;
  final double? eveningQuota;
  final String? address;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.phone,
    required this.username,
    required this.password,
    required this.role,
    this.status = 'approved',
    this.name,
    this.dairyId,
    this.customerId,
    this.fcmToken,
    this.morningQuota,
    this.eveningQuota,
    this.address,
    required this.createdAt,
  });

  bool get isOwner => role == 'owner';
  bool get isCustomer => role == 'customer';
  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      phone: map['phone'] ?? '',
      username: (map['username'] ?? map['phone'] ?? '').toString().trim().toLowerCase(),
      password: map['password'] ?? '',
      role: map['role'] ?? 'customer',
      status: map['status'] ?? 'approved',
      name: map['name'],
      dairyId: map['dairyId'],
      customerId: map['customerId'],
      fcmToken: map['fcmToken'],
      morningQuota: map['morningQuota'] != null ? (map['morningQuota'] as num).toDouble() : null,
      eveningQuota: map['eveningQuota'] != null ? (map['eveningQuota'] as num).toDouble() : null,
      address: map['address'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'username': username.toLowerCase().trim(),
      'password': password,
      'role': role,
      'status': status,
      'name': name,
      'dairyId': dairyId,
      'customerId': customerId,
      'fcmToken': fcmToken,
      'morningQuota': morningQuota,
      'eveningQuota': eveningQuota,
      'address': address,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? uid,
    String? phone,
    String? username,
    String? password,
    String? role,
    String? status,
    String? name,
    String? dairyId,
    String? customerId,
    String? fcmToken,
    double? morningQuota,
    double? eveningQuota,
    String? address,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phone: phone ?? this.phone,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      status: status ?? this.status,
      name: name ?? this.name,
      dairyId: dairyId ?? this.dairyId,
      customerId: customerId ?? this.customerId,
      fcmToken: fcmToken ?? this.fcmToken,
      morningQuota: morningQuota ?? this.morningQuota,
      eveningQuota: eveningQuota ?? this.eveningQuota,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
