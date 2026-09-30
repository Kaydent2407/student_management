import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/audit_log_service.dart';

class RoomsPage extends StatefulWidget {
  const RoomsPage({super.key});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  final _db = FirebaseFirestore.instance;
  final _search = TextEditingController();
  String _keyword = '';

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _showForm([
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  ]) async {
    final data = doc?.data();
    final code = TextEditingController(text: data?['roomCode']?.toString() ?? '');
    final name = TextEditingController(text: data?['roomName']?.toString() ?? '');
    final capacity = TextEditingController(text: data?['capacity']?.toString() ?? '40');
    final location = TextEditingController(text: data?['location']?.toString() ?? '');
    bool active = data?['isActive'] as bool? ?? true;
    bool loading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> save() async {
            final roomCode = code.text.trim().toUpperCase();
            final roomName = name.text.trim();
            final roomCapacity = int.tryParse(capacity.text.trim()) ?? 0;
            if (roomCode.isEmpty) {
              _message('Vui lòng nhập mã phòng.');
              return;
            }
            if (roomCapacity <= 0) {
              _message('Sức chứa phải lớn hơn 0.');
              return;
            }

            final duplicate = await _db
                .collection('rooms')
                .where('roomCode', isEqualTo: roomCode)
                .get();
            if (duplicate.docs.any((item) => item.id != doc?.id)) {
              _message('Mã phòng đã tồn tại.');
              return;
            }

            try {
              setDialogState(() => loading = true);
              final payload = <String, dynamic>{
                'roomCode': roomCode,
                'roomName': roomName,
                'capacity': roomCapacity,
                'location': location.text.trim(),
                'isActive': active,
                'updatedAt': FieldValue.serverTimestamp(),
              };
              String targetId;
              if (doc == null) {
                payload['createdAt'] = FieldValue.serverTimestamp();
                final ref = await _db.collection('rooms').add(payload);
                targetId = ref.id;
              } else {
                await doc.reference.update(payload);
                targetId = doc.id;
              }
              await AuditLogService.log(
                action: doc == null ? 'create' : 'update',
                module: 'rooms',
                targetId: targetId,
                description: '${doc == null ? 'Tạo' : 'Cập nhật'} phòng $roomCode',
                details: payload,
              );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              _message(doc == null ? 'Thêm phòng thành công.' : 'Cập nhật phòng thành công.');
            } catch (e) {
              if (dialogContext.mounted) setDialogState(() => loading = false);
              _message('Không thể lưu phòng: $e');
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Icon(Icons.meeting_room_outlined),
                const SizedBox(width: 10),
                Text(doc == null ? 'Thêm phòng học' : 'Cập nhật phòng học'),
              ],
            ),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: code,
                      enabled: !loading,
                      decoration: const InputDecoration(
                        labelText: 'Mã phòng',
                        prefixIcon: Icon(Icons.tag_outlined),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: name,
                      enabled: !loading,
                      decoration: const InputDecoration(
                        labelText: 'Tên phòng',
                        prefixIcon: Icon(Icons.meeting_room_outlined),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: capacity,
                      enabled: !loading,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sức chứa',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: location,
                      enabled: !loading,
                      decoration: const InputDecoration(
                        labelText: 'Vị trí / cơ sở',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Đang sử dụng'),
                      value: active,
                      onChanged: loading ? null : (value) => setDialogState(() => active = value),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Hủy'),
              ),
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

  Future<void> _delete(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data();
    final code = data['roomCode']?.toString() ?? '';
    final inUse = await _db.collection('course_sections').where('roomId', isEqualTo: doc.id).limit(1).get();
    if (inUse.docs.isNotEmpty) {
      _message('Phòng đang được dùng trong lớp học phần, không thể xóa.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa phòng học'),
        content: Text('Bạn có chắc muốn xóa phòng "$code"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await doc.reference.delete();
    await AuditLogService.log(
      action: 'delete',
      module: 'rooms',
      targetId: doc.id,
      description: 'Xóa phòng $code',
    );
    _message('Đã xóa phòng.');
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
                  Text('Quản lý phòng học', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text('Danh mục phòng và sức chứa', style: TextStyle(color: Colors.grey)),
                ],
              ),
              FilledButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add),
                label: const Text('Thêm phòng'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: 430,
            child: TextField(
              controller: _search,
              onChanged: (value) => setState(() => _keyword = value.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Tìm mã phòng, tên phòng, vị trí...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffe5e7eb)),
              ),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _db.collection('rooms').orderBy('roomCode').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs.where((doc) {
                    final d = doc.data();
                    final text = '${d['roomCode'] ?? ''} ${d['roomName'] ?? ''} ${d['location'] ?? ''}'.toLowerCase();
                    return _keyword.isEmpty || text.contains(_keyword);
                  }).toList();
                  if (docs.isEmpty) return const Center(child: Text('Chưa có phòng học.'));
                  return SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Mã phòng')),
                          DataColumn(label: Text('Tên phòng')),
                          DataColumn(label: Text('Sức chứa')),
                          DataColumn(label: Text('Vị trí')),
                          DataColumn(label: Text('Trạng thái')),
                          DataColumn(label: Text('Thao tác')),
                        ],
                        rows: docs.map((doc) {
                          final d = doc.data();
                          final active = d['isActive'] as bool? ?? true;
                          return DataRow(cells: [
                            DataCell(Text(d['roomCode']?.toString() ?? '')),
                            DataCell(Text(d['roomName']?.toString() ?? '-')),
                            DataCell(Text('${d['capacity'] ?? 0}')),
                            DataCell(Text(d['location']?.toString() ?? '-')),
                            DataCell(Chip(label: Text(active ? 'Đang dùng' : 'Tạm ngưng'))),
                            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(tooltip: 'Sửa', onPressed: () => _showForm(doc), icon: const Icon(Icons.edit_outlined)),
                              IconButton(tooltip: 'Xóa', onPressed: () => _delete(doc), icon: const Icon(Icons.delete_outline, color: Colors.red)),
                            ])),
                          ]);
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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }
}
