import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/tuition_service.dart';

class TuitionPage extends StatefulWidget {
  const TuitionPage({super.key});

  @override
  State<TuitionPage> createState() =>
      _TuitionPageState();
}

class _TuitionPageState extends State<TuitionPage> {
  final TuitionService _service =
      TuitionService();

  final TextEditingController _searchController =
      TextEditingController();

  String _searchText = '';

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // FORMAT MONEY
  // =========================================================

  String _formatMoney(dynamic value) {
    if (value == null) {
      return '0 đ';
    }

    final num number =
        value is num
            ? value
            : num.tryParse(
                  value.toString(),
                ) ??
                0;

    final text =
        number.round().toString();

    final formatted = text.replaceAllMapped(
      RegExp(
        r'\B(?=(\d{3})+(?!\d))',
      ),
      (match) => '.',
    );

    return '$formatted đ';
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return '-';
    }

    final date = value.toDate();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // =========================================================
  // PARSE MONEY
  // =========================================================

  double? _parseMoney(
    String value,
  ) {
    final cleaned =
        value.replaceAll(
      RegExp(r'[^\d]'),
      '',
    );

    if (cleaned.isEmpty) {
      return null;
    }

    return double.tryParse(
      cleaned,
    );
  }

  // =========================================================
  // TRẠNG THÁI
  // =========================================================

  String _statusText(
    String status,
  ) {
    switch (status) {
      case 'paid':
        return 'Đã đóng';

      case 'partial':
        return 'Đóng một phần';

      default:
        return 'Chưa đóng';
    }
  }

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'paid':
        return Colors.green;

      case 'partial':
        return Colors.orange;

