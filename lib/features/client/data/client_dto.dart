class ClientDto {
  final int? id;
  final String? email;
  final String? name;
  final String? phone;
  final String? companyName;
  final String? businessAddress;
  final String? businessPhone;

  const ClientDto({
    this.id,
    this.email,
    this.name,
    this.phone,
    this.companyName,
    this.businessAddress,
    this.businessPhone,
  });

  factory ClientDto.fromJson(Map<String, dynamic> json) {
    return ClientDto(
      id: (json['id'] as num?)?.toInt(),
      email: json['email'] as String?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      companyName: json['companyName'] as String?,
      businessAddress: json['businessAddress'] as String?,
      businessPhone: json['businessPhone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (companyName != null) 'companyName': companyName,
      if (businessAddress != null) 'businessAddress': businessAddress,
      if (businessPhone != null) 'businessPhone': businessPhone,
    };
  }
}
