import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _edit(Map<String, dynamic> data) async {
    final nameController = TextEditingController(
      text: data['fullName']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: data['phone']?.toString() ?? '',
    );
    bool loading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();

              if (name.isEmpty) {
                _showMessage('Vui lòng nhập họ tên.');
                return;
              }

              try {
                setDialogState(() => loading = true);
                final uid = _auth.currentUser!.uid;

                await _db.collection('users').doc(uid).set({
                  'fullName': name,
                  'phone': phone,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                final studentId = data['studentId']?.toString() ?? '';
                if (studentId.isNotEmpty) {
                  await _db.collection('students').doc(studentId).set({
                    'fullName': name,
                    'phone': phone,
                  }, SetOptions(merge: true));
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                _showMessage('Cập nhật thông tin thành công.');
              } catch (e) {
                if (dialogContext.mounted) {
                  setDialogState(() => loading = false);
                }
                _showMessage('Không thể cập nhật thông tin: $e');
              }
            }

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.manage_accounts_outlined),
                  SizedBox(width: 10),
                  Text('Cập nhật thông tin'),
                ],
              ),
              content: SizedBox(
                width: 550,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      enabled: !loading,
                      decoration: const InputDecoration(
                        labelText: 'Họ tên',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      enabled: !loading,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                  ],
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

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Chưa đăng nhập'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() ?? {};
        final fullName = data['fullName']?.toString() ?? '';
        final isActive = data['isActive'] is bool
            ? data['isActive'] as bool
            : true;

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
                        'Trang cá nhân',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Thông tin tài khoản và hồ sơ cá nhân',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => _edit(data),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Chỉnh sửa'),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffe5e7eb)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 45,
                      child: Icon(Icons.person_outline, size: 48),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName.isNotEmpty
                                ? fullName
                                : 'Chưa cập nhật họ tên',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _infoRow(
                            Icons.badge_outlined,
                            'MSSV',
                            data['studentCode']?.toString() ?? '-',
                          ),
                          _infoRow(
                            Icons.email_outlined,
                            'Email',
                            data['email']?.toString() ?? user.email ?? '-',
                          ),
                          _infoRow(
                            Icons.phone_outlined,
                            'Số điện thoại',
                            data['phone']?.toString() ?? '-',
                          ),
                          _infoRow(
                            Icons.school_outlined,
                            'Vai trò',
                            data['role'] == 'admin'
                                ? 'Quản trị viên'
                                : 'Sinh viên',
                          ),
                          _infoRow(
                            Icons.toggle_on_outlined,
                            'Trạng thái',
                            isActive ? 'Đang hoạt động' : 'Đã khóa',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
