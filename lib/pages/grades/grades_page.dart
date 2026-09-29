import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/grade_service.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() =>
      _GradesPageState();
}

class _GradesPageState
    extends State<GradesPage> {
  final GradeService _gradeService =
      GradeService();

  final TextEditingController
      _searchController =
      TextEditingController();

  String _searchText = '';

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // FORMAT SCORE
  // =========================================================

  String _formatScore(dynamic value) {
    if (value == null) {
      return '-';
    }

    if (value is num) {
      return value
          .toDouble()
          .toStringAsFixed(2)
          .replaceFirst(
            RegExp(r'\.?0+$'),
            '',
          );
    }

    return value.toString();
  }

  // =========================================================
  // NHẬP / SỬA ĐIỂM
  // =========================================================

  Future<void> _showGradeDialog({
    required String registrationId,
    required Map<String, dynamic>
        registration,
    Map<String, dynamic>? grade,
  }) async {
    final midtermController =
        TextEditingController(
      text: grade?['midtermScore']
              ?.toString() ??
          '',
    );

    final finalController =
        TextEditingController(
      text: grade?['finalScore']
              ?.toString() ??
          '',
    );

    bool loading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            Future<void> save() async {
              final midterm =
                  double.tryParse(
                midtermController.text
                    .trim()
                    .replaceAll(',', '.'),
              );

              final finalScore =
                  double.tryParse(
                finalController.text
                    .trim()
                    .replaceAll(',', '.'),
              );

              if (midterm == null) {
                _showMessage(
                  'Điểm giữa kỳ không hợp lệ.',
                );
                return;
              }

              if (finalScore == null) {
                _showMessage(
                  'Điểm cuối kỳ không hợp lệ.',
                );
                return;
              }

              if (midterm < 0 ||
                  midterm > 10 ||
                  finalScore < 0 ||
                  finalScore > 10) {
                _showMessage(
                  'Điểm phải nằm trong khoảng 0 đến 10.',
                );
                return;
              }

              try {
                setDialogState(() {
                  loading = true;
                });

                await _gradeService
                    .saveGrade(
                  registrationId:
                      registrationId,
                  registration:
                      registration,
                  midterm:
                      midterm,
                  finalScore:
                      finalScore,
                );

                if (!mounted) return;

                if (dialogContext.mounted) {
                  Navigator.of(
                    dialogContext,
                  ).pop();
                }

                _showMessage(
                  grade == null
                      ? 'Nhập điểm thành công.'
                      : 'Cập nhật điểm thành công.',
                );
              } catch (e) {
                if (dialogContext.mounted) {
                  setDialogState(() {
                    loading = false;
                  });
                }

                _showMessage(
                  e.toString()
                      .replaceFirst(
                    'Exception: ',
                    '',
                  ),
                );
              }
            }

            final studentCode =
                registration[
                            'studentCode']
                        ?.toString() ??
                    '';

            final studentName =
                registration[
                            'studentName']
                        ?.toString() ??
                    '';

            final subjectCode =
                registration[
                            'subjectCode']
                        ?.toString() ??
                    '';

            final subjectName =
                registration[
                            'subjectName']
                        ?.toString() ??
                    '';

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(
                    Icons
                        .edit_note_outlined,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    grade == null
                        ? 'Nhập điểm'
                        : 'Cập nhật điểm',
                  ),
                ],
              ),

              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets
                              .all(16),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xfff8fafc,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(10),
                        border:
                            Border.all(
                          color:
                              const Color(
                            0xffe5e7eb,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            '$studentCode - $studentName',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          Text(
                            '$subjectCode - $subjectName',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    TextField(
                      controller:
                          midtermController,
                      enabled: !loading,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Điểm giữa kỳ',
                        hintText:
                            'Từ 0 đến 10',
                        prefixIcon: Icon(
                          Icons
                              .edit_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    TextField(
                      controller:
                          finalController,
                      enabled: !loading,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Điểm cuối kỳ',
                        hintText:
                            'Từ 0 đến 10',
                        prefixIcon: Icon(
                          Icons
                              .fact_check_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    const Text(
                      'Điểm tổng kết = Giữa kỳ × 40% + Cuối kỳ × 60%',
                      style: TextStyle(
                        color:
                            Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          Navigator.of(
                            dialogContext,
                          ).pop();
                        },
                  child:
                      const Text('Hủy'),
                ),

                FilledButton.icon(
                  onPressed:
                      loading
                          ? null
                          : save,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons
                              .save_outlined,
                        ),
                  label: Text(
                    loading
                        ? 'Đang lưu...'
                        : 'Lưu điểm',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // Không dispose controller ở đây
    // để tránh lỗi _dependents.isEmpty trên Flutter Web.
  }

  // =========================================================
  // XÓA ĐIỂM
  // =========================================================

  Future<void> _deleteGrade({
    required String registrationId,
    required String studentName,
    required String subjectName,
  }) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Xóa điểm'),
          content: Text(
            'Bạn có chắc muốn xóa điểm môn '
            '"$subjectName" của "$studentName" không?',
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

    if (confirmed != true) {
      return;
    }

    try {
      await _gradeService.deleteGrade(
        registrationId,
      );

      _showMessage(
        'Xóa điểm thành công.',
      );
    } catch (e) {
      _showMessage(
        'Không thể xóa điểm: $e',
      );
    }
  }

  // =========================================================
  // BUILD - CHECK ROLE
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

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
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
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

        if (!snapshot.hasData ||
            !snapshot.data!.exists) {
          return const Center(
            child: Text(
              'Không tìm thấy tài khoản.',
            ),
          );
        }

        final data =
            snapshot.data!.data()!;

        final role =
            data['role']?.toString() ??
                'student';

        if (role == 'admin') {
          return _buildAdminPage();
        }

        return _buildStudentPage();
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
          const Text(
            'Quản lý điểm',
            style: TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Nhập và quản lý điểm của sinh viên theo môn học',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 25),

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
                    'Tìm MSSV, sinh viên hoặc môn học...',
                prefixIcon:
                    Icon(Icons.search),
              ),
            ),
          ),

          const SizedBox(height: 22),

          Expanded(
            child: Container(
              width:
                  double.infinity,
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius
                        .circular(12),
                border: Border.all(
                  color:
                      const Color(
                    0xffe5e7eb,
                  ),
                ),
              ),
              child: StreamBuilder<
                  QuerySnapshot<
                      Map<String,
                          dynamic>>>(
                stream:
                    _gradeService
                        .getAllGrades(),
                builder:
                    (context,
                        gradeSnapshot) {
                  if (gradeSnapshot
                          .connectionState ==
                      ConnectionState
                          .waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  final Map<
                      String,
                      Map<String,
                          dynamic>>
                      grades = {};

                  for (final doc
                      in gradeSnapshot
                              .data?.docs ??
                          []) {
                    grades[doc.id] =
                        doc.data();
                  }

                  return StreamBuilder<
                      QuerySnapshot<
                          Map<String,
                              dynamic>>>(
                    stream:
                        _gradeService
                            .getRegistrations(),
                    builder:
                        (context,
                            registrationSnapshot) {
                      if (registrationSnapshot
                              .connectionState ==
                          ConnectionState
                              .waiting) {
                        return const Center(
                          child:
                              CircularProgressIndicator(),
                        );
                      }

                      if (registrationSnapshot
                          .hasError) {
                        return Center(
                          child: Text(
                            'Lỗi: ${registrationSnapshot.error}',
                          ),
                        );
                      }

                      final docs =
                          registrationSnapshot
                                  .data
                                  ?.docs ??
                              [];

                      final filtered =
                          docs.where(
                        (doc) {
                          final data =
                              doc.data();

                          final studentCode =
                              (data['studentCode'] ??
                                      '')
                                  .toString()
                                  .toLowerCase();

                          final studentName =
                              (data['studentName'] ??
                                      '')
                                  .toString()
                                  .toLowerCase();

                          final subjectCode =
                              (data['subjectCode'] ??
                                      '')
                                  .toString()
                                  .toLowerCase();

                          final subjectName =
                              (data['subjectName'] ??
                                      '')
                                  .toString()
                                  .toLowerCase();

                          return studentCode
                                  .contains(
                                    _searchText,
                                  ) ||
                              studentName
                                  .contains(
                                    _searchText,
                                  ) ||
                              subjectCode
                                  .contains(
                                    _searchText,
                                  ) ||
                              subjectName
                                  .contains(
                                    _searchText,
                                  );
                        },
                      ).toList();

                      return Column(
                        children: [
                          _buildAdminHeader(),

                          Expanded(
                            child: filtered
                                    .isEmpty
                                ? const Center(
                                    child:
                                        Text(
                                      'Chưa có sinh viên đăng ký môn học.',
                                      style:
                                          TextStyle(
                                        color:
                                            Colors.grey,
                                      ),
                                    ),
                                  )
                                : ListView
                                    .builder(
                                    itemCount:
                                        filtered
                                            .length,
                                    itemBuilder:
                                        (context,
                                            index) {
                                      final doc =
                                          filtered[
                                              index];

                                      return _buildAdminRow(
                                        registrationId:
                                            doc.id,
                                        registration:
                                            doc.data(),
                                        grade:
                                            grades[
                                                doc.id],
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ADMIN TABLE HEADER
  // =========================================================

  Widget _buildAdminHeader() {
    const style = TextStyle(
      fontWeight:
          FontWeight.w600,
      color: Color(0xff374151),
    );

    return Container(
      height: 56,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      decoration:
          const BoxDecoration(
        color: Color(0xfff8fafc),
        borderRadius:
            BorderRadius.only(
          topLeft:
              Radius.circular(12),
          topRight:
              Radius.circular(12),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 14,
            child: Text(
              'MSSV',
              style: style,
            ),
          ),
          Expanded(
            flex: 22,
            child: Text(
              'Sinh viên',
              style: style,
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              'Mã môn',
              style: style,
            ),
          ),
          Expanded(
            flex: 22,
            child: Text(
              'Môn học',
              style: style,
            ),
          ),
          Expanded(
            flex: 10,
            child: Center(
              child: Text(
                'Giữa kỳ',
                style: style,
              ),
            ),
          ),
          Expanded(
            flex: 10,
            child: Center(
              child: Text(
                'Cuối kỳ',
                style: style,
              ),
            ),
          ),
          Expanded(
            flex: 10,
            child: Center(
              child: Text(
                'Tổng kết',
                style: style,
              ),
            ),
          ),
          Expanded(
            flex: 8,
            child: Center(
              child: Text(
                'Loại',
                style: style,
              ),
            ),
          ),
          Expanded(
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
  // ADMIN ROW
  // =========================================================

  Widget _buildAdminRow({
    required String registrationId,
    required Map<String, dynamic>
        registration,
    Map<String, dynamic>? grade,
  }) {
    final studentCode =
        registration['studentCode']
                ?.toString() ??
            '';

    final studentName =
        registration['studentName']
                ?.toString() ??
            '';

    final subjectCode =
        registration['subjectCode']
                ?.toString() ??
            '';

    final subjectName =
        registration['subjectName']
                ?.toString() ??
            '';

    return Container(
      constraints:
          const BoxConstraints(
        minHeight: 68,
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
                Color(0xffe5e7eb),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 14,
            child: Text(
              studentCode,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            flex: 22,
            child: Text(
              studentName,
              overflow:
                  TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            flex: 12,
            child: Text(
              subjectCode,
              overflow:
                  TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            flex: 22,
            child: Text(
              subjectName,
              overflow:
                  TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            flex: 10,
            child: Center(
              child: Text(
                _formatScore(
                  grade?[
                      'midtermScore'],
                ),
              ),
            ),
          ),

          Expanded(
            flex: 10,
            child: Center(
              child: Text(
                _formatScore(
                  grade?[
                      'finalScore'],
                ),
              ),
            ),
          ),

          Expanded(
            flex: 10,
            child: Center(
              child: Text(
                _formatScore(
                  grade?[
                      'averageScore'],
                ),
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  color:
                      grade == null
                          ? Colors.grey
                          : const Color(
                              0xff2563eb,
                            ),
                ),
              ),
            ),
          ),

          Expanded(
            flex: 8,
            child: Center(
              child: grade == null
                  ? const Text('-')
                  : Container(
                      width: 35,
                      height: 30,
                      alignment:
                          Alignment.center,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xffeff6ff,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(7),
                      ),
                      child: Text(
                        grade[
                                    'letterGrade']
                                ?.toString() ??
                            '-',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,
                          color:
                              Color(
                            0xff2563eb,
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          Expanded(
            flex: 12,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,
              children: [
                IconButton(
                  tooltip:
                      grade == null
                          ? 'Nhập điểm'
                          : 'Sửa điểm',
                  onPressed: () {
                    _showGradeDialog(
                      registrationId:
                          registrationId,
                      registration:
                          registration,
                      grade: grade,
                    );
                  },
                  icon: Icon(
                    grade == null
                        ? Icons
                            .add_chart
                        : Icons
                            .edit_outlined,
                  ),
                ),

                if (grade != null)
                  IconButton(
                    tooltip:
                        'Xóa điểm',
                    onPressed: () {
                      _deleteGrade(
                        registrationId:
                            registrationId,
                        studentName:
                            studentName,
                        subjectName:
                            subjectName,
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
  // STUDENT PAGE
  // =========================================================

  Widget _buildStudentPage() {
    return Padding(
      padding:
          const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Kết quả học tập',
            style: TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Xem điểm các môn học của bạn',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 25),

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String,
                        dynamic>>>(
              stream:
                  _gradeService
                      .getMyGrades(),
              builder:
                  (context, snapshot) {
                if (snapshot
                        .connectionState ==
                    ConnectionState
                        .waiting) {
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

                final grades =
                    snapshot.data?.docs ??
                        [];

                if (grades.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          Icons
                              .school_outlined,
                          size: 60,
                          color:
                              Colors.grey,
                        ),
                        SizedBox(
                          height: 12,
                        ),
                        Text(
                          'Chưa có điểm.',
                          style:
                              TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                double total = 0;

                for (final doc
                    in grades) {
                  final value =
                      doc.data()[
                          'averageScore'];

                  if (value is num) {
                    total +=
                        value.toDouble();
                  }
                }

                final average =
                    total /
                    grades.length;

                return Column(
                  children: [
                    // ============================
                    // SUMMARY
                    // ============================

                    Row(
                      children: [
                        _summaryCard(
                          title:
                              'Số môn có điểm',
                          value:
                              '${grades.length}',
                          icon: Icons
                              .menu_book_outlined,
                        ),

                        const SizedBox(
                          width: 18,
                        ),

                        _summaryCard(
                          title:
                              'Điểm trung bình',
                          value: average
                              .toStringAsFixed(
                                2,
                              ),
                          icon: Icons
                              .analytics_outlined,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    Expanded(
                      child:
                          Container(
                        width: double
                            .infinity,
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                          border:
                              Border.all(
                            color:
                                const Color(
                              0xffe5e7eb,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildStudentHeader(),

                            Expanded(
                              child:
                                  ListView
                                      .builder(
                                itemCount:
                                    grades
                                        .length,
                                itemBuilder:
                                    (context,
                                        index) {
                                  return _buildStudentRow(
                                    grades[
                                            index]
                                        .data(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SUMMARY CARD
  // =========================================================

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 110,
        padding:
            const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          border: Border.all(
            color:
                const Color(
              0xffe5e7eb,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xffeff6ff,
                ),
                borderRadius:
                    BorderRadius
                        .circular(10),
              ),
              child: Icon(
                icon,
                color:
                    const Color(
                  0xff2563eb,
                ),
              ),
            ),

            const SizedBox(
              width: 15,
            ),

            Column(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        Colors.grey,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // STUDENT TABLE HEADER
  // =========================================================

  Widget _buildStudentHeader() {
    const style = TextStyle(
      fontWeight:
          FontWeight.w600,
      color: Color(0xff374151),
    );

    return Container(
      height: 56,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      decoration:
          const BoxDecoration(
        color: Color(0xfff8fafc),
        borderRadius:
            BorderRadius.only(
          topLeft:
              Radius.circular(12),
          topRight:
              Radius.circular(12),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 15,
            child: Text(
              'Mã môn',
              style: style,
            ),
          ),
          Expanded(
            flex: 30,
            child: Text(
              'Môn học',
              style: style,
            ),
          ),
          Expanded(
            flex: 12,
            child: Center(
              child: Text(
                'Tín chỉ',
                style: style,
              ),
            ),
          ),
          Expanded(
            flex: 14,
            child: Center(
              child: Text(
                'Giữa kỳ',
                style: style,
              ),
            ),
          ),
          Expanded(
            flex: 14,
            child: Center(
              child: Text(
                'Cuối kỳ',
                style: style,
              ),
            ),
          ),
          Expanded(
            flex: 14,
            child: Center(
              child: Text(
                'Tổng kết',
                style: style,
              ),
            ),
          ),
          Expanded(
            flex: 10,
            child: Center(
              child: Text(
                'Xếp loại',
                style: style,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STUDENT ROW
  // =========================================================

  Widget _buildStudentRow(
    Map<String, dynamic> grade,
  ) {
    return Container(
      constraints:
          const BoxConstraints(
        minHeight: 65,
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
                Color(0xffe5e7eb),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 15,
            child: Text(
              grade['subjectCode']
                      ?.toString() ??
                  '',
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            flex: 30,
            child: Text(
              grade['subjectName']
                      ?.toString() ??
                  '',
              overflow:
                  TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            flex: 12,
            child: Center(
              child: Text(
                '${grade['credits'] ?? 0}',
              ),
            ),
          ),

          Expanded(
            flex: 14,
            child: Center(
              child: Text(
                _formatScore(
                  grade[
                      'midtermScore'],
                ),
              ),
            ),
          ),

          Expanded(
            flex: 14,
            child: Center(
              child: Text(
                _formatScore(
                  grade[
                      'finalScore'],
                ),
              ),
            ),
          ),

          Expanded(
            flex: 14,
            child: Center(
              child: Text(
                _formatScore(
                  grade[
                      'averageScore'],
                ),
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(
                    0xff2563eb,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            flex: 10,
            child: Center(
              child: Container(
                width: 38,
                height: 30,
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xffeff6ff,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(7),
                ),
                child: Text(
                  grade['letterGrade']
                          ?.toString() ??
                      '-',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight
                            .bold,
                    color:
                        Color(
                      0xff2563eb,
                    ),
                  ),
                ),
              ),
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