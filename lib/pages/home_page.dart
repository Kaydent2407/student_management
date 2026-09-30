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
import 'tuition/tuition_page.dart';
import 'attendance/attendance_page.dart';
import 'reports/reports_page.dart';
import 'notifications/notifications_page.dart';
import 'profile/profile_page.dart';
import 'course_sections/course_sections_page.dart';
import 'rooms/rooms_page.dart';
import 'exams/exam_schedules_page.dart';
import 'academic/academic_rules_page.dart';
import 'academic/academic_summary_page.dart';
import 'payments/payment_history_page.dart';
import 'audit/audit_logs_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  int _navigationDirection = 1;

  final UserService userService =
      UserService();

  void _selectPage(int index) {
    if (index == selectedIndex) return;

    setState(() {
      _navigationDirection = index > selectedIndex ? 1 : -1;
      selectedIndex = index;
    });
  }

  String _userInitials(String fullName, String email) {
    final source = fullName.trim().isNotEmpty
        ? fullName.trim()
        : email.split('@').first.trim();
    if (source.isEmpty) return 'U';

    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: const Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xffffe4e6),
                child: Icon(
                  Icons.logout_rounded,
                  color: Color(0xffdc2626),
                  size: 21,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Đăng xuất?',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: const Text(
            'Bạn có chắc muốn kết thúc phiên làm việc hiện tại không?',
            style: TextStyle(
              color: Color(0xff6b7280),
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xffdc2626),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await AuthService().logout();
    }
  }

  Widget _buildAccountMenu({
    required String role,
    required String fullName,
    required String email,
  }) {
    final displayName = fullName.trim().isEmpty ? email : fullName.trim();
    final roleLabel = role == 'admin' ? 'Quản trị viên' : 'Sinh viên';
    final initials = _userInitials(fullName, email);

    return PopupMenuButton<String>(
      tooltip: 'Tài khoản',
      offset: const Offset(0, 52),
      elevation: 14,
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      surfaceTintColor: Colors.white,
      constraints: const BoxConstraints(
        minWidth: 315,
        maxWidth: 335,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xffe5e7eb)),
      ),
      onSelected: (value) async {
        if (value == 'profile') {
          _selectPage(role == 'admin' ? 12 : 7);
        } else if (value == 'logout') {
          await _confirmLogout();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          height: 102,
          padding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xfff8fafc),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(17),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xffdbeafe),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xff2563eb),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xff111827),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xff6b7280),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffeef2ff),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          roleLabel,
                          style: const TextStyle(
                            color: Color(0xff4f46e5),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
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
        PopupMenuItem<String>(
          value: 'profile',
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xffeef2ff),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xff4f46e5),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trang cá nhân',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xff111827),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Xem và cập nhật thông tin',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xff9ca3af),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xff9ca3af),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 8),
        PopupMenuItem<String>(
          value: 'logout',
          height: 60,
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xfffff1f2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Color(0xffdc2626),
                  size: 21,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Đăng xuất',
                    style: TextStyle(
                      color: Color(0xffdc2626),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xfff87171),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 5, 9, 5),
        decoration: BoxDecoration(
          color: const Color(0xfff8fafc),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xffe5e7eb)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xffe0e7ff),
              child: Text(
                initials,
                style: const TextStyle(
                  color: Color(0xff4f46e5),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff111827),
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    roleLabel,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color(0xff9ca3af),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xff6b7280),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton({
    required String role,
    required String userId,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .snapshots(),
      builder: (context, notificationSnapshot) {
        final visibleIds = (notificationSnapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[])
            .where((doc) {
              final audience = doc.data()['audience']?.toString() ?? 'all';
              return audience == 'all' ||
                  (role == 'admin' && audience == 'admin') ||
                  (role != 'admin' && audience == 'student');
            })
            .map((doc) => doc.id)
            .toSet();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('notification_reads')
              .where('userId', isEqualTo: userId)
              .snapshots(),
          builder: (context, readSnapshot) {
            final readIds = (readSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                .map((doc) => doc.data()['notificationId']?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toSet();
            final unread = visibleIds.where((id) => !readIds.contains(id)).length;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Thông báo',
                  onPressed: () {
                    _selectPage(role == 'admin' ? 11 : 6);
                  },
                  icon: const Icon(Icons.notifications_none),
                ),
                if (unread > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xffdc2626),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================
  // ADMIN PAGE
  // =========================================================

  Widget adminPage(int index, Map<String, dynamic> userData) {
    switch (index) {
      case 0:
        return DashboardPage(
          role: 'admin',
          userData: userData,
          onNavigate: _selectPage,
        );

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
        return const TuitionPage();

      case 9:
        return const AttendancePage(isAdmin: true);

      case 10:
        return const ReportsPage();

      case 11:
        return const NotificationsPage(isAdmin: true);

      case 12:
        return const ProfilePage();

      case 13:
        return const AccountManagementPage();

      case 14:
        return const CourseSectionsPage();

      case 15:
        return const RoomsPage();

      case 16:
        return const ExamSchedulesPage(isAdmin: true);

      case 17:
        return const AcademicRulesPage();

      case 18:
        return const PaymentHistoryPage(isAdmin: true);

      case 19:
        return const AuditLogsPage();

      default:
        return DashboardPage(
          role: 'admin',
          userData: userData,
          onNavigate: _selectPage,
        );
    }
  }

  // =========================================================
  // STUDENT PAGE
  // =========================================================

  Widget studentPage(int index, Map<String, dynamic> userData) {
    switch (index) {
      case 0:
        return DashboardPage(
          role: 'student',
          userData: userData,
          onNavigate: _selectPage,
        );

      case 1:
        return const CourseRegistrationPage();

      case 2:
        return const GradesPage();

      case 3:
        return const SchedulesPage();

      case 4:
        return const TuitionPage();

      case 5:
        return const AttendancePage(isAdmin: false);

      case 6:
        return const NotificationsPage(isAdmin: false);

      case 7:
        return const ProfilePage();

      case 8:
        return const AcademicSummaryPage();

      case 9:
        return const ExamSchedulesPage(isAdmin: false);

      case 10:
        return const PaymentHistoryPage(isAdmin: false);

      default:
        return DashboardPage(
          role: 'student',
          userData: userData,
          onNavigate: _selectPage,
        );
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
                onSelect: _selectPage,
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
                          _buildNotificationButton(
                            role: role,
                            userId: currentUser.uid,
                          ),

                          const SizedBox(
                            width: 15,
                          ),

                          _buildAccountMenu(
                            role: role,
                            fullName: fullName,
                            email: email,
                          ),
                        ],
                      ),
                    ),

                    // ===========================================
                    // PAGE CONTENT
                    // ===========================================

                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        reverseDuration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            fit: StackFit.expand,
                            clipBehavior: Clip.hardEdge,
                            children: [
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        transitionBuilder: (child, animation) {
                          final curved = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          );
                          final currentKey =
                              ValueKey<String>('$role-$selectedIndex');
                          final isIncoming = child.key == currentKey;
                          final beginDx = isIncoming
                              ? 0.035 * _navigationDirection
                              : -0.02 * _navigationDirection;
                          final slide = Tween<Offset>(
                            begin: Offset(beginDx, 0),
                            end: Offset.zero,
                          ).animate(curved);

                          return FadeTransition(
                            opacity: curved,
                            child: SlideTransition(
                              position: slide,
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey<String>(
                            '$role-$selectedIndex',
                          ),
                          child: role == 'admin'
                              ? adminPage(
                                  selectedIndex,
                                  data,
                                )
                              : studentPage(
                                  selectedIndex,
                                  data,
                                ),
                        ),
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