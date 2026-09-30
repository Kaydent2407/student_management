import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/audit_log_service.dart';

class PaymentHistoryPage extends StatefulWidget {
  final bool isAdmin;

  const PaymentHistoryPage({
    super.key,
    required this.isAdmin,
  });

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final _db = FirebaseFirestore.instance;
  final _search = TextEditingController();
  String _keyword = '';

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  String _money(num? value) {
    final number = (value ?? 0).round().toString();
    final chars = number.split('').reversed.toList();
    final parts = <String>[];
    for (var i = 0; i < chars.length; i += 3) {
      parts.add(chars.skip(i).take(3).toList().reversed.join());
    }
    return '${parts.reversed.join('.')} đ';
  }

  String _date(dynamic value) {
    if (value is! Timestamp) return '-';
    final d = value.toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<String> _currentStudentId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data()?['studentId']?.toString() ?? '';
  }

  Future<void> _showAddPayment() async {
    final tuitionSnap = await _db.collection('tuition').get();
    if (!mounted) return;
    if (tuitionSnap.docs.isEmpty) {
      _message('Chưa có hồ sơ học phí để ghi nhận thanh toán.');
      return;
    }

    String tuitionId = tuitionSnap.docs.first.id;
    final amount = TextEditingController();
    final transaction = TextEditingController();
    String method = 'bank_transfer';
    String status = 'success';
    bool loading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> save() async {
            final paymentAmount = double.tryParse(amount.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
            if (paymentAmount <= 0) {
              _message('Số tiền thanh toán phải lớn hơn 0.');
              return;
            }

            final tuitionDoc = tuitionSnap.docs.firstWhere((x) => x.id == tuitionId);
            final tuition = tuitionDoc.data();
            final total = (tuition['totalAmount'] as num? ?? 0).toDouble();
            final paid = (tuition['paidAmount'] as num? ?? 0).toDouble();
            if (status == 'success' && paid + paymentAmount > total) {
              _message('Số tiền thanh toán vượt quá số học phí còn lại.');
              return;
            }

            try {
              setDialogState(() => loading = true);
              final batch = _db.batch();
              final paymentRef = _db.collection('tuition_payments').doc();
              batch.set(paymentRef, {
                'tuitionId': tuitionId,
                'studentId': tuition['studentId'] ?? '',
                'studentCode': tuition['studentCode'] ?? '',
                'studentName': tuition['studentName'] ?? '',
                'semesterCode': tuition['semesterCode'] ?? '',
                'semesterName': tuition['semesterName'] ?? '',
                'amount': paymentAmount,
                'method': method,
                'transactionCode': transaction.text.trim(),
                'status': status,
                'paidAt': FieldValue.serverTimestamp(),
                'createdAt': FieldValue.serverTimestamp(),
                'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
              });

              if (status == 'success') {
                final newPaid = paid + paymentAmount;
                final remaining = (total - newPaid).clamp(0, double.infinity);
                batch.update(tuitionDoc.reference, {
                  'paidAmount': newPaid,
                  'remainingAmount': remaining,
                  'status': remaining <= 0 ? 'paid' : 'partial',
                  'updatedAt': FieldValue.serverTimestamp(),
                  'lastPaidAt': FieldValue.serverTimestamp(),
                });
              }
              await batch.commit();
              await AuditLogService.log(
                action: 'create_payment',
                module: 'tuition',
                targetId: paymentRef.id,
                description: 'Ghi nhận thanh toán học phí ${tuition['studentCode'] ?? ''}',
                details: {
                  'tuitionId': tuitionId,
                  'amount': paymentAmount,
                  'method': method,
                  'status': status,
                },
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              _message('Đã ghi nhận giao dịch học phí.');
            } catch (e) {
              if (dialogContext.mounted) setDialogState(() => loading = false);
              _message('Không thể lưu giao dịch: $e');
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.receipt_long_outlined),
                SizedBox(width: 10),
                Text('Ghi nhận thanh toán'),
              ],
            ),
            content: SizedBox(
              width: 620,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: tuitionId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Hồ sơ học phí', prefixIcon: Icon(Icons.school_outlined)),
                      items: tuitionSnap.docs.map((item) {
                        final d = item.data();
                        return DropdownMenuItem(
                          value: item.id,
                          child: Text('${d['studentCode'] ?? ''} - ${d['studentName'] ?? ''} • ${d['semesterName'] ?? ''}'),
                        );
                      }).toList(),
                      onChanged: loading ? null : (value) => setDialogState(() => tuitionId = value ?? tuitionId),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: amount,
                      enabled: !loading,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Số tiền', prefixIcon: Icon(Icons.payments_outlined), suffixText: 'đ'),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: method,
                      decoration: const InputDecoration(labelText: 'Phương thức', prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Tiền mặt')),
                        DropdownMenuItem(value: 'bank_transfer', child: Text('Chuyển khoản')),
                        DropdownMenuItem(value: 'mock', child: Text('Thanh toán demo')),
                        DropdownMenuItem(value: 'other', child: Text('Khác')),
                      ],
                      onChanged: loading ? null : (value) => setDialogState(() => method = value ?? method),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: transaction,
                      enabled: !loading,
                      decoration: const InputDecoration(labelText: 'Mã giao dịch', prefixIcon: Icon(Icons.confirmation_number_outlined)),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Trạng thái', prefixIcon: Icon(Icons.verified_outlined)),
                      items: const [
                        DropdownMenuItem(value: 'success', child: Text('Thành công')),
                        DropdownMenuItem(value: 'pending', child: Text('Đang xử lý')),
                        DropdownMenuItem(value: 'failed', child: Text('Thất bại')),
                      ],
                      onChanged: loading ? null : (value) => setDialogState(() => status = value ?? status),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: loading ? null : () => Navigator.pop(dialogContext), child: const Text('Hủy')),
              FilledButton.icon(
                onPressed: loading ? null : save,
                icon: loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(loading ? 'Đang lưu...' : 'Lưu giao dịch'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _method(String value) {
    switch (value) {
      case 'cash':
        return 'Tiền mặt';
      case 'bank_transfer':
        return 'Chuyển khoản';
      case 'mock':
        return 'Demo';
      default:
        return 'Khác';
    }
  }

  String _status(String value) {
    switch (value) {
      case 'success':
        return 'Thành công';
      case 'pending':
        return 'Đang xử lý';
      case 'failed':
        return 'Thất bại';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: widget.isAdmin ? Future.value('') : _currentStudentId(),
      builder: (context, studentSnapshot) {
        if (!widget.isAdmin && studentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final studentId = studentSnapshot.data ?? '';
        return Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.isAdmin ? 'Lịch sử thanh toán' : 'Lịch sử học phí', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(widget.isAdmin ? 'Theo dõi các giao dịch học phí' : 'Các lần thanh toán học phí của bạn', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  if (widget.isAdmin)
                    FilledButton.icon(onPressed: _showAddPayment, icon: const Icon(Icons.add_card_outlined), label: const Text('Ghi nhận thanh toán')),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 470,
                child: TextField(
                  controller: _search,
                  onChanged: (value) => setState(() => _keyword = value.trim().toLowerCase()),
                  decoration: const InputDecoration(hintText: 'Tìm MSSV, sinh viên, học kỳ, mã giao dịch...', prefixIcon: Icon(Icons.search)),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xffe5e7eb))),
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: widget.isAdmin
                        ? _db.collection('tuition_payments').orderBy('createdAt', descending: true).snapshots()
                        : _db.collection('tuition_payments').where('studentId', isEqualTo: studentId).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final docs = snapshot.data!.docs.where((doc) {
                        final d = doc.data();
                        final text = '${d['studentCode'] ?? ''} ${d['studentName'] ?? ''} ${d['semesterName'] ?? ''} ${d['transactionCode'] ?? ''}'.toLowerCase();
                        return _keyword.isEmpty || text.contains(_keyword);
                      }).toList()
                        ..sort((a, b) {
                          final aDate = a.data()['createdAt'] as Timestamp?;
                          final bDate = b.data()['createdAt'] as Timestamp?;
                          return (bDate?.millisecondsSinceEpoch ?? 0).compareTo(aDate?.millisecondsSinceEpoch ?? 0);
                        });
                      if (docs.isEmpty) return const Center(child: Text('Chưa có giao dịch học phí.'));
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            if (widget.isAdmin) const DataColumn(label: Text('Sinh viên')),
                            const DataColumn(label: Text('Học kỳ')),
                            const DataColumn(label: Text('Số tiền')),
                            const DataColumn(label: Text('Phương thức')),
                            const DataColumn(label: Text('Mã giao dịch')),
                            const DataColumn(label: Text('Trạng thái')),
                            const DataColumn(label: Text('Thời gian')),
                          ],
                          rows: docs.map((doc) {
                            final d = doc.data();
                            return DataRow(cells: [
                              if (widget.isAdmin) DataCell(Text('${d['studentCode'] ?? ''} - ${d['studentName'] ?? ''}')),
                              DataCell(Text(d['semesterName']?.toString() ?? '-')),
                              DataCell(Text(_money(d['amount'] as num?))),
                              DataCell(Text(_method(d['method']?.toString() ?? 'other'))),
                              DataCell(Text(d['transactionCode']?.toString().isNotEmpty == true ? d['transactionCode'].toString() : '-')),
                              DataCell(Chip(label: Text(_status(d['status']?.toString() ?? 'success')))),
                              DataCell(Text(_date(d['paidAt'] ?? d['createdAt']))),
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
      },
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }
}
