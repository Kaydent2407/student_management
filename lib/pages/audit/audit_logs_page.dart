import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  final _db = FirebaseFirestore.instance;
  final _search = TextEditingController();
  String _keyword = '';
  String _module = 'all';

  String _formatDate(dynamic value) {
    if (value is! Timestamp) return '-';
    final d = value.toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
  }

  String _actionLabel(String value) {
    switch (value) {
      case 'create':
        return 'Tạo mới';
      case 'update':
        return 'Cập nhật';
      case 'delete':
        return 'Xóa';
      case 'register':
        return 'Đăng ký';
      case 'cancel_registration':
        return 'Hủy đăng ký';
      case 'create_payment':
        return 'Thanh toán';
      case 'change_password':
        return 'Đổi mật khẩu';
      case 'update_prerequisites':
        return 'Môn tiên quyết';
      case 'login':
        return 'Đăng nhập';
      case 'logout':
        return 'Đăng xuất';
      case 'export':
        return 'Xuất dữ liệu';
      case 'import':
        return 'Nhập dữ liệu';
      case 'mark_attendance':
        return 'Điểm danh';
      default:
        return value;
    }
  }

  void _showDetails(Map<String, dynamic> data) {
    final details = data['details'];
    final entries = details is Map
        ? details.entries.map((e) => '${e.key}: ${e.value}').join('\n')
        : '';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.history_outlined),
            SizedBox(width: 10),
            Text('Chi tiết nhật ký'),
          ],
        ),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line('Thời gian', _formatDate(data['createdAt'])),
                _line('Người thực hiện', '${data['actorName'] ?? ''} (${data['actorEmail'] ?? ''})'),
                _line('Vai trò', data['actorRole']?.toString() ?? '-'),
                _line('Hành động', _actionLabel(data['action']?.toString() ?? '')),
                _line('Chức năng', data['module']?.toString() ?? '-'),
                _line('Đối tượng', data['targetId']?.toString().isNotEmpty == true ? data['targetId'].toString() : '-'),
                _line('Mô tả', data['description']?.toString() ?? '-'),
                if (entries.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Dữ liệu liên quan', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xfff8fafc),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(entries),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 135, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nhật ký hệ thống', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text('Theo dõi các thao tác quan trọng trong hệ thống', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 22),
          Row(
            children: [
              SizedBox(
                width: 430,
                child: TextField(
                  controller: _search,
                  onChanged: (value) => setState(() => _keyword = value.trim().toLowerCase()),
                  decoration: const InputDecoration(hintText: 'Tìm người dùng, mô tả, hành động...', prefixIcon: Icon(Icons.search)),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: _module,
                  decoration: const InputDecoration(labelText: 'Chức năng', prefixIcon: Icon(Icons.filter_alt_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'students', child: Text('Sinh viên')),
                    DropdownMenuItem(value: 'classes', child: Text('Lớp học')),
                    DropdownMenuItem(value: 'subjects', child: Text('Môn học')),
                    DropdownMenuItem(value: 'course_sections', child: Text('Lớp học phần')),
                    DropdownMenuItem(value: 'rooms', child: Text('Phòng học')),
                    DropdownMenuItem(value: 'registrations', child: Text('Đăng ký môn')),
                    DropdownMenuItem(value: 'grades', child: Text('Điểm')),
                    DropdownMenuItem(value: 'schedules', child: Text('Lịch học')),
                    DropdownMenuItem(value: 'exam_schedules', child: Text('Lịch thi')),
                    DropdownMenuItem(value: 'tuition', child: Text('Học phí')),
                    DropdownMenuItem(value: 'notifications', child: Text('Thông báo')),
                    DropdownMenuItem(value: 'account', child: Text('Tài khoản')),
                    DropdownMenuItem(value: 'profile', child: Text('Cá nhân')),
                    DropdownMenuItem(value: 'academic_rules', child: Text('Quy định học vụ')),
                    DropdownMenuItem(value: 'departments', child: Text('Khoa')),
                    DropdownMenuItem(value: 'majors', child: Text('Chuyên ngành')),
                    DropdownMenuItem(value: 'attendance', child: Text('Điểm danh')),
                    DropdownMenuItem(value: 'reports', child: Text('Báo cáo')),
                  ],
                  onChanged: (value) => setState(() => _module = value ?? 'all'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xffe5e7eb))),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _db.collection('audit_logs').orderBy('createdAt', descending: true).limit(500).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs.where((doc) {
                    final d = doc.data();
                    if (_module != 'all' && d['module']?.toString() != _module) return false;
                    final text = '${d['actorName'] ?? ''} ${d['actorEmail'] ?? ''} ${d['action'] ?? ''} ${d['module'] ?? ''} ${d['description'] ?? ''}'.toLowerCase();
                    return _keyword.isEmpty || text.contains(_keyword);
                  }).toList();
                  if (docs.isEmpty) return const Center(child: Text('Chưa có nhật ký phù hợp.'));
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Thời gian')),
                        DataColumn(label: Text('Người thực hiện')),
                        DataColumn(label: Text('Vai trò')),
                        DataColumn(label: Text('Hành động')),
                        DataColumn(label: Text('Chức năng')),
                        DataColumn(label: Text('Mô tả')),
                        DataColumn(label: Text('Chi tiết')),
                      ],
                      rows: docs.map((doc) {
                        final d = doc.data();
                        return DataRow(cells: [
                          DataCell(Text(_formatDate(d['createdAt']))),
                          DataCell(SizedBox(width: 190, child: Text(d['actorName']?.toString().isNotEmpty == true ? d['actorName'].toString() : (d['actorEmail']?.toString() ?? '-'), overflow: TextOverflow.ellipsis))),
                          DataCell(Text(d['actorRole']?.toString() ?? '-')),
                          DataCell(Chip(label: Text(_actionLabel(d['action']?.toString() ?? '')))),
                          DataCell(Text(d['module']?.toString() ?? '-')),
                          DataCell(SizedBox(width: 300, child: Text(d['description']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis))),
                          DataCell(IconButton(tooltip: 'Xem chi tiết', onPressed: () => _showDetails(d), icon: const Icon(Icons.visibility_outlined))),
                        ]);
                      }).toList(),
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