      default:
        return Colors.red;
    }
  }

  // =========================================================
  // THÊM / SỬA
  // =========================================================

  Future<void> _showTuitionDialog({
    String? id,
    Map<String, dynamic>? oldData,
  }) async {
    try {
      final students =
          await FirebaseFirestore.instance
              .collection('students')
              .orderBy('studentCode')
              .get();

      if (!mounted) return;

      if (students.docs.isEmpty) {
        _showMessage(
          'Chưa có sinh viên.',
        );
        return;
      }

      String? selectedStudentId =
          oldData?['studentId']
              ?.toString();

      if (selectedStudentId != null &&
          !students.docs.any(
            (doc) =>
                doc.id ==
                selectedStudentId,
          )) {
        selectedStudentId = null;
      }

      final semesterController =
          TextEditingController(
        text:
            oldData?['semester']
                    ?.toString() ??
                '',
      );

      final totalController =
          TextEditingController(
        text: oldData == null
            ? ''
            : oldData['totalAmount']
                ?.toStringAsFixed(0),
      );

      final paidController =
          TextEditingController(
        text: oldData == null
            ? '0'
            : oldData['paidAmount']
                ?.toStringAsFixed(0),
      );

      DateTime selectedDueDate =
          oldData?['dueDate']
                  is Timestamp
              ? (oldData!['dueDate']
                      as Timestamp)
                  .toDate()
              : DateTime.now().add(
                  const Duration(
                    days: 30,
                  ),
                );

      bool loading = false;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder:
                (context,
                    setDialogState) {
              Future<void>
                  pickDate() async {
                final picked =
                    await showDatePicker(
                  context:
                      dialogContext,
                  initialDate:
                      selectedDueDate,
                  firstDate:
                      DateTime(2020),
                  lastDate:
                      DateTime(2100),
                );

                if (picked != null) {
                  setDialogState(() {
                    selectedDueDate =
                        picked;
                  });
                }
              }

              Future<void> save() async {
                if (selectedStudentId ==
                    null) {
                  _showMessage(
                    'Vui lòng chọn sinh viên.',
                  );
                  return;
                }

                final semester =
                    semesterController.text
                        .trim();

                if (semester.isEmpty) {
                  _showMessage(
                    'Vui lòng nhập học kỳ.',
                  );
                  return;
                }

                final totalAmount =
                    _parseMoney(
                  totalController.text,
                );

                final paidAmount =
                    _parseMoney(
                          paidController.text,
                        ) ??
                        0;

                if (totalAmount == null ||
                    totalAmount <= 0) {
                  _showMessage(
                    'Tổng học phí không hợp lệ.',
                  );
                  return;
                }

                final studentDoc =
                    students.docs.firstWhere(
                  (doc) =>
                      doc.id ==
                      selectedStudentId,
                );

                final studentData =
                    studentDoc.data();

                final studentCode =
                    studentData[
                                'studentCode']
                            ?.toString() ??
                        '';

                final studentName =
                    studentData[
                                'fullName']
                            ?.toString() ??
                        '';

                try {
                  setDialogState(() {
                    loading = true;
                  });

                  if (id == null) {
                    await _service
                        .addTuition(
                      studentId:
                          studentDoc.id,
                      studentCode:
                          studentCode,
                      studentName:
                          studentName,
                      semester:
                          semester,
                      totalAmount:
                          totalAmount,
                      paidAmount:
                          paidAmount,
                      dueDate:
                          selectedDueDate,
                    );
                  } else {
                    await _service
                        .updateTuition(
                      id: id,
                      studentId:
                          studentDoc.id,
                      studentCode:
                          studentCode,
                      studentName:
                          studentName,
                      semester:
                          semester,
                      totalAmount:
                          totalAmount,
                      paidAmount:
                          paidAmount,
                      dueDate:
                          selectedDueDate,
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
                        ? 'Thêm học phí thành công.'
                        : 'Cập nhật học phí thành công.',
                  );
                } catch (e) {
                  if (dialogContext
                      .mounted) {
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

              return AlertDialog(
                title: Text(
                  id == null
                      ? 'Thêm học phí'
                      : 'Cập nhật học phí',
                ),

                content: SizedBox(
                  width: 530,
                  child:
                      SingleChildScrollView(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<
                            String>(
                          initialValue:
                              selectedStudentId,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Sinh viên',
                            prefixIcon:
                                Icon(
                              Icons
                                  .person_outline,
                            ),
                          ),
                          items:
                              students.docs
                                  .map(
                            (doc) {
                              final data =
                                  doc.data();

                              final code =
                                  data['studentCode'] ??
                                      '';

                              final name =
                                  data['fullName'] ??
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
                                          selectedStudentId =
                                              value;
                                        },
                                      );
                                    },
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

                        const SizedBox(
                          height: 16,
                        ),

                        TextField(
                          controller:
                              totalController,
                          enabled:
                              !loading,
                          keyboardType:
                              TextInputType
                                  .number,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Tổng học phí',
                            hintText:
                                'VD: 15000000',
                            prefixIcon:
                                Icon(
                              Icons
                                  .payments_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        TextField(
                          controller:
                              paidController,
                          enabled:
                              !loading,
                          keyboardType:
                              TextInputType
                                  .number,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Đã đóng',
                            hintText:
                                'VD: 5000000',
                            prefixIcon:
                                Icon(
                              Icons
                                  .paid_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        InkWell(
                          onTap: loading
                              ? null
                              : pickDate,
                          borderRadius:
                              BorderRadius
                                  .circular(10),
                          child:
                              InputDecorator(
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Hạn đóng',
                              prefixIcon:
                                  Icon(
                                Icons
                                    .event_outlined,
                              ),
                            ),
                            child: Text(
                              '${selectedDueDate.day.toString().padLeft(2, '0')}/'
                              '${selectedDueDate.month.toString().padLeft(2, '0')}/'
                              '${selectedDueDate.year}',
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
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Icon(
                            Icons
                                .save_outlined,
                          ),
                    label: const Text(
                      'Lưu',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      // Không dispose controller ngay sau dialog
      // vì Flutter Web trước đó của bạn từng lỗi context.
    } catch (e) {
      _showMessage(
        'Không thể tải danh sách sinh viên: $e',
      );
    }
  }

  // =========================================================
  // XÓA
  // =========================================================

  Future<void> _deleteTuition({
    required String id,
    required String studentName,
    required String semester,
  }) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Xóa học phí'),
          content: Text(
            'Xóa học phí "$semester" của "$studentName"?',
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
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child:
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
      await _service
          .deleteTuition(id);

      _showMessage(
        'Xóa học phí thành công.',
      );
    } catch (e) {
      _showMessage(
        'Không thể xóa học phí: $e',
      );
    }
  }

  // =========================================================
  // CHECK ROLE
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
            userData['role']?.toString() ??
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
  // ADMIN PAGE
  // =========================================================

  Widget _buildAdminPage() {
    return Padding(
      padding: const EdgeInsets.all(30),
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
                    'Quản lý học phí',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Quản lý học phí và trạng thái thanh toán của sinh viên',
                    style: TextStyle(
                      color:
                          Colors.grey,
                    ),
                  ),
                ],
              ),

              FilledButton.icon(
                onPressed: () {
                  _showTuitionDialog();
                },
                icon: const Icon(
                  Icons.add,
                ),
                label: const Text(
                  'Thêm học phí',
                ),
              ),
            ],
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
                    'Tìm MSSV, sinh viên, học kỳ...',
                prefixIcon:
                    Icon(Icons.search),
              ),
            ),
          ),

          const SizedBox(height: 22),

          Expanded(
            child:
                _buildAdminTable(),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ADMIN TABLE
  // =========================================================

  Widget _buildAdminTable() {
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
            _service.getAllTuition(),
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

          var docs =
              [...snapshot.data?.docs ??
                  []];

          docs.sort(
            (a, b) {
              final aTime =
                  a.data()['createdAt'];

              final bTime =
                  b.data()['createdAt'];

              if (aTime is Timestamp &&
                  bTime is Timestamp) {
                return bTime.compareTo(
                  aTime,
                );
              }

              return 0;
            },
          );

          docs = docs.where(
            (doc) {
              final data =
                  doc.data();

              final text =
                  '${data['studentCode'] ?? ''} '
                          '${data['studentName'] ?? ''} '
                          '${data['semester'] ?? ''}'
                      .toLowerCase();

              return text.contains(
                _searchText,
              );
            },
          ).toList();

          return Column(
            children: [
              _buildHeader(
                admin: true,
              ),

              Expanded(
                child: docs.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có dữ liệu học phí.',
                          style:
                              TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount:
                            docs.length,
                        itemBuilder:
                            (context,
                                index) {
                          return _buildRow(
                            docs[index],
                            admin: true,
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
  // STUDENT PAGE
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

    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Học phí',
            style: TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Theo dõi học phí và trạng thái thanh toán',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 25),

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream: _service
                  .getStudentTuition(
                studentId,
              ),
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

                final docs =
                    snapshot.data?.docs ??
                        [];

                double total = 0;
                double paid = 0;
                double remaining = 0;

                for (final doc in docs) {
                  final data =
                      doc.data();

                  total +=
                      (data['totalAmount']
                                  as num? ??
                              0)
                          .toDouble();

                  paid +=
                      (data['paidAmount']
                                  as num? ??
                              0)
                          .toDouble();

                  remaining +=
                      (data['remainingAmount']
                                  as num? ??
                              0)
                          .toDouble();
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        _summaryCard(
                          title:
                              'Tổng học phí',
                          value:
                              _formatMoney(
                            total,
                          ),
                          icon: Icons
                              .account_balance_wallet_outlined,
                        ),

                        const SizedBox(
                          width: 18,
                        ),

                        _summaryCard(
                          title:
                              'Đã đóng',
                          value:
                              _formatMoney(
                            paid,
                          ),
                          icon: Icons
                              .check_circle_outline,
                        ),

                        const SizedBox(
                          width: 18,
                        ),

                        _summaryCard(
                          title:
                              'Còn lại',
                          value:
                              _formatMoney(
                            remaining,
                          ),
                          icon: Icons
                              .payments_outlined,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    Expanded(
                      child: Container(
                        width:
                            double.infinity,
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(12),
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
                            _buildHeader(
                              admin:
                                  false,
                            ),

                            Expanded(
                              child:
                                  docs.isEmpty
                                      ? const Center(
                                          child:
                                              Text(
                                            'Chưa có thông tin học phí.',
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.grey,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount:
                                              docs.length,
                                          itemBuilder:
                                              (context,
                                                  index) {
                                            return _buildRow(
                                              docs[index],
                                              admin:
                                                  false,
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
  // SUMMARY
  // =========================================================

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 105,
        padding:
            const EdgeInsets.all(18),
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
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color:
                  const Color(
                0xff2563eb,
              ),
            ),

            const SizedBox(
              width: 15,
            ),

            Expanded(
              child: Column(
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
                      fontSize: 20,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader({
    required bool admin,
  }) {
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
          if (admin)
            const Expanded(
              flex: 14,
              child: Text(
                'MSSV',
                style: style,
              ),
            ),

          if (admin)
            const Expanded(
              flex: 21,
              child: Text(
                'Sinh viên',
                style: style,
              ),
            ),

          const Expanded(
            flex: 17,
            child: Text(
              'Học kỳ',
              style: style,
            ),
          ),

          const Expanded(
            flex: 17,
            child: Text(
              'Tổng học phí',
              style: style,
            ),
          ),

          const Expanded(
            flex: 15,
            child: Text(
              'Đã đóng',
              style: style,
            ),
          ),

          const Expanded(
            flex: 15,
            child: Text(
              'Còn lại',
              style: style,
            ),
          ),

          const Expanded(
            flex: 16,
            child: Text(
              'Hạn đóng',
              style: style,
            ),
          ),

          const Expanded(
            flex: 17,
            child: Text(
              'Trạng thái',
              style: style,
            ),
          ),

          if (admin)
            const Expanded(
              flex: 11,
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
    required bool admin,
  }) {
    final data = doc.data();

    final studentName =
        data['studentName']
                ?.toString() ??
            '';

    final semester =
        data['semester']
                ?.toString() ??
            '';

    final status =
        data['status']?.toString() ??
            'unpaid';

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
          if (admin)
            Expanded(
              flex: 14,
              child: Text(
                data['studentCode']
                        ?.toString() ??
                    '',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

          if (admin)
            Expanded(
              flex: 21,
              child: Text(
                studentName,
                overflow:
                    TextOverflow
                        .ellipsis,
              ),
            ),

          Expanded(
            flex: 17,
            child: Text(
              semester,
              overflow:
                  TextOverflow
                      .ellipsis,
            ),
          ),

          Expanded(
            flex: 17,
            child: Text(
              _formatMoney(
                data['totalAmount'],
              ),
            ),
          ),

          Expanded(
            flex: 15,
            child: Text(
              _formatMoney(
                data['paidAmount'],
              ),
            ),
          ),

          Expanded(
            flex: 15,
            child: Text(
              _formatMoney(
                data[
                    'remainingAmount'],
              ),
            ),
          ),

          Expanded(
            flex: 16,
            child: Text(
              _formatDate(
                data['dueDate'],
              ),
            ),
          ),

          Expanded(
            flex: 17,
            child: Align(
              alignment:
                  Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      _statusColor(
                            status,
                          )
                          .withValues(
                            alpha:
                                0.10,
                          ),
                  borderRadius:
                      BorderRadius
                          .circular(20),
                ),
                child: Text(
                  _statusText(
                    status,
                  ),
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    color:
                        _statusColor(
                      status,
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (admin)
            Expanded(
              flex: 11,
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  IconButton(
                    tooltip:
                        'Sửa học phí',
                    onPressed: () {
                      _showTuitionDialog(
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
                        'Xóa học phí',
                    onPressed: () {
                      _deleteTuition(
                        id:
                            doc.id,
                        studentName:
                            studentName,
                        semester:
                            semester,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}