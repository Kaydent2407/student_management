import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final String role;
  final Function(int) onSelect;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.role,
    required this.onSelect,
  });

  // =========================================================
  // MENU THEO ROLE
  // =========================================================

  List<Map<String, dynamic>> getMenus() {
    // ================= ADMIN =================
    if (role == 'admin') {
      return [
        {
          'title': 'Dashboard',
          'icon': Icons.dashboard_outlined,
        },
        {
          'title': 'Sinh viên',
          'icon': Icons.people_outline,
        },
        {
          'title': 'Lớp học',
          'icon': Icons.class_outlined,
        },
        {
          'title': 'Môn học',
          'icon': Icons.menu_book_outlined,
        },
        {
          'title': 'Điểm',
          'icon': Icons.grade_outlined,
        },
        {
          'title': 'Đăng ký môn học',
          'icon': Icons.app_registration,
        },
        {
          'title': 'Khoa / Chuyên ngành',
          'icon': Icons.account_tree_outlined,
        },
        {
          'title': 'Lịch học',
          'icon': Icons.calendar_month_outlined,
        },
        {
          'title': 'Điểm danh',
          'icon': Icons.fact_check_outlined,
        },
        {
          'title': 'Báo cáo thống kê',
          'icon': Icons.bar_chart,
        },
        {
          'title': 'Thông báo',
          'icon': Icons.notifications_outlined,
        },
        {
          'title': 'Trang cá nhân',
          'icon': Icons.person_outline,
        },
        {
          'title': 'Quản trị hệ thống',
          'icon': Icons.admin_panel_settings_outlined,
        },
      ];
    }

    // ================= STUDENT =================
    return [
      {
        'title': 'Dashboard',
        'icon': Icons.dashboard_outlined,
      },
      {
        'title': 'Đăng ký môn học',
        'icon': Icons.app_registration,
      },
      {
        'title': 'Điểm',
        'icon': Icons.grade_outlined,
      },
      {
        'title': 'Lịch học',
        'icon': Icons.calendar_month_outlined,
      },
      {
        'title': 'Thông báo',
        'icon': Icons.notifications_outlined,
      },
      {
        'title': 'Trang cá nhân',
        'icon': Icons.person_outline,
      },
    ];
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final menus = getMenus();

    return Container(
      width: 250,
      color: const Color(0xff111827),
      child: Column(
        children: [
          // =================================================
          // LOGO
          // =================================================

          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 35,
                ),

                SizedBox(width: 12),

                Text(
                  'STUDENT\nMANAGER',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            color: Colors.white12,
            height: 1,
          ),

          // =================================================
          // MENU
          // =================================================

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
              itemCount: menus.length,
              itemBuilder: (context, index) {
                final selected =
                    selectedIndex == index;

                return Container(
                  margin: const EdgeInsets.only(
                    bottom: 5,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xff2563EB)
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    dense: true,

                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),

                    onTap: () {
                      onSelect(index);
                    },

                    leading: Icon(
                      menus[index]['icon']
                          as IconData,
                      size: 22,
                      color: selected
                          ? Colors.white
                          : Colors.white70,
                    ),

                    title: Text(
                      menus[index]['title']
                          as String,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.white70,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}