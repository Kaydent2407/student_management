import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/audit_log_service.dart';

class AttendancePage extends StatefulWidget {
  final bool isAdmin;

  const AttendancePage({
    super.key,
    this.isAdmin = true,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final db = FirebaseFirestore.instance;
  String _search = '';
  String _subjectFilter = 'Tất cả';
  DateTime _date = DateTime.now();

  String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _setStatus(String registrationId, Map<String, dynamic> reg, String status) async {
    final id = '${_dateKey(_date)}_$registrationId';
    await db.collection('attendance').doc(id).set({
      'registrationId': registrationId,
      'userId': reg['userId'] ?? '',
      'studentId': reg['studentId'] ?? '',
      'studentCode': reg['studentCode'] ?? '',
      'studentName': reg['studentName'] ?? '',
      'subjectId': reg['subjectId'] ?? '',
      'subjectCode': reg['subjectCode'] ?? '',
      'subjectName': reg['subjectName'] ?? '',
      'semesterCode': reg['semesterCode'] ?? '',
      'date': _dateKey(_date),
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await AuditLogService.log(
      action: 'update',
      module: 'attendance',
      targetId: id,
      description: 'Điểm danh ${reg['studentCode'] ?? ''} - ${reg['subjectCode'] ?? ''}: $status',
      details: {'status': status, 'date': _dateKey(_date)},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAdmin) {
      return _buildStudentView();
    }

    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Điểm danh', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Điểm danh sinh viên theo môn học và ngày học', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm MSSV hoặc họ tên...'), onChanged: (v) => setState(() => _search = v.trim().toLowerCase()))),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(_dateKey(_date)),
            onPressed: () async {
              final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2035));
              if (d != null) setState(() => _date = d);
            },
          ),
        ]),
        const SizedBox(height: 16),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: db.collection('registrations').snapshots(),
          builder: (context, regSnap) {
            if (regSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (regSnap.hasError) return Center(child: Text('Lỗi: ${regSnap.error}'));
            final regs = regSnap.data?.docs ?? [];
            final subjects = <String>{'Tất cả', ...regs.map((d) => '${d.data()['subjectCode'] ?? ''} - ${d.data()['subjectName'] ?? ''}')};
            if (!subjects.contains(_subjectFilter)) _subjectFilter = 'Tất cả';
            final filtered = regs.where((d) {
              final x = d.data();
              final q = '${x['studentCode'] ?? ''} ${x['studentName'] ?? ''}'.toLowerCase();
              final s = '${x['subjectCode'] ?? ''} - ${x['subjectName'] ?? ''}';
              return q.contains(_search) && (_subjectFilter == 'Tất cả' || s == _subjectFilter);
            }).toList();
            return Column(children: [
              Align(alignment: Alignment.centerLeft, child: SizedBox(width: 420, child: DropdownButtonFormField<String>(value: _subjectFilter, decoration: const InputDecoration(labelText: 'Môn học', prefixIcon: Icon(Icons.menu_book_outlined)), items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _subjectFilter = v ?? 'Tất cả')))),
              const SizedBox(height: 14),
              Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: db.collection('attendance').where('date', isEqualTo: _dateKey(_date)).snapshots(),
                builder: (context, attSnap) {
                  final attendance = <String, String>{};
                  for (final d in attSnap.data?.docs ?? []) {
                    attendance[d.data()['registrationId']?.toString() ?? ''] = d.data()['status']?.toString() ?? '';
                  }
                  if (filtered.isEmpty) return const Center(child: Text('Không có dữ liệu đăng ký môn học.'));
                  return Card(child: ListView.separated(itemCount: filtered.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (context, i) {
                    final doc = filtered[i]; final x = doc.data(); final current = attendance[doc.id] ?? 'Chưa điểm danh';
                    return ListTile(
                      leading: CircleAvatar(child: Text((x['studentName']?.toString().isNotEmpty ?? false) ? x['studentName'].toString()[0].toUpperCase() : '?')),
                      title: Text('${x['studentCode'] ?? ''} - ${x['studentName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${x['subjectCode'] ?? ''} - ${x['subjectName'] ?? ''}'),
                      trailing: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        Chip(label: Text(current)),
                        _statusButton(doc.id, x, 'Có mặt', Icons.check_circle_outline),
                        _statusButton(doc.id, x, 'Vắng', Icons.cancel_outlined),
                        _statusButton(doc.id, x, 'Có phép', Icons.info_outline),
                      ]),
                    );
                  }));
                },
              )),
            ]);
          },
        )),
      ]),
    );
  }


  Widget _buildStudentView() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Chưa đăng nhập.'));
    }

    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Điểm danh của tôi',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Lịch sử có mặt, vắng và có phép theo từng môn học',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db
                  .collection('attendance')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs.toList() ?? [];
                docs.sort((a, b) => (b.data()['date'] ?? '')
                    .toString()
                    .compareTo((a.data()['date'] ?? '').toString()));

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Chưa có dữ liệu điểm danh.'),
                  );
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final status = data['status']?.toString() ?? '';
                    IconData icon = Icons.help_outline;
                    if (status == 'Có mặt') icon = Icons.check_circle_outline;
                    if (status == 'Vắng') icon = Icons.cancel_outlined;
                    if (status == 'Có phép') icon = Icons.info_outline;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(icon)),
                        title: Text(
                          '${data['subjectCode'] ?? ''} - ${data['subjectName'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('Ngày: ${data['date'] ?? ''}'),
                        trailing: Chip(label: Text(status)),
                      ),
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

  Widget _statusButton(String id, Map<String, dynamic> data, String status, IconData icon) {
    return OutlinedButton.icon(onPressed: () async {
      try { await _setStatus(id, data, status); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã cập nhật: $status'))); }
      catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể cập nhật: $e'))); }
    }, icon: Icon(icon, size: 18), label: Text(status));
  }
}
