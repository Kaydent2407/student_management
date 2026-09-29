class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role;
  final String studentCode;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.studentCode,
  });

  factory UserModel.fromMap(
    String uid,
    Map<String, dynamic> data,
  ) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      role: data['role'] ?? 'student',
      studentCode: data['studentCode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'role': role,
      'studentCode': studentCode,
    };
  }
}