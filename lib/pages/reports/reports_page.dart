// ignore_for_file: deprecated_member_use
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../services/audit_log_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _db = FirebaseFirestore.instance;
  bool _exporting = false;
  bool _importing = false;

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<int> _count(String collection) async {
    final snapshot = await _db.collection(collection).get();
    return snapshot.docs.length;
  }

  String _cellText(Data? cell) => cell?.value?.toString().trim() ?? '';

  void _downloadBytes(List<int> bytes, String fileName, String mime) {
    final blob = html.Blob([bytes], mime);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _exportExcel() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final results = await Future.wait([
        _db.collection('students').get(),
        _db.collection('classes').get(),
        _db.collection('subjects').get(),
        _db.collection('registrations').get(),
        _db.collection('grades').get(),
        _db.collection('attendance').get(),
        _db.collection('tuition').get(),
      ]);

      final book = Excel.createExcel();
      final studentSheet = book['Sinh vien'];
      studentSheet.appendRow([
        TextCellValue('MSSV'),
        TextCellValue('Ho ten'),
        TextCellValue('Email'),
        TextCellValue('So dien thoai'),
        TextCellValue('Lop'),
        TextCellValue('Chuyen nganh'),
      ]);
      for (final raw in results[0].docs) {
        final d = raw.data();
        studentSheet.appendRow([
          TextCellValue(d['studentCode']?.toString() ?? ''),
          TextCellValue(d['fullName']?.toString() ?? ''),
          TextCellValue(d['email']?.toString() ?? ''),
          TextCellValue(d['phone']?.toString() ?? ''),
          TextCellValue(d['className']?.toString() ?? d['classCode']?.toString() ?? ''),
          TextCellValue(d['major']?.toString() ?? ''),
        ]);
      }

      final classSheet = book['Lop hoc'];
      classSheet.appendRow([TextCellValue('Ma lop'), TextCellValue('Ten lop'), TextCellValue('Chuyen nganh'), TextCellValue('Nien khoa')]);
      for (final raw in results[1].docs) {
        final d = raw.data();
        classSheet.appendRow([
          TextCellValue(d['classCode']?.toString() ?? ''),
          TextCellValue(d['className']?.toString() ?? ''),
          TextCellValue(d['major']?.toString() ?? ''),
          TextCellValue(d['academicYear']?.toString() ?? ''),
        ]);
      }

      final subjectSheet = book['Mon hoc'];
      subjectSheet.appendRow([TextCellValue('Ma mon'), TextCellValue('Ten mon'), TextCellValue('Tin chi'), TextCellValue('Mon tien quyet')]);
      for (final raw in results[2].docs) {
        final d = raw.data();
        subjectSheet.appendRow([
          TextCellValue(d['subjectCode']?.toString() ?? ''),
          TextCellValue(d['subjectName']?.toString() ?? ''),
          TextCellValue('${d['credits'] ?? 0}'),
          TextCellValue((d['prerequisiteCodes'] as List? ?? const []).join(', ')),
        ]);
      }

      final regSheet = book['Dang ky mon'];
      regSheet.appendRow([
        TextCellValue('MSSV'), TextCellValue('Ho ten'), TextCellValue('Ma mon'), TextCellValue('Mon hoc'),
        TextCellValue('Lop hoc phan'), TextCellValue('Tin chi'), TextCellValue('Hoc ky'),
      ]);
      for (final raw in results[3].docs) {
        final d = raw.data();
        regSheet.appendRow([
          TextCellValue(d['studentCode']?.toString() ?? ''),
          TextCellValue(d['studentName']?.toString() ?? ''),
          TextCellValue(d['subjectCode']?.toString() ?? ''),
          TextCellValue(d['subjectName']?.toString() ?? ''),
          TextCellValue(d['sectionCode']?.toString() ?? ''),
          TextCellValue('${d['credits'] ?? 0}'),
          TextCellValue(d['semesterName']?.toString() ?? ''),
        ]);
      }

      final gradeSheet = book['Bang diem'];
      gradeSheet.appendRow([
        TextCellValue('MSSV'), TextCellValue('Ho ten'), TextCellValue('Ma mon'), TextCellValue('Mon hoc'),
        TextCellValue('Giua ky'), TextCellValue('Cuoi ky'), TextCellValue('Tong ket'), TextCellValue('Diem chu'),
      ]);
      for (final raw in results[4].docs) {
        final d = raw.data();
        gradeSheet.appendRow([
          TextCellValue(d['studentCode']?.toString() ?? ''),
          TextCellValue(d['studentName']?.toString() ?? ''),
          TextCellValue(d['subjectCode']?.toString() ?? ''),
          TextCellValue(d['subjectName']?.toString() ?? ''),
          TextCellValue('${d['midtermScore'] ?? ''}'),
          TextCellValue('${d['finalScore'] ?? ''}'),
          TextCellValue('${d['averageScore'] ?? ''}'),
          TextCellValue(d['letterGrade']?.toString() ?? ''),
        ]);
      }

      final attendanceSheet = book['Diem danh'];
      attendanceSheet.appendRow([
        TextCellValue('MSSV'), TextCellValue('Ho ten'), TextCellValue('Ma mon'), TextCellValue('Mon hoc'), TextCellValue('Ngay'), TextCellValue('Trang thai'),
      ]);
      for (final raw in results[5].docs) {
        final d = raw.data();
        attendanceSheet.appendRow([
          TextCellValue(d['studentCode']?.toString() ?? ''),
          TextCellValue(d['studentName']?.toString() ?? ''),
          TextCellValue(d['subjectCode']?.toString() ?? ''),
          TextCellValue(d['subjectName']?.toString() ?? ''),
          TextCellValue(d['date']?.toString() ?? ''),
          TextCellValue(d['status']?.toString() ?? ''),
        ]);
      }

      final tuitionSheet = book['Hoc phi'];
      tuitionSheet.appendRow([
        TextCellValue('MSSV'), TextCellValue('Ho ten'), TextCellValue('Hoc ky'), TextCellValue('Tong hoc phi'), TextCellValue('Da dong'), TextCellValue('Con lai'), TextCellValue('Trang thai'),
      ]);
      for (final raw in results[6].docs) {
        final d = raw.data();
        tuitionSheet.appendRow([
          TextCellValue(d['studentCode']?.toString() ?? ''),
          TextCellValue(d['studentName']?.toString() ?? ''),
          TextCellValue(d['semesterName']?.toString() ?? ''),
          TextCellValue('${d['totalAmount'] ?? 0}'),
          TextCellValue('${d['paidAmount'] ?? 0}'),
          TextCellValue('${d['remainingAmount'] ?? 0}'),
          TextCellValue(d['status']?.toString() ?? ''),
        ]);
      }

      if (book.tables.containsKey('Sheet1')) book.delete('Sheet1');
      final bytes = book.encode();
      if (bytes == null) throw Exception('Không thể tạo file Excel.');
      final now = DateTime.now();
      _downloadBytes(
        bytes,
        'student_management_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      await AuditLogService.log(action: 'export', module: 'reports', description: 'Xuất báo cáo Excel');
      _message('Đã tạo file Excel.');
    } catch (e) {
      _message('Xuất Excel thất bại: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final results = await Future.wait([
        _db.collection('students').get(),
        _db.collection('classes').get(),
        _db.collection('subjects').get(),
        _db.collection('registrations').get(),
        _db.collection('tuition').get(),
      ]);
      final regular = await PdfGoogleFonts.notoSansRegular();
      final bold = await PdfGoogleFonts.notoSansBold();
      final doc = pw.Document();
      final totalTuition = results[4].docs.fold<double>(0, (sum, item) => sum + (item.data()['totalAmount'] as num? ?? 0).toDouble());
      final totalPaid = results[4].docs.fold<double>(0, (sum, item) => sum + (item.data()['paidAmount'] as num? ?? 0).toDouble());

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: regular, bold: bold),
          build: (context) => [
            pw.Text('BÁO CÁO HỆ THỐNG QUẢN LÝ SINH VIÊN', style: pw.TextStyle(font: bold, fontSize: 18)),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: ['Chỉ số', 'Số lượng / giá trị'],
              data: [
                ['Sinh viên', '${results[0].docs.length}'],
                ['Lớp học', '${results[1].docs.length}'],
                ['Môn học', '${results[2].docs.length}'],
                ['Lượt đăng ký', '${results[3].docs.length}'],
                ['Tổng học phí', totalTuition.toStringAsFixed(0)],
                ['Đã thu', totalPaid.toStringAsFixed(0)],
                ['Còn lại', (totalTuition - totalPaid).toStringAsFixed(0)],
              ],
              headerStyle: pw.TextStyle(font: bold),
            ),
            pw.SizedBox(height: 18),
            pw.Text('Danh sách sinh viên', style: pw.TextStyle(font: bold, fontSize: 14)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['MSSV', 'Họ tên', 'Lớp', 'Chuyên ngành'],
              data: results[0].docs.map((raw) {
                final d = raw.data();
                return [
                  d['studentCode']?.toString() ?? '',
                  d['fullName']?.toString() ?? '',
                  d['className']?.toString() ?? d['classCode']?.toString() ?? '',
                  d['major']?.toString() ?? '',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(font: bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (_) async => doc.save(), name: 'student_management_report.pdf');
      await AuditLogService.log(action: 'export', module: 'reports', description: 'Xuất báo cáo PDF');
      _message('Đã tạo báo cáo PDF.');
    } catch (e) {
      _message('Xuất PDF thất bại: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _importStudents() async {
    if (_importing) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    setState(() => _importing = true);
    try {
      final book = Excel.decodeBytes(result.files.single.bytes!);
      if (book.tables.isEmpty) throw Exception('File Excel không có sheet dữ liệu.');
      final sheet = book.tables.values.first;
      if (sheet.rows.isEmpty) throw Exception('File Excel trống.');

      final headers = sheet.rows.first.map(_cellText).map((e) => e.toLowerCase()).toList();
      int indexOf(List<String> names) {
        for (var i = 0; i < headers.length; i++) {
          if (names.any((name) => headers[i] == name.toLowerCase())) return i;
        }
        return -1;
      }

      final codeIndex = indexOf(['mssv', 'studentcode', 'student code']);
      final nameIndex = indexOf(['họ tên', 'ho ten', 'fullname', 'full name']);
      final emailIndex = indexOf(['email']);
      final phoneIndex = indexOf(['số điện thoại', 'so dien thoai', 'phone']);
      final classIndex = indexOf(['lớp', 'lop', 'classname', 'class']);
      final majorIndex = indexOf(['chuyên ngành', 'chuyen nganh', 'major']);
      if (codeIndex < 0 || nameIndex < 0) {
        throw Exception('File cần tối thiểu 2 cột: MSSV và Họ tên.');
      }

      // Nạp danh mục một lần để khi Excel có Lớp/Chuyên ngành thì
      // hồ sơ sinh viên được liên kết đúng ID, không chỉ lưu tên hiển thị.
      final lookupResults = await Future.wait([
        _db.collection('classes').get(),
        _db.collection('majors').get(),
      ]);
      final classes = lookupResults[0].docs;
      final majors = lookupResults[1].docs;

      int inserted = 0;
      int updated = 0;
      int skipped = 0;
      for (final row in sheet.rows.skip(1)) {
        String valueAt(int index) => index >= 0 && index < row.length ? _cellText(row[index]) : '';
        final code = valueAt(codeIndex).trim();
        final name = valueAt(nameIndex).trim();
        if (code.isEmpty || name.isEmpty) {
          skipped++;
          continue;
        }
        final classInput = valueAt(classIndex).trim();
        final majorInput = valueAt(majorIndex).trim();

        QueryDocumentSnapshot<Map<String, dynamic>>? matchedClass;
        for (final item in classes) {
          final d = item.data();
          final codeValue = d['classCode']?.toString().trim().toLowerCase() ?? '';
          final nameValue = d['className']?.toString().trim().toLowerCase() ?? '';
          if (classInput.isNotEmpty &&
              (codeValue == classInput.toLowerCase() || nameValue == classInput.toLowerCase())) {
            matchedClass = item;
            break;
          }
        }

        QueryDocumentSnapshot<Map<String, dynamic>>? matchedMajor;
        final classMajorId = matchedClass == null ? '' : (matchedClass.data()['majorId']?.toString() ?? '');
        if (classMajorId.isNotEmpty) {
          for (final item in majors) {
            if (item.id == classMajorId) {
              matchedMajor = item;
              break;
            }
          }
        }
        if (matchedMajor == null && majorInput.isNotEmpty) {
          for (final item in majors) {
            final d = item.data();
            final codeValue = d['majorCode']?.toString().trim().toLowerCase() ?? '';
            final nameValue = d['majorName']?.toString().trim().toLowerCase() ?? '';
            if (codeValue == majorInput.toLowerCase() || nameValue == majorInput.toLowerCase()) {
              matchedMajor = item;
              break;
            }
          }
        }

        final matchedClassData = matchedClass?.data();
        final matchedMajorData = matchedMajor?.data();
        final payload = <String, dynamic>{
          'studentCode': code,
          'fullName': name,
          'email': valueAt(emailIndex),
          'phone': valueAt(phoneIndex),
          'classId': matchedClass?.id ?? '',
          'classCode': matchedClassData?['classCode'] ?? '',
          'className': matchedClassData?['className'] ?? classInput,
          'majorId': matchedMajor?.id ?? '',
          'major': matchedMajorData?['majorName'] ?? majorInput,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        final existing = await _db.collection('students').where('studentCode', isEqualTo: code).limit(1).get();
        if (existing.docs.isEmpty) {
          payload['createdAt'] = FieldValue.serverTimestamp();
          await _db.collection('students').add(payload);
          inserted++;
        } else {
          await existing.docs.first.reference.set(payload, SetOptions(merge: true));
          updated++;
        }
      }
      await AuditLogService.log(
        action: 'import',
        module: 'students',
        description: 'Nhập sinh viên từ Excel',
        details: {'inserted': inserted, 'updated': updated, 'skipped': skipped},
      );
      _message('Nhập Excel hoàn tất: thêm $inserted, cập nhật $updated, bỏ qua $skipped.');
    } catch (e) {
      _message('Nhập Excel thất bại: $e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Báo cáo và thống kê', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Tổng quan dữ liệu học vụ của hệ thống', style: TextStyle(color: Colors.grey)),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _importing ? null : _importStudents,
                    icon: _importing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload_file_outlined),
                    label: const Text('Nhập Excel SV'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exporting ? null : _exportExcel,
                    icon: const Icon(Icons.table_view_outlined),
                    label: const Text('Xuất Excel'),
                  ),
                  FilledButton.icon(
                    onPressed: _exporting ? null : _exportPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Xuất PDF'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 14.0;
              final columns = constraints.maxWidth >= 900 ? 4 : 2;
              final cardWidth = (constraints.maxWidth - (gap * (columns - 1))) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _summaryCard(width: cardWidth, title: 'Sinh viên', value: _count('students'), icon: Icons.people_outline),
                  _summaryCard(width: cardWidth, title: 'Lớp học', value: _count('classes'), icon: Icons.class_outlined),
                  _summaryCard(width: cardWidth, title: 'Môn học', value: _count('subjects'), icon: Icons.menu_book_outlined),
                  _summaryCard(width: cardWidth, title: 'Đăng ký môn', value: _count('registrations'), icon: Icons.app_registration_outlined),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 760) {
                  return ListView(
                    children: [
                      SizedBox(height: 260, child: _studentByMajor()),
                      const SizedBox(height: 16),
                      SizedBox(height: 260, child: _registrationBySubject()),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: _studentByMajor()),
                    const SizedBox(width: 18),
                    Expanded(child: _registrationBySubject()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required double width,
    required String title,
    required Future<int> value,
    required IconData icon,
  }) {
    return SizedBox(
      width: width,
      height: 112,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    FutureBuilder<int>(
                      future: value,
                      builder: (_, snapshot) => Text(
                        snapshot.hasData ? '${snapshot.data}' : '...',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _studentByMajor() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sinh viên theo chuyên ngành', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _db.collection('students').snapshots(),
                builder: (_, snapshot) {
                  final counts = <String, int>{};
                  for (final doc in snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
                    final key = (doc.data()['major'] ?? 'Chưa cập nhật').toString();
                    counts[key] = (counts[key] ?? 0) + 1;
                  }
                  final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                  if (entries.isEmpty) return const Center(child: Text('Chưa có dữ liệu'));
                  return ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final item = entries[index];
                      return ListTile(contentPadding: EdgeInsets.zero, dense: true, title: Text(item.key, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: Text('${item.value}'));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _registrationBySubject() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lượt đăng ký theo môn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _db.collection('registrations').snapshots(),
                builder: (_, snapshot) {
                  final counts = <String, int>{};
                  for (final doc in snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
                    final data = doc.data();
                    final code = (data['subjectCode'] ?? '').toString();
                    final name = (data['subjectName'] ?? '').toString();
                    final key = [code, name].where((item) => item.trim().isNotEmpty).join(' - ');
                    final label = key.isEmpty ? 'Chưa cập nhật' : key;
                    counts[label] = (counts[label] ?? 0) + 1;
                  }
                  final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                  if (entries.isEmpty) return const Center(child: Text('Chưa có dữ liệu'));
                  return ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final item = entries[index];
                      return ListTile(contentPadding: EdgeInsets.zero, dense: true, title: Text(item.key, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: Text('${item.value}'));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
