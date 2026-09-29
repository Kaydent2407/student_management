import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() =>
      _SubjectsPageState();
}

class _SubjectsPageState
    extends State<SubjectsPage> {
  final FirestoreService service =
      FirestoreService();

  void showSubjectDialog({
    String? id,
    Map<String, dynamic>? data,
  }) {
    final codeController =
        TextEditingController(
      text: data?['subjectCode'] ?? '',
    );

    final nameController =
        TextEditingController(
      text: data?['subjectName'] ?? '',
    );

    final creditController =
        TextEditingController(
      text: data?['credits']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            id == null
                ? 'Thêm môn học'
                : 'Cập nhật môn học',
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration:
                      const InputDecoration(
                    labelText: 'Mã môn',
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(
                    labelText: 'Tên môn',
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller:
                      creditController,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                    labelText: 'Số tín chỉ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                final credits = int.tryParse(
                      creditController.text,
                    ) ??
                    0;

                final subject = {
                  'subjectCode':
                      codeController.text
                          .trim(),
                  'subjectName':
                      nameController.text
                          .trim(),
                  'credits': credits,
                };

                if (id == null) {
                  await service
                      .addSubject(subject);
                } else {
                  await service
                      .updateSubject(
                    id,
                    subject,
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quản lý môn học',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Danh sách môn học',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              FilledButton.icon(
                onPressed: () {
                  showSubjectDialog();
                },
                icon: const Icon(Icons.add),
                label:
                    const Text('Thêm môn'),
              ),
            ],
          ),

          const SizedBox(height: 25),

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream:
                  service.getSubjects(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                return Container(
                  width: double.infinity,
                  color: Colors.white,
                  child:
                      SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(
                          label:
                              Text('Mã môn'),
                        ),
                        DataColumn(
                          label:
                              Text('Tên môn'),
                        ),
                        DataColumn(
                          label:
                              Text('Tín chỉ'),
                        ),
                        DataColumn(
                          label:
                              Text('Thao tác'),
                        ),
                      ],
                      rows: snapshot
                          .data!.docs
                          .map((doc) {
                        final data =
                            doc.data();

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                data['subjectCode'] ??
                                    '',
                              ),
                            ),
                            DataCell(
                              Text(
                                data['subjectName'] ??
                                    '',
                              ),
                            ),
                            DataCell(
                              Text(
                                '${data['credits'] ?? 0}',
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      showSubjectDialog(
                                        id: doc.id,
                                        data: data,
                                      );
                                    },
                                    icon:
                                        const Icon(
                                      Icons.edit,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed:
                                        () async {
                                      await service
                                          .deleteSubject(
                                        doc.id,
                                      );
                                    },
                                    icon:
                                        const Icon(
                                      Icons.delete,
                                      color:
                                          Colors.red,
                                    ),
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
      ),
    );
  }
}