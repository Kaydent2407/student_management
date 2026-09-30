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

  List<Map<String, dynamic>> getMenus() {
    if (role == 'admin') {
      return [
        {'pageIndex': 0, 'title': 'Dashboard', 'icon': Icons.dashboard_outlined},
        {'pageIndex': 1, 'title': 'Sinh viên', 'icon': Icons.people_outline},
        {'pageIndex': 2, 'title': 'Lớp học', 'icon': Icons.class_outlined},
        {'pageIndex': 3, 'title': 'Môn học', 'icon': Icons.menu_book_outlined},
        {'pageIndex': 14, 'title': 'Lớp học phần', 'icon': Icons.school_outlined},
        {'pageIndex': 15, 'title': 'Phòng học', 'icon': Icons.meeting_room_outlined},
        {'pageIndex': 4, 'title': 'Điểm', 'icon': Icons.grade_outlined},
        {'pageIndex': 5, 'title': 'Đăng ký môn học', 'icon': Icons.app_registration},
        {'pageIndex': 6, 'title': 'Khoa / Chuyên ngành', 'icon': Icons.account_tree_outlined},
        {'pageIndex': 7, 'title': 'Lịch học', 'icon': Icons.calendar_month_outlined},
        {'pageIndex': 16, 'title': 'Lịch thi', 'icon': Icons.event_note_outlined},
        {'pageIndex': 8, 'title': 'Học phí', 'icon': Icons.payments_outlined},
        {'pageIndex': 18, 'title': 'Lịch sử thanh toán', 'icon': Icons.receipt_long_outlined},
        {'pageIndex': 9, 'title': 'Điểm danh', 'icon': Icons.fact_check_outlined},
        {'pageIndex': 10, 'title': 'Báo cáo thống kê', 'icon': Icons.bar_chart},
        {'pageIndex': 11, 'title': 'Thông báo', 'icon': Icons.notifications_outlined},
        {'pageIndex': 17, 'title': 'Quy định học vụ', 'icon': Icons.rule_folder_outlined},
        {'pageIndex': 19, 'title': 'Nhật ký hệ thống', 'icon': Icons.history_outlined},
        {'pageIndex': 12, 'title': 'Trang cá nhân', 'icon': Icons.person_outline},
        {'pageIndex': 13, 'title': 'Quản trị hệ thống', 'icon': Icons.admin_panel_settings_outlined},
      ];
    }

    return [
      {'pageIndex': 0, 'title': 'Dashboard', 'icon': Icons.dashboard_outlined},
      {'pageIndex': 1, 'title': 'Đăng ký môn học', 'icon': Icons.app_registration},
      {'pageIndex': 2, 'title': 'Điểm', 'icon': Icons.grade_outlined},
      {'pageIndex': 8, 'title': 'Kết quả học tập', 'icon': Icons.analytics_outlined},
      {'pageIndex': 3, 'title': 'Lịch học', 'icon': Icons.calendar_month_outlined},
      {'pageIndex': 9, 'title': 'Lịch thi', 'icon': Icons.event_note_outlined},
      {'pageIndex': 4, 'title': 'Học phí', 'icon': Icons.payments_outlined},
      {'pageIndex': 10, 'title': 'Lịch sử học phí', 'icon': Icons.receipt_long_outlined},
      {'pageIndex': 5, 'title': 'Điểm danh', 'icon': Icons.fact_check_outlined},
      {'pageIndex': 6, 'title': 'Thông báo', 'icon': Icons.notifications_outlined},
      {'pageIndex': 7, 'title': 'Trang cá nhân', 'icon': Icons.person_outline},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final menus = getMenus();
    return Container(
      width: 250,
      color: const Color(0xff111827),
      child: Column(
        children: [
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Row(
              children: [
                Icon(Icons.school, color: Colors.white, size: 35),
                SizedBox(width: 12),
                Text(
                  'STUDENT\nMANAGER',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, height: 1.15),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              itemCount: menus.length,
              itemBuilder: (context, index) {
                final pageIndex = menus[index]['pageIndex'] as int;
                final selected = selectedIndex == pageIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(bottom: 5),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xff2563EB) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    onTap: () => onSelect(pageIndex),
                    leading: Icon(
                      menus[index]['icon'] as IconData,
                      size: 22,
                      color: selected ? Colors.white : Colors.white70,
                    ),
                    title: Text(
                      menus[index]['title'] as String,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
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
