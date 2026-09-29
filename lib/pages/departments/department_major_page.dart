import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/department_service.dart';

class DepartmentMajorPage extends StatefulWidget {
  const DepartmentMajorPage({super.key});

  @override
  State<DepartmentMajorPage> createState() =>
      _DepartmentMajorPageState();
}

class _DepartmentMajorPageState
    extends State<DepartmentMajorPage> {
  final DepartmentService _service =
      DepartmentService();

  String _departmentSearch = '';
  String _majorSearch = '';

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // DEPARTMENT DIALOG
  // =========================================================

  Future<void> _showDepartmentDialog({
    String? id,
    Map<String, dynamic>? data,
  }) async {
    final codeController = TextEditingController(
      text: data?['departmentCode'] ?? '',
    );

    final nameController = TextEditingController(
      text: data?['departmentName'] ?? '',
    );

    bool loading = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              final code =
                  codeController.text.trim();
              final name =
                  nameController.text.trim();

              if (code.isEmpty || name.isEmpty) {
                _showMessage(
                  'Vui lòng nhập đầy đủ mã khoa và tên khoa.',
                );
                return;
              }

              try {
                setDialogState(() {
                  loading = true;
                });

                if (id == null) {
                  await _service.addDepartment(
                    departmentCode: code,
                    departmentName: name,
                  );
                } else {
                  await _service.updateDepartment(
                    id: id,
                    departmentCode: code,
                    departmentName: name,
                  );
                }

                if (!mounted) return;

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }

                _showMessage(
                  id == null
                      ? 'Thêm khoa thành công.'
                      : 'Cập nhật khoa thành công.',
                );
              } catch (e) {
                if (dialogContext.mounted) {
                  setDialogState(() {
                    loading = false;
                  });
                }

                _showMessage(
                  e.toString().replaceFirst(
                        'Exception: ',
                        '',
                      ),
                );
              }
            }

            return AlertDialog(
              title: Text(
                id == null
                    ? 'Thêm khoa'
                    : 'Cập nhật khoa',
              ),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      enabled: !loading,
                      decoration:
                          const InputDecoration(
                        labelText: 'Mã khoa',
                        hintText: 'VD: CNTT',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      enabled: !loading,
                      decoration:
                          const InputDecoration(
                        labelText: 'Tên khoa',
                        hintText:
                            'VD: Công nghệ thông tin',
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
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: loading ? null : save,
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          id == null
                              ? 'Thêm'
                              : 'Lưu',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    codeController.dispose();
    nameController.dispose();
  }

  // =========================================================
  // MAJOR DIALOG
  // =========================================================

  Future<void> _showMajorDialog({
    String? id,
    Map<String, dynamic>? data,
  }) async {
    final departments =
        await FirebaseFirestore.instance
            .collection('departments')
            .orderBy('departmentCode')
            .get();

    if (!mounted) return;

    if (departments.docs.isEmpty) {
      _showMessage(
        'Hãy tạo khoa trước khi tạo chuyên ngành.',
      );
      return;
    }

    final codeController = TextEditingController(
      text: data?['majorCode'] ?? '',
    );

    final nameController = TextEditingController(
      text: data?['majorName'] ?? '',
    );

    String? selectedDepartmentId =
        data?['departmentId'];

    bool loading = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              final code =
                  codeController.text.trim();
              final name =
                  nameController.text.trim();

              if (code.isEmpty ||
                  name.isEmpty ||
                  selectedDepartmentId == null) {
                _showMessage(
                  'Vui lòng nhập đầy đủ thông tin.',
                );
                return;
              }

              try {
                setDialogState(() {
                  loading = true;
                });

                if (id == null) {
                  await _service.addMajor(
                    majorCode: code,
                    majorName: name,
                    departmentId:
                        selectedDepartmentId!,
                  );
                } else {
                  await _service.updateMajor(
                    id: id,
                    majorCode: code,
                    majorName: name,
                    departmentId:
                        selectedDepartmentId!,
                  );
                }

                if (!mounted) return;

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }

                _showMessage(
                  id == null
                      ? 'Thêm chuyên ngành thành công.'
                      : 'Cập nhật chuyên ngành thành công.',
                );
              } catch (e) {
                if (dialogContext.mounted) {
                  setDialogState(() {
                    loading = false;
                  });
                }

                _showMessage(
                  e.toString().replaceFirst(
                        'Exception: ',
                        '',
                      ),
                );
              }
            }

            return AlertDialog(
              title: Text(
                id == null
                    ? 'Thêm chuyên ngành'
                    : 'Cập nhật chuyên ngành',
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      enabled: !loading,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Mã chuyên ngành',
                        hintText: 'VD: CNPM',
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: nameController,
                      enabled: !loading,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Tên chuyên ngành',
                        hintText:
                            'VD: Công nghệ phần mềm',
                      ),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue:
                          selectedDepartmentId,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(
                        labelText: 'Khoa',
                      ),
                      items:
                          departments.docs.map(
                        (doc) {
                          final department =
                              doc.data();

                          final code =
                              department[
                                      'departmentCode'] ??
                                  '';

                          final name =
                              department[
                                      'departmentName'] ??
                                  '';

                          return DropdownMenuItem(
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
                              setDialogState(() {
                                selectedDepartmentId =
                                    value;
                              });
                            },
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
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: loading ? null : save,
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          id == null
                              ? 'Thêm'
                              : 'Lưu',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    codeController.dispose();
    nameController.dispose();
  }

  // =========================================================
  // DELETE DEPARTMENT
  // =========================================================

  Future<void> _deleteDepartment({
    required String id,
    required String name,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa khoa'),
          content: Text(
            'Bạn có chắc muốn xóa khoa "$name" không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _service.deleteDepartment(id);

      _showMessage(
        'Xóa khoa thành công.',
      );
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  // =========================================================
  // DELETE MAJOR
  // =========================================================

  Future<void> _deleteMajor({
    required String id,
    required String name,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Xóa chuyên ngành'),
          content: Text(
            'Bạn có chắc muốn xóa chuyên ngành "$name" không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _service.deleteMajor(id);

      _showMessage(
        'Xóa chuyên ngành thành công.',
      );
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
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
          const Text(
            'Khoa / Chuyên ngành',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Quản lý khoa và chuyên ngành trong hệ thống',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 25),

          Expanded(
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                // =============================================
                // DEPARTMENTS
                // =============================================

                Expanded(
                  child: _buildDepartmentPanel(),
                ),

                const SizedBox(width: 20),

                // =============================================
                // MAJORS
                // =============================================

                Expanded(
                  child: _buildMajorPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DEPARTMENT PANEL
  // =========================================================

  Widget _buildDepartmentPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xffe5e7eb),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Danh sách khoa',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                FilledButton.icon(
                  onPressed: () {
                    _showDepartmentDialog();
                  },
                  icon: const Icon(Icons.add),
                  label:
                      const Text('Thêm khoa'),
                ),
              ],
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _departmentSearch =
                      value
                          .trim()
                          .toLowerCase();
                });
              },
              decoration:
                  const InputDecoration(
                hintText:
                    'Tìm mã hoặc tên khoa...',
                prefixIcon:
                    Icon(Icons.search),
              ),
            ),
          ),

          const SizedBox(height: 15),

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream:
                  _service.getDepartments(),
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

                final docs =
                    snapshot.data?.docs ?? [];

                final filtered =
                    docs.where((doc) {
                  final data = doc.data();

                  final code =
                      (data['departmentCode'] ??
                              '')
                          .toString()
                          .toLowerCase();

                  final name =
                      (data['departmentName'] ??
                              '')
                          .toString()
                          .toLowerCase();

                  return code.contains(
                          _departmentSearch) ||
                      name.contains(
                          _departmentSearch);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có khoa.',
                    ),
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  separatorBuilder:
                      (_, __) =>
                          const Divider(),
                  itemBuilder:
                      (context, index) {
                    final doc =
                        filtered[index];
                    final data =
                        doc.data();

                    final code =
                        data['departmentCode']
                                ?.toString() ??
                            '';

                    final name =
                        data['departmentName']
                                ?.toString() ??
                            '';

                    return ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading: Container(
                        width: 46,
                        height: 46,
                        decoration:
                            BoxDecoration(
                          color: const Color(
                            0xffeef2ff,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(10),
                        ),
                        child: const Icon(
                          Icons
                              .account_balance_outlined,
                          color: Color(
                            0xff4f46e5,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Mã khoa: $code',
                      ),
                      trailing: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip:
                                'Sửa khoa',
                            onPressed: () {
                              _showDepartmentDialog(
                                id: doc.id,
                                data: data,
                              );
                            },
                            icon: const Icon(
                              Icons
                                  .edit_outlined,
                            ),
                          ),
                          IconButton(
                            tooltip:
                                'Xóa khoa',
                            onPressed: () {
                              _deleteDepartment(
                                id: doc.id,
                                name: name,
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

  // =========================================================
  // MAJOR PANEL
  // =========================================================

  Widget _buildMajorPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xffe5e7eb),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Danh sách chuyên ngành',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                FilledButton.icon(
                  onPressed: () {
                    _showMajorDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Thêm chuyên ngành',
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _majorSearch =
                      value
                          .trim()
                          .toLowerCase();
                });
              },
              decoration:
                  const InputDecoration(
                hintText:
                    'Tìm mã hoặc tên chuyên ngành...',
                prefixIcon:
                    Icon(Icons.search),
              ),
            ),
          ),

          const SizedBox(height: 15),

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream: _service.getMajors(),
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

                final docs =
                    snapshot.data?.docs ?? [];

                final filtered =
                    docs.where((doc) {
                  final data = doc.data();

                  final code =
                      (data['majorCode'] ??
                              '')
                          .toString()
                          .toLowerCase();

                  final name =
                      (data['majorName'] ??
                              '')
                          .toString()
                          .toLowerCase();

                  return code.contains(
                          _majorSearch) ||
                      name.contains(
                          _majorSearch);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có chuyên ngành.',
                    ),
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  separatorBuilder:
                      (_, __) =>
                          const Divider(),
                  itemBuilder:
                      (context, index) {
                    final doc =
                        filtered[index];

                    final data =
                        doc.data();

                    final code =
                        data['majorCode']
                                ?.toString() ??
                            '';

                    final name =
                        data['majorName']
                                ?.toString() ??
                            '';

                    final departmentId =
                        data['departmentId']
                                ?.toString() ??
                            '';

                    return FutureBuilder<
                        DocumentSnapshot<
                            Map<String,
                                dynamic>>>(
                      future:
                          FirebaseFirestore
                              .instance
                              .collection(
                                'departments',
                              )
                              .doc(
                                departmentId,
                              )
                              .get(),
                      builder:
                          (context, depSnap) {
                        final depData =
                            depSnap.data
                                ?.data();

                        final depName =
                            depData?[
                                    'departmentName']
                                ?.toString();

                        return ListTile(
                          contentPadding:
                              EdgeInsets.zero,
                          leading: Container(
                            width: 46,
                            height: 46,
                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xfff0f9ff,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(10),
                            ),
                            child:
                                const Icon(
                              Icons
                                  .school_outlined,
                              color: Color(
                                0xff0284c7,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                          subtitle: Text(
                            '$code • ${depName ?? 'Đang tải khoa...'}',
                          ),
                          trailing: Row(
                            mainAxisSize:
                                MainAxisSize
                                    .min,
                            children: [
                              IconButton(
                                tooltip:
                                    'Sửa chuyên ngành',
                                onPressed: () {
                                  _showMajorDialog(
                                    id: doc.id,
                                    data: data,
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
                                    'Xóa chuyên ngành',
                                onPressed: () {
                                  _deleteMajor(
                                    id: doc.id,
                                    name: name,
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
                        );
                      },
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
}