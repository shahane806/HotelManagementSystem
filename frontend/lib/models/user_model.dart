class UserModel {
  final String userId;
  final String fullName;
  final String email;
  final String mobile;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.mobile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'mobile': mobile,
    };
  }

  @override
  String toString() {
    return 'UserModel(userId: $userId, fullName: $fullName, email: $email, mobile: $mobile)';
  }
}
