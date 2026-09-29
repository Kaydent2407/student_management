import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final FirestoreService _service = FirestoreService();

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
  // THÊM / SỬA SINH VIÊN
  // =========================================================

  Future<void> _showStudentDialog({
    String? id,
    Map<String, dynamic>? data,
  }) async {
    try {
      // =====================================================
      // LOAD CLASSES + MAJORS
      // =====================================================

      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('classes')
            .orderBy('classCode')
            .get(),

        FirebaseFirestore.instance
            .collection('majors')
            .get(),
      ]);

      if (!mounted) return;

      final classesSnapshot =
          results[0] as QuerySnapshot<Map<String, dynamic>>;

      final majorsSnapshot =
          results[1] as QuerySnapshot<Map<String, dynamic>>;

      if (classesSnapshot.docs.isEmpty) {
        _showMessage(
          'Chưa có lớp học. Hãy tạo lớp học trước.',
        );
        return;
      }

      // majorId -> majorName
      final Map<String, String> majorNames = {};

      for (final doc in majorsSnapshot.docs) {
        majorNames[doc.id] =
            doc.data()['majorName']?.toString() ?? '';
      }

      // =====================================================
      // CONTROLLERS
      // =====================================================

      final studentCodeController =
          TextEditingController(
        text: data?['studentCode']?.toString() ?? '',
      );

      final fullNameController =
          TextEditingController(
        text: data?['fullName']?.toString() ?? '',
      );

      final emailController =
          TextEditingController(
        text: data?['email']?.toString() ?? '',
      );

      final phoneController =
          TextEditingController(
        text: data?['phone']?.toString() ?? '',
      );

      String? selectedClassId =
          data?['classId']?.toString();

      String? selectedMajorId =
          data?['majorId']?.toString();

      String selectedMajorName =
          data?['major']?.toString() ?? '';

      // Nếu classId cũ không còn tồn tại
      if (selectedClassId != null &&
          !classesSnapshot.docs.any(
            (doc) => doc.id == selectedClassId,
          )) {
        selectedClassId = null;
      }

      // Nếu đang sửa dữ liệu mới
      if (selectedClassId != null) {
        final classDoc = classesSnapshot.docs.firstWhere(
          (doc) => doc.id == selectedClassId,
        );

        selectedMajorId =
            classDoc.data()['majorId']?.toString();

        selectedMajorName =
            majorNames[selectedMajorId] ?? selectedMajorName;
      }

      bool loading = false;

      // =====================================================
      // DIALOG
      // =====================================================

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              // =============================================
              // SAVE
              // =============================================

              Future<void> saveStudent() async {
                final studentCode =
                    studentCodeController.text
                        .trim()
                        .toUpperCase();

                final fullName =
                    fullNameController.text.trim();

                final email =
                    emailController.text.trim();

                final phone =
                    phoneController.text.trim();

                if (studentCode.isEmpty) {
                  _showMessage(
                    'Vui lòng nhập mã sinh viên.',
                  );
                  return;
                }

                if (fullName.isEmpty) {
                  _showMessage(
                    'Vui lòng nhập họ tên sinh viên.',
                  );
                  return;
                }

                if (email.isNotEmpty &&
                    !email.contains('@')) {
                  _showMessage(
                    'Email không hợp lệ.',
                  );
                  return;
                }

                if (selectedClassId == null) {
                  _showMessage(
                    'Vui lòng chọn lớp học.',
                  );
                  return;
                }

                try {
                  setDialogState(() {
                    loading = true;
                  });

                  // =========================================
                  // CHECK DUPLICATE STUDENT CODE
                  // =========================================

                  final duplicateSnapshot =
                      await FirebaseFirestore.instance
                          .collection('students')
                          .where(
                            'studentCode',
                            isEqualTo: studentCode,
                          )
                          .get();

                  final duplicate =
                      duplicateSnapshot.docs.any(
                    (doc) => doc.id != id,
                  );

                  if (duplicate) {
                    if (dialogContext.mounted) {
                      setDialogState(() {
                        loading = false;
                      });
                    }

                    _showMessage(
                      'Mã sinh viên đã tồn tại.',
                    );

                    return;
                  }

                  // =========================================
                  // LẤY CLASS ĐANG CHỌN
                  // =========================================

                  final selectedClass =
                      classesSnapshot.docs.firstWhere(
                    (doc) =>
                        doc.id == selectedClassId,
                  );

                  final classData =
                      selectedClass.data();

                  final className =
                      classData['className']
                              ?.toString() ??
                          '';

                  final classCode =
                      classData['classCode']
                              ?.toString() ??
                          '';

                  final majorId =
                      classData['majorId']
                              ?.toString() ??
                          '';

                  final majorName =
                      majorNames[majorId] ?? '';

                  // =========================================
                  // DATA
                  // =========================================

                  final studentData =
                      <String, dynamic>{
                    'studentCode': studentCode,
                    'fullName': fullName,
                    'email': email,
                    'phone': phone,

                    // ID quan hệ
                    'classId': selectedClassId,
                    'majorId': majorId,

                    // Cache để hiển thị nhanh
                    'classCode': classCode,
                    'className': className,
                    'major': majorName,

                    'updatedAt':
                        FieldValue.serverTimestamp(),
                  };

                  if (id == null) {
                    studentData['createdAt'] =
                        FieldValue.serverTimestamp();

                    await _service.addStudent(
                      studentData,
                    );
                  } else {
                    await _service.updateStudent(
                      id,
                      studentData,
                    );
                  }

                  if (!mounted) return;

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }

                  _showMessage(
                    id == null
                        ? 'Thêm sinh viên thành công.'
                        : 'Cập nhật sinh viên thành công.',
                  );
                } catch (e) {
                  if (dialogContext.mounted) {
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
                          ? Icons.person_add_alt_1
                          : Icons.edit_outlined,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      id == null
                          ? 'Thêm sinh viên'
                          : 'Cập nhật sinh viên',
                    ),
                  ],
                ),

                content: SizedBox(
                  width: 550,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        // ===================================
                        // MSSV
                        // ===================================

                        TextField(
                          controller:
                              studentCodeController,
                          enabled: !loading,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Mã sinh viên',
                            hintText:
                                'VD: 24DH110001',
                            prefixIcon:
                                Icon(Icons.badge_outlined),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ===================================
                        // FULL NAME
                        // ===================================

                        TextField(
                          controller:
                              fullNameController,
                          enabled: !loading,
                          decoration:
                              const InputDecoration(
                            labelText: 'Họ và tên',
                            hintText:
                                'VD: Nguyễn Văn A',
                            prefixIcon:
                                Icon(Icons.person_outline),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ===================================
                        // EMAIL
                        // ===================================

                        TextField(
                          controller:
                              emailController,
                          enabled: !loading,
                          keyboardType:
                              TextInputType.emailAddress,
                          decoration:
                              const InputDecoration(
                            labelText: 'Email',
                            hintText:
                                'VD: example@gmail.com',
                            prefixIcon:
                                Icon(Icons.email_outlined),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ===================================
                        // PHONE
                        // ===================================

                        TextField(
                          controller:
                              phoneController,
                          enabled: !loading,
                          keyboardType:
                              TextInputType.phone,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Số điện thoại',
                            hintText:
                                'VD: 0901234567',
                            prefixIcon:
                                Icon(Icons.phone_outlined),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ===================================
                        // CLASS
                        // ===================================

                        DropdownButtonFormField<String>(
                          initialValue:
                              selectedClassId,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(
                            labelText: 'Lớp học',
                            prefixIcon:
                                Icon(Icons.class_outlined),
                          ),
                          items:
                              classesSnapshot.docs.map(
                            (doc) {
                              final classData =
                                  doc.data();

                              final code =
                                  classData['classCode']
                                          ?.toString() ??
                                      '';

                              final name =
                                  classData['className']
                                          ?.toString() ??
                                      '';

                              return DropdownMenuItem<
                                  String>(
                                value: doc.id,
                                child: Text(
                                  '$code - $name',
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ).toList(),
                          onChanged: loading
                              ? null
                              : (value) {
                                  if (value == null) {
                                    return;
                                  }

                                  final selectedClass =
                                      classesSnapshot.docs
                                          .firstWhere(
                                    (doc) =>
                                        doc.id == value,
                                  );

                                  final classData =
                                      selectedClass.data();

                                  final majorId =
                                      classData['majorId']
                                              ?.toString() ??
                                          '';

                                  setDialogState(() {
                                    selectedClassId =
                                        value;

                                    selectedMajorId =
                                        majorId;

                                    selectedMajorName =
                                        majorNames[
                                                majorId] ??
                                            '';
                                  });
                                },
                        ),

                        const SizedBox(height: 16),

                        // ===================================
                        // MAJOR AUTO
                        // ===================================

                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xfff8fafc),
                            borderRadius:
                                BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  const Color(0xffe5e7eb),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.school_outlined,
                                color:
                                    Color(0xff2563eb),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    const Text(
                                      'Chuyên ngành',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            Colors.grey,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      selectedClassId ==
                                              null
                                          ? 'Chọn lớp để xác định chuyên ngành'
                                          : selectedMajorName
                                                  .isEmpty
                                              ? 'Lớp này chưa được gán chuyên ngành'
                                              : selectedMajorName,
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
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
                        loading ? null : saveStudent,
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            id == null
                                ? Icons.add
                                : Icons.save_outlined,
                          ),
                    label: Text(
                      loading
                          ? 'Đang lưu...'
                          : id == null
                              ? 'Thêm sinh viên'
                              : 'Lưu',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      studentCodeController.dispose();
      fullNameController.dispose();
      emailController.dispose();
      phoneController.dispose();
    } catch (e) {
      _showMessage(
        'Không thể tải dữ liệu lớp học: $e',
      );
    }
  }

  // =========================================================
  // DELETE STUDENT
  // =========================================================

  Future<void> _deleteStudent({
    required String id,
    required String studentCode,
    required String fullName,
  }) async {
    // Kiểm tra sinh viên đã có account chưa
    try {
      final userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where(
                'studentId',
                isEqualTo: id,
              )
              .limit(1)
              .get();

      if (userSnapshot.docs.isNotEmpty) {
        _showMessage(
          'Không thể xóa sinh viên vì sinh viên này đang có tài khoản đăng nhập.',
        );
        return;
      }

      if (!mounted) return;

      final confirmed =
          await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(
              'Xóa sinh viên',
            ),
            content: Text(
              'Bạn có chắc muốn xóa sinh viên:\n\n'
              '$studentCode - $fullName ?',
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

      await _service.deleteStudent(id);

      _showMessage(
        'Xóa sinh viên thành công.',
      );
    } catch (e) {
      _showMessage(
        'Không thể xóa sinh viên: $e',
      );
    }
  }

  // =========================================================
  // TABLE HEADER
  // =========================================================

  Widget _buildHeader() {
    const style = TextStyle(
      fontWeight: FontWeight.w600,
      color: Color(0xff374151),
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
            flex: 14,
            child: Text(
              'MSSV',
              style: style,
            ),
          ),

          Expanded(
            flex: 22,
            child: Text(
              'Họ tên',
              style: style,
            ),
          ),

          Expanded(
            flex: 22,
            child: Text(
              'Email',
              style: style,
            ),
          ),

          Expanded(
            flex: 15,
            child: Text(
              'Lớp',
              style: style,
            ),
          ),

          Expanded(
            flex: 19,
            child: Text(
              'Chuyên ngành',
              style: style,
            ),
          ),

          Expanded(
            flex: 10,
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
  // STUDENT ROW
  // =========================================================

  Widget _buildStudentRow({
    required QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc,
  }) {
    final data = doc.data();

    final studentCode =
        data['studentCode']?.toString() ?? '';

    final fullName =
        data['fullName']?.toString() ?? '';

    final email =
        data['email']?.toString() ?? '';

    final classCode =
        data['classCode']?.toString() ??
            data['className']?.toString() ??
            '';

    final major =
        data['major']?.toString() ?? '';

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
          // MSSV
          Expanded(
            flex: 14,
            child: Text(
              studentCode,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // NAME
          Expanded(
            flex: 22,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 17,
                  backgroundColor:
                      Color(0xffeff6ff),
                  child: Icon(
                    Icons.person,
                    size: 18,
                    color:
                        Color(0xff2563eb),
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    fullName,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // EMAIL
          Expanded(
            flex: 22,
            child: Padding(
              padding:
                  const EdgeInsets.only(
                right: 10,
              ),
              child: Text(
                email.isEmpty ? '-' : email,
                overflow:
                    TextOverflow.ellipsis,
              ),
            ),
          ),

          // CLASS
          Expanded(
            flex: 15,
            child: Text(
              classCode.isEmpty
                  ? '-'
                  : classCode,
              overflow:
                  TextOverflow.ellipsis,
            ),
          ),

          // MAJOR
          Expanded(
            flex: 19,
            child: Row(
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 17,
                  color:
                      Color(0xff2563eb),
                ),

                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    major.isEmpty
                        ? '-'
                        : major,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // ACTION
          Expanded(
            flex: 10,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip:
                      'Sửa sinh viên',
                  onPressed: () {
                    _showStudentDialog(
                      id: doc.id,
                      data: data,
                    );
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                ),

                IconButton(
                  tooltip:
                      'Xóa sinh viên',
                  onPressed: () {
                    _deleteStudent(
                      id: doc.id,
                      studentCode:
                          studentCode,
                      fullName:
                          fullName,
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
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
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // =================================================
          // TITLE
          // =================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quản lý sinh viên',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    'Quản lý thông tin sinh viên trong hệ thống',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              FilledButton.icon(
                onPressed: () {
                  _showStudentDialog();
                },
                icon: const Icon(
                  Icons.person_add_alt_1,
                ),
                label: const Text(
                  'Thêm sinh viên',
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // =================================================
          // SEARCH
          // =================================================

          SizedBox(
            width: 430,
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
                    'Tìm MSSV, tên, lớp hoặc chuyên ngành...',
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
                    BorderRadius.circular(12),
                border: Border.all(
                  color:
                      const Color(0xffe5e7eb),
                ),
              ),
              child: StreamBuilder<
                  QuerySnapshot<
                      Map<String, dynamic>>>(
                stream:
                    _service.getStudents(),
                builder:
                    (context, snapshot) {
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

                  final docs =
                      snapshot.data?.docs ??
                          [];

                  final filteredStudents =
                      docs.where((doc) {
                    final data =
                        doc.data();

                    final studentCode =
                        (data['studentCode'] ??
                                '')
                            .toString()
                            .toLowerCase();

                    final fullName =
                        (data['fullName'] ??
                                '')
                            .toString()
                            .toLowerCase();

                    final email =
                        (data['email'] ?? '')
                            .toString()
                            .toLowerCase();

                    final classCode =
                        (data['classCode'] ??
                                data['className'] ??
                                '')
                            .toString()
                            .toLowerCase();

                    final className =
                        (data['className'] ??
                                '')
                            .toString()
                            .toLowerCase();

                    final major =
                        (data['major'] ?? '')
                            .toString()
                            .toLowerCase();

                    return studentCode
                            .contains(_searchText) ||
                        fullName
                            .contains(_searchText) ||
                        email
                            .contains(_searchText) ||
                        classCode
                            .contains(_searchText) ||
                        className
                            .contains(_searchText) ||
                        major
                            .contains(_searchText);
                  }).toList();

                  return Column(
                    children: [
                      _buildHeader(),

                      Expanded(
                        child: filteredStudents
                                .isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisSize:
                                      MainAxisSize
                                          .min,
                                  children: [
                                    Icon(
                                      Icons
                                          .people_outline,
                                      size: 55,
                                      color:
                                          Colors.grey,
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Text(
                                      'Chưa có sinh viên.',
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
                                    filteredStudents
                                        .length,
                                itemBuilder:
                                    (context,
                                        index) {
                                  return _buildStudentRow(
                                    doc:
                                        filteredStudents[
                                            index],
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