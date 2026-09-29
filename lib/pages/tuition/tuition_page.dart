import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/tuition_service.dart';

class TuitionPage extends StatefulWidget {
  const TuitionPage({
    super.key,
  });

  @override
  State<TuitionPage> createState() =>
      _TuitionPageState();
}

class _TuitionPageState
    extends State<TuitionPage> {
  final TuitionService _service =
      TuitionService();

  final TextEditingController
      _searchController =
      TextEditingController();

  String _searchText = '';

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
  // FORMAT MONEY
  // =========================================================

  String _money(
    dynamic value,
  ) {
    final number =
        value is num
            ? value.round()
            : int.tryParse(
                  value?.toString() ??
                      '',
                ) ??
                0;

    final text =
        number.toString();

    final formatted =
        text.replaceAllMapped(
      RegExp(
        r'\B(?=(\d{3})+(?!\d))',
      ),
      (_) => '.',
    );

    return '$formatted đ';
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  String _date(
    dynamic value,
  ) {
    if (value is! Timestamp) {
      return '-';
    }

    final date =
        value.toDate();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // =========================================================
  // STATUS
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
  // ADMIN - CẤU HÌNH HỌC KỲ
  // =========================================================

  Future<void> _showRateDialog() async {
    final codeController =
        TextEditingController();

    final nameController =
        TextEditingController();

    final priceController =
        TextEditingController();

    DateTime dueDate =
        DateTime.now().add(
      const Duration(
        days: 30,
      ),
    );

    bool isActive = true;
    bool loading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            Future<void> pickDate() async {
              final result =
                  await showDatePicker(
                context:
                    dialogContext,
                initialDate:
                    dueDate,
                firstDate:
                    DateTime(2020),
                lastDate:
                    DateTime(2100),
              );

              if (result != null) {
                setDialogState(() {
                  dueDate =
                      result;
                });
              }
            }

            Future<void> save() async {
              final code =
                  codeController.text
                      .trim();

              final name =
                  nameController.text
                      .trim();

              final price =
                  double.tryParse(
                priceController.text
                    .replaceAll(
                  RegExp(r'[^\d]'),
                  '',
                ),
              );

              if (code.isEmpty) {
                _showMessage(
                  'Vui lòng nhập mã học kỳ.',
                );
                return;
              }

              if (name.isEmpty) {
                _showMessage(
                  'Vui lòng nhập tên học kỳ.',
                );
                return;
              }

              if (price == null ||
                  price <= 0) {
                _showMessage(
                  'Đơn giá tín chỉ không hợp lệ.',
                );
                return;
              }

              try {
                setDialogState(() {
                  loading = true;
                });

                await _service
                    .saveTuitionRate(
                  semesterCode:
                      code,
                  semesterName:
                      name,
                  pricePerCredit:
                      price,
                  dueDate:
                      dueDate,
                  isActive:
                      isActive,
                );

                if (!mounted) return;

                if (dialogContext
                    .mounted) {
                  Navigator.of(
                    dialogContext,
                  ).pop();
                }

                _showMessage(
                  'Lưu cấu hình học kỳ thành công.',
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
              title: const Text(
                'Cấu hình học phí',
              ),

              content: SizedBox(
                width: 500,
                child:
                    SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      TextField(
                        controller:
                            codeController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Mã học kỳ',
                          hintText:
                              'HK1_2026_2027',
                          prefixIcon:
                              Icon(
                            Icons.code,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextField(
                        controller:
                            nameController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Tên học kỳ',
                          hintText:
                              'HK1 2026-2027',
                          prefixIcon:
                              Icon(
                            Icons
                                .calendar_month_outlined,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextField(
                        controller:
                            priceController,
                        keyboardType:
                            TextInputType
                                .number,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Đơn giá / tín chỉ',
                          hintText:
                              '850000',
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

                      InkWell(
                        borderRadius:
                            BorderRadius
                                .circular(
                          8,
                        ),
                        onTap:
                            loading
                                ? null
                                : pickDate,
                        child:
                            InputDecorator(
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Hạn đóng học phí',
                            prefixIcon:
                                Icon(
                              Icons
                                  .event_outlined,
                            ),
                          ),
                          child: Text(
                            '${dueDate.day.toString().padLeft(2, '0')}/'
                            '${dueDate.month.toString().padLeft(2, '0')}/'
                            '${dueDate.year}',
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      SwitchListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        title:
                            const Text(
                          'Đặt làm học kỳ hiện tại',
                        ),
                        subtitle:
                            const Text(
                          'Sinh viên sẽ đăng ký môn vào học kỳ này',
                        ),
                        value:
                            isActive,
                        onChanged:
                            loading
                                ? null
                                : (value) {
                                    setDialogState(
                                      () {
                                        isActive =
                                            value;
                                      },
                                    );
                                  },
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
                  icon:
                      const Icon(
                    Icons.save_outlined,
                  ),
                  label:
                      const Text(
                    'Lưu',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // Không dispose controller ngay sau showDialog
    // để tránh lỗi Flutter Web đã gặp trước đó.
  }

  // =========================================================
  // ADMIN - TẠO HỌC PHÍ
  // =========================================================

  Future<void> _showGenerateDialog() async {
    try {
      final students =
          await FirebaseFirestore
              .instance
              .collection('students')
              .orderBy(
                'studentCode',
              )
              .get();

      final rates =
          await FirebaseFirestore
              .instance
              .collection(
                'tuition_rates',
              )
              .get();

      if (!mounted) return;

      if (students.docs.isEmpty) {
        _showMessage(
          'Chưa có sinh viên.',
        );
        return;
      }

      if (rates.docs.isEmpty) {
        _showMessage(
          'Chưa cấu hình học kỳ.',
        );
        return;
      }

      String? selectedStudentId;

      String? selectedSemesterCode;

      // Ưu tiên học kỳ active
      for (final doc in rates.docs) {
        if (doc.data()['isActive'] ==
            true) {
          selectedSemesterCode =
              doc.id;
          break;
        }
      }

      selectedSemesterCode ??=
          rates.docs.first.id;

      final paidController =
          TextEditingController(
        text: '0',
      );

      Map<String, dynamic>?
          preview;

      bool loading = false;
      bool calculating = false;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (
              context,
              setDialogState,
            ) {
              Future<void>
                  calculate() async {
                if (selectedStudentId ==
                        null ||
                    selectedSemesterCode ==
                        null) {
                  return;
                }

                try {
                  setDialogState(() {
                    calculating =
                        true;
                  });

                  final result =
                      await _service
                          .calculateTuition(
                    studentId:
                        selectedStudentId!,
                    semesterCode:
                        selectedSemesterCode!,
                  );

                  if (!dialogContext
                      .mounted) {
                    return;
                  }

                  setDialogState(() {
                    preview =
                        result;
                    calculating =
                        false;
                  });
                } catch (e) {
                  if (dialogContext
                      .mounted) {
                    setDialogState(() {
                      calculating =
                          false;
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

              Future<void> save() async {
                if (selectedStudentId ==
                    null) {
                  _showMessage(
                    'Vui lòng chọn sinh viên.',
                  );
                  return;
                }

                if (selectedSemesterCode ==
                    null) {
                  _showMessage(
                    'Vui lòng chọn học kỳ.',
                  );
                  return;
                }

                final student =
                    students.docs
                        .firstWhere(
                  (doc) =>
                      doc.id ==
                      selectedStudentId,
                );

                final studentData =
                    student.data();

                final paidAmount =
                    double.tryParse(
                          paidController
                              .text
                              .replaceAll(
                            RegExp(
                              r'[^\d]',
                            ),
                            '',
                          ),
                        ) ??
                        0;

                try {
                  setDialogState(() {
                    loading = true;
                  });

                  await _service
                      .saveStudentTuition(
                    studentId:
                        student.id,

                    studentCode:
                        studentData[
                                    'studentCode']
                                ?.toString() ??
                            '',

                    studentName:
                        studentData[
                                    'fullName']
                                ?.toString() ??
                            '',

                    semesterCode:
                        selectedSemesterCode!,

                    paidAmount:
                        paidAmount,
                  );

                  if (!mounted) return;

                  if (dialogContext
                      .mounted) {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  }

                  _showMessage(
                    'Tạo học phí thành công.',
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
                title: const Text(
                  'Tạo / cập nhật học phí',
                ),

                content: SizedBox(
                  width: 550,
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
                          isExpanded:
                              true,
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

                              return DropdownMenuItem<
                                  String>(
                                value:
                                    doc.id,
                                child:
                                    Text(
                                  '${data['studentCode'] ?? ''} - '
                                  '${data['fullName'] ?? ''}',
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
                                          preview =
                                              null;
                                        },
                                      );

                                      calculate();
                                    },
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        DropdownButtonFormField<
                            String>(
                          initialValue:
                              selectedSemesterCode,
                          isExpanded:
                              true,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Học kỳ',
                            prefixIcon:
                                Icon(
                              Icons
                                  .calendar_month_outlined,
                            ),
                          ),
                          items:
                              rates.docs
                                  .map(
                            (doc) {
                              final data =
                                  doc.data();

                              final active =
                                  data['isActive'] ==
                                      true;

                              return DropdownMenuItem<
                                  String>(
                                value:
                                    doc.id,
                                child:
                                    Text(
                                  '${data['semesterName'] ?? doc.id}'
                                  '${active ? ' (Hiện tại)' : ''}',
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
                                          selectedSemesterCode =
                                              value;
                                          preview =
                                              null;
                                        },
                                      );

                                      calculate();
                                    },
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        if (calculating)
                          const Padding(
                            padding:
                                EdgeInsets.all(
                              20,
                            ),
                            child:
                                CircularProgressIndicator(),
                          ),

                        if (!calculating &&
                            preview != null)
                          Container(
                            width:
                                double.infinity,
                            padding:
                                const EdgeInsets.all(
                              18,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xfff8fafc,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                              border:
                                  Border.all(
                                color:
                                    const Color(
                                  0xffe5e7eb,
                                ),
                              ),
                            ),
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  'Số môn đăng ký: ${preview!['subjectCount']}',
                                ),

                                const SizedBox(
                                  height:
                                      6,
                                ),

                                Text(
                                  'Tổng tín chỉ: ${preview!['totalCredits']}',
                                ),

                                const SizedBox(
                                  height:
                                      6,
                                ),

                                Text(
                                  'Đơn giá: ${_money(preview!['pricePerCredit'])} / tín chỉ',
                                ),

                                const Divider(
                                  height:
                                      24,
                                ),

                                Text(
                                  'Tổng học phí: ${_money(preview!['totalAmount'])}',
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        18,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color:
                                        Color(
                                      0xff2563eb,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(
                          height: 18,
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
                                'Số tiền đã đóng',
                            hintText:
                                '0',
                            prefixIcon:
                                Icon(
                              Icons
                                  .paid_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        const Align(
                          alignment:
                              Alignment.centerLeft,
                          child: Text(
                            'Có thể để 0. Sinh viên sẽ thanh toán giả lập ở tài khoản của mình.',
                            style:
                                TextStyle(
                              color:
                                  Colors.grey,
                              fontSize:
                                  12,
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
                    icon:
                        const Icon(
                      Icons
                          .calculate_outlined,
                    ),
                    label:
                        const Text(
                      'Lưu học phí',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      _showMessage(
        'Không thể tải dữ liệu: $e',
      );
    }
  }

  // =========================================================
  // SINH VIÊN - THANH TOÁN GIẢ LẬP
  // =========================================================

  Future<void> _mockPayment({
    required String tuitionId,
    required dynamic remainingAmount,
  }) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Row(
            children: [
              Icon(
                Icons
                    .payment_outlined,
                color:
                    Color(
                  0xff2563eb,
                ),
              ),

              SizedBox(
                width: 10,
              ),

              Text(
                'Thanh toán học phí',
              ),
            ],
          ),

          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Đây là chức năng thanh toán giả lập dùng để demo hệ thống.',
              ),

              const SizedBox(
                height: 20,
              ),

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xfff8fafc,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Số tiền cần thanh toán',
                      style:
                          TextStyle(
                        color:
                            Colors.grey,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      _money(
                        remainingAmount,
                      ),
                      style:
                          const TextStyle(
                        fontSize:
                            23,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(
                          0xff2563eb,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              const Row(
                children: [
                  Icon(
                    Icons
                        .info_outline,
                    size: 18,
                    color:
                        Colors.orange,
                  ),

                  SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: Text(
                      'Không có tiền thật được chuyển. Sau khi xác nhận, hệ thống sẽ đánh dấu học phí là đã thanh toán.',
                      style:
                          TextStyle(
                        fontSize:
                            12,
                        color:
                            Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text(
                'Hủy',
              ),
            ),

            FilledButton.icon(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              icon:
                  const Icon(
                Icons.check,
              ),
              label:
                  const Text(
                'Xác nhận thanh toán',
              ),
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
          .mockPayTuition(
        tuitionId:
            tuitionId,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            icon:
                const Icon(
              Icons
                  .check_circle,
              size: 65,
              color:
                  Colors.green,
            ),

            title:
                const Text(
              'Thanh toán thành công',
              textAlign:
                  TextAlign.center,
            ),

            content:
                const Text(
              'Học phí đã được cập nhật thành trạng thái "Đã đóng".',
              textAlign:
                  TextAlign.center,
            ),

            actions: [
              Center(
                child:
                    FilledButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child:
                      const Text(
                    'Hoàn tất',
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      _showMessage(
        e.toString()
            .replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // =========================================================
  // ROLE
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final currentUser =
        FirebaseAuth
            .instance.currentUser;

    if (currentUser == null) {
      return const Center(
        child:
            Text(
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
          .doc(currentUser.uid)
          .snapshots(),
      builder: (
        context,
        snapshot,
      ) {
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
            child:
                Text(
              'Không tìm thấy tài khoản.',
            ),
          );
        }

        final userData =
            snapshot.data!
                .data()!;

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
  // ADMIN PAGE
  // =========================================================

  Widget _buildAdminPage() {
    return Padding(
      padding:
          const EdgeInsets.all(
        30,
      ),
      child:
          Column(
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
                    style:
                        TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),

                  SizedBox(
                    height: 5,
                  ),

                  Text(
                    'Học phí được tính tự động theo số tín chỉ đã đăng ký',
                    style:
                        TextStyle(
                      color:
                          Colors.grey,
                    ),
                  ),
                ],
              ),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed:
                        _showRateDialog,
                    icon:
                        const Icon(
                      Icons
                          .settings_outlined,
                    ),
                    label:
                        const Text(
                      'Cấu hình học kỳ',
                    ),
                  ),

                  FilledButton.icon(
                    onPressed:
                        _showGenerateDialog,
                    icon:
                        const Icon(
                      Icons
                          .calculate_outlined,
                    ),
                    label:
                        const Text(
                      'Tạo học phí',
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(
            height: 25,
          ),

          SizedBox(
            width: 430,
            child:
                TextField(
              controller:
                  _searchController,
              onChanged:
                  (value) {
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
                    Icon(
                  Icons.search,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Expanded(
            child:
                _buildTuitionTable(
              admin: true,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STUDENT PAGE
  // =========================================================

  Widget _buildStudentPage(
    Map<String, dynamic>
        userData,
  ) {
    final studentId =
        userData['studentId']
                ?.toString() ??
            '';

    if (studentId.isEmpty) {
      return const Center(
        child:
            Text(
          'Tài khoản chưa liên kết với hồ sơ sinh viên.',
        ),
      );
    }

    return Padding(
      padding:
          const EdgeInsets.all(
        30,
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Học phí',
            style:
                TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          const Text(
            'Theo dõi và thanh toán học phí',
            style:
                TextStyle(
              color:
                  Colors.grey,
            ),
          ),

          const SizedBox(
            height: 25,
          ),

          Expanded(
            child:
                _buildTuitionTable(
              admin: false,
              studentId:
                  studentId,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TABLE
  // =========================================================

  Widget _buildTuitionTable({
    required bool admin,
    String? studentId,
  }) {
    final Stream<
            QuerySnapshot<
                Map<String,
                    dynamic>>>
        stream;

    if (admin) {
      stream =
          _service
              .getAllTuition();
    } else {
      stream =
          _service
              .getStudentTuition(
        studentId!,
      );
    }

    return Container(
      width:
          double.infinity,
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
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
      child:
          StreamBuilder<
              QuerySnapshot<
                  Map<String,
                      dynamic>>>(
        stream:
            stream,
        builder: (
          context,
          snapshot,
        ) {
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
              snapshot.data?.docs ??
                  [];

          docs = docs.where(
            (doc) {
              final data =
                  doc.data();

              final text =
                  '${data['studentCode'] ?? ''} '
                          '${data['studentName'] ?? ''} '
                          '${data['semesterName'] ?? ''}'
                      .toLowerCase();

              return text.contains(
                _searchText,
              );
            },
          ).toList();

          if (docs.isEmpty) {
            return const Center(
              child:
                  Text(
                'Chưa có dữ liệu học phí.',
                style:
                    TextStyle(
                  color:
                      Colors.grey,
                ),
              ),
            );
          }

          return Column(
            children: [
              // =================================================
              // HEADER
              // =================================================

              Container(
                height: 56,
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 18,
                ),
                decoration:
                    const BoxDecoration(
                  color:
                      Color(
                    0xfff8fafc,
                  ),
                  borderRadius:
                      BorderRadius.only(
                    topLeft:
                        Radius.circular(
                      12,
                    ),
                    topRight:
                        Radius.circular(
                      12,
                    ),
                  ),
                ),
                child:
                    Row(
                  children: [
                    if (admin)
                      const Expanded(
                        flex:
                            13,
                        child:
                            Text(
                          'MSSV',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),

                    if (admin)
                      const Expanded(
                        flex:
                            18,
                        child:
                            Text(
                          'Sinh viên',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),

                    const Expanded(
                      flex: 16,
                      child: Text(
                        'Học kỳ',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),

                    const Expanded(
                      flex: 9,
                      child: Center(
                        child: Text(
                          'TC',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const Expanded(
                      flex: 15,
                      child: Text(
                        'Đơn giá/TC',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),

                    const Expanded(
                      flex: 17,
                      child: Text(
                        'Tổng',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),

                    const Expanded(
                      flex: 16,
                      child: Text(
                        'Đã đóng',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),

                    const Expanded(
                      flex: 16,
                      child: Text(
                        'Còn lại',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),

                    const Expanded(
                      flex: 15,
                      child: Text(
                        'Hạn đóng',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),

                    const Expanded(
                      flex: 17,
                      child: Text(
                        'Trạng thái',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),

                    if (!admin)
                      const Expanded(
                        flex: 17,
                        child: Center(
                          child: Text(
                            'Thanh toán',
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // =================================================
              // ROWS
              // =================================================

              Expanded(
                child:
                    ListView.builder(
                  itemCount:
                      docs.length,
                  itemBuilder:
                      (
                    context,
                    index,
                  ) {
                    final doc =
                        docs[index];

                    final data =
                        doc.data();

                    final status =
                        data['status']
                                ?.toString() ??
                            'unpaid';

                    final remaining =
                        data[
                                'remainingAmount'] ??
                            0;

                    final isPaid =
                        status ==
                            'paid';

                    return Container(
                      constraints:
                          const BoxConstraints(
                        minHeight:
                            72,
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal:
                            18,
                        vertical:
                            8,
                      ),
                      decoration:
                          const BoxDecoration(
                        border:
                            Border(
                          top:
                              BorderSide(
                            color:
                                Color(
                              0xffe5e7eb,
                            ),
                          ),
                        ),
                      ),
                      child:
                          Row(
                        children: [
                          if (admin)
                            Expanded(
                              flex:
                                  13,
                              child:
                                  Text(
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
                              flex:
                                  18,
                              child:
                                  Text(
                                data['studentName']
                                        ?.toString() ??
                                    '',
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            ),

                          Expanded(
                            flex:
                                16,
                            child:
                                Text(
                              data['semesterName']
                                      ?.toString() ??
                                  '',
                            ),
                          ),

                          Expanded(
                            flex:
                                9,
                            child:
                                Center(
                              child:
                                  Text(
                                '${data['totalCredits'] ?? 0}',
                              ),
                            ),
                          ),

                          Expanded(
                            flex:
                                15,
                            child:
                                Text(
                              _money(
                                data['pricePerCredit'],
                              ),
                            ),
                          ),

                          Expanded(
                            flex:
                                17,
                            child:
                                Text(
                              _money(
                                data['totalAmount'],
                              ),
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ),

                          Expanded(
                            flex:
                                16,
                            child:
                                Text(
                              _money(
                                data['paidAmount'],
                              ),
                            ),
                          ),

                          Expanded(
                            flex:
                                16,
                            child:
                                Text(
                              _money(
                                remaining,
                              ),
                            ),
                          ),

                          Expanded(
                            flex:
                                15,
                            child:
                                Text(
                              _date(
                                data['dueDate'],
                              ),
                            ),
                          ),

                          Expanded(
                            flex:
                                17,
                            child:
                                Align(
                              alignment:
                                  Alignment.centerLeft,
                              child:
                                  Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal:
                                      10,
                                  vertical:
                                      6,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color:
                                      _statusColor(
                                    status,
                                  ).withOpacity(
                                    0.10,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                    20,
                                  ),
                                ),
                                child:
                                    Text(
                                  _statusText(
                                    status,
                                  ),
                                  style:
                                      TextStyle(
                                    color:
                                        _statusColor(
                                      status,
                                    ),
                                    fontSize:
                                        12,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // =====================================
                          // PAYMENT BUTTON FOR STUDENT
                          // =====================================

                          if (!admin)
                            Expanded(
                              flex:
                                  17,
                              child:
                                  Center(
                                child:
                                    isPaid
                                        ? const Row(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                                size: 18,
                                              ),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              Text(
                                                'Hoàn tất',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          )
                                        : FilledButton.icon(
                                            onPressed: () {
                                              _mockPayment(
                                                tuitionId: doc.id,
                                                remainingAmount: remaining,
                                              );
                                            },
                                            icon:
                                                const Icon(
                                              Icons.payment,
                                              size: 17,
                                            ),
                                            label:
                                                const Text(
                                              'Thanh toán',
                                            ),
                                          ),
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
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _searchController
        .dispose();

    super.dispose();
  }
}