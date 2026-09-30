import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/audit_log_service.dart';

class AcademicRulesPage extends StatefulWidget {
  const AcademicRulesPage({super.key});

  @override
  State<AcademicRulesPage> createState() => _AcademicRulesPageState();
}

class _AcademicRulesPageState extends State<AcademicRulesPage> {
  final _db = FirebaseFirestore.instance;
  final _maxCredits = TextEditingController(text: '24');
  bool _loadingSettings = true;
  bool _savingSettings = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await _db.collection('academic_settings').doc('general').get();
    if (!mounted) return;
    setState(() {
      _maxCredits.text = '${doc.data()?['maxCreditsPerSemester'] ?? 24}';
      _loadingSettings = false;
    });
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _saveSettings() async {
    final value = int.tryParse(_maxCredits.text.trim()) ?? 0;
    if (value <= 0 || value > 60) {
      _message('Số tín chỉ tối đa phải từ 1 đến 60.');
      return;
    }
    setState(() => _savingSettings = true);
    await _db.collection('academic_settings').doc('general').set({
      'maxCreditsPerSemester': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await AuditLogService.log(
      action: 'update',
      module: 'academic_rules',
      targetId: 'general',
      description: 'Cập nhật giới hạn tín chỉ mỗi học kỳ: $value',
      details: {'maxCreditsPerSemester': value},
    );
    if (mounted) setState(() => _savingSettings = false);
    _message('Đã lưu quy định học vụ.');
  }

  Future<void> _editPrerequisites(
    QueryDocumentSnapshot<Map<String, dynamic>> subject,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> allSubjects,
  ) async {
    final data = subject.data();
    final selected = Set<String>.from(
      (data['prerequisiteIds'] as List? ?? const []).map((e) => e.toString()),
    );
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Icon(Icons.rule_folder_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Môn tiên quyết - ${data['subjectCode'] ?? ''}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 600,
              height: 420,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['subjectName']?.toString() ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  const Text('Sinh viên phải đạt các môn được chọn trước khi đăng ký môn này.'),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: allSubjects
                          .where((item) => item.id != subject.id)
                          .map((item) {
                        final d = item.data();
                        return CheckboxListTile(
                          value: selected.contains(item.id),
                          dense: true,
                          title: Text('${d['subjectCode'] ?? ''} - ${d['subjectName'] ?? ''}'),
                          subtitle: Text('${d['credits'] ?? 0} tín chỉ'),
                          onChanged: saving
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      selected.add(item.id);
                                    } else {
                                      selected.remove(item.id);
                                    }
                                  });
                                },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Hủy'),
              ),
              FilledButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        setDialogState(() => saving = true);
                        final names = <String>[];
                        for (final id in selected) {
                          final item = allSubjects.where((x) => x.id == id).firstOrNull;
                          if (item != null) names.add(item.data()['subjectCode']?.toString() ?? '');
                        }
                        await subject.reference.update({
                          'prerequisiteIds': selected.toList(),
                          'prerequisiteCodes': names,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        await AuditLogService.log(
                          action: 'update_prerequisites',
                          module: 'subjects',
                          targetId: subject.id,
                          description: 'Cập nhật môn tiên quyết cho ${data['subjectCode'] ?? ''}',
                          details: {'prerequisiteIds': selected.toList(), 'prerequisiteCodes': names},
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        _message('Đã cập nhật môn tiên quyết.');
                      },
                icon: saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? 'Đang lưu...' : 'Lưu'),
              ),
            ],
          );
        },
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
          const Text('Quy định học vụ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text('Giới hạn tín chỉ và cấu hình môn tiên quyết', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffe5e7eb)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_outlined, size: 28),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Số tín chỉ tối đa / học kỳ', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Hệ thống sẽ chặn đăng ký khi tổng tín chỉ vượt mức này.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _maxCredits,
                    enabled: !_loadingSettings && !_savingSettings,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(suffixText: 'TC'),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _loadingSettings || _savingSettings ? null : _saveSettings,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Lưu'),
                ),
              ],
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
                stream: _db.collection('subjects').orderBy('subjectCode').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text('Chưa có môn học.'));
                  return SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Mã môn')),
                          DataColumn(label: Text('Tên môn')),
                          DataColumn(label: Text('Tín chỉ')),
                          DataColumn(label: Text('Môn tiên quyết')),
                          DataColumn(label: Text('Thao tác')),
                        ],
                        rows: docs.map((doc) {
                          final d = doc.data();
                          final codes = (d['prerequisiteCodes'] as List? ?? const []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
                          return DataRow(cells: [
                            DataCell(Text(d['subjectCode']?.toString() ?? '')),
                            DataCell(Text(d['subjectName']?.toString() ?? '')),
                            DataCell(Text('${d['credits'] ?? 0}')),
                            DataCell(Text(codes.isEmpty ? 'Không có' : codes.join(', '))),
                            DataCell(OutlinedButton.icon(
                              onPressed: () => _editPrerequisites(doc, docs),
                              icon: const Icon(Icons.rule_outlined, size: 18),
                              label: const Text('Thiết lập'),
                            )),
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
    _maxCredits.dispose();
    super.dispose();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}
