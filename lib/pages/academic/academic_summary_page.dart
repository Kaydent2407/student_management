import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AcademicSummaryPage extends StatelessWidget {
  const AcademicSummaryPage({super.key});

  double _toFour(double score) {
    if (score >= 8.5) return 4.0;
    if (score >= 7.0) return 3.0;
    if (score >= 5.5) return 2.0;
    if (score >= 4.0) return 1.0;
    return 0.0;
  }

  String _classification(double gpa) {
    if (gpa >= 3.6) return 'Xuất sắc';
    if (gpa >= 3.2) return 'Giỏi';
    if (gpa >= 2.5) return 'Khá';
    if (gpa >= 2.0) return 'Trung bình';
    if (gpa >= 1.0) return 'Yếu';
    return 'Kém';
  }

  Widget _metric(String title, String value, IconData icon) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xffeef2ff),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xff4f46e5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Chưa đăng nhập.'));

    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kết quả học tập', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text('GPA, tín chỉ tích lũy và kết quả theo học kỳ', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 22),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('grades').where('userId', isEqualTo: user.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('Chưa có dữ liệu điểm để tổng hợp.'));

                var weighted10 = 0.0;
                var weighted4 = 0.0;
                var attemptedCredits = 0;
                var passedCredits = 0;
                var failedCredits = 0;
                final bySemester = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

                for (final doc in docs) {
                  final d = doc.data();
                  final score = (d['averageScore'] as num? ?? 0).toDouble();
                  final credits = (d['credits'] as num? ?? 0).toInt();
                  attemptedCredits += credits;
                  weighted10 += score * credits;
                  weighted4 += _toFour(score) * credits;
                  if (score >= 4.0) {
                    passedCredits += credits;
                  } else {
                    failedCredits += credits;
                  }
                  final semester = d['semesterName']?.toString().trim();
                  final code = d['semesterCode']?.toString().trim();
                  final key = (semester != null && semester.isNotEmpty)
                      ? semester
                      : ((code != null && code.isNotEmpty) ? code : 'Chưa xác định học kỳ');
                  bySemester.putIfAbsent(key, () => []).add(doc);
                }

                final gpa10 = attemptedCredits == 0 ? 0.0 : weighted10 / attemptedCredits;
                final gpa4 = attemptedCredits == 0 ? 0.0 : weighted4 / attemptedCredits;
                final semesters = bySemester.entries.toList();

                return ListView(
                  children: [
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _metric('GPA hệ 10', gpa10.toStringAsFixed(2), Icons.analytics_outlined),
                        _metric('GPA hệ 4', gpa4.toStringAsFixed(2), Icons.stars_outlined),
                        _metric('Tín chỉ đạt', '$passedCredits', Icons.check_circle_outline),
                        _metric('Tín chỉ nợ', '$failedCredits', Icons.warning_amber_outlined),
                        _metric('Xếp loại', _classification(gpa4), Icons.workspace_premium_outlined),
                      ],
                    ),
                    const SizedBox(height: 22),
                    ...semesters.map((entry) {
                      var credits = 0;
                      var scoreWeighted = 0.0;
                      var fourWeighted = 0.0;
                      for (final doc in entry.value) {
                        final d = doc.data();
                        final c = (d['credits'] as num? ?? 0).toInt();
                        final score = (d['averageScore'] as num? ?? 0).toDouble();
                        credits += c;
                        scoreWeighted += score * c;
                        fourWeighted += _toFour(score) * c;
                      }
                      final s10 = credits == 0 ? 0.0 : scoreWeighted / credits;
                      final s4 = credits == 0 ? 0.0 : fourWeighted / credits;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xffe5e7eb)),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                                  Text('GPA 10: ${s10.toStringAsFixed(2)}  •  GPA 4: ${s4.toStringAsFixed(2)}  •  $credits TC'),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Mã môn')),
                                  DataColumn(label: Text('Môn học')),
                                  DataColumn(label: Text('Tín chỉ')),
                                  DataColumn(label: Text('Giữa kỳ')),
                                  DataColumn(label: Text('Cuối kỳ')),
                                  DataColumn(label: Text('Tổng kết')),
                                  DataColumn(label: Text('Điểm chữ')),
                                  DataColumn(label: Text('Kết quả')),
                                ],
                                rows: entry.value.map((doc) {
                                  final d = doc.data();
                                  final avg = (d['averageScore'] as num? ?? 0).toDouble();
                                  return DataRow(cells: [
                                    DataCell(Text(d['subjectCode']?.toString() ?? '')),
                                    DataCell(SizedBox(width: 220, child: Text(d['subjectName']?.toString() ?? ''))),
                                    DataCell(Text('${d['credits'] ?? 0}')),
                                    DataCell(Text('${d['midtermScore'] ?? '-'}')),
                                    DataCell(Text('${d['finalScore'] ?? '-'}')),
                                    DataCell(Text(avg.toStringAsFixed(2))),
                                    DataCell(Text(d['letterGrade']?.toString() ?? '-')),
                                    DataCell(Text(avg >= 4.0 ? 'Đạt' : 'Chưa đạt')),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
