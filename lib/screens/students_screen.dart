import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final searchController = TextEditingController();

  String searchText = '';

  Future<void> showStudentDialog({
    String? docId,
    Map<String, dynamic>? student,
  }) async {
    final studentCodeController = TextEditingController(
      text: student?['studentCode'] ?? '',
    );

    final fullNameController = TextEditingController(
      text: student?['fullName'] ?? '',
    );

    final emailController = TextEditingController(
      text: student?['email'] ?? '',
    );

    final phoneController = TextEditingController(
      text: student?['phone'] ?? '',
    );

    final classController = TextEditingController(
      text: student?['classId'] ?? '',
    );

    final genderController = TextEditingController(
      text: student?['gender'] ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            docId == null ? 'Thêm sinh viên' : 'Cập nhật sinh viên',
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: studentCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Mã sinh viên',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: classController,
                    decoration: const InputDecoration(
                      labelText: 'Lớp',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: genderController,
                    decoration: const InputDecoration(
                      labelText: 'Giới tính',
                      hintText: 'Nam / Nữ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Hủy'),
            ),

            ElevatedButton(
              onPressed: () async {
                final studentCode =
                    studentCodeController.text.trim();

                final fullName =
                    fullNameController.text.trim();

                final email =
                    emailController.text.trim();

                if (studentCode.isEmpty || fullName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'MSSV và họ tên không được để trống',
                      ),
                    ),
                  );
                  return;
                }

                if (email.isNotEmpty &&
                    !RegExp(
                      r'^[\w\.-]+@[\w\.-]+\.\w+$',
                    ).hasMatch(email)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email không hợp lệ'),
                    ),
                  );
                  return;
                }

                try {
                  final duplicate = await firestore
                      .collection('students')
                      .where(
                        'studentCode',
                        isEqualTo: studentCode,
                      )
                      .get();

                  final isDuplicate = duplicate.docs.any(
                    (doc) => doc.id != docId,
                  );

                  if (isDuplicate) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Mã sinh viên đã tồn tại',
                        ),
                      ),
                    );

                    return;
                  }

                  final data = {
                    'studentCode': studentCode,
                    'fullName': fullName,
                    'email': email,
                    'phone':
                        phoneController.text.trim(),
                    'classId':
                        classController.text.trim(),
                    'gender':
                        genderController.text.trim(),
                    'status': 'active',
                    'updatedAt':
                        FieldValue.serverTimestamp(),
                  };

                  if (docId == null) {
                    data['createdAt'] =
                        FieldValue.serverTimestamp();

                    await firestore
                        .collection('students')
                        .add(data);
                  } else {
                    await firestore
                        .collection('students')
                        .doc(docId)
                        .update(data);
                  }

                  if (!mounted) return;

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        docId == null
                            ? 'Thêm sinh viên thành công'
                            : 'Cập nhật thành công',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Có lỗi xảy ra: $e'),
                    ),
                  );
                }
              },
              child: Text(
                docId == null ? 'Thêm' : 'Cập nhật',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteStudent(
    String docId,
    String studentName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc muốn xóa sinh viên "$studentName" không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Không'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await firestore
          .collection('students')
          .doc(docId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa sinh viên'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchText =
                        value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText:
                      'Tìm theo MSSV hoặc họ tên...',
                  prefixIcon:
                      const Icon(Icons.search),
                  suffixIcon:
                      searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                searchController.clear();

                                setState(() {
                                  searchText = '';
                                });
                              },
                              icon:
                                  const Icon(Icons.clear),
                            )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 20),

            ElevatedButton.icon(
              onPressed: () {
                showStudentDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm sinh viên'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 25),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('students')
                .orderBy(
                  'createdAt',
                  descending: true,
                )
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Lỗi: ${snapshot.error}',
                  ),
                );
              }

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              final docs =
                  snapshot.data?.docs ?? [];

              final filteredDocs =
                  docs.where((doc) {
                final data =
                    doc.data()
                        as Map<String, dynamic>;

                final code =
                    (data['studentCode'] ?? '')
                        .toString()
                        .toLowerCase();

                final name =
                    (data['fullName'] ?? '')
                        .toString()
                        .toLowerCase();

                return code.contains(searchText) ||
                    name.contains(searchText);
              }).toList();

              if (filteredDocs.isEmpty) {
                return const Center(
                  child: Text(
                    'Không tìm thấy sinh viên',
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(
                        label: Text('MSSV'),
                      ),
                      DataColumn(
                        label: Text('Họ tên'),
                      ),
                      DataColumn(
                        label: Text('Email'),
                      ),
                      DataColumn(
                        label: Text('SĐT'),
                      ),
                      DataColumn(
                        label: Text('Lớp'),
                      ),
                      DataColumn(
                        label: Text('Giới tính'),
                      ),
                      DataColumn(
                        label: Text('Thao tác'),
                      ),
                    ],
                    rows:
                        filteredDocs.map((doc) {
                      final data =
                          doc.data()
                              as Map<
                                  String,
                                  dynamic>;

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              data['studentCode'] ??
                                  '',
                            ),
                          ),
                          DataCell(
                            Text(
                              data['fullName'] ??
                                  '',
                            ),
                          ),
                          DataCell(
                            Text(
                              data['email'] ?? '',
                            ),
                          ),
                          DataCell(
                            Text(
                              data['phone'] ?? '',
                            ),
                          ),
                          DataCell(
                            Text(
                              data['classId'] ??
                                  '',
                            ),
                          ),
                          DataCell(
                            Text(
                              data['gender'] ??
                                  '',
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  tooltip:
                                      'Cập nhật',
                                  icon: const Icon(
                                    Icons.edit,
                                  ),
                                  onPressed: () {
                                    showStudentDialog(
                                      docId:
                                          doc.id,
                                      student:
                                          data,
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Xóa',
                                  icon: const Icon(
                                    Icons.delete,
                                  ),
                                  onPressed: () {
                                    deleteStudent(
                                      doc.id,
                                      data['fullName'] ??
                                          '',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}