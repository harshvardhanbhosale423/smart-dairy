class CustomerModel {
  final String id;
  final String ownerId;
  final String? userId; // Linked user account UID
  final String name;
  final String phone;
  final String? username;
  final String? password;
  final String address;
  final double morningQuota;
  final double eveningQuota;
  final double milkRate;
  final DateTime joiningDate;
  final String status; // 'active', 'paused', 'inactive'
  final double currentBalance; // Positive = customer owes money; Negative = advance paid
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerModel({
    required this.id,
    required this.ownerId,
    this.userId,
    required this.name,
    required this.phone,
    this.username,
    this.password,
    this.address = '',
    this.morningQuota = 1.0,
    this.eveningQuota = 1.0,
    this.milkRate = 60.0,
    required this.joiningDate,
    this.status = 'active',
    this.currentBalance = 0.0,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  double get dailyTotalQuota => morningQuota + eveningQuota;
  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isInactive => status == 'inactive';

  factory CustomerModel.fromMap(Map<String, dynamic> map, String id) {
    return CustomerModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      userId: map['userId'],
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      username: map['username'],
      password: map['password'],
      address: map['address'] ?? '',
      morningQuota: (map['morningQuota'] ?? 1.0).toDouble(),
      eveningQuota: (map['eveningQuota'] ?? 1.0).toDouble(),
      milkRate: (map['milkRate'] ?? 60.0).toDouble(),
      joiningDate: map['joiningDate'] != null
          ? (map['joiningDate'] as dynamic).toDate()
          : DateTime.now(),
      status: map['status'] ?? 'active',
      currentBalance: (map['currentBalance'] ?? 0.0).toDouble(),
      notes: map['notes'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'userId': userId,
      'name': name,
      'phone': phone,
      'username': username,
      'password': password,
      'address': address,
      'morningQuota': morningQuota,
      'eveningQuota': eveningQuota,
      'milkRate': milkRate,
      'joiningDate': joiningDate,
      'status': status,
      'currentBalance': currentBalance,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  CustomerModel copyWith({
    String? id,
    String? ownerId,
    String? userId,
    String? name,
    String? phone,
    String? username,
    String? password,
    String? address,
    double? morningQuota,
    double? eveningQuota,
    double? milkRate,
    DateTime? joiningDate,
    String? status,
    double? currentBalance,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      username: username ?? this.username,
      password: password ?? this.password,
      address: address ?? this.address,
      morningQuota: morningQuota ?? this.morningQuota,
      eveningQuota: eveningQuota ?? this.eveningQuota,
      milkRate: milkRate ?? this.milkRate,
      joiningDate: joiningDate ?? this.joiningDate,
      status: status ?? this.status,
      currentBalance: currentBalance ?? this.currentBalance,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
