import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/account_service.dart';

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key});

  @override
  State<AccountManagementPage> createState() =>
      _AccountManagementPageState();
}

class _AccountManagementPageState
    extends State<AccountManagementPage> {
  final AccountService _accountService = AccountService();

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
  // TẠO TÀI KHOẢN SINH VIÊN
  // =========================================================

  Future<void> _showCreateAccountDialog() async {
    try {
      final studentSnapshot =
          await FirebaseFirestore.instance
              .collection('students')
              .orderBy('studentCode')
              .get();

      if (!mounted) return;

      if (studentSnapshot.docs.isEmpty) {
        _showMessage(
          'Chưa có sinh viên. Hãy thêm sinh viên trước.',
        );
        return;
      }

      final emailController = TextEditingController();
      final passwordController = TextEditingController();

      String? selectedStudentId;
      Map<String, dynamic>? selectedStudent;

      bool isLoading = false;
      bool obscurePassword = true;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> createAccount() async {
                if (selectedStudentId == null ||
                    selectedStudent == null) {
                  _showMessage(
                    'Vui lòng chọn sinh viên.',
                  );
                  return;
                }

                final email =
                    emailController.text.trim();

                final password =
                    passwordController.text.trim();

                final studentCode =
                    selectedStudent!['studentCode']
                            ?.toString()
                            .trim() ??
                        '';

                final fullName =
                    selectedStudent!['fullName']
                            ?.toString()
                            .trim() ??
                        '';

                if (email.isEmpty) {
                  _showMessage(
                    'Vui lòng nhập email.',
                  );
                  return;
                }

                if (!email.contains('@')) {
                  _showMessage(
                    'Email không hợp lệ.',
                  );
                  return;
                }

                if (password.length < 6) {
                  _showMessage(
                    'Mật khẩu phải có ít nhất 6 ký tự.',
                  );
                  return;
                }

                try {
                  setDialogState(() {
                    isLoading = true;
                  });

                  // Kiểm tra sinh viên đã được cấp tài khoản chưa
                  final existingAccount =
                      await FirebaseFirestore.instance
                          .collection('users')
                          .where(
                            'studentCode',
                            isEqualTo: studentCode,
                          )
                          .limit(1)
                          .get();

                  if (existingAccount.docs.isNotEmpty) {
                    if (dialogContext.mounted) {
                      setDialogState(() {
                        isLoading = false;
                      });
                    }

                    _showMessage(
                      'Sinh viên này đã được cấp tài khoản.',
                    );

                    return;
                  }

                  await _accountService
                      .createStudentAccount(
                    email: email,
                    password: password,
                    fullName: fullName,
                    studentCode: studentCode,
                    studentId: selectedStudentId!,
                  );

                  if (!mounted) return;

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }

                  _showMessage(
                    'Cấp tài khoản thành công.',
                  );
                } on FirebaseAuthException catch (e) {
                  String message =
                      'Không thể tạo tài khoản.';

                  switch (e.code) {
                    case 'email-already-in-use':
                      message =
                          'Email này đã được sử dụng.';
                      break;

                    case 'invalid-email':
                      message =
                          'Email không hợp lệ.';
                      break;

                    case 'weak-password':
                      message =
                          'Mật khẩu quá yếu.';
                      break;

                    case 'operation-not-allowed':
                      message =
                          'Firebase chưa bật Email/Password.';
                      break;
                  }

                  if (dialogContext.mounted) {
                    setDialogState(() {
                      isLoading = false;
                    });
                  }

                  _showMessage(message);
                } catch (e) {
                  if (dialogContext.mounted) {
                    setDialogState(() {
                      isLoading = false;
                    });
                  }

                  _showMessage(
                    'Có lỗi xảy ra: $e',
                  );
                }
              }

              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(
                      Icons.person_add_alt_1,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Cấp tài khoản sinh viên',
                    ),
                  ],
                ),

                content: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue:
                              selectedStudentId,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Chọn sinh viên',
                            prefixIcon: Icon(
                              Icons.school_outlined,
                            ),
                          ),
                          items:
                              studentSnapshot.docs.map(
                            (doc) {
                              final data =
                                  doc.data();

                              final code =
                                  data['studentCode']
                                          ?.toString() ??
                                      '';

                              final name =
                                  data['fullName']
                                          ?.toString() ??
                                      '';

                              return DropdownMenuItem<
                                  String>(
                                value: doc.id,
                                child: Text(
                                  '$code - $name',
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                ),
                              );
                            },
                          ).toList(),
                          onChanged: isLoading
                              ? null
                              : (value) {
                                  if (value ==
                                      null) {
                                    return;
                                  }

                                  final document =
                                      studentSnapshot
                                          .docs
                                          .firstWhere(
                                    (doc) =>
                                        doc.id ==
                                        value,
                                  );

                                  final data =
                                      document.data();

                                  final code =
                                      data['studentCode']
                                              ?.toString()
                                              .trim() ??
                                          '';

                                  setDialogState(
                                    () {
                                      selectedStudentId =
                                          document.id;

                                      selectedStudent =
                                          data;

                                      if (code
                                          .isNotEmpty) {
                                        emailController
                                                .text =
                                            '$code@student.com';
                                      }
                                    },
                                  );
                                },
                        ),

                        if (selectedStudent != null) ...[
                          const SizedBox(
                            height: 18,
                          ),

                          Container(
                            width:
                                double.infinity,
                            padding:
                                const EdgeInsets
                                    .all(16),
                            decoration:
                                BoxDecoration(
                              color: const Color(
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
                                  selectedStudent![
                                              'fullName']
                                          ?.toString() ??
                                      '',
                                  style:
                                      const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Text(
                                  'MSSV: ${selectedStudent!['studentCode'] ?? ''}',
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  'Lớp: ${selectedStudent!['className'] ?? '-'}',
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  'Chuyên ngành: ${selectedStudent!['major'] ?? '-'}',
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(
                          height: 18,
                        ),

                        TextField(
                          controller:
                              emailController,
                          enabled: !isLoading,
                          keyboardType:
                              TextInputType
                                  .emailAddress,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Email đăng nhập',
                            prefixIcon: Icon(
                              Icons
                                  .email_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        TextField(
                          controller:
                              passwordController,
                          enabled: !isLoading,
                          obscureText:
                              obscurePassword,
                          onSubmitted: (_) {
                            if (!isLoading) {
                              createAccount();
                            }
                          },
                          decoration:
                              InputDecoration(
                            labelText:
                                'Mật khẩu tạm thời',
                            helperText:
                                'Tối thiểu 6 ký tự',
                            prefixIcon:
                                const Icon(
                              Icons.lock_outline,
                            ),
                            suffixIcon:
                                IconButton(
                              onPressed:
                                  isLoading
                                      ? null
                                      : () {
                                          setDialogState(
                                            () {
                                              obscurePassword =
                                                  !obscurePassword;
                                            },
                                          );
                                        },
                              icon: Icon(
                                obscurePassword
                                    ? Icons
                                        .visibility
                                    : Icons
                                        .visibility_off,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                actions: [
                  TextButton(
                    onPressed: isLoading
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
                    onPressed: isLoading
                        ? null
                        : createAccount,
                    icon: isLoading
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
                                .person_add_alt_1,
                          ),
                    label: Text(
                      isLoading
                          ? 'Đang tạo...'
                          : 'Cấp tài khoản',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      emailController.dispose();
      passwordController.dispose();
    } catch (e) {
      _showMessage(
        'Không thể tải danh sách sinh viên: $e',
      );
    }
  }

  // =========================================================
  // THAY ĐỔI ROLE
  // =========================================================

  Future<void> _showChangeRoleDialog({
    required String uid,
    required String currentRole,
    required String fullName,
  }) async {
    String selectedRole = currentRole;
    bool isLoading = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Thay đổi quyền',
              ),

              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      fullName,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    DropdownButtonFormField<
                        String>(
                      initialValue:
                          selectedRole,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Quyền tài khoản',
                        prefixIcon: Icon(
                          Icons
                              .admin_panel_settings_outlined,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'student',
                          child:
                              Text('Sinh viên'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text(
                            'Quản trị viên',
                          ),
                        ),
                      ],
                      onChanged: isLoading
                          ? null
                          : (value) {
                              if (value ==
                                  null) {
                                return;
                              }

                              setDialogState(
                                () {
                                  selectedRole =
                                      value;
                                },
                              );
                            },
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(
                            dialogContext,
                          ).pop();
                        },
                  child:
                      const Text('Hủy'),
                ),

                FilledButton(
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                              try {
                                setDialogState(
                                  () {
                                    isLoading =
                                        true;
                                  },
                                );

                                await _accountService
                                    .changeRole(
                                  uid: uid,
                                  role:
                                      selectedRole,
                                );

                                if (!mounted) {
                                  return;
                                }

                                if (dialogContext
                                    .mounted) {
                                  Navigator.of(
                                    dialogContext,
                                  ).pop();
                                }

                                _showMessage(
                                  'Cập nhật quyền thành công.',
                                );
                              } catch (e) {
                                if (dialogContext
                                    .mounted) {
                                  setDialogState(
                                    () {
                                      isLoading =
                                          false;
                                    },
                                  );
                                }

                                _showMessage(
                                  'Không thể cập nhật quyền: $e',
                                );
                              }
                            },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================
  // KHÓA / MỞ KHÓA
  // =========================================================

  Future<void> _changeAccountStatus({
    required String uid,
    required String fullName,
    required bool currentStatus,
  }) async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            currentStatus
                ? 'Khóa tài khoản'
                : 'Mở khóa tài khoản',
          ),
          content: Text(
            currentStatus
                ? 'Bạn có chắc muốn khóa tài khoản "$fullName" không?'
                : 'Bạn có chắc muốn mở khóa tài khoản "$fullName" không?',
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
              child: Text(
                currentStatus
                    ? 'Khóa'
                    : 'Mở khóa',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _accountService
          .changeAccountStatus(
        uid: uid,
        isActive: !currentStatus,
      );

      _showMessage(
        currentStatus
            ? 'Đã khóa tài khoản.'
            : 'Đã mở khóa tài khoản.',
      );
    } catch (e) {
      _showMessage(
        'Không thể cập nhật trạng thái: $e',
      );
    }
  }

  // =========================================================
  // HEADER CỦA BẢNG
  // =========================================================

  Widget _buildTableHeader() {
    const headerStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: Color(0xff374151),
      fontSize: 14,
    );

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xfff8fafc),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 22,
            child: Text(
              'Họ tên',
              style: headerStyle,
            ),
          ),

          Expanded(
            flex: 27,
            child: Text(
              'Email',
              style: headerStyle,
            ),
          ),

          Expanded(
            flex: 16,
            child: Text(
              'MSSV',
              style: headerStyle,
            ),
          ),

          Expanded(
            flex: 14,
            child: Text(
              'Quyền',
              style: headerStyle,
            ),
          ),

          Expanded(
            flex: 14,
            child: Text(
              'Trạng thái',
              style: headerStyle,
            ),
          ),

          Expanded(
            flex: 12,
            child: Center(
              child: Text(
                'Thao tác',
                style: headerStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MỘT DÒNG TÀI KHOẢN
  // =========================================================

  Widget _buildUserRow({
    required QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc,
    required String? currentUid,
  }) {
    final data = doc.data();

    final fullName =
        data['fullName']?.toString() ?? '';

    final email =
        data['email']?.toString() ?? '';

    final studentCode =
        data['studentCode']?.toString() ?? '';

    final role =
        data['role']?.toString() ?? 'student';

    final isActive =
        data['isActive'] as bool? ?? true;

    final isCurrentUser =
        doc.id == currentUid;

    return Container(
      constraints: const BoxConstraints(
        minHeight: 68,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xffe5e7eb),
          ),
        ),
      ),
      child: Row(
        children: [
          // HỌ TÊN
          Expanded(
            flex: 22,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      role == 'admin'
                          ? const Color(
                              0xffe0e7ff,
                            )
                          : const Color(
                              0xffeff6ff,
                            ),
                  child: Icon(
                    role == 'admin'
                        ? Icons
                            .admin_panel_settings
                        : Icons.person,
                    size: 18,
                    color: const Color(
                      0xff4f46e5,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    fullName,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // EMAIL
          Expanded(
            flex: 27,
            child: Padding(
              padding:
                  const EdgeInsets.only(
                right: 15,
              ),
              child: Text(
                email,
                overflow:
                    TextOverflow.ellipsis,
              ),
            ),
          ),

          // MSSV
          Expanded(
            flex: 16,
            child: Text(
              studentCode.isEmpty
                  ? '-'
                  : studentCode,
              overflow:
                  TextOverflow.ellipsis,
            ),
          ),

          // ROLE
          Expanded(
            flex: 14,
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
                  color: role == 'admin'
                      ? const Color(
                          0xffeef2ff,
                        )
                      : const Color(
                          0xfff0f9ff,
                        ),
                  borderRadius:
                      BorderRadius
                          .circular(8),
                  border: Border.all(
                    color:
                        const Color(
                      0xffd1d5db,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      role == 'admin'
                          ? Icons
                              .admin_panel_settings
                          : Icons.school,
                      size: 16,
                      color:
                          const Color(
                        0xff4f46e5,
                      ),
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Flexible(
                      child: Text(
                        role == 'admin'
                            ? 'Admin'
                            : 'Sinh viên',
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // TRẠNG THÁI
          Expanded(
            flex: 14,
            child: Row(
              children: [
                Icon(
                  isActive
                      ? Icons.check_circle
                      : Icons.cancel,
                  size: 18,
                  color: isActive
                      ? Colors.green
                      : Colors.red,
                ),

                const SizedBox(width: 7),

                Flexible(
                  child: Text(
                    isActive
                        ? 'Hoạt động'
                        : 'Đã khóa',
                    overflow:
                        TextOverflow
                            .ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // THAO TÁC
          Expanded(
            flex: 12,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Tooltip(
                  message: isCurrentUser
                      ? 'Không thể đổi quyền tài khoản đang đăng nhập'
                      : 'Thay đổi quyền',
                  child: IconButton(
                    onPressed:
                        isCurrentUser
                            ? null
                            : () {
                                _showChangeRoleDialog(
                                  uid:
                                      doc.id,
                                  currentRole:
                                      role,
                                  fullName:
                                      fullName,
                                );
                              },
                    icon: const Icon(
                      Icons
                          .admin_panel_settings_outlined,
                    ),
                    iconSize: 21,
                  ),
                ),

                Tooltip(
                  message: isCurrentUser
                      ? 'Không thể khóa tài khoản đang đăng nhập'
                      : isActive
                          ? 'Khóa tài khoản'
                          : 'Mở khóa tài khoản',
                  child: IconButton(
                    onPressed:
                        isCurrentUser
                            ? null
                            : () {
                                _changeAccountStatus(
                                  uid:
                                      doc.id,
                                  fullName:
                                      fullName,
                                  currentStatus:
                                      isActive,
                                );
                              },
                    icon: Icon(
                      isActive
                          ? Icons
                              .lock_outline
                          : Icons.lock_open,
                    ),
                    iconSize: 21,
                    color: isCurrentUser
                        ? Colors.grey
                        : isActive
                            ? Colors.red
                            : Colors.green,
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
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final currentUid =
        FirebaseAuth
            .instance.currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // =================================================
          // TITLE + BUTTON
          // =================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              const Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    'Quản lý tài khoản',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    'Cấp và quản lý tài khoản sử dụng hệ thống',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              FilledButton.icon(
                onPressed:
                    _showCreateAccountDialog,
                icon: const Icon(
                  Icons.person_add_alt_1,
                ),
                label: const Text(
                  'Cấp tài khoản',
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // =================================================
          // SEARCH
          // =================================================

          SizedBox(
            width: 420,
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
                    'Tìm tên, email hoặc MSSV...',
                prefixIcon:
                    Icon(Icons.search),
              ),
            ),
          ),

          const SizedBox(height: 22),

          // =================================================
          // TABLE
          // =================================================

          Expanded(
            child: Container(
              width: double.infinity,
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
              child: StreamBuilder<
                  QuerySnapshot<
                      Map<String,
                          dynamic>>>(
                stream:
                    _accountService
                        .getUsers(),
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
                      child: Column(
                        mainAxisSize:
                            MainAxisSize
                                .min,
                        children: [
                          const Icon(
                            Icons
                                .error_outline,
                            size: 45,
                            color:
                                Colors.red,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            'Lỗi: ${snapshot.error}',
                          ),
                        ],
                      ),
                    );
                  }

                  final docs =
                      snapshot.data?.docs ??
                          [];

                  final filteredUsers =
                      docs.where((doc) {
                    final data =
                        doc.data();

                    final fullName =
                        (data['fullName'] ??
                                '')
                            .toString()
                            .toLowerCase();

                    final email =
                        (data['email'] ??
                                '')
                            .toString()
                            .toLowerCase();

                    final code =
                        (data['studentCode'] ??
                                '')
                            .toString()
                            .toLowerCase();

                    return fullName
                            .contains(
                                _searchText) ||
                        email.contains(
                            _searchText) ||
                        code.contains(
                            _searchText);
                  }).toList();

                  return Column(
                    children: [
                      // Header
                      _buildTableHeader(),

                      // Rows
                      Expanded(
                        child:
                            filteredUsers
                                    .isEmpty
                                ? const Center(
                                    child:
                                        Column(
                                      mainAxisSize:
                                          MainAxisSize
                                              .min,
                                      children: [
                                        Icon(
                                          Icons
                                              .person_search_outlined,
                                          size:
                                              55,
                                          color:
                                              Colors.grey,
                                        ),
                                        SizedBox(
                                          height:
                                              12,
                                        ),
                                        Text(
                                          'Không tìm thấy tài khoản.',
                                          style:
                                              TextStyle(
                                            color:
                                                Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount:
                                        filteredUsers
                                            .length,
                                    itemBuilder:
                                        (context,
                                            index) {
                                      return _buildUserRow(
                                        doc:
                                            filteredUsers[index],
                                        currentUid:
                                            currentUid,
                                      );
                                    },
                                  ),
                      ),
                    ],
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
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}