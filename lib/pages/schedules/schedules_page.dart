import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/schedule_service.dart';

class _PeriodSlot {
  final int period;
  final String start;
  final String end;

  const _PeriodSlot(this.period, this.start, this.end);
}

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> {
  final ScheduleService _service = ScheduleService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  String _searchText = '';
  String? _selectedAdminClassId;

  static const double _periodColumnWidth = 96;
  static const double _dayColumnWidth = 180;
  static const double _periodRowHeight = 74;
  static const double _breakHeight = 18;

  final List<Map<String, dynamic>> _days = const [
    {'index': 2, 'name': 'Thứ 2'},
    {'index': 3, 'name': 'Thứ 3'},
    {'index': 4, 'name': 'Thứ 4'},
    {'index': 5, 'name': 'Thứ 5'},
    {'index': 6, 'name': 'Thứ 6'},
    {'index': 7, 'name': 'Thứ 7'},
    {'index': 8, 'name': 'Chủ nhật'},
  ];

  final List<_PeriodSlot> _periods = const [
    _PeriodSlot(1, '06:45', '07:35'),
    _PeriodSlot(2, '07:35', '08:25'),
    _PeriodSlot(3, '08:25', '09:15'),
    _PeriodSlot(4, '09:30', '10:20'),
    _PeriodSlot(5, '10:20', '11:10'),
    _PeriodSlot(6, '11:10', '12:00'),
    _PeriodSlot(7, '12:45', '13:35'),
    _PeriodSlot(8, '13:35', '14:25'),
    _PeriodSlot(9, '14:25', '15:15'),
    _PeriodSlot(10, '15:30', '16:20'),
    _PeriodSlot(11, '16:20', '17:10'),
    _PeriodSlot(12, '17:10', '18:00'),
  ];

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int _minutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 +
        (int.tryParse(parts[1]) ?? 0);
  }

  int _nearestStartPeriod(String? time) {
    if (time == null || time.isEmpty) return 1;
    final target = _minutes(time);
    var best = _periods.first;
    var bestDiff = (_minutes(best.start) - target).abs();

    for (final slot in _periods.skip(1)) {
      final diff = (_minutes(slot.start) - target).abs();
      if (diff < bestDiff) {
        best = slot;
        bestDiff = diff;
      }
    }
    return best.period;
  }

  int _nearestEndPeriod(String? time) {
    if (time == null || time.isEmpty) return 3;
    final target = _minutes(time);
    var best = _periods.first;
    var bestDiff = (_minutes(best.end) - target).abs();

    for (final slot in _periods.skip(1)) {
      final diff = (_minutes(slot.end) - target).abs();
      if (diff < bestDiff) {
        best = slot;
        bestDiff = diff;
      }
    }
    return best.period;
  }

  int _startPeriodOf(Map<String, dynamic> data) {
    final saved = data['startPeriod'];
    if (saved is int && saved >= 1 && saved <= 12) return saved;
    if (saved is num && saved >= 1 && saved <= 12) return saved.toInt();
    return _nearestStartPeriod(data['startTime']?.toString());
  }

  int _endPeriodOf(Map<String, dynamic> data) {
    final saved = data['endPeriod'];
    if (saved is int && saved >= 1 && saved <= 12) return saved;
    if (saved is num && saved >= 1 && saved <= 12) return saved.toInt();
    return _nearestEndPeriod(data['endTime']?.toString());
  }

  _PeriodSlot _slot(int period) => _periods[period - 1];

  int _blockStart(int period) => ((period - 1) ~/ 3) * 3 + 1;
  int _blockEnd(int period) => _blockStart(period) + 2;

  String _periodLabel(int period) {
    final slot = _slot(period);
    return 'Tiết ${slot.period} (${slot.start} - ${slot.end})';
  }

  double get _timetableBodyHeight =>
      _periodRowHeight * 12 + _breakHeight * 3;

  double _topForPeriod(int period) {
    final periodsBefore = period - 1;
    var breaksBefore = 0;
    if (period >= 4) breaksBefore++;
    if (period >= 7) breaksBefore++;
    if (period >= 10) breaksBefore++;
    return periodsBefore * _periodRowHeight +
        breaksBefore * _breakHeight;
  }

  double _heightForPeriodRange(int startPeriod, int endPeriod) {
    return (endPeriod - startPeriod + 1) * _periodRowHeight;
  }

  Future<void> _showScheduleDialog({
    String? id,
    Map<String, dynamic>? oldData,
  }) async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('subjects')
            .orderBy('subjectCode')
            .get(),
        FirebaseFirestore.instance
            .collection('classes')
            .orderBy('classCode')
            .get(),
      ]);

      if (!mounted) return;

      final subjects =
          results[0] as QuerySnapshot<Map<String, dynamic>>;
      final classes = results[1] as QuerySnapshot<Map<String, dynamic>>;

      if (subjects.docs.isEmpty) {
        _showMessage('Chưa có môn học.');
        return;
      }
      if (classes.docs.isEmpty) {
        _showMessage('Chưa có lớp học.');
        return;
      }

      String? selectedSubjectId = oldData?['subjectId']?.toString();
      String? selectedClassId = oldData?['classId']?.toString();
      int selectedDay = oldData?['dayIndex'] as int? ?? 2;
      int selectedStartPeriod = oldData == null ? 1 : _startPeriodOf(oldData);
      int selectedEndPeriod = oldData == null ? 3 : _endPeriodOf(oldData);

      if (_blockStart(selectedStartPeriod) != _blockStart(selectedEndPeriod) ||
          selectedEndPeriod < selectedStartPeriod) {
        selectedEndPeriod = _blockEnd(selectedStartPeriod);
      }

      final roomController = TextEditingController(
        text: oldData?['room']?.toString() ?? '',
      );
      final semesterController = TextEditingController(
        text: oldData?['semester']?.toString() ?? '',
      );

      if (selectedSubjectId != null &&
          !subjects.docs.any((doc) => doc.id == selectedSubjectId)) {
        selectedSubjectId = null;
      }
      if (selectedClassId != null &&
          !classes.docs.any((doc) => doc.id == selectedClassId)) {
        selectedClassId = null;
      }

      bool loading = false;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> save() async {
                final room = roomController.text.trim();
                final semester = semesterController.text.trim();

                if (selectedSubjectId == null) {
                  _showMessage('Vui lòng chọn môn học.');
                  return;
                }
                if (selectedClassId == null) {
                  _showMessage('Vui lòng chọn lớp.');
                  return;
                }
                if (selectedEndPeriod < selectedStartPeriod) {
                  _showMessage('Tiết kết thúc phải lớn hơn hoặc bằng tiết bắt đầu.');
                  return;
                }
                if (_blockStart(selectedStartPeriod) !=
                    _blockStart(selectedEndPeriod)) {
                  _showMessage(
                    'Một ca học không được vượt qua giờ nghỉ. Hãy chọn trong các nhóm tiết 1-3, 4-6, 7-9 hoặc 10-12.',
                  );
                  return;
                }
                if (room.isEmpty) {
                  _showMessage('Vui lòng nhập phòng học.');
                  return;
                }
                if (semester.isEmpty) {
                  _showMessage('Vui lòng nhập học kỳ.');
                  return;
                }

                try {
                  setDialogState(() => loading = true);

                  final subjectDoc = subjects.docs.firstWhere(
                    (doc) => doc.id == selectedSubjectId,
                  );
                  final classDoc = classes.docs.firstWhere(
                    (doc) => doc.id == selectedClassId,
                  );
                  final subjectData = subjectDoc.data();
                  final classData = classDoc.data();
                  final day = _days.firstWhere(
                    (item) => item['index'] == selectedDay,
                  );

                  final existing = await FirebaseFirestore.instance
                      .collection('schedules')
                      .where('classId', isEqualTo: selectedClassId)
                      .where('dayIndex', isEqualTo: selectedDay)
                      .get();

                  final duplicate = existing.docs.any((doc) {
                    if (doc.id == id) return false;
                    final data = doc.data();
                    final otherStart = _startPeriodOf(data);
                    final otherEnd = _endPeriodOf(data);
                    return selectedStartPeriod <= otherEnd &&
                        selectedEndPeriod >= otherStart;
                  });

                  if (duplicate) {
                    if (dialogContext.mounted) {
                      setDialogState(() => loading = false);
                    }
                    _showMessage(
                      'Lớp này đã có lịch trùng tiết vào ${day['name']}.',
                    );
                    return;
                  }

                  final startSlot = _slot(selectedStartPeriod);
                  final endSlot = _slot(selectedEndPeriod);

                  final data = <String, dynamic>{
                    'subjectId': subjectDoc.id,
                    'subjectCode': subjectData['subjectCode'] ?? '',
                    'subjectName': subjectData['subjectName'] ?? '',
                    'classId': classDoc.id,
                    'classCode': classData['classCode'] ?? '',
                    'className': classData['className'] ?? '',
                    'dayIndex': selectedDay,
                    'dayName': day['name'],
                    'startPeriod': selectedStartPeriod,
                    'endPeriod': selectedEndPeriod,
                    'periodCount': selectedEndPeriod - selectedStartPeriod + 1,
                    'startTime': startSlot.start,
                    'endTime': endSlot.end,
                    'room': room,
                    'semester': semester,
                  };

                  if (id == null) {
                    await _service.addSchedule(data);
                  } else {
                    await _service.updateSchedule(id: id, data: data);
                  }

                  if (!mounted) return;
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  _showMessage(
                    id == null
                        ? 'Thêm lịch học thành công.'
                        : 'Cập nhật lịch học thành công.',
                  );
                } catch (e) {
                  if (dialogContext.mounted) {
                    setDialogState(() => loading = false);
                  }
                  _showMessage('Có lỗi xảy ra: $e');
                }
              }

              final blockEnd = _blockEnd(selectedStartPeriod);
              if (selectedEndPeriod < selectedStartPeriod ||
                  selectedEndPeriod > blockEnd) {
                selectedEndPeriod = blockEnd;
              }

              return AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      id == null
                          ? Icons.calendar_month_outlined
                          : Icons.edit_calendar_outlined,
                    ),
                    const SizedBox(width: 10),
                    Text(id == null ? 'Thêm lịch học' : 'Cập nhật lịch học'),
                  ],
                ),
                content: SizedBox(
                  width: 560,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedSubjectId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Môn học',
                            prefixIcon: Icon(Icons.menu_book_outlined),
                          ),
                          items: subjects.docs.map((doc) {
                            final data = doc.data();
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(
                                '${data['subjectCode'] ?? ''} - ${data['subjectName'] ?? ''}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: loading
                              ? null
                              : (value) => setDialogState(
                                    () => selectedSubjectId = value,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedClassId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Lớp học',
                            prefixIcon: Icon(Icons.class_outlined),
                          ),
                          items: classes.docs.map((doc) {
                            final data = doc.data();
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(
                                '${data['classCode'] ?? ''} - ${data['className'] ?? ''}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: loading
                              ? null
                              : (value) => setDialogState(
                                    () => selectedClassId = value,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: selectedDay,
                          decoration: const InputDecoration(
                            labelText: 'Thứ',
                            prefixIcon: Icon(Icons.today_outlined),
                          ),
                          items: _days
                              .map(
                                (day) => DropdownMenuItem<int>(
                                  value: day['index'] as int,
                                  child: Text(day['name'].toString()),
                                ),
                              )
                              .toList(),
                          onChanged: loading
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setDialogState(() => selectedDay = value);
                                },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: selectedStartPeriod,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Tiết bắt đầu',
                                  prefixIcon: Icon(Icons.schedule_outlined),
                                ),
                                items: _periods
                                    .map(
                                      (slot) => DropdownMenuItem<int>(
                                        value: slot.period,
                                        child: Text(
                                          '${slot.period} • ${slot.start}',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: loading
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        setDialogState(() {
                                          selectedStartPeriod = value;
                                          selectedEndPeriod = _blockEnd(value);
                                        });
                                      },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: selectedEndPeriod,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Tiết kết thúc',
                                  prefixIcon: Icon(Icons.schedule),
                                ),
                                items: List.generate(
                                  blockEnd - selectedStartPeriod + 1,
                                  (index) => selectedStartPeriod + index,
                                )
                                    .map(
                                      (period) => DropdownMenuItem<int>(
                                        value: period,
                                        child: Text(
                                          '$period • ${_slot(period).end}',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: loading
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        setDialogState(
                                          () => selectedEndPeriod = value,
                                        );
                                      },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffeef5ff),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xffc7d7f3),
                            ),
                          ),
                          child: Text(
                            'Tiết $selectedStartPeriod - $selectedEndPeriod  •  '
                            '${_slot(selectedStartPeriod).start} - ${_slot(selectedEndPeriod).end}',
                            style: const TextStyle(
                              color: Color(0xff1e3a8a),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: roomController,
                          enabled: !loading,
                          decoration: const InputDecoration(
                            labelText: 'Phòng học',
                            hintText: 'VD: A101',
                            prefixIcon: Icon(Icons.meeting_room_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: semesterController,
                          enabled: !loading,
                          decoration: const InputDecoration(
                            labelText: 'Học kỳ',
                            hintText: 'VD: HK1 2026-2027',
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Hủy'),
                  ),
                  FilledButton.icon(
                    onPressed: loading ? null : save,
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(loading ? 'Đang lưu...' : 'Lưu'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      _showMessage('Không thể tải dữ liệu: $e');
    }
  }

  Future<void> _deleteSchedule({
    required String id,
    required String subjectName,
    required String dayName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa lịch học'),
          content: Text(
            'Bạn có chắc muốn xóa lịch "$subjectName - $dayName" không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _service.deleteSchedule(id);
      _showMessage('Xóa lịch học thành công.');
    } catch (e) {
      _showMessage('Không thể xóa lịch học: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Bạn chưa đăng nhập.'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Không tìm thấy tài khoản.'));
        }

        final userData = snapshot.data!.data()!;
        final role = userData['role']?.toString() ?? 'student';
        if (role == 'admin') return _buildAdminPage();
        return _buildStudentPage(userData);
      },
    );
  }

  Widget _buildAdminPage() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quản lý lịch học',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Thời khóa biểu theo tiết học HUFLIT',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () => _showScheduleDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Thêm lịch học'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .orderBy('classCode')
                .snapshots(),
            builder: (context, classSnapshot) {
              if (classSnapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }

              final List<QueryDocumentSnapshot<Map<String, dynamic>>> classes =
                  classSnapshot.data?.docs ??
                      <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              if (classes.isEmpty) {
                return const Expanded(
                  child: Center(child: Text('Chưa có lớp học.')),
                );
              }

              final validSelected = _selectedAdminClassId != null &&
                  classes.any((doc) => doc.id == _selectedAdminClassId);
              final selectedId =
                  validSelected ? _selectedAdminClassId! : classes.first.id;

              if (_selectedAdminClassId != selectedId) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _selectedAdminClassId != selectedId) {
                    setState(() => _selectedAdminClassId = selectedId);
                  }
                });
              }

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 310,
                          child: DropdownButtonFormField<String>(
                            value: selectedId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Lớp đang xem',
                              prefixIcon: Icon(Icons.groups_2_outlined),
                            ),
                            items: classes.map((doc) {
                              final data = doc.data();
                              final code = data['classCode']?.toString() ?? '';
                              final name = data['className']?.toString() ?? '';
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(
                                  name.isEmpty ? code : '$code - $name',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedAdminClassId = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        SizedBox(
                          width: 360,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchText = value.trim().toLowerCase();
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: 'Tìm môn, phòng...',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: _buildScheduleTimetable(
                        isAdmin: true,
                        classId: selectedId,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentPage(Map<String, dynamic> userData) {
    final studentId = userData['studentId']?.toString() ?? '';
    if (studentId.isEmpty) {
      return const Center(
        child: Text('Tài khoản chưa liên kết với hồ sơ sinh viên.'),
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('students').doc(studentId).get(),
      builder: (context, studentSnapshot) {
        if (studentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!studentSnapshot.hasData || !studentSnapshot.data!.exists) {
          return const Center(child: Text('Không tìm thấy hồ sơ sinh viên.'));
        }

        final student = studentSnapshot.data!.data()!;
        final classId = student['classId']?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lịch học',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                'Lớp: ${student['classCode'] ?? student['className'] ?? '-'}  •  Thời khóa biểu theo tiết học HUFLIT',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 22),
              Expanded(child: _buildStudentSchedule(classId)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentSchedule(String classId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('registrations')
          .where(
            'userId',
            isEqualTo: FirebaseAuth.instance.currentUser!.uid,
          )
          .snapshots(),
      builder: (context, registrationSnapshot) {
        if (registrationSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (registrationSnapshot.hasError) {
          return Center(
            child: Text('Lỗi đăng ký môn: ${registrationSnapshot.error}'),
          );
        }

        final registrations = registrationSnapshot.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final subjectIds = registrations
            .map((doc) => doc.data()['subjectId']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();

        return _buildScheduleTimetable(
          isAdmin: false,
          classId: classId,
          subjectIds: subjectIds,
        );
      },
    );
  }

  Widget _buildScheduleTimetable({
    required bool isAdmin,
    required String classId,
    Set<String>? subjectIds,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.getSchedules(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        List<QueryDocumentSnapshot<Map<String, dynamic>>> schedules =
            (snapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                .where((doc) {
          final data = doc.data();
          if (data['classId']?.toString() != classId) return false;
          if (!isAdmin &&
              !(subjectIds ?? <String>{})
                  .contains(data['subjectId']?.toString() ?? '')) {
            return false;
          }
          return true;
        }).toList();

        if (_searchText.isNotEmpty && isAdmin) {
          schedules = schedules.where((doc) {
            final data = doc.data();
            final text = '${data['subjectCode'] ?? ''} '
                    '${data['subjectName'] ?? ''} '
                    '${data['room'] ?? ''} '
                    '${data['semester'] ?? ''}'
                .toLowerCase();
            return text.contains(_searchText);
          }).toList();
        }

        schedules.sort((a, b) {
          final aData = a.data();
          final bData = b.data();
          final dayCompare = (aData['dayIndex'] as int? ?? 99)
              .compareTo(bData['dayIndex'] as int? ?? 99);
          if (dayCompare != 0) return dayCompare;
          return _startPeriodOf(aData).compareTo(_startPeriodOf(bData));
        });

        return _buildTimetableCanvas(schedules, isAdmin: isAdmin);
      },
    );
  }

  Widget _buildTimetableCanvas(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> schedules, {
    required bool isAdmin,
  }) {
    final totalWidth = _periodColumnWidth + _dayColumnWidth * _days.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffd7e0e8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        controller: _horizontalScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Column(
              children: [
                _buildTimetableHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPeriodColumn(),
                        ..._days.map((day) {
                          final dayIndex = day['index'] as int;
                          final daySchedules = schedules
                              .where(
                                (doc) =>
                                    (doc.data()['dayIndex'] as int? ?? -1) ==
                                    dayIndex,
                              )
                              .toList();
                          return _buildDayColumn(
                            daySchedules,
                            isAdmin: isAdmin,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimetableHeader() {
    const headerColor = Color(0xff155a84);
    const borderColor = Color(0xffb9cedc);

    Widget headerCell(String text, double width) {
      return Container(
        width: width,
        height: 54,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: headerColor,
          border: Border(
            right: BorderSide(color: borderColor),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      );
    }

    return Row(
      children: [
        headerCell('Tiết', _periodColumnWidth),
        ..._days.map(
          (day) => headerCell(day['name'].toString(), _dayColumnWidth),
        ),
      ],
    );
  }

  Widget _buildPeriodColumn() {
    return SizedBox(
      width: _periodColumnWidth,
      height: _timetableBodyHeight,
      child: Column(
        children: [
          for (final slot in _periods) ...[
            Container(
              width: _periodColumnWidth,
              height: _periodRowHeight,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xffe8f1f7),
                border: Border(
                  right: BorderSide(color: Color(0xffc8d8e3)),
                  bottom: BorderSide(color: Color(0xffc8d8e3)),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${slot.period}',
                    style: const TextStyle(
                      color: Color(0xff23456b),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${slot.start}\n${slot.end}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xff58738c),
                      fontSize: 10,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            if (slot.period == 3)
              _buildBreakCell('Nghỉ 15 phút')
            else if (slot.period == 6)
              _buildBreakCell('Nghỉ trưa')
            else if (slot.period == 9)
              _buildBreakCell('Nghỉ 15 phút'),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakCell(String label) {
    return Container(
      width: _periodColumnWidth,
      height: _breakHeight,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xffd9e8f1),
        border: Border(
          right: BorderSide(color: Color(0xffc8d8e3)),
          bottom: BorderSide(color: Color(0xffc8d8e3)),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xff506b7f),
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDayColumn(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> schedules, {
    required bool isAdmin,
  }) {
    return SizedBox(
      width: _dayColumnWidth,
      height: _timetableBodyHeight,
      child: Stack(
        children: [
          _buildDayGridBackground(),
          ...schedules.map(
            (doc) => _buildScheduleCard(doc, isAdmin: isAdmin),
          ),
        ],
      ),
    );
  }

  Widget _buildDayGridBackground() {
    return Column(
      children: [
        for (final slot in _periods) ...[
          Container(
            width: _dayColumnWidth,
            height: _periodRowHeight,
            decoration: const BoxDecoration(
              color: Color(0xfffbfcfd),
              border: Border(
                right: BorderSide(color: Color(0xffd5e0e8)),
                bottom: BorderSide(color: Color(0xffd5e0e8)),
              ),
            ),
          ),
          if (slot.period == 3 || slot.period == 6 || slot.period == 9)
            Container(
              width: _dayColumnWidth,
              height: _breakHeight,
              decoration: const BoxDecoration(
                color: Color(0xffedf4f8),
                border: Border(
                  right: BorderSide(color: Color(0xffd5e0e8)),
                  bottom: BorderSide(color: Color(0xffd5e0e8)),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildScheduleCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required bool isAdmin,
  }) {
    final data = doc.data();
    var startPeriod = _startPeriodOf(data);
    var endPeriod = _endPeriodOf(data);
    if (endPeriod < startPeriod) endPeriod = startPeriod;
    if (_blockStart(startPeriod) != _blockStart(endPeriod)) {
      endPeriod = _blockEnd(startPeriod);
    }

    final top = _topForPeriod(startPeriod) + 5;
    final height = _heightForPeriodRange(startPeriod, endPeriod) - 10;
    final periodCount = endPeriod - startPeriod + 1;

    final subjectCode = data['subjectCode']?.toString() ?? '';
    final subjectName = data['subjectName']?.toString() ?? '';
    final classCode = data['classCode']?.toString() ?? '';
    final room = data['room']?.toString() ?? '';
    final semester = data['semester']?.toString() ?? '';
    final dayName = data['dayName']?.toString() ?? '';
    final startTime = _slot(startPeriod).start;
    final endTime = _slot(endPeriod).end;

    final compact = periodCount == 1;

    return Positioned(
      top: top,
      left: 5,
      right: 5,
      height: height,
      child: Tooltip(
        message: '$subjectCode - $subjectName\n'
            'Lớp: $classCode • Phòng: $room\n'
            'Tiết: $startPeriod-$endPeriod • $startTime-$endTime\n'
            'Học kỳ: $semester',
        child: Container(
          padding: EdgeInsets.fromLTRB(
            compact ? 6 : 8,
            compact ? 5 : 7,
            compact ? 6 : 8,
            compact ? 5 : 7,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xffffa63d),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(right: isAdmin ? 20 : 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        subjectCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xff0c3858),
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 11 : 13,
                        ),
                      ),
                      SizedBox(height: compact ? 1 : 3),
                      Text(
                        subjectName,
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xffe53935),
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 10 : 11.5,
                          height: 1.18,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Lớp: $classCode',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xff174f78),
                            fontSize: 10.5,
                          ),
                        ),
                        Text(
                          'Phòng: $room',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xff174f78),
                            fontSize: 10.5,
                          ),
                        ),
                        Text(
                          'Tiết: $startPeriod-$endPeriod',
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xff174f78),
                            fontSize: 10.5,
                          ),
                        ),
                        if (periodCount >= 2)
                          Text(
                            '$startTime - $endTime',
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xff174f78),
                              fontSize: 10,
                            ),
                          ),
                      ] else
                        Text(
                          'T$startPeriod • $room',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xff174f78),
                            fontSize: 9.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (isAdmin)
                Positioned(
                  top: -6,
                  right: -8,
                  child: PopupMenuButton<String>(
                    tooltip: 'Thao tác',
                    padding: EdgeInsets.zero,
                    iconSize: 17,
                    icon: const Icon(
                      Icons.more_vert,
                      color: Color(0xff5b6470),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showScheduleDialog(id: doc.id, oldData: data);
                      } else if (value == 'delete') {
                        _deleteSchedule(
                          id: doc.id,
                          subjectName: subjectName,
                          dayName: dayName,
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Sửa'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text('Xóa'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }
}
