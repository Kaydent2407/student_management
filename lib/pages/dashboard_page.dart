import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<int> countCollection(
    String collection,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(collection)
        .get();

    return snapshot.docs.length;
  }

  Widget statisticCard({
    required String title,
    required Future<int> future,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xffe5e7eb),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xffeff6ff),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xff2563EB),
                size: 30,
              ),
            ),

            const SizedBox(width: 18),

            Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                FutureBuilder<int>(
                  future: future,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 25,
                        width: 25,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      );
                    }

                    return Text(
                      snapshot.data.toString(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Tổng quan hệ thống quản lý sinh viên',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 30),

          Row(
            children: [
              statisticCard(
                title: 'Sinh viên',
                future: countCollection(
                  'students',
                ),
                icon: Icons.people,
              ),

              const SizedBox(width: 20),

              statisticCard(
                title: 'Lớp học',
                future:
                    countCollection('classes'),
                icon: Icons.class_,
              ),

              const SizedBox(width: 20),

              statisticCard(
                title: 'Môn học',
                future:
                    countCollection('subjects'),
                icon: Icons.menu_book,
              ),
            ],
          ),
        ],
      ),
    );
  }
}