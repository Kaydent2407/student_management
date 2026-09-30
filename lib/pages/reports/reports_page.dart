import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  Future<int> _count(String collection) async {
    final snapshot = await FirebaseFirestore.instance.collection(collection).get();
    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Báo cáo và thống kê',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tổng quan dữ liệu học vụ của hệ thống',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 14.0;
              final columns = constraints.maxWidth >= 900 ? 4 : 2;
              final cardWidth =
                  (constraints.maxWidth - (gap * (columns - 1))) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _summaryCard(
                    width: cardWidth,
                    title: 'Sinh viên',
                    value: _count('students'),
                    icon: Icons.people_outline,
                  ),
                  _summaryCard(
                    width: cardWidth,
                    title: 'Lớp học',
                    value: _count('classes'),
                    icon: Icons.class_outlined,
                  ),
                  _summaryCard(
                    width: cardWidth,
                    title: 'Môn học',
                    value: _count('subjects'),
                    icon: Icons.menu_book_outlined,
                  ),
                  _summaryCard(
                    width: cardWidth,
                    title: 'Đăng ký môn',
                    value: _count('registrations'),
                    icon: Icons.app_registration_outlined,
                  ),
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
                      SizedBox(
                        height: 260,
                        child: _studentByMajor(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 260,
                        child: _registrationBySubject(),
                      ),
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
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<int>(
                      future: value,
                      builder: (_, snapshot) => Text(
                        snapshot.hasData ? '${snapshot.data}' : '...',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
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
            const Text(
              'Sinh viên theo chuyên ngành',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('students')
                    .snapshots(),
                builder: (_, snapshot) {
                  final counts = <String, int>{};
                  for (final doc in snapshot.data?.docs ?? []) {
                    final key =
                        (doc.data()['major'] ?? 'Chưa cập nhật').toString();
                    counts[key] = (counts[key] ?? 0) + 1;
                  }

                  final entries = counts.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  if (entries.isEmpty) {
                    return const Center(child: Text('Chưa có dữ liệu'));
                  }

                  return ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final item = entries[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(
                          item.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text('${item.value}'),
                      );
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
            const Text(
              'Lượt đăng ký theo môn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('registrations')
                    .snapshots(),
                builder: (_, snapshot) {
                  final counts = <String, int>{};
                  for (final doc in snapshot.data?.docs ?? []) {
                    final data = doc.data();
                    final code = (data['subjectCode'] ?? '').toString();
                    final name = (data['subjectName'] ?? '').toString();
                    final key = [code, name]
                        .where((item) => item.trim().isNotEmpty)
                        .join(' - ');
                    counts[key.isEmpty ? 'Chưa cập nhật' : key] =
                        (counts[key.isEmpty ? 'Chưa cập nhật' : key] ?? 0) + 1;
                  }

                  final entries = counts.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  if (entries.isEmpty) {
                    return const Center(child: Text('Chưa có dữ liệu'));
                  }

                  return ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final item = entries[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(
                          item.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text('${item.value}'),
                      );
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
