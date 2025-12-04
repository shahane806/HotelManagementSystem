
// Updated UserModel with Aadhaar card number
class UserModel {
  final String userId;
  final String fullName;
  final String email;
  final String mobile;
  final String aadhaarNumber;
  String? role;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.aadhaarNumber,
    this.role
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      aadhaarNumber: json['aadhaarNumber'] ?? '',
      role: json['role'] ?? ''
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'mobile': mobile,
      'aadhaarNumber': aadhaarNumber,
      'role':role,
    };
  }

  @override
  String toString() {
    return 'UserModel(userId: $userId, fullName: $fullName, email: $email, mobile: $mobile, aadhaarNumber: $aadhaarNumber, role: $role)';
  }
}