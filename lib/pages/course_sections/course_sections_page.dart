import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/audit_log_service.dart';

class CourseSectionsPage extends StatefulWidget {
  const CourseSectionsPage({super.key});

  @override
  State<CourseSectionsPage> createState() => _CourseSectionsPageState();
}

class _CourseSectionsPageState extends State<CourseSectionsPage> {
  final _db = FirebaseFirestore.instance;
  final _search = TextEditingController();
  String _keyword = '';

  static const _days = <int, String>{
    2: 'Thứ 2',
    3: 'Thứ 3',
    4: 'Thứ 4',
    5: 'Thứ 5',
    6: 'Thứ 6',
    7: 'Thứ 7',
    8: 'Chủ nhật',
  };

  static const _startTimes = <int, String>{
    1: '06:45', 2: '07:35', 3: '08:25', 4: '09:30', 5: '10:20', 6: '11:10',
    7: '12:45', 8: '13:35', 9: '14:25', 10: '15:30', 11: '16:20', 12: '17:10',
  };
  static const _endTimes = <int, String>{
    1: '07:35', 2: '08:25', 3: '09:15', 4: '10:20', 5: '11:10', 6: '12:00',
    7: '13:35', 8: '14:25', 9: '15:15', 10: '16:20', 11: '17:10', 12: '18:00',
  };

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  bool _overlap(int aStart, int aEnd, int bStart, int bEnd) {
    return aStart <= bEnd && bStart <= aEnd;
  }

  Future<Map<String, dynamic>?> _activeSemester() async {
    final snap = await _db.collection('tuition_rates').where('isActive', isEqualTo: true).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return {'id': snap.docs.first.id, ...snap.docs.first.data()};
  }

