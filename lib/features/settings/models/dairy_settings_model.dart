class DairySettingsModel {
  final String id;
  final String ownerId;
  final String dairyName;
  final String ownerName;
  final String ownerPhone;
  final String ownerUpiId;
  final String? accountHolderName;
  final int cowCount;
  final double defaultMilkRate;
  final String address;
  final DateTime updatedAt;

  DairySettingsModel({
    required this.id,
    required this.ownerId,
    required this.dairyName,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerUpiId,
    this.accountHolderName,
    this.cowCount = 5,
    this.defaultMilkRate = 60.0,
    this.address = '',
    required this.updatedAt,
  });

  factory DairySettingsModel.fromMap(Map<String, dynamic> map, String id) {
    return DairySettingsModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      dairyName: map['dairyName'] ?? 'Smart Dairy Farm',
      ownerName: map['ownerName'] ?? 'Dairy Owner',
      ownerPhone: map['ownerPhone'] ?? '',
      ownerUpiId: map['ownerUpiId'] ?? '',
      accountHolderName: map['accountHolderName'],
      cowCount: (map['cowCount'] ?? 5).toInt(),
      defaultMilkRate: (map['defaultMilkRate'] ?? 60.0).toDouble(),
      address: map['address'] ?? '',
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'dairyName': dairyName,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'ownerUpiId': ownerUpiId,
      'accountHolderName': accountHolderName,
      'cowCount': cowCount,
      'defaultMilkRate': defaultMilkRate,
      'address': address,
      'updatedAt': updatedAt,
    };
  }

  DairySettingsModel copyWith({
    String? dairyName,
    String? ownerName,
    String? ownerPhone,
    String? ownerUpiId,
    String? accountHolderName,
    int? cowCount,
    double? defaultMilkRate,
    String? address,
  }) {
    return DairySettingsModel(
      id: id,
      ownerId: ownerId,
      dairyName: dairyName ?? this.dairyName,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerUpiId: ownerUpiId ?? this.ownerUpiId,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      cowCount: cowCount ?? this.cowCount,
      defaultMilkRate: defaultMilkRate ?? this.defaultMilkRate,
      address: address ?? this.address,
      updatedAt: DateTime.now(),
    );
  }
}

