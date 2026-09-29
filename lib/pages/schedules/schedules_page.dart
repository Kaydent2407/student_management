import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/schedule_service.dart';

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  State<SchedulesPage> createState() =>
      _SchedulesPageState();
}

class _SchedulesPageState
    extends State<SchedulesPage> {
  final ScheduleService _service =
      ScheduleService();

  final TextEditingController
      _searchController =
      TextEditingController();

  String _searchText = '';

  final List<Map<String, dynamic>> _days = [
    {
      'index': 2,
      'name': 'Thứ 2',
    },
    {
      'index': 3,
      'name': 'Thứ 3',
    },
    {
      'index': 4,
      'name': 'Thứ 4',
    },
    {
      'index': 5,
      'name': 'Thứ 5',
    },
    {
      'index': 6,
      'name': 'Thứ 6',
    },
    {
      'index': 7,
      'name': 'Thứ 7',
    },
    {
      'index': 8,
      'name': 'Chủ nhật',
    },
  ];

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // KIỂM TRA HH:MM
  // =========================================================

  bool _isValidTime(
    String value,
  ) {
    final regex = RegExp(
      r'^([01]\d|2[0-3]):[0-5]\d$',
    );

    return regex.hasMatch(value);
  }

  // =========================================================
  // SO SÁNH GIỜ
  // =========================================================

  bool _isStartBeforeEnd({
    required String start,
    required String end,
  }) {
    final startParts =
        start.split(':');

    final endParts =
        end.split(':');

    final startMinutes =
        int.parse(startParts[0]) * 60 +
            int.parse(startParts[1]);

    final endMinutes =
        int.parse(endParts[0]) * 60 +
            int.parse(endParts[1]);

    return startMinutes < endMinutes;
  }

  // =========================================================
  // THÊM / SỬA LỊCH
  // =========================================================

  Future<void> _showScheduleDialog({
    String? id,
    Map<String, dynamic>? oldData,
  }) async {
    try {
      final results =
          await Future.wait([
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
          results[0]
              as QuerySnapshot<
                  Map<String, dynamic>>;

      final classes =
          results[1]
              as QuerySnapshot<
                  Map<String, dynamic>>;

      if (subjects.docs.isEmpty) {
        _showMessage(
          'Chưa có môn học.',
        );
        return;
      }

      if (classes.docs.isEmpty) {
        _showMessage(
          'Chưa có lớp học.',
        );
        return;
      }

      String? selectedSubjectId =
          oldData?['subjectId']
              ?.toString();

      String? selectedClassId =
          oldData?['classId']
              ?.toString();

      int selectedDay =
          oldData?['dayIndex']
                  as int? ??
              2;

      final startController =
          TextEditingController(
        text: oldData?['startTime']
                ?.toString() ??
            '07:30',
      );

      final endController =
          TextEditingController(
        text: oldData?['endTime']
                ?.toString() ??
            '09:30',
      );

      final roomController =
          TextEditingController(
        text: oldData?['room']
                ?.toString() ??
            '',
      );

      final semesterController =
          TextEditingController(
        text: oldData?['semester']
                ?.toString() ??
            '',
      );

      if (selectedSubjectId != null &&
          !subjects.docs.any(
            (doc) =>
                doc.id ==
                selectedSubjectId,
          )) {
        selectedSubjectId = null;
      }

      if (selectedClassId != null &&
          !classes.docs.any(
            (doc) =>
                doc.id ==
                selectedClassId,
          )) {
        selectedClassId = null;
      }

      bool loading = false;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder:
                (context,
                    setDialogState) {
              Future<void> save() async {
                final startTime =
                    startController.text
                        .trim();

                final endTime =
                    endController.text
                        .trim();

                final room =
                    roomController.text
                        .trim();

                final semester =
                    semesterController
                        .text
                        .trim();

                if (selectedSubjectId ==
                    null) {
                  _showMessage(
                    'Vui lòng chọn môn học.',
                  );
                  return;
                }

                if (selectedClassId ==
                    null) {
                  _showMessage(
                    'Vui lòng chọn lớp.',
                  );
                  return;
                }

                if (!_isValidTime(
                        startTime) ||
                    !_isValidTime(
                        endTime)) {
                  _showMessage(
                    'Giờ học phải đúng định dạng HH:mm. Ví dụ 07:30.',
                  );
                  return;
                }

                if (!_isStartBeforeEnd(
                  start: startTime,
                  end: endTime,
                )) {
                  _showMessage(
                    'Giờ bắt đầu phải nhỏ hơn giờ kết thúc.',
                  );
                  return;
                }

                if (room.isEmpty) {
                  _showMessage(
                    'Vui lòng nhập phòng học.',
                  );
                  return;
                }

                if (semester.isEmpty) {
                  _showMessage(
                    'Vui lòng nhập học kỳ.',
                  );
                  return;
                }

                try {
                  setDialogState(() {
                    loading = true;
                  });

                  final subjectDoc =
                      subjects.docs
                          .firstWhere(
                    (doc) =>
                        doc.id ==
                        selectedSubjectId,
                  );

                  final classDoc =
                      classes.docs
                          .firstWhere(
                    (doc) =>
                        doc.id ==
                        selectedClassId,
                  );

                  final subjectData =
                      subjectDoc.data();

                  final classData =
                      classDoc.data();

                  final day =
                      _days.firstWhere(
                    (item) =>
                        item['index'] ==
                        selectedDay,
                  );

                  // Kiểm tra trùng lịch cùng lớp
                  final existing =
                      await FirebaseFirestore
                          .instance
                          .collection(
                            'schedules',
                          )
                          .where(
                            'classId',
                            isEqualTo:
                                selectedClassId,
                          )
                          .where(
                            'dayIndex',
                            isEqualTo:
                                selectedDay,
                          )
                          .where(
                            'startTime',
                            isEqualTo:
                                startTime,
                          )
                          .get();

                  final duplicate =
                      existing.docs.any(
                    (doc) =>
                        doc.id != id,
                  );

                  if (duplicate) {
                    if (dialogContext
                        .mounted) {
                      setDialogState(() {
                        loading = false;
                      });
                    }

                    _showMessage(
                      'Lớp này đã có lịch bắt đầu lúc $startTime vào ${day['name']}.',
                    );

                    return;
                  }

                  final data =
                      <String, dynamic>{
                    'subjectId':
                        subjectDoc.id,

                    'subjectCode':
                        subjectData[
                                'subjectCode'] ??
                            '',

                    'subjectName':
                        subjectData[
                                'subjectName'] ??
                            '',

                    'classId':
                        classDoc.id,

                    'classCode':
                        classData[
                                'classCode'] ??
                            '',

                    'className':
                        classData[
                                'className'] ??
                            '',

                    'dayIndex':
                        selectedDay,

                    'dayName':
                        day['name'],

                    'startTime':
                        startTime,

                    'endTime':
                        endTime,

                    'room':
                        room,

                    'semester':
                        semester,
                  };

                  if (id == null) {
                    await _service
                        .addSchedule(
                      data,
                    );
                  } else {
                    await _service
                        .updateSchedule(
                      id: id,
                      data: data,
                    );
                  }

                  if (!mounted) return;

                  if (dialogContext
                      .mounted) {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  }

                  _showMessage(
                    id == null
                        ? 'Thêm lịch học thành công.'
                        : 'Cập nhật lịch học thành công.',
                  );
                } catch (e) {
                  if (dialogContext
                      .mounted) {
                    setDialogState(() {
                      loading = false;
                    });
                  }

                  _showMessage(
                    'Có lỗi xảy ra: $e',
                  );
                }
              }

              return AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      id == null
                          ? Icons
                              .calendar_month_outlined
                          : Icons
                              .edit_calendar_outlined,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      id == null
                          ? 'Thêm lịch học'
                          : 'Cập nhật lịch học',
                    ),
                  ],
                ),

                content: SizedBox(
                  width: 550,
                  child:
                      SingleChildScrollView(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize
                              .min,
                      children: [
                        DropdownButtonFormField<
                            String>(
                          initialValue:
                              selectedSubjectId,
                          isExpanded:
                              true,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Môn học',
                            prefixIcon:
                                Icon(
                              Icons
                                  .menu_book_outlined,
                            ),
                          ),
                          items:
                              subjects.docs
                                  .map(
                            (doc) {
                              final data =
                                  doc.data();

                              final code =
                                  data['subjectCode'] ??
                                      '';

                              final name =
                                  data['subjectName'] ??
                                      '';

                              return DropdownMenuItem<
                                  String>(
                                value:
                                    doc.id,
                                child: Text(
                                  '$code - $name',
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                ),
                              );
                            },
                          ).toList(),
                          onChanged:
                              loading
                                  ? null
                                  : (value) {
                                      setDialogState(
                                        () {
                                          selectedSubjectId =
                                              value;
                                        },
                                      );
                                    },
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        DropdownButtonFormField<
                            String>(
                          initialValue:
                              selectedClassId,
                          isExpanded:
                              true,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Lớp học',
                            prefixIcon:
                                Icon(
                              Icons
                                  .class_outlined,
                            ),
                          ),
                          items:
                              classes.docs.map(
                            (doc) {
                              final data =
                                  doc.data();

                              final code =
                                  data['classCode'] ??
                                      '';

                              final name =
                                  data['className'] ??
                                      '';

                              return DropdownMenuItem<
                                  String>(
                                value:
                                    doc.id,
                                child: Text(
                                  '$code - $name',
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                ),
                              );
                            },
                          ).toList(),
                          onChanged:
                              loading
                                  ? null
                                  : (value) {
                                      setDialogState(
                                        () {
                                          selectedClassId =
                                              value;
                                        },
                                      );
                                    },
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        DropdownButtonFormField<
                            int>(
                          initialValue:
                              selectedDay,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Thứ',
                            prefixIcon:
                                Icon(
                              Icons
                                  .today_outlined,
                            ),
                          ),
                          items: _days
                              .map(
                                (day) =>
                                    DropdownMenuItem<
                                        int>(
                                  value:
                                      day['index']
                                          as int,
                                  child:
                                      Text(
                                    day['name']
                                        .toString(),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged:
                              loading
                                  ? null
                                  : (value) {
                                      if (value ==
                                          null) {
                                        return;
                                      }

                                      setDialogState(
                                        () {
                                          selectedDay =
                                              value;
                                        },
                                      );
                                    },
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        Row(
                          children: [
                            Expanded(
                              child:
                                  TextField(
                                controller:
                                    startController,
                                enabled:
                                    !loading,
                                decoration:
                                    const InputDecoration(
                                  labelText:
                                      'Giờ bắt đầu',
                                  hintText:
                                      '07:30',
                                  prefixIcon:
                                      Icon(
                                    Icons
                                        .schedule,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 15,
                            ),

                            Expanded(
                              child:
                                  TextField(
                                controller:
                                    endController,
                                enabled:
                                    !loading,
                                decoration:
                                    const InputDecoration(
                                  labelText:
                                      'Giờ kết thúc',
                                  hintText:
                                      '09:30',
                                  prefixIcon:
                                      Icon(
                                    Icons
                                        .schedule_outlined,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        TextField(
                          controller:
                              roomController,
                          enabled:
                              !loading,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Phòng học',
                            hintText:
                                'VD: A101',
                            prefixIcon:
                                Icon(
                              Icons
                                  .meeting_room_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        TextField(
                          controller:
                              semesterController,
                          enabled:
                              !loading,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Học kỳ',
                            hintText:
                                'VD: HK1 2026-2027',
                            prefixIcon:
                                Icon(
                              Icons
                                  .school_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                actions: [
                  TextButton(
                    onPressed:
                        loading
                            ? null
                            : () {
                                Navigator.of(
                                  dialogContext,
                                ).pop();
                              },
                    child:
                        const Text(
                      'Hủy',
                    ),
                  ),

                  FilledButton.icon(
                    onPressed:
                        loading
                            ? null
                            : save,
                    icon: loading
                        ? const SizedBox(
                            width:
                                18,
                            height:
                                18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Icon(
                            Icons
                                .save_outlined,
                          ),
                    label: Text(
                      loading
                          ? 'Đang lưu...'
                          : 'Lưu',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      // Không dispose local controllers ngay sau showDialog
      // để tránh lỗi Flutter Web _dependents.isEmpty.
    } catch (e) {
      _showMessage(
        'Không thể tải dữ liệu: $e',
      );
    }
  }

  // =========================================================
  // XÓA
  // =========================================================

  Future<void> _deleteSchedule({
    required String id,
    required String subjectName,
    required String dayName,
  }) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Xóa lịch học',
          ),
          content: Text(
            'Bạn có chắc muốn xóa lịch "$subjectName - $dayName" không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              icon: const Icon(
                Icons.delete_outline,
              ),
              label:
                  const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _service
          .deleteSchedule(id);

      _showMessage(
        'Xóa lịch học thành công.',
      );
    } catch (e) {
      _showMessage(
        'Không thể xóa lịch học: $e',
      );
    }
  }

  // =========================================================
  // CHECK ROLE
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final user =
        FirebaseAuth
            .instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          'Bạn chưa đăng nhập.',
        ),
      );
    }

    return StreamBuilder<
        DocumentSnapshot<
            Map<String, dynamic>>>(
      stream: FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot
                .connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData ||
            !snapshot.data!.exists) {
          return const Center(
            child: Text(
              'Không tìm thấy tài khoản.',
            ),
          );
        }

        final userData =
            snapshot.data!.data()!;

        final role =
            userData['role']
                    ?.toString() ??
                'student';

        if (role == 'admin') {
          return _buildAdminPage();
        }

        return _buildStudentPage(
          userData,
        );
      },
    );
  }

  // =========================================================
  // ADMIN
  // =========================================================

  Widget _buildAdminPage() {
    return Padding(
      padding:
          const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children: [
              const Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    'Quản lý lịch học',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    'Quản lý lịch học theo lớp và môn học',
                    style: TextStyle(
                      color:
                          Colors.grey,
                    ),
                  ),
                ],
              ),

              FilledButton.icon(
                onPressed: () {
                  _showScheduleDialog();
                },
                icon: const Icon(
                  Icons.add,
                ),
                label: const Text(
                  'Thêm lịch học',
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 25,
          ),

          SizedBox(
            width: 450,
            child: TextField(
              controller:
                  _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText =
                      value
                          .trim()
                          .toLowerCase();
                });
              },
              decoration:
                  const InputDecoration(
                hintText:
                    'Tìm môn, lớp, phòng...',
                prefixIcon:
                    Icon(Icons.search),
              ),
            ),
          ),

          const SizedBox(
            height: 22,
          ),

          Expanded(
            child:
                _buildScheduleTable(
              isAdmin: true,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STUDENT
  // =========================================================

  Widget _buildStudentPage(
    Map<String, dynamic> userData,
  ) {
    final studentId =
        userData['studentId']
                ?.toString() ??
            '';

    if (studentId.isEmpty) {
      return const Center(
        child: Text(
          'Tài khoản chưa liên kết với hồ sơ sinh viên.',
        ),
      );
    }

    return FutureBuilder<
        DocumentSnapshot<
            Map<String, dynamic>>>(
      future: FirebaseFirestore
          .instance
          .collection('students')
          .doc(studentId)
          .get(),
      builder:
          (context, studentSnapshot) {
        if (studentSnapshot
                .connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        if (!studentSnapshot
                .hasData ||
            !studentSnapshot
                .data!.exists) {
          return const Center(
            child: Text(
              'Không tìm thấy hồ sơ sinh viên.',
            ),
          );
        }

        final student =
            studentSnapshot
                .data!
                .data()!;

        final classId =
            student['classId']
                    ?.toString() ??
                '';

        return Padding(
          padding:
              const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              const Text(
                'Lịch học',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                'Lớp: ${student['classCode'] ?? student['className'] ?? '-'}',
                style:
                    const TextStyle(
                  color:
                      Colors.grey,
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              Expanded(
                child:
                    _buildStudentSchedule(
                  classId,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // STUDENT SCHEDULE
  // =========================================================

  Widget _buildStudentSchedule(
    String classId,
  ) {
    return StreamBuilder<
        QuerySnapshot<
            Map<String, dynamic>>>(
      stream: FirebaseFirestore
          .instance
          .collection(
            'registrations',
          )
          .where(
            'userId',
            isEqualTo:
                FirebaseAuth.instance
                    .currentUser!.uid,
          )
          .snapshots(),
      builder:
          (context,
              registrationSnapshot) {
        if (registrationSnapshot
                .connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        if (registrationSnapshot
            .hasError) {
          return Center(
            child: Text(
              'Lỗi đăng ký môn: ${registrationSnapshot.error}',
            ),
          );
        }

        final subjectIds =
            (registrationSnapshot
                        .data?.docs ??
                    [])
                .map(
                  (doc) => doc
                          .data()[
                              'subjectId']
                          ?.toString() ??
                      '',
                )
                .where(
                  (id) =>
                      id.isNotEmpty,
                )
                .toSet();

        return _buildScheduleTable(
          isAdmin: false,
          classId: classId,
          subjectIds: subjectIds,
        );
      },
    );
  }

  // =========================================================
  // TABLE
  // =========================================================

  Widget _buildScheduleTable({
    required bool isAdmin,
    String? classId,
    Set<String>? subjectIds,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              const Color(
            0xffe5e7eb,
          ),
        ),
      ),
      child: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream:
            _service.getSchedules(),
        builder: (context, snapshot) {
          if (snapshot
                  .connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
              ),
            );
          }

          var schedules =
              [...snapshot.data?.docs ??
                  []];

          if (!isAdmin) {
            schedules =
                schedules.where(
              (doc) {
                final data =
                    doc.data();

                return data['classId'] ==
                        classId &&
                    (subjectIds ??
                            {})
                        .contains(
                      data['subjectId']
                          ?.toString(),
                    );
              },
            ).toList();
          }

          schedules.sort(
            (a, b) {
              final aData =
                  a.data();

              final bData =
                  b.data();

              final dayCompare =
                  (aData['dayIndex']
                              as int? ??
                          99)
                      .compareTo(
                bData['dayIndex']
                        as int? ??
                    99,
              );

              if (dayCompare != 0) {
                return dayCompare;
              }

              return (aData['startTime']
                          ?.toString() ??
                      '')
                  .compareTo(
                bData['startTime']
                        ?.toString() ??
                    '',
              );
            },
          );

          if (_searchText.isNotEmpty) {
            schedules =
                schedules.where(
              (doc) {
                final data =
                    doc.data();

                final text =
                    '${data['subjectCode'] ?? ''} '
                            '${data['subjectName'] ?? ''} '
                            '${data['classCode'] ?? ''} '
                            '${data['className'] ?? ''} '
                            '${data['room'] ?? ''} '
                            '${data['dayName'] ?? ''}'
                        .toLowerCase();

                return text.contains(
                  _searchText,
                );
              },
            ).toList();
          }

          return Column(
            children: [
              _buildHeader(
                isAdmin,
              ),

              Expanded(
                child:
                    schedules.isEmpty
                        ? const Center(
                            child: Text(
                              'Chưa có lịch học.',
                              style:
                                  TextStyle(
                                color:
                                    Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount:
                                schedules
                                    .length,
                            itemBuilder:
                                (context,
                                    index) {
                              return _buildRow(
                                schedules[
                                    index],
                                isAdmin:
                                    isAdmin,
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader(
    bool isAdmin,
  ) {
    const style = TextStyle(
      fontWeight:
          FontWeight.w600,
      color:
          Color(0xff374151),
    );

    return Container(
      height: 56,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      color:
          const Color(0xfff8fafc),
      child: Row(
        children: [
          const Expanded(
            flex: 13,
            child: Text(
              'Thứ',
              style: style,
            ),
          ),
          const Expanded(
            flex: 15,
            child: Text(
              'Mã môn',
              style: style,
            ),
          ),
          const Expanded(
            flex: 24,
            child: Text(
              'Môn học',
              style: style,
            ),
          ),
          const Expanded(
            flex: 15,
            child: Text(
              'Lớp',
              style: style,
            ),
          ),
          const Expanded(
            flex: 15,
            child: Text(
              'Thời gian',
              style: style,
            ),
          ),
          const Expanded(
            flex: 12,
            child: Text(
              'Phòng',
              style: style,
            ),
          ),
          const Expanded(
            flex: 18,
            child: Text(
              'Học kỳ',
              style: style,
            ),
          ),

          if (isAdmin)
            const Expanded(
              flex: 12,
              child: Center(
                child: Text(
                  'Thao tác',
                  style: style,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // ROW
  // =========================================================

  Widget _buildRow(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc, {
    required bool isAdmin,
  }) {
    final data =
        doc.data();

    final subjectName =
        data['subjectName']
                ?.toString() ??
            '';

    final dayName =
        data['dayName']
                ?.toString() ??
            '';

    return Container(
      constraints:
          const BoxConstraints(
        minHeight: 66,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      decoration:
          const BoxDecoration(
        border: Border(
          top: BorderSide(
            color:
                Color(
              0xffe5e7eb,
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 13,
            child: Text(
              dayName,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            flex: 15,
            child: Text(
              data['subjectCode']
                      ?.toString() ??
                  '',
            ),
          ),

          Expanded(
            flex: 24,
            child: Text(
              subjectName,
              overflow:
                  TextOverflow
                      .ellipsis,
            ),
          ),

          Expanded(
            flex: 15,
            child: Text(
              data['classCode']
                      ?.toString() ??
                  '',
            ),
          ),

          Expanded(
            flex: 15,
            child: Text(
              '${data['startTime'] ?? ''} - ${data['endTime'] ?? ''}',
            ),
          ),

          Expanded(
            flex: 12,
            child: Text(
              data['room']
                      ?.toString() ??
                  '',
            ),
          ),

          Expanded(
            flex: 18,
            child: Text(
              data['semester']
                      ?.toString() ??
                  '',
              overflow:
                  TextOverflow
                      .ellipsis,
            ),
          ),

          if (isAdmin)
            Expanded(
              flex: 12,
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  IconButton(
                    tooltip:
                        'Sửa lịch',
                    onPressed: () {
                      _showScheduleDialog(
                        id:
                            doc.id,
                        oldData:
                            data,
                      );
                    },
                    icon:
                        const Icon(
                      Icons
                          .edit_outlined,
                    ),
                  ),

                  IconButton(
                    tooltip:
                        'Xóa lịch',
                    onPressed: () {
                      _deleteSchedule(
                        id:
                            doc.id,
                        subjectName:
                            subjectName,
                        dayName:
                            dayName,
                      );
                    },
                    icon:
                        const Icon(
                      Icons
                          .delete_outline,
                      color:
                          Colors.red,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}