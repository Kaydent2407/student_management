class StudentModel {
  final String id;
  final String studentCode;
  final String fullName;
  final String email;
  final String phone;
  final String className;
  final String major;

  StudentModel({
    required this.id,
    required this.studentCode,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.className,
    required this.major,
  });

  factory StudentModel.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return StudentModel(
      id: id,
      studentCode: data['studentCode'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      className: data['className'] ?? '',
      major: data['major'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentCode': studentCode,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'className': className,
      'major': major,
    };
  }
}