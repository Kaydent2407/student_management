import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/audit_log_service.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  bool _isVisibleForRole(Map<String, dynamic> data) {
    final audience = data['audience']?.toString() ?? 'all';
    if (widget.isAdmin) return audience == 'all' || audience == 'admin';
    return audience == 'all' || audience == 'student';
  }

  Future<void> _markRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('notification_reads').doc('${user.uid}_$notificationId').set({
      'userId': user.uid,
      'notificationId': notificationId,
      'readAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _markAllRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final batch = _db.batch();
    for (final doc in docs) {
      final ref = _db.collection('notification_reads').doc('${user.uid}_${doc.id}');
      batch.set(ref, {
        'userId': user.uid,
        'notificationId': doc.id,
        'readAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
    _showMessage('Đã đánh dấu tất cả thông báo là đã đọc.');
  }

  Future<void> _showDetail(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    await _markRead(doc.id);
    if (!mounted) return;
    final data = doc.data();
    final createdAt = data['createdAt'];
    final date = createdAt is Timestamp ? createdAt.toDate() : null;
    final dateText = date == null
        ? '-'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.notifications_active_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                data['title']?.toString() ?? 'Thông báo',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(label: Text(_audienceLabel(data['audience']?.toString() ?? 'all'))),
                    const SizedBox(width: 8),
                    Text(dateText, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                SelectableText(
                  data['content']?.toString() ?? '',
                  style: const TextStyle(fontSize: 15, height: 1.55),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Future<void> _showForm([
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  ]) async {
    final data = doc?.data();
    final titleController = TextEditingController(text: data?['title']?.toString() ?? '');
    final contentController = TextEditingController(text: data?['content']?.toString() ?? '');
    String audience = data?['audience']?.toString() ?? 'all';
    bool loading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
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
                'createdBy': _auth.currentUser?.uid ?? '',
              };
              String targetId;
              if (doc == null) {
                payload['createdAt'] = FieldValue.serverTimestamp();
                final ref = await _db.collection('notifications').add(payload);
                targetId = ref.id;
              } else {
                await doc.reference.update(payload);
                targetId = doc.id;
              }
              await AuditLogService.log(
                action: doc == null ? 'create' : 'update',
                module: 'notifications',
                targetId: targetId,
                description: '${doc == null ? 'Tạo' : 'Cập nhật'} thông báo: $title',
                details: {'audience': audience},
              );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              _showMessage(doc == null ? 'Tạo thông báo thành công.' : 'Cập nhật thông báo thành công.');
            } catch (e) {
              if (dialogContext.mounted) setDialogState(() => loading = false);
              _showMessage('Có lỗi xảy ra: $e');
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                Icon(doc == null ? Icons.add_alert_outlined : Icons.edit_notifications_outlined),
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
                      decoration: const InputDecoration(labelText: 'Tiêu đề', prefixIcon: Icon(Icons.title_outlined)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      enabled: !loading,
                      minLines: 5,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Nội dung',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 105),
                          child: Icon(Icons.notes_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: audience,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Đối tượng', prefixIcon: Icon(Icons.groups_outlined)),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                        DropdownMenuItem(value: 'student', child: Text('Sinh viên')),
                        DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
                      ],
                      onChanged: loading ? null : (value) => setDialogState(() => audience = value ?? 'all'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: loading ? null : () => Navigator.of(dialogContext).pop(), child: const Text('Hủy')),
              FilledButton.icon(
                onPressed: loading ? null : save,
                icon: loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(loading ? 'Đang lưu...' : 'Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteNotification(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final title = doc.data()['title']?.toString() ?? 'thông báo này';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Xóa thông báo'),
          ],
        ),
        content: Text('Bạn có chắc muốn xóa "$title" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await doc.reference.delete();
      await AuditLogService.log(
        action: 'delete',
        module: 'notifications',
        targetId: doc.id,
        description: 'Xóa thông báo: $title',
      );
      _showMessage('Xóa thông báo thành công.');
    } catch (e) {
      _showMessage('Không thể xóa thông báo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text('Chưa đăng nhập.'));

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
                  Text('Thông báo', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text('Thông tin và thông báo học vụ', style: TextStyle(color: Colors.grey)),
                ],
              ),
              if (widget.isAdmin)
                FilledButton.icon(onPressed: () => _showForm(), icon: const Icon(Icons.add), label: const Text('Tạo thông báo')),
            ],
          ),
          const SizedBox(height: 25),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db.collection('notifications').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, notificationSnapshot) {
                if (!notificationSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = notificationSnapshot.data!.docs.where((doc) => _isVisibleForRole(doc.data())).toList();

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _db.collection('notification_reads').where('userId', isEqualTo: user.uid).snapshots(),
                  builder: (context, readSnapshot) {
                    final readIds = (readSnapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                        .map((doc) => doc.data()['notificationId']?.toString() ?? '')
                        .where((id) => id.isNotEmpty)
                        .toSet();
                    final unread = docs.where((doc) => !readIds.contains(doc.id)).length;

                    return Column(
                      children: [
                        Row(
                          children: [
                            Chip(
                              avatar: const Icon(Icons.mark_email_unread_outlined, size: 18),
                              label: Text('$unread chưa đọc'),
                            ),
                            const SizedBox(width: 10),
                            if (unread > 0)
                              TextButton.icon(
                                onPressed: () => _markAllRead(docs),
                                icon: const Icon(Icons.done_all_outlined),
                                label: const Text('Đánh dấu tất cả đã đọc'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xffe5e7eb)),
                            ),
                            child: docs.isEmpty
                                ? const Center(child: Text('Chưa có thông báo.'))
                                : SingleChildScrollView(
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: DataTable(
                                        columns: const [
                                          DataColumn(label: Text('')),
                                          DataColumn(label: Text('Tiêu đề')),
                                          DataColumn(label: Text('Nội dung')),
                                          DataColumn(label: Text('Đối tượng')),
                                          DataColumn(label: Text('Ngày tạo')),
                                          DataColumn(label: Text('Thao tác')),
                                        ],
                                        rows: docs.map((doc) {
                                          final data = doc.data();
                                          final isRead = readIds.contains(doc.id);
                                          final createdAt = data['createdAt'];
                                          final date = createdAt is Timestamp ? createdAt.toDate() : null;
                                          final dateText = date == null
                                              ? '-'
                                              : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                                          return DataRow(
                                            color: WidgetStatePropertyAll(isRead ? Colors.white : const Color(0xfff5f7ff)),
                                            cells: [
                                              DataCell(Icon(isRead ? Icons.drafts_outlined : Icons.mark_email_unread_outlined, color: isRead ? Colors.grey : const Color(0xff4f46e5))),
                                              DataCell(
                                                SizedBox(
                                                  width: 180,
                                                  child: Text(
                                                    data['title']?.toString() ?? '',
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(fontWeight: isRead ? FontWeight.w500 : FontWeight.w700),
                                                  ),
                                                ),
                                                onTap: () => _showDetail(doc),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 330,
                                                  child: Text(data['content']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                                                ),
                                                onTap: () => _showDetail(doc),
                                              ),
                                              DataCell(Text(_audienceLabel(data['audience']?.toString() ?? 'all'))),
                                              DataCell(Text(dateText)),
                                              DataCell(
                                                widget.isAdmin
                                                    ? Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          IconButton(tooltip: 'Xem', onPressed: () => _showDetail(doc), icon: const Icon(Icons.visibility_outlined)),
                                                          IconButton(tooltip: 'Sửa', onPressed: () => _showForm(doc), icon: const Icon(Icons.edit_outlined)),
                                                          IconButton(tooltip: 'Xóa', onPressed: () => _deleteNotification(doc), icon: const Icon(Icons.delete_outline, color: Colors.red)),
                                                        ],
                                                      )
                                                    : IconButton(tooltip: 'Xem', onPressed: () => _showDetail(doc), icon: const Icon(Icons.visibility_outlined)),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
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
