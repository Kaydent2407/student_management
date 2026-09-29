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
import 'registrations/course_registration_page.dart';
import 'schedules/schedules_page.dart';

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

  // =========================================================
  // ADMIN PAGE
  // =========================================================

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
        return const CourseRegistrationPage();

      case 6:
        return const DepartmentMajorPage();

      case 7:
        return const SchedulesPage();

      case 8:
        return const PlaceholderPage(
          title: 'Điểm danh',
        );

      case 9:
        return const PlaceholderPage(
          title: 'Báo cáo thống kê',
        );

      case 10:
        return const PlaceholderPage(
          title: 'Thông báo',
        );

      case 11:
        return const PlaceholderPage(
          title: 'Trang cá nhân',
        );

      case 12:
        return const AccountManagementPage();

      default:
        return const DashboardPage();
    }
  }

  // =========================================================
  // STUDENT PAGE
  // =========================================================

  Widget studentPage(int index) {
    switch (index) {
      case 0:
        return const DashboardPage();

      case 1:
        return const CourseRegistrationPage();

      case 2:
        return const GradesPage();

      case 3:
        return const SchedulesPage();

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

  // =========================================================
  // BUILD
  // =========================================================

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
        DocumentSnapshot<
            Map<String, dynamic>>>(
      stream:
          userService.currentUserStream(),

      builder: (context, snapshot) {
        // ===================================================
        // LOADING USER
        // ===================================================

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        // ===================================================
        // ERROR
        // ===================================================

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Có lỗi xảy ra: ${snapshot.error}',
              ),
            ),
          );
        }

        // ===================================================
        // USER DOCUMENT KHÔNG TỒN TẠI
        // ===================================================

        if (!snapshot.hasData ||
            !snapshot.data!.exists) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber,
                    size: 55,
                    color: Colors.orange,
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  const Text(
                    'Không tìm thấy thông tin người dùng.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  FilledButton.icon(
                    onPressed: () async {
                      await AuthService()
                          .logout();
                    },
                    icon: const Icon(
                      Icons.logout,
                    ),
                    label: const Text(
                      'Đăng xuất',
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final data =
            snapshot.data!.data()!;

        // ===================================================
        // USER INFO
        // ===================================================

        final role =
            data['role']?.toString() ??
                'student';

        final fullName =
            data['fullName']?.toString() ??
                '';

        final email =
            data['email']?.toString() ??
                currentUser.email ??
                '';

        final isActive =
            data['isActive'] as bool? ??
                true;

        // ===================================================
        // ACCOUNT BỊ KHÓA
        // ===================================================

        if (!isActive) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 70,
                    color: Colors.red,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    'Tài khoản đã bị khóa',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  const Text(
                    'Vui lòng liên hệ quản trị viên.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  FilledButton.icon(
                    onPressed: () async {
                      await AuthService()
                          .logout();
                    },
                    icon: const Icon(
                      Icons.logout,
                    ),
                    label: const Text(
                      'Đăng xuất',
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ===================================================
        // MAIN UI
        // ===================================================

        return Scaffold(
          body: Row(
            children: [
              // =================================================
              // SIDEBAR
              // =================================================

              Sidebar(
                selectedIndex:
                    selectedIndex,
                role: role,
                onSelect: (index) {
                  setState(() {
                    selectedIndex =
                        index;
                  });
                },
              ),

              // =================================================
              // CONTENT
              // =================================================

              Expanded(
                child: Column(
                  children: [
                    // ===========================================
                    // TOP BAR
                    // ===========================================

                    Container(
                      height: 70,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 30,
                      ),
                      decoration:
                          const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom:
                              BorderSide(
                            color:
                                Color(
                              0xffe5e7eb,
                            ),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .end,
                        children: [
                          // Notification
                          IconButton(
                            tooltip:
                                'Thông báo',
                            onPressed: () {
                              if (role ==
                                  'admin') {
                                setState(() {
                                  selectedIndex =
                                      10;
                                });
                              } else {
                                setState(() {
                                  selectedIndex =
                                      4;
                                });
                              }
                            },
                            icon: const Icon(
                              Icons
                                  .notifications_none,
                            ),
                          ),

                          const SizedBox(
                            width: 15,
                          ),

                          // Avatar
                          const CircleAvatar(
                            backgroundColor:
                                Color(
                              0xffe0e7ff,
                            ),
                            child: Icon(
                              Icons.person,
                              color: Color(
                                0xff4f46e5,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          // User info
                          Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                fullName
                                        .isEmpty
                                    ? email
                                    : fullName,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              const SizedBox(
                                height: 2,
                              ),

                              Text(
                                role ==
                                        'admin'
                                    ? 'Quản trị viên'
                                    : 'Sinh viên',
                                style:
                                    const TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors.grey,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            width: 5,
                          ),

                          // Menu
                          PopupMenuButton<
                              String>(
                            tooltip:
                                'Tài khoản',
                            onSelected:
                                (value) async {
                              if (value ==
                                  'profile') {
                                setState(() {
                                  if (role ==
                                      'admin') {
                                    selectedIndex =
                                        11;
                                  } else {
                                    selectedIndex =
                                        5;
                                  }
                                });
                              }

                              if (value ==
                                  'logout') {
                                await AuthService()
                                    .logout();
                              }
                            },
                            itemBuilder:
                                (context) => [
                              PopupMenuItem<
                                  String>(
                                enabled: false,
                                child: Column(
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
                                    const SizedBox(
                                      height: 3,
                                    ),
                                    Text(
                                      email,
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            12,
                                        color:
                                            Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const PopupMenuDivider(),

                              const PopupMenuItem<
                                  String>(
                                value:
                                    'profile',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons
                                          .person_outline,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      'Trang cá nhân',
                                    ),
                                  ],
                                ),
                              ),

                              const PopupMenuItem<
                                  String>(
                                value:
                                    'logout',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.logout,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
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

                    // ===========================================
                    // PAGE CONTENT
                    // ===========================================

                    Expanded(
                      child:
                          role == 'admin'
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

// =============================================================
// PLACEHOLDER PAGE
// =============================================================

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({
    super.key,
    required this.title,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          const Icon(
            Icons
                .construction_outlined,
            size: 65,
            color: Colors.grey,
          ),

          const SizedBox(
            height: 15,
          ),

          Text(
            title,
            style:
                const TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          const Text(
            'Chức năng đang phát triển',
            style:
                TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}