  Future<void> _showForm([
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  ]) async {
    final results = await Future.wait([
      _db.collection('subjects').orderBy('subjectCode').get(),
      _db.collection('rooms').orderBy('roomCode').get(),
      _db.collection('classes').orderBy('classCode').get(),
      _activeSemester(),
    ]);
    if (!mounted) return;

    final subjects = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final rooms = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final classes = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final semester = results[3] as Map<String, dynamic>?;

    if (subjects.docs.isEmpty) {
      _message('Vui lòng tạo môn học trước.');
      return;
    }
    if (rooms.docs.isEmpty) {
      _message('Vui lòng tạo phòng học trước.');
      return;
    }
    if (semester == null) {
      _message('Vui lòng cấu hình học kỳ hiện tại trong mục Học phí.');
      return;
    }
    final activeSemester = semester;

    final old = doc?.data();
    final codeController = TextEditingController(text: old?['sectionCode']?.toString() ?? '');
    final capacityController = TextEditingController(text: old?['capacity']?.toString() ?? '40');
    String subjectId = old?['subjectId']?.toString() ?? subjects.docs.first.id;
    String roomId = old?['roomId']?.toString() ?? rooms.docs.first.id;
    String classId = old?['classId']?.toString() ?? (classes.docs.isEmpty ? '' : classes.docs.first.id);
    int dayIndex = (old?['dayIndex'] as num?)?.toInt() ?? 2;
    int startPeriod = (old?['startPeriod'] as num?)?.toInt() ?? 1;
    int endPeriod = (old?['endPeriod'] as num?)?.toInt() ?? 3;
    bool isOpen = old?['isOpen'] as bool? ?? true;
    bool loading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> save() async {
            final sectionCode = codeController.text.trim().toUpperCase();
            final capacity = int.tryParse(capacityController.text.trim()) ?? 0;
            if (sectionCode.isEmpty) {
              _message('Vui lòng nhập mã lớp học phần.');
              return;
            }
            if (capacity <= 0) {
              _message('Sĩ số tối đa phải lớn hơn 0.');
              return;
            }
            if (endPeriod < startPeriod) {
              _message('Tiết kết thúc phải lớn hơn hoặc bằng tiết bắt đầu.');
              return;
            }

            final duplicate = await _db.collection('course_sections').where('sectionCode', isEqualTo: sectionCode).get();
            if (duplicate.docs.any((item) => item.id != doc?.id)) {
              _message('Mã lớp học phần đã tồn tại.');
              return;
            }

            final roomConflicts = await _db
                .collection('course_sections')
                .where('semesterCode', isEqualTo: activeSemester['id'])
                .where('roomId', isEqualTo: roomId)
                .get();
            for (final item in roomConflicts.docs) {
              if (item.id == doc?.id) continue;
              final d = item.data();
              final otherDay = (d['dayIndex'] as num?)?.toInt() ?? 0;
              final otherStart = (d['startPeriod'] as num?)?.toInt() ?? 0;
              final otherEnd = (d['endPeriod'] as num?)?.toInt() ?? 0;
              if (otherDay == dayIndex && _overlap(startPeriod, endPeriod, otherStart, otherEnd)) {
                _message('Phòng đã có lớp khác trong khung tiết này.');
                return;
              }
            }

            final subjectDoc = subjects.docs.firstWhere((item) => item.id == subjectId);
            final subject = subjectDoc.data();
            final roomDoc = rooms.docs.firstWhere((item) => item.id == roomId);
            final room = roomDoc.data();
            final roomCapacity = (room['capacity'] as num? ?? 0).toInt();
            if (roomCapacity > 0 && capacity > roomCapacity) {
              setDialogState(() => loading = false);
              _message('Sĩ số lớp học phần ($capacity) vượt sức chứa phòng ($roomCapacity).');
              return;
            }
            Map<String, dynamic>? classData;
            if (classId.isNotEmpty && classes.docs.any((item) => item.id == classId)) {
              classData = classes.docs.firstWhere((item) => item.id == classId).data();
            }

            final payload = <String, dynamic>{
              'sectionCode': sectionCode,
              'subjectId': subjectId,
              'subjectCode': subject['subjectCode'] ?? '',
              'subjectName': subject['subjectName'] ?? '',
              'credits': subject['credits'] ?? 0,
              'semesterCode': activeSemester['id'],
              'semesterName': activeSemester['semesterName'] ?? activeSemester['id'],
              'capacity': capacity,
              'roomId': roomId,
              'roomCode': room['roomCode'] ?? '',
              'roomName': room['roomName'] ?? '',
              'classId': classId,
              'classCode': classData?['classCode'] ?? '',
              'className': classData?['className'] ?? '',
              'dayIndex': dayIndex,
              'dayName': _days[dayIndex],
              'startPeriod': startPeriod,
              'endPeriod': endPeriod,
              'startTime': _startTimes[startPeriod],
              'endTime': _endTimes[endPeriod],
              'isOpen': isOpen,
              'updatedAt': FieldValue.serverTimestamp(),
            };

            try {
              setDialogState(() => loading = true);
              String sectionId;
              if (doc == null) {
                payload['createdAt'] = FieldValue.serverTimestamp();
                final ref = await _db.collection('course_sections').add(payload);
                sectionId = ref.id;
              } else {
                await doc.reference.update(payload);
                sectionId = doc.id;
              }

              // Đồng bộ sang thời khóa biểu để màn Lịch học dùng cùng dữ liệu.
              final scheduleRef = _db.collection('schedules').doc('section_$sectionId');
              await scheduleRef.set({
                'sectionId': sectionId,
                'sectionCode': sectionCode,
                'subjectId': subjectId,
                'subjectCode': subject['subjectCode'] ?? '',
                'subjectName': subject['subjectName'] ?? '',
                'classId': classId,
                'classCode': classData?['classCode'] ?? '',
                'className': classData?['className'] ?? '',
                'dayIndex': dayIndex,
                'dayName': _days[dayIndex],
                'startPeriod': startPeriod,
                'endPeriod': endPeriod,
                'startTime': _startTimes[startPeriod],
                'endTime': _endTimes[endPeriod],
                'room': room['roomCode'] ?? '',
                'semester': activeSemester['semesterName'] ?? activeSemester['id'],
                'semesterCode': activeSemester['id'],
                'updatedAt': FieldValue.serverTimestamp(),
                if (doc == null) 'createdAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              await AuditLogService.log(
                action: doc == null ? 'create' : 'update',
                module: 'course_sections',
                targetId: sectionId,
                description: '${doc == null ? 'Tạo' : 'Cập nhật'} lớp học phần $sectionCode',
                details: payload,
              );

              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              _message(doc == null ? 'Tạo lớp học phần thành công.' : 'Cập nhật lớp học phần thành công.');
            } catch (e) {
              if (dialogContext.mounted) setDialogState(() => loading = false);
              _message('Không thể lưu lớp học phần: $e');
            }
          }

          DropdownButtonFormField<T> dropdown<T>({
            required T value,
            required String label,
            required IconData icon,
            required List<DropdownMenuItem<T>> items,
            required ValueChanged<T?> onChanged,
          }) {
            return DropdownButtonFormField<T>(
              initialValue: value,
              isExpanded: true,
              decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
              items: items,
              onChanged: loading ? null : onChanged,
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Icon(Icons.school_outlined),
                const SizedBox(width: 10),
                Text(doc == null ? 'Thêm lớp học phần' : 'Cập nhật lớp học phần'),
              ],
            ),
            content: SizedBox(
              width: 650,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      enabled: !loading,
                      decoration: const InputDecoration(labelText: 'Mã lớp học phần', prefixIcon: Icon(Icons.tag_outlined)),
                    ),
                    const SizedBox(height: 14),
                    dropdown<String>(
                      value: subjectId,
                      label: 'Môn học',
                      icon: Icons.menu_book_outlined,
                      items: subjects.docs.map((item) {
                        final d = item.data();
                        return DropdownMenuItem(value: item.id, child: Text('${d['subjectCode'] ?? ''} - ${d['subjectName'] ?? ''}'));
                      }).toList(),
                      onChanged: (value) => setDialogState(() => subjectId = value ?? subjectId),
                    ),
                    const SizedBox(height: 14),
                    if (classes.docs.isNotEmpty)
                      dropdown<String>(
                        value: classId,
                        label: 'Lớp sinh viên áp dụng',
                        icon: Icons.class_outlined,
                        items: classes.docs.map((item) {
                          final d = item.data();
                          return DropdownMenuItem(value: item.id, child: Text('${d['classCode'] ?? ''} - ${d['className'] ?? ''}'));
                        }).toList(),
                        onChanged: (value) => setDialogState(() => classId = value ?? classId),
                      ),
                    if (classes.docs.isNotEmpty) const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: dropdown<int>(
                            value: dayIndex,
                            label: 'Thứ',
                            icon: Icons.calendar_today_outlined,
                            items: _days.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                            onChanged: (value) => setDialogState(() => dayIndex = value ?? dayIndex),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: dropdown<String>(
                            value: roomId,
                            label: 'Phòng',
                            icon: Icons.meeting_room_outlined,
                            items: rooms.docs.map((item) {
                              final d = item.data();
                              return DropdownMenuItem(value: item.id, child: Text('${d['roomCode'] ?? ''} (${d['capacity'] ?? 0} chỗ)'));
                            }).toList(),
                            onChanged: (value) => setDialogState(() => roomId = value ?? roomId),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: dropdown<int>(
                            value: startPeriod,
                            label: 'Tiết bắt đầu',
                            icon: Icons.schedule_outlined,
                            items: List.generate(12, (i) => i + 1).map((p) => DropdownMenuItem(value: p, child: Text('Tiết $p (${_startTimes[p]})'))).toList(),
                            onChanged: (value) => setDialogState(() {
                              startPeriod = value ?? startPeriod;
                              if (endPeriod < startPeriod) endPeriod = startPeriod;
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: dropdown<int>(
                            value: endPeriod,
                            label: 'Tiết kết thúc',
                            icon: Icons.schedule_outlined,
                            items: List.generate(12, (i) => i + 1).map((p) => DropdownMenuItem(value: p, child: Text('Tiết $p (${_endTimes[p]})'))).toList(),
                            onChanged: (value) => setDialogState(() => endPeriod = value ?? endPeriod),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: capacityController,
                      enabled: !loading,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Sĩ số tối đa', prefixIcon: Icon(Icons.groups_outlined)),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Cho phép đăng ký'),
                      subtitle: Text('Học kỳ: ${activeSemester['semesterName'] ?? activeSemester['id']}'),
                      value: isOpen,
                      onChanged: loading ? null : (value) => setDialogState(() => isOpen = value),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: loading ? null : () => Navigator.of(dialogContext).pop(), child: const Text('Hủy')),
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
    final code = doc.data()['sectionCode']?.toString() ?? '';
    final regs = await _db.collection('registrations').where('sectionId', isEqualTo: doc.id).limit(1).get();
    if (regs.docs.isNotEmpty) {
      _message('Lớp học phần đã có sinh viên đăng ký, không thể xóa. Hãy đóng đăng ký thay vì xóa.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lớp học phần'),
        content: Text('Bạn có chắc muốn xóa "$code"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    await Future.wait([
      doc.reference.delete(),
      _db.collection('schedules').doc('section_${doc.id}').delete(),
    ]);
    await AuditLogService.log(action: 'delete', module: 'course_sections', targetId: doc.id, description: 'Xóa lớp học phần $code');
    _message('Đã xóa lớp học phần.');
  }

  @override
  Widget build(BuildContext context) {
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
                  Text('Lớp học phần', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text('Môn học, lớp, phòng, tiết học và sĩ số đăng ký', style: TextStyle(color: Colors.grey)),
                ],
              ),
              FilledButton.icon(onPressed: () => _showForm(), icon: const Icon(Icons.add), label: const Text('Thêm lớp học phần')),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: 470,
            child: TextField(
              controller: _search,
              onChanged: (value) => setState(() => _keyword = value.trim().toLowerCase()),
              decoration: const InputDecoration(hintText: 'Tìm mã lớp học phần, môn, lớp, phòng...', prefixIcon: Icon(Icons.search)),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xffe5e7eb))),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _db.collection('course_sections').orderBy('sectionCode').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs.where((doc) {
                    final d = doc.data();
                    final text = '${d['sectionCode'] ?? ''} ${d['subjectCode'] ?? ''} ${d['subjectName'] ?? ''} ${d['classCode'] ?? ''} ${d['roomCode'] ?? ''}'.toLowerCase();
                    return _keyword.isEmpty || text.contains(_keyword);
                  }).toList();
                  if (docs.isEmpty) return const Center(child: Text('Chưa có lớp học phần.'));
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Mã LHP')),
                        DataColumn(label: Text('Môn học')),
                        DataColumn(label: Text('Lớp')),
                        DataColumn(label: Text('Lịch')),
                        DataColumn(label: Text('Phòng')),
                        DataColumn(label: Text('Sĩ số')),
                        DataColumn(label: Text('Trạng thái')),
                        DataColumn(label: Text('Thao tác')),
                      ],
                      rows: docs.map((doc) {
                        final d = doc.data();
                        return DataRow(cells: [
                          DataCell(Text(d['sectionCode']?.toString() ?? '')),
                          DataCell(SizedBox(width: 230, child: Text('${d['subjectCode'] ?? ''} - ${d['subjectName'] ?? ''}', overflow: TextOverflow.ellipsis))),
                          DataCell(Text(d['classCode']?.toString() ?? '-')),
                          DataCell(Text('${d['dayName'] ?? '-'} • Tiết ${d['startPeriod'] ?? '-'}-${d['endPeriod'] ?? '-'}')),
                          DataCell(Text(d['roomCode']?.toString() ?? '-')),
                          DataCell(Text('${d['capacity'] ?? 0}')),
                          DataCell(Chip(label: Text((d['isOpen'] as bool? ?? true) ? 'Đang mở' : 'Đã đóng'))),
                          DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(onPressed: () => _showForm(doc), icon: const Icon(Icons.edit_outlined)),
                            IconButton(onPressed: () => _delete(doc), icon: const Icon(Icons.delete_outline, color: Colors.red)),
                          ])),
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
    _search.dispose();
    super.dispose();
  }
}
