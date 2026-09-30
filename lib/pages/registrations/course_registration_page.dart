import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/registration_service.dart';

class CourseRegistrationPage extends StatefulWidget {
  const CourseRegistrationPage({super.key});

  @override
  State<CourseRegistrationPage> createState() => _CourseRegistrationPageState();
}

class _CourseRegistrationPageState extends State<CourseRegistrationPage> {
  final RegistrationService _service = RegistrationService();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _processing = {};
  String _searchText = '';

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _registerSection(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    if (_processing.contains(doc.id)) return;
    setState(() => _processing.add(doc.id));
    try {
      await _service.registerSection(sectionId: doc.id, sectionData: doc.data());
      _showMessage('Đăng ký lớp học phần thành công.');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processing.remove(doc.id));
    }
  }

  Future<void> _registerLegacy(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    if (_processing.contains(doc.id)) return;
    setState(() => _processing.add(doc.id));
    try {
      await _service.registerSubject(subjectId: doc.id, subjectData: doc.data());
      _showMessage('Đăng ký môn học thành công.');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processing.remove(doc.id));
    }
  }

  Future<void> _cancel({
    required String subjectId,
    String? sectionId,
    required String subjectName,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy đăng ký'),
        content: Text('Bạn có chắc muốn hủy "$subjectName" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Không')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hủy đăng ký')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.cancelMyRegistration(subjectId: subjectId, sectionId: sectionId);
      _showMessage('Đã hủy đăng ký.');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Bạn chưa đăng nhập.'));

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        final userData = userSnapshot.data?.data() ?? <String, dynamic>{};
        if (userData['role'] == 'admin') return _buildAdminPage();

        return FutureBuilder<Map<String, dynamic>>(
          future: _service.getActiveSemester(),
          builder: (context, semesterSnapshot) {
            if (semesterSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (semesterSnapshot.hasError) {
              return Center(child: Text(semesterSnapshot.error.toString().replaceFirst('Exception: ', '')));
            }
            final semester = semesterSnapshot.data!;
            return _buildStudentPage(
              semesterCode: semester['semesterCode'].toString(),
              semesterName: semester['semesterName']?.toString() ?? semester['semesterCode'].toString(),
            );
          },
        );
      },
    );
  }

  Widget _buildStudentPage({
    required String semesterCode,
    required String semesterName,
  }) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Đăng ký môn học', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text('Chọn lớp học phần phù hợp với thời khóa biểu', style: TextStyle(color: Colors.grey)),
                ],
              ),
              Chip(avatar: const Icon(Icons.calendar_month_outlined), label: Text(semesterName)),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: 470,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchText = value.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Tìm mã môn, tên môn, mã lớp học phần...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.getMyRegistrations(semesterCode: semesterCode),
              builder: (context, myRegSnapshot) {
                if (!myRegSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                final myRegs = myRegSnapshot.data!.docs;
                final mySectionIds = myRegs.map((d) => d.data()['sectionId']?.toString() ?? '').where((e) => e.isNotEmpty).toSet();
                final mySubjectIds = myRegs.map((d) => d.data()['subjectId']?.toString() ?? '').where((e) => e.isNotEmpty).toSet();
                final totalCredits = myRegs.fold<int>(0, (sum, d) => sum + (d.data()['credits'] as num? ?? 0).toInt());

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _service.getCourseSections(),
                  builder: (context, sectionSnapshot) {
                    if (!sectionSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final allSections = sectionSnapshot.data!.docs;
                    final sections = allSections.where((doc) {
                      final d = doc.data();
                      if (d['semesterCode']?.toString() != semesterCode) return false;
                      if ((d['isOpen'] as bool? ?? true) == false) return false;
                      final text = '${d['sectionCode'] ?? ''} ${d['subjectCode'] ?? ''} ${d['subjectName'] ?? ''} ${d['roomCode'] ?? ''}'.toLowerCase();
                      return _searchText.isEmpty || text.contains(_searchText);
                    }).toList();

                    if (allSections.where((d) => d.data()['semesterCode']?.toString() == semesterCode).isEmpty) {
                      return _buildLegacySubjects(
                        semesterCode: semesterCode,
                        registeredSubjectIds: mySubjectIds,
                        totalCredits: totalCredits,
                      );
                    }

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _service.getAllRegistrations(),
                      builder: (context, allRegSnapshot) {
                        final counts = <String, int>{};
                        for (final doc in allRegSnapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
                          final sectionId = doc.data()['sectionId']?.toString() ?? '';
                          if (sectionId.isNotEmpty) counts[sectionId] = (counts[sectionId] ?? 0) + 1;
                        }

                        if (sections.isEmpty) return const Center(child: Text('Không tìm thấy lớp học phần phù hợp.'));
                        return Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xffeef2ff),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Color(0xff4f46e5)),
                                  const SizedBox(width: 10),
                                  Text('Đã đăng ký: $totalCredits tín chỉ. Hệ thống tự kiểm tra trùng lịch, sĩ số, giới hạn tín chỉ và môn tiên quyết.'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Expanded(
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 420,
                                  mainAxisExtent: 280,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: sections.length,
                                itemBuilder: (context, index) {
                                  final doc = sections[index];
                                  final d = doc.data();
                                  final capacity = (d['capacity'] as num? ?? 0).toInt();
                                  final enrolled = counts[doc.id] ?? 0;
                                  final full = capacity > 0 && enrolled >= capacity;
                                  final registered = mySectionIds.contains(doc.id) || mySubjectIds.contains(d['subjectId']?.toString() ?? '');
                                  final processing = _processing.contains(doc.id);
                                  return Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: registered ? Colors.green : const Color(0xffe5e7eb)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                              decoration: BoxDecoration(color: const Color(0xffeef2ff), borderRadius: BorderRadius.circular(8)),
                                              child: Text(d['sectionCode']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xff4f46e5))),
                                            ),
                                            const Spacer(),
                                            Chip(label: Text('${d['credits'] ?? 0} TC')),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text('${d['subjectCode'] ?? ''} - ${d['subjectName'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 12),
                                        _detail(Icons.calendar_today_outlined, '${d['dayName'] ?? '-'} • Tiết ${d['startPeriod'] ?? '-'}-${d['endPeriod'] ?? '-'} (${d['startTime'] ?? ''}-${d['endTime'] ?? ''})'),
                                        _detail(Icons.meeting_room_outlined, 'Phòng ${d['roomCode'] ?? '-'}'),
                                        _detail(Icons.class_outlined, 'Lớp ${d['classCode']?.toString().isNotEmpty == true ? d['classCode'] : '-'}'),
                                        _detail(Icons.groups_outlined, 'Sĩ số $enrolled/${capacity > 0 ? capacity : '-'}'),
                                        const Spacer(),
                                        SizedBox(
                                          width: double.infinity,
                                          child: registered
                                              ? OutlinedButton(
                                                  onPressed: processing
                                                      ? null
                                                      : () => _cancel(
                                                            subjectId: d['subjectId']?.toString() ?? '',
                                                            sectionId: doc.id,
                                                            subjectName: d['subjectName']?.toString() ?? '',
                                                          ),
                                                  child: const Text('Hủy đăng ký'),
                                                )
                                              : FilledButton(
                                                  onPressed: processing || full ? null : () => _registerSection(doc),
                                                  child: Text(full ? 'Đã đủ sĩ số' : (processing ? 'Đang xử lý...' : 'Đăng ký')),
                                                ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 17, color: Colors.grey),
          const SizedBox(width: 7),
          Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xff4b5563)))),
        ],
      ),
    );
  }

  Widget _buildLegacySubjects({
    required String semesterCode,
    required Set<String> registeredSubjectIds,
    required int totalCredits,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.getSubjects(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final subjects = snapshot.data!.docs.where((doc) {
          final d = doc.data();
          final text = '${d['subjectCode'] ?? ''} ${d['subjectName'] ?? ''}'.toLowerCase();
          return _searchText.isEmpty || text.contains(_searchText);
        }).toList();
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xfffffbeb), borderRadius: BorderRadius.circular(10)),
              child: const Text('Chưa có lớp học phần cho học kỳ này. Hệ thống đang hiển thị chế độ đăng ký môn cũ; Admin nên tạo Lớp học phần để dùng kiểm tra lịch và sĩ số.'),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 390, mainAxisExtent: 210, crossAxisSpacing: 16, mainAxisSpacing: 16),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final doc = subjects[index];
                  final d = doc.data();
                  final registered = registeredSubjectIds.contains(doc.id);
                  final processing = _processing.contains(doc.id);
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: registered ? Colors.green : const Color(0xffe5e7eb))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [const Icon(Icons.menu_book_outlined, color: Color(0xff2563eb)), const Spacer(), Chip(label: Text('${d['credits'] ?? 0} tín chỉ'))]),
                        const SizedBox(height: 10),
                        Text(d['subjectCode']?.toString() ?? '', style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 5),
                        Text(d['subjectName']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: registered
                              ? OutlinedButton(onPressed: processing ? null : () => _cancel(subjectId: doc.id, subjectName: d['subjectName']?.toString() ?? ''), child: const Text('Hủy đăng ký'))
                              : FilledButton(onPressed: processing ? null : () => _registerLegacy(doc), child: const Text('Đăng ký')),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdminPage() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quản lý đăng ký môn học', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text('Danh sách sinh viên và lớp học phần đã đăng ký', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 22),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xffe5e7eb))),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _service.getAllRegistrations(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs.toList()
                    ..sort((a, b) {
                      final aDate = a.data()['registeredAt'] as Timestamp?;
                      final bDate = b.data()['registeredAt'] as Timestamp?;
                      return (bDate?.millisecondsSinceEpoch ?? 0).compareTo(aDate?.millisecondsSinceEpoch ?? 0);
                    });
                  if (docs.isEmpty) return const Center(child: Text('Chưa có đăng ký.'));
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Sinh viên')),
                        DataColumn(label: Text('Môn học')),
                        DataColumn(label: Text('Lớp học phần')),
                        DataColumn(label: Text('Lịch')),
                        DataColumn(label: Text('Phòng')),
                        DataColumn(label: Text('Tín chỉ')),
                        DataColumn(label: Text('Học kỳ')),
                      ],
                      rows: docs.map((doc) {
                        final d = doc.data();
                        return DataRow(cells: [
                          DataCell(Text('${d['studentCode'] ?? ''} - ${d['studentName'] ?? ''}')),
                          DataCell(SizedBox(width: 230, child: Text('${d['subjectCode'] ?? ''} - ${d['subjectName'] ?? ''}'))),
                          DataCell(Text(d['sectionCode']?.toString().isNotEmpty == true ? d['sectionCode'].toString() : '-')),
                          DataCell(Text(d['dayName']?.toString().isNotEmpty == true ? '${d['dayName']} • Tiết ${d['startPeriod'] ?? '-'}-${d['endPeriod'] ?? '-'}' : '-')),
                          DataCell(Text(d['roomCode']?.toString() ?? '-')),
                          DataCell(Text('${d['credits'] ?? 0}')),
                          DataCell(Text(d['semesterName']?.toString() ?? '-')),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
