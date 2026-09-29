class ClassModel {
  final String id;
  final String classCode;
  final String className;
  final String major;
  final String academicYear;
  final String advisor;

  ClassModel({
    required this.id,
    required this.classCode,
    required this.className,
    required this.major,
    required this.academicYear,
    required this.advisor,
  });

  factory ClassModel.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return ClassModel(
      id: id,
      classCode: data['classCode'] ?? '',
      className: data['className'] ?? '',
      major: data['major'] ?? '',
      academicYear: data['academicYear'] ?? '',
      advisor: data['advisor'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classCode': classCode,
      'className': className,
      'major': major,
      'academicYear': academicYear,
      'advisor': advisor,
    };
  }
}