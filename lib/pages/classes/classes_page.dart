import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';

class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key});

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  final FirestoreService _service = FirestoreService();

  final TextEditingController _searchController =
      TextEditingController();

  String _searchText = '';

  // =========================================================
  // THÔNG BÁO
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
  // THÊM / SỬA LỚP
  // =========================================================

  Future<void> _showClassDialog({
    String? id,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Lấy danh sách chuyên ngành
      final majorsSnapshot = await FirebaseFirestore.instance
          .collection('majors')
          .orderBy('majorCode')
          .get();

      if (!mounted) return;

      if (majorsSnapshot.docs.isEmpty) {
        _showMessage(
          'Chưa có chuyên ngành. Hãy tạo chuyên ngành trước.',
        );
        return;
      }

      final codeController = TextEditingController(
        text: data?['classCode']?.toString() ?? '',
      );

      final nameController = TextEditingController(
        text: data?['className']?.toString() ?? '',
      );

      final yearController = TextEditingController(
        text: data?['academicYear']?.toString() ?? '',
      );

      final advisorController = TextEditingController(
        text: data?['advisor']?.toString() ?? '',
      );

      String? selectedMajorId =
          data?['majorId']?.toString();

      // Nếu majorId cũ không còn tồn tại
      if (selectedMajorId != null &&
          !majorsSnapshot.docs.any(
            (doc) => doc.id == selectedMajorId,
          )) {
        selectedMajorId = null;
      }

      bool loading = false;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> saveClass() async {
                final classCode =
                    codeController.text.trim().toUpperCase();

                final className =
                    nameController.text.trim();

                final academicYear =
                    yearController.text.trim();

                final advisor =
                    advisorController.text.trim();

                if (classCode.isEmpty) {
                  _showMessage(
                    'Vui lòng nhập mã lớp.',
                  );
                  return;
                }

                if (className.isEmpty) {
                  _showMessage(
                    'Vui lòng nhập tên lớp.',
                  );
                  return;
                }

                if (selectedMajorId == null) {
                  _showMessage(
                    'Vui lòng chọn chuyên ngành.',
                  );
                  return;
                }

                if (academicYear.isEmpty) {
                  _showMessage(
                    'Vui lòng nhập niên khóa.',
                  );
                  return;
                }

                try {
                  setDialogState(() {
                    loading = true;
                  });

                  // Kiểm tra trùng mã lớp
                  final existing =
                      await FirebaseFirestore.instance
                          .collection('classes')
                          .where(
                            'classCode',
                            isEqualTo: classCode,
                          )
                          .get();

                  final duplicate =
                      existing.docs.any(
                    (doc) => doc.id != id,
                  );

                  if (duplicate) {
                    if (dialogContext.mounted) {
                      setDialogState(() {
                        loading = false;
                      });
                    }

                    _showMessage(
                      'Mã lớp đã tồn tại.',
                    );
                    return;
                  }

                  final classData = <String, dynamic>{
                    'classCode': classCode,
                    'className': className,
                    'majorId': selectedMajorId,
                    'academicYear': academicYear,
                    'advisor': advisor,
                    'updatedAt':
                        FieldValue.serverTimestamp(),
                  };

                  if (id == null) {
                    classData['createdAt'] =
                        FieldValue.serverTimestamp();

                    await _service.addClass(
                      classData,
                    );
                  } else {
                    await _service.updateClass(
                      id,
                      classData,
                    );
                  }

                  if (!mounted) return;

                  if (dialogContext.mounted) {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  }

                  _showMessage(
                    id == null
                        ? 'Thêm lớp học thành công.'
                        : 'Cập nhật lớp học thành công.',
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
                          ? Icons.add_business_outlined
                          : Icons.edit_outlined,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      id == null
                          ? 'Thêm lớp học'
                          : 'Cập nhật lớp học',
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
                        TextField(
                          controller:
                              codeController,
                          enabled: !loading,
                          decoration:
                              const InputDecoration(
                            labelText: 'Mã lớp',
                            hintText:
                                'VD: CNTT2401',
                            prefixIcon: Icon(
                              Icons.tag,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller:
                              nameController,
                          enabled: !loading,
                          decoration:
                              const InputDecoration(
                            labelText: 'Tên lớp',
                            hintText:
                                'VD: Công nghệ thông tin 01',
                            prefixIcon: Icon(
                              Icons.class_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<
                            String>(
                          initialValue:
                              selectedMajorId,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Chuyên ngành',
                            prefixIcon: Icon(
                              Icons.school_outlined,
                            ),
                          ),
                          items:
                              majorsSnapshot.docs.map(
                            (doc) {
                              final major =
                                  doc.data();

                              final majorCode =
                                  major['majorCode']
                                          ?.toString() ??
                                      '';

                              final majorName =
                                  major['majorName']
                                          ?.toString() ??
                                      '';

                              return DropdownMenuItem<
                                  String>(
                                value: doc.id,
                                child: Text(
                                  '$majorCode - $majorName',
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                ),
                              );
                            },
                          ).toList(),
                          onChanged: loading
                              ? null
                              : (value) {
                                  setDialogState(
                                    () {
                                      selectedMajorId =
                                          value;
                                    },
                                  );
                                },
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller:
                              yearController,
                          enabled: !loading,
                          decoration:
                              const InputDecoration(
                            labelText: 'Niên khóa',
                            hintText:
                                'VD: 2024 - 2028',
                            prefixIcon: Icon(
                              Icons
                                  .calendar_month_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller:
                              advisorController,
                          enabled: !loading,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Cố vấn học tập',
                            hintText:
                                'VD: Nguyễn Văn A',
                            prefixIcon: Icon(
                              Icons
                                  .person_outline,
                            ),
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
                        loading ? null : saveClass,
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
                              ? 'Thêm lớp'
                              : 'Lưu',
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
        'Không thể tải danh sách chuyên ngành: $e',
      );
    }
  }

  // =========================================================
  // XÓA LỚP
  // =========================================================

  Future<void> _deleteClass({
    required String id,
    required String className,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Xóa lớp học',
          ),
          content: Text(
            'Bạn có chắc muốn xóa lớp "$className" không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text('Hủy'),
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
              label: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      // Không cho xóa nếu còn sinh viên thuộc lớp
      final students =
          await FirebaseFirestore.instance
              .collection('students')
              .where(
                'classId',
                isEqualTo: id,
              )
              .limit(1)
              .get();

      if (students.docs.isNotEmpty) {
        _showMessage(
          'Không thể xóa lớp vì vẫn còn sinh viên thuộc lớp này.',
        );
        return;
      }

      await _service.deleteClass(id);

      _showMessage(
        'Xóa lớp học thành công.',
      );
    } catch (e) {
      _showMessage(
        'Không thể xóa lớp: $e',
      );
    }
  }

  // =========================================================
  // HEADER BẢNG
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
            flex: 15,
            child: Text(
              'Mã lớp',
              style: style,
            ),
          ),
          Expanded(
            flex: 23,
            child: Text(
              'Tên lớp',
              style: style,
            ),
          ),
          Expanded(
            flex: 22,
            child: Text(
              'Chuyên ngành',
              style: style,
            ),
          ),
          Expanded(
            flex: 16,
            child: Text(
              'Niên khóa',
              style: style,
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              'Cố vấn',
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
  // DÒNG LỚP
  // =========================================================

  Widget _buildClassRow({
    required QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc,
    required Map<String, String> majorNames,
  }) {
    final data = doc.data();

    final classCode =
        data['classCode']?.toString() ?? '';

    final className =
        data['className']?.toString() ?? '';

    final academicYear =
        data['academicYear']?.toString() ?? '';

    final advisor =
        data['advisor']?.toString() ?? '';

    final majorId =
        data['majorId']?.toString() ?? '';

    // Hỗ trợ dữ liệu cũ đang lưu major bằng text
    final oldMajor =
        data['major']?.toString() ?? '';

    final majorName = majorNames[majorId] ??
        (oldMajor.isNotEmpty
            ? oldMajor
            : 'Chưa chọn');

    return Container(
      constraints: const BoxConstraints(
        minHeight: 65,
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
          Expanded(
            flex: 15,
            child: Text(
              classCode,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            flex: 23,
            child: Text(
              className,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            flex: 22,
            child: Row(
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 17,
                  color: Color(0xff2563eb),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    majorName,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 16,
            child: Text(
              academicYear,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            flex: 18,
            child: Text(
              advisor.isEmpty
                  ? '-'
                  : advisor,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            flex: 10,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Sửa lớp',
                  onPressed: () {
                    _showClassDialog(
                      id: doc.id,
                      data: data,
                    );
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                ),

                IconButton(
                  tooltip: 'Xóa lớp',
                  onPressed: () {
                    _deleteClass(
                      id: doc.id,
                      className: className,
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
          // ================= HEADER =================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quản lý lớp học',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Quản lý danh sách lớp và chuyên ngành',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              FilledButton.icon(
                onPressed: () {
                  _showClassDialog();
                },
                icon: const Icon(Icons.add),
                label: const Text(
                  'Thêm lớp học',
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // ================= SEARCH =================

          SizedBox(
            width: 420,
            child: TextField(
              controller:
                  _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText =
                      value.trim().toLowerCase();
                });
              },
              decoration:
                  const InputDecoration(
                hintText:
                    'Tìm mã lớp, tên lớp...',
                prefixIcon:
                    Icon(Icons.search),
              ),
            ),
          ),

          const SizedBox(height: 22),

          // ================= TABLE =================

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
                stream: FirebaseFirestore.instance
                    .collection('majors')
                    .snapshots(),
                builder:
                    (context, majorSnapshot) {
                  if (majorSnapshot
                          .connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  if (majorSnapshot.hasError) {
                    return Center(
                      child: Text(
                        'Không thể tải chuyên ngành: '
                        '${majorSnapshot.error}',
                      ),
                    );
                  }

                  // Map majorId -> majorName
                  final Map<String, String>
                      majorNames = {};

                  for (final doc
                      in majorSnapshot.data?.docs ??
                          []) {
                    majorNames[doc.id] =
                        doc.data()['majorName']
                                ?.toString() ??
                            '';
                  }

                  return StreamBuilder<
                      QuerySnapshot<
                          Map<String, dynamic>>>(
                    stream:
                        _service.getClasses(),
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

                      final filtered =
                          docs.where((doc) {
                        final data =
                            doc.data();

                        final code =
                            (data['classCode'] ??
                                    '')
                                .toString()
                                .toLowerCase();

                        final name =
                            (data['className'] ??
                                    '')
                                .toString()
                                .toLowerCase();

                        final majorId =
                            data['majorId']
                                    ?.toString() ??
                                '';

                        final majorName =
                            (majorNames[
                                        majorId] ??
                                    data['major'] ??
                                    '')
                                .toString()
                                .toLowerCase();

                        return code.contains(
                                _searchText) ||
                            name.contains(
                                _searchText) ||
                            majorName.contains(
                                _searchText);
                      }).toList();

                      return Column(
                        children: [
                          _buildHeader(),

                          Expanded(
                            child: filtered
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
                                              .class_outlined,
                                          size: 55,
                                          color:
                                              Colors.grey,
                                        ),
                                        SizedBox(
                                          height:
                                              12,
                                        ),
                                        Text(
                                          'Chưa có lớp học.',
                                          style:
                                              TextStyle(
                                            color:
                                                Colors.grey,
                                          ),
                                        ),
                                      ],
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
                                      return _buildClassRow(
                                        doc:
                                            filtered[
                                                index],
                                        majorNames:
                                            majorNames,
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
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}