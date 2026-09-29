class SubjectModel {
  final String id;
  final String subjectCode;
  final String subjectName;
  final int credits;

  SubjectModel({
    required this.id,
    required this.subjectCode,
    required this.subjectName,
    required this.credits,
  });

  factory SubjectModel.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return SubjectModel(
      id: id,
      subjectCode: data['subjectCode'] ?? '',
      subjectName: data['subjectName'] ?? '',
      credits: data['credits'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'credits': credits,
    };
  }
}