import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/sidebar.dart';

import 'dashboard_page.dart';
import 'students/students_page.dart';
import 'classes/classes_page.dart';
import 'subjects/subjects_page.dart';
import 'grades/grades_page.dart';
import 'admin/account_management_page.dart';
import 'departments/department_major_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final UserService userService =
      UserService();

  Widget adminPage(int index) {
    switch (index) {
      case 0:
        return const DashboardPage();

      case 1:
        return const StudentsPage();

      case 2:
        return const ClassesPage();

      case 3:
        return const SubjectsPage();

      case 4:
        return const GradesPage();

      case 5:
        return const PlaceholderPage(
          title: 'Đăng ký môn học',
        );

      case 6:
        return const DepartmentMajorPage();

      case 7:
        return const PlaceholderPage(
          title: 'Điểm danh',
        );

      case 8:
        return const PlaceholderPage(
          title: 'Báo cáo thống kê',
        );

      case 9:
        return const PlaceholderPage(
          title: 'Thông báo',
        );

      case 10:
        return const PlaceholderPage(
          title: 'Trang cá nhân',
        );

      case 11:
        return const AccountManagementPage();

      default:
        return const DashboardPage();
    }
  }

  Widget studentPage(int index) {
    switch (index) {
      case 0:
        return const DashboardPage();

      case 1:
        return const PlaceholderPage(
          title: 'Đăng ký môn học',
        );

      case 2:
        return const GradesPage();

      case 3:
        return const PlaceholderPage(
          title: 'Lịch học',
        );

      case 4:
        return const PlaceholderPage(
          title: 'Thông báo',
        );

      case 5:
        return const PlaceholderPage(
          title: 'Trang cá nhân',
        );

      default:
        return const DashboardPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: userService.currentUserStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData ||
            !snapshot.data!.exists) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber,
                    size: 50,
                    color: Colors.orange,
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'Không tìm thấy thông tin người dùng.',
                  ),

                  const SizedBox(height: 15),

                  FilledButton(
                    onPressed: () async {
                      await AuthService().logout();
                    },
                    child: const Text(
                      'Đăng xuất',
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!.data()!;

        final isActive = data['isActive'] ?? true;

if (!isActive) {
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 70,
            color: Colors.red,
          ),

          const SizedBox(height: 20),

          const Text(
            'Tài khoản đã bị khóa',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Vui lòng liên hệ quản trị viên.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 25),

          FilledButton.icon(
            onPressed: () async {
              await AuthService().logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    ),
  );
}

        final role =
            data['role'] ?? 'student';

        final fullName =
            data['fullName'] ?? '';

        final email =
            data['email'] ??
                currentUser.email ??
                '';

        return Scaffold(
          body: Row(
            children: [
              Sidebar(
                selectedIndex: selectedIndex,
                role: role,
                onSelect: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
              ),

              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 70,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 30,
                      ),
                      decoration:
                          const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color:
                                Color(0xffe5e7eb),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.end,
                        children: [
                          const Icon(
                            Icons
                                .notifications_none,
                          ),

                          const SizedBox(width: 20),

                          const CircleAvatar(
                            child:
                                Icon(Icons.person),
                          ),

                          const SizedBox(width: 10),

                          Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                fullName,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                              Text(
                                role == 'admin'
                                    ? 'Quản trị viên'
                                    : 'Sinh viên',
                                style:
                                    const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 10),

                          PopupMenuButton<String>(
                            onSelected:
                                (value) async {
                              if (value ==
                                  'logout') {
                                await AuthService()
                                    .logout();
                              }
                            },
                            itemBuilder:
                                (context) => [
                              PopupMenuItem(
                                enabled: false,
                                child: Text(
                                  email,
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.logout,
                                    ),
                                    SizedBox(
                                        width: 10),
                                    Text(
                                      'Đăng xuất',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: role == 'admin'
                          ? adminPage(
                              selectedIndex,
                            )
                          : studentPage(
                              selectedIndex,
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
}

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title\nĐang phát triển',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}