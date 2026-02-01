class Restaurant {
  final String restaurantId;
  final String ownerId; // Add this field
  final String name;
  final String address;
  final String contact; // Assuming "edit text" means contact
  final double rating;
  final String? description;
  final String? imageUrl;
  final List<String>? categories;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Verification fields
  final String verificationStatus; // 'pending', 'verified', 'rejected'
  final String? licenseImageBase64;
  final String? idImageBase64;
  final DateTime? verifiedAt;
  final String? verifiedBy; // Admin userId who verified
  final String? rejectionReason;
  
  // Location fields
  final double? latitude;
  final double? longitude;

  Restaurant({
    required this.restaurantId,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.contact,
    required this.rating,
    this.description,
    this.imageUrl,
    this.categories,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.verificationStatus = 'pending',
    this.licenseImageBase64,
    this.idImageBase64,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'ownerId': ownerId,
      'name': name,
      'address': address,
      'contact': contact,
      'rating': rating,
      'description': description,
      'imageUrl': imageUrl,
      'categories': categories,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'verificationStatus': verificationStatus,
      'licenseImageBase64': licenseImageBase64,
      'idImageBase64': idImageBase64,
      'verifiedAt': verifiedAt?.millisecondsSinceEpoch,
      'verifiedBy': verifiedBy,
      'rejectionReason': rejectionReason,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      restaurantId: map['restaurantId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      contact: map['contact'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      description: map['description'],
      imageUrl: map['imageUrl'],
      categories: map['categories'] != null
          ? List<String>.from(map['categories'])
          : null,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      verificationStatus: map['verificationStatus'] ?? 'pending',
      licenseImageBase64: map['licenseImageBase64'],
      idImageBase64: map['idImageBase64'],
      verifiedAt: map['verifiedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['verifiedAt'])
          : null,
      verifiedBy: map['verifiedBy'],
      rejectionReason: map['rejectionReason'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  Restaurant copyWith({
    String? restaurantId,
    String? ownerId,
    String? name,
    String? address,
    String? contact,
    double? rating,
    String? description,
    String? imageUrl,
    List<String>? categories,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? verificationStatus,
    String? licenseImageBase64,
    String? idImageBase64,
    DateTime? verifiedAt,
    String? verifiedBy,
    String? rejectionReason,
    double? latitude,
    double? longitude,
  }) {
    return Restaurant(
      restaurantId: restaurantId ?? this.restaurantId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      rating: rating ?? this.rating,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      categories: categories ?? this.categories,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      licenseImageBase64: licenseImageBase64 ?? this.licenseImageBase64,
      idImageBase64: idImageBase64 ?? this.idImageBase64,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}