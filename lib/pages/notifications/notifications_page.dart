import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  final bool isAdmin;

  const NotificationsPage({
    super.key,
    required this.isAdmin,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _audienceLabel(String value) {
    switch (value) {
      case 'student':
        return 'Sinh viên';
      case 'admin':
        return 'Quản trị viên';
      default:
        return 'Tất cả';
    }
  }

  Future<void> _showForm([
    DocumentSnapshot<Map<String, dynamic>>? doc,
  ]) async {
    final data = doc?.data();
    final titleController = TextEditingController(
      text: data?['title']?.toString() ?? '',
    );
    final contentController = TextEditingController(
      text: data?['content']?.toString() ?? '',
    );
    String audience = data?['audience']?.toString() ?? 'all';
    bool loading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              final title = titleController.text.trim();
              final content = contentController.text.trim();

              if (title.isEmpty) {
                _showMessage('Vui lòng nhập tiêu đề thông báo.');
                return;
              }
              if (content.isEmpty) {
                _showMessage('Vui lòng nhập nội dung thông báo.');
                return;
              }

              try {
                setDialogState(() => loading = true);

                final payload = <String, dynamic>{
                  'title': title,
                  'content': content,
                  'audience': audience,
                  'updatedAt': FieldValue.serverTimestamp(),
                  'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
                };

                if (doc == null) {
                  payload['createdAt'] = FieldValue.serverTimestamp();
                  await _db.collection('notifications').add(payload);
                } else {
                  await doc.reference.update(payload);
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                _showMessage(
                  doc == null
                      ? 'Tạo thông báo thành công.'
                      : 'Cập nhật thông báo thành công.',
                );
              } catch (e) {
                if (dialogContext.mounted) {
                  setDialogState(() => loading = false);
                }
                _showMessage('Có lỗi xảy ra: $e');
              }
            }

            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    doc == null
                        ? Icons.add_alert_outlined
                        : Icons.edit_notifications_outlined,
                  ),
                  const SizedBox(width: 10),
                  Text(doc == null ? 'Tạo thông báo' : 'Cập nhật thông báo'),
                ],
              ),
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        enabled: !loading,
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề',
                          prefixIcon: Icon(Icons.title_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: contentController,
                        enabled: !loading,
                        minLines: 5,
                        maxLines: 7,
                        decoration: const InputDecoration(
                          labelText: 'Nội dung',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 100),
                            child: Icon(Icons.notes_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: audience,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Đối tượng',
                          prefixIcon: Icon(Icons.groups_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Tất cả'),
                          ),
                          DropdownMenuItem(
                            value: 'student',
                            child: Text('Sinh viên'),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Quản trị viên'),
                          ),
                        ],
                        onChanged: loading
                            ? null
                            : (value) {
                                setDialogState(() {
                                  audience = value ?? 'all';
                                });
                              },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton.icon(
                  onPressed: loading ? null : save,
                  icon: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(loading ? 'Đang lưu...' : 'Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteNotification(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final title = doc.data()?['title']?.toString() ?? 'thông báo này';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text('Xóa thông báo'),
            ],
          ),
          content: Text('Bạn có chắc muốn xóa "$title" không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await doc.reference.delete();
      _showMessage('Xóa thông báo thành công.');
    } catch (e) {
      _showMessage('Không thể xóa thông báo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông báo',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Thông tin và thông báo học vụ',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              if (widget.isAdmin)
                FilledButton.icon(
                  onPressed: () => _showForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo thông báo'),
                ),
            ],
          ),
          const SizedBox(height: 25),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffe5e7eb)),
              ),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _db
                    .collection('notifications')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}'));
                  }

                  final docs = (snapshot.data?.docs ?? []).where((doc) {
                    if (widget.isAdmin) return true;
                    final audience =
                        doc.data()['audience']?.toString() ?? 'all';
                    return audience == 'all' || audience == 'student';
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text('Chưa có thông báo.'));
                  }

                  return SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Tiêu đề')),
                          DataColumn(label: Text('Nội dung')),
                          DataColumn(label: Text('Đối tượng')),
                          DataColumn(label: Text('Ngày tạo')),
                          DataColumn(label: Text('Thao tác')),
                        ],
                        rows: docs.map((doc) {
                          final data = doc.data();
                          final createdAt = data['createdAt'];
                          final date = createdAt is Timestamp
                              ? createdAt.toDate()
                              : null;
                          final dateText = date == null
                              ? '-'
                              : '${date.day.toString().padLeft(2, '0')}/'
                                  '${date.month.toString().padLeft(2, '0')}/'
                                  '${date.year}';

                          return DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    data['title']?.toString() ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 360,
                                  child: Text(
                                    data['content']?.toString() ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(Text(_audienceLabel(
                                data['audience']?.toString() ?? 'all',
                              ))),
                              DataCell(Text(dateText)),
                              DataCell(
                                widget.isAdmin
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Sửa thông báo',
                                            onPressed: () => _showForm(doc),
                                            icon: const Icon(Icons.edit_outlined),
                                          ),
                                          IconButton(
                                            tooltip: 'Xóa thông báo',
                                            onPressed: () =>
                                                _deleteNotification(doc),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
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
          ),
        ],
      ),
    );
  }
}
