import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/audit_log_service.dart';

class ExamSchedulesPage extends StatefulWidget {
  final bool isAdmin;

  const ExamSchedulesPage({
    super.key,
    required this.isAdmin,
  });

  @override
  State<ExamSchedulesPage> createState() => _ExamSchedulesPageState();
}

class _ExamSchedulesPageState extends State<ExamSchedulesPage> {
  final _db = FirebaseFirestore.instance;
  final _search = TextEditingController();
  String _keyword = '';

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<void> _showForm([
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  ]) async {
    final results = await Future.wait([
      _db.collection('subjects').orderBy('subjectCode').get(),
      _db.collection('rooms').orderBy('roomCode').get(),
      _db.collection('tuition_rates').get(),
    ]);
    if (!mounted) return;

    final subjects = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final rooms = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final semesters = results[2] as QuerySnapshot<Map<String, dynamic>>;
    if (subjects.docs.isEmpty || rooms.docs.isEmpty) {
      _message('Cần có môn học và phòng học trước khi tạo lịch thi.');
      return;
    }

    final old = doc?.data();
    String subjectId = old?['subjectId']?.toString() ?? subjects.docs.first.id;
    String roomId = old?['roomId']?.toString() ?? rooms.docs.first.id;
    String semesterCode = old?['semesterCode']?.toString() ??
        (semesters.docs.where((x) => x.data()['isActive'] == true).isNotEmpty
            ? semesters.docs.firstWhere((x) => x.data()['isActive'] == true).id
            : (semesters.docs.isEmpty ? '' : semesters.docs.first.id));
    DateTime examDate = old?['examDate'] is Timestamp
        ? (old!['examDate'] as Timestamp).toDate()
        : DateTime.now().add(const Duration(days: 7));
    final start = TextEditingController(text: old?['startTime']?.toString() ?? '07:30');
    final end = TextEditingController(text: old?['endTime']?.toString() ?? '09:00');
    final type = TextEditingController(text: old?['examType']?.toString() ?? 'Tự luận');
    bool loading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> save() async {
            if (start.text.trim().isEmpty || end.text.trim().isEmpty) {
              _message('Vui lòng nhập giờ bắt đầu và kết thúc.');
              return;
            }
            final subjectDoc = subjects.docs.firstWhere((x) => x.id == subjectId);
            final roomDoc = rooms.docs.firstWhere((x) => x.id == roomId);
            final subject = subjectDoc.data();
            final room = roomDoc.data();
            final semesterDoc = semesters.docs.where((x) => x.id == semesterCode).isNotEmpty
                ? semesters.docs.firstWhere((x) => x.id == semesterCode)
                : null;

            try {
              setDialogState(() => loading = true);
              final payload = <String, dynamic>{
                'subjectId': subjectId,
                'subjectCode': subject['subjectCode'] ?? '',
                'subjectName': subject['subjectName'] ?? '',
                'roomId': roomId,
                'roomCode': room['roomCode'] ?? '',
                'semesterCode': semesterCode,
                'semesterName': semesterDoc == null ? semesterCode : (semesterDoc.data()['semesterName'] ?? semesterCode),
                'examDate': Timestamp.fromDate(DateTime(examDate.year, examDate.month, examDate.day)),
                'startTime': start.text.trim(),
                'endTime': end.text.trim(),
                'examType': type.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              };
              String targetId;
              if (doc == null) {
                payload['createdAt'] = FieldValue.serverTimestamp();
                final ref = await _db.collection('exam_schedules').add(payload);
                targetId = ref.id;
              } else {
                await doc.reference.update(payload);
                targetId = doc.id;
              }
              await AuditLogService.log(
                action: doc == null ? 'create' : 'update',
                module: 'exam_schedules',
                targetId: targetId,
                description: '${doc == null ? 'Tạo' : 'Cập nhật'} lịch thi ${subject['subjectCode'] ?? ''}',
                details: payload,
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              _message(doc == null ? 'Tạo lịch thi thành công.' : 'Cập nhật lịch thi thành công.');
            } catch (e) {
              if (dialogContext.mounted) setDialogState(() => loading = false);
              _message('Không thể lưu lịch thi: $e');
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Icon(Icons.event_note_outlined),
                const SizedBox(width: 10),
                Text(doc == null ? 'Thêm lịch thi' : 'Cập nhật lịch thi'),
              ],
            ),
            content: SizedBox(
              width: 620,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: subjectId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Môn thi', prefixIcon: Icon(Icons.menu_book_outlined)),
                      items: subjects.docs.map((item) {
                        final d = item.data();
                        return DropdownMenuItem(value: item.id, child: Text('${d['subjectCode'] ?? ''} - ${d['subjectName'] ?? ''}'));
                      }).toList(),
                      onChanged: loading ? null : (value) => setDialogState(() => subjectId = value ?? subjectId),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: roomId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Phòng thi', prefixIcon: Icon(Icons.meeting_room_outlined)),
                            items: rooms.docs.map((item) {
                              final d = item.data();
                              return DropdownMenuItem(value: item.id, child: Text(d['roomCode']?.toString() ?? ''));
                            }).toList(),
                            onChanged: loading ? null : (value) => setDialogState(() => roomId = value ?? roomId),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: semesters.docs.any((x) => x.id == semesterCode) ? semesterCode : null,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Học kỳ', prefixIcon: Icon(Icons.calendar_month_outlined)),
                            items: semesters.docs.map((item) => DropdownMenuItem(value: item.id, child: Text(item.data()['semesterName']?.toString() ?? item.id))).toList(),
                            onChanged: loading ? null : (value) => setDialogState(() => semesterCode = value ?? semesterCode),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: loading
                          ? null
                          : () async {
                              final value = await showDatePicker(
                                context: dialogContext,
                                initialDate: examDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (value != null) setDialogState(() => examDate = value);
                            },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Ngày thi', prefixIcon: Icon(Icons.event_outlined)),
                        child: Text(_formatDate(examDate)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: start, decoration: const InputDecoration(labelText: 'Giờ bắt đầu', prefixIcon: Icon(Icons.schedule_outlined)))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: end, decoration: const InputDecoration(labelText: 'Giờ kết thúc', prefixIcon: Icon(Icons.schedule_outlined)))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(controller: type, decoration: const InputDecoration(labelText: 'Hình thức thi', prefixIcon: Icon(Icons.description_outlined))),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: loading ? null : () => Navigator.pop(dialogContext), child: const Text('Hủy')),
              FilledButton.icon(
                onPressed: loading ? null : save,
                icon: loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(loading ? 'Đang lưu...' : 'Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lịch thi'),
        content: Text('Xóa lịch thi ${doc.data()['subjectCode'] ?? ''}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    final code = doc.data()['subjectCode']?.toString() ?? '';
    await doc.reference.delete();
    await AuditLogService.log(action: 'delete', module: 'exam_schedules', targetId: doc.id, description: 'Xóa lịch thi $code');
    _message('Đã xóa lịch thi.');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Chưa đăng nhập.'));

    return FutureBuilder<Set<String>>(
      future: widget.isAdmin
          ? Future.value(<String>{})
          : _db.collection('registrations').where('userId', isEqualTo: user.uid).get().then(
                (snap) => snap.docs.map((d) => d.data()['subjectId']?.toString() ?? '').where((e) => e.isNotEmpty).toSet(),
              ),
      builder: (context, regSnapshot) {
        final subjectIds = regSnapshot.data ?? <String>{};
        return Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.isAdmin ? 'Quản lý lịch thi' : 'Lịch thi', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(widget.isAdmin ? 'Tạo và quản lý lịch thi của sinh viên' : 'Lịch thi các môn bạn đã đăng ký', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  if (widget.isAdmin)
                    FilledButton.icon(onPressed: () => _showForm(), icon: const Icon(Icons.add), label: const Text('Thêm lịch thi')),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 450,
                child: TextField(
                  controller: _search,
                  onChanged: (value) => setState(() => _keyword = value.trim().toLowerCase()),
                  decoration: const InputDecoration(hintText: 'Tìm môn, phòng, học kỳ...', prefixIcon: Icon(Icons.search)),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xffe5e7eb))),
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _db.collection('exam_schedules').orderBy('examDate').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || (!widget.isAdmin && regSnapshot.connectionState == ConnectionState.waiting)) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data!.docs.where((doc) {
                        final d = doc.data();
                        if (!widget.isAdmin && !subjectIds.contains(d['subjectId']?.toString() ?? '')) return false;
                        final text = '${d['subjectCode'] ?? ''} ${d['subjectName'] ?? ''} ${d['roomCode'] ?? ''} ${d['semesterName'] ?? ''}'.toLowerCase();
                        return _keyword.isEmpty || text.contains(_keyword);
                      }).toList();
                      if (docs.isEmpty) return const Center(child: Text('Chưa có lịch thi phù hợp.'));
                      return SingleChildScrollView(
                        child: SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            columns: [
                              const DataColumn(label: Text('Môn thi')),
                              const DataColumn(label: Text('Ngày thi')),
                              const DataColumn(label: Text('Giờ thi')),
                              const DataColumn(label: Text('Phòng')),
                              const DataColumn(label: Text('Hình thức')),
                              const DataColumn(label: Text('Học kỳ')),
                              if (widget.isAdmin) const DataColumn(label: Text('Thao tác')),
                            ],
                            rows: docs.map((doc) {
                              final d = doc.data();
                              final date = d['examDate'] is Timestamp ? (d['examDate'] as Timestamp).toDate() : null;
                              return DataRow(cells: [
                                DataCell(SizedBox(width: 250, child: Text('${d['subjectCode'] ?? ''} - ${d['subjectName'] ?? ''}'))),
                                DataCell(Text(date == null ? '-' : _formatDate(date))),
                                DataCell(Text('${d['startTime'] ?? '-'} - ${d['endTime'] ?? '-'}')),
                                DataCell(Text(d['roomCode']?.toString() ?? '-')),
                                DataCell(Text(d['examType']?.toString() ?? '-')),
                                DataCell(Text(d['semesterName']?.toString() ?? '-')),
                                if (widget.isAdmin)
                                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                    IconButton(onPressed: () => _showForm(doc), icon: const Icon(Icons.edit_outlined)),
                                    IconButton(onPressed: () => _delete(doc), icon: const Icon(Icons.delete_outline, color: Colors.red)),
                                  ])),
                              ]);
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }
}
