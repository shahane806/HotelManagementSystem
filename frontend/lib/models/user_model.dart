
// Updated UserModel with Aadhaar card number
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String mobile;
  final String aadhaarNumber;
  String? role;
  String? password;
  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.aadhaarNumber,
    this.role,
    this.password,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['userId']?.toString() ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      aadhaarNumber: json['aadhaarNumber'] ?? '',
      role: json['role'] ?? ''
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'mobile': mobile,
      'aadhaarNumber': aadhaarNumber,
      'role':role,
      'password':password,
    };
  }

  @override
  String toString() {
    return 'UserModel(id: $id, fullName: $fullName, email: $email, mobile: $mobile, aadhaarNumber: $aadhaarNumber, role: $role)';
  }
}