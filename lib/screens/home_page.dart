import 'package:flutter/material.dart';
import 'students_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final List<String> menuTitles = [
    'Dashboard',
    'Sinh viên',
    'Lớp học',
    'Môn học',
    'Điểm',
  ];

  final List<IconData> menuIcons = [
    Icons.dashboard,
    Icons.people,
    Icons.class_,
    Icons.menu_book,
    Icons.grade,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 240,
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                const SizedBox(height: 30),

                const CircleAvatar(
                  radius: 35,
                  child: Icon(
                    Icons.school,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Student Manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                Expanded(
                  child: ListView.builder(
                    itemCount: menuTitles.length,
                    itemBuilder: (context, index) {
                      final isSelected = selectedIndex == index;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Icon(
                            menuIcons[index],
                            color: Colors.white,
                          ),
                          title: Text(
                            menuTitles[index],
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),

                const Divider(
                  color: Colors.white24,
                ),

                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Đăng xuất',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onTap: () {
                    // Sau này thêm Firebase Auth logout
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // NỘI DUNG BÊN PHẢI
          Expanded(
            child: Container(
              color: const Color(0xFFF1F5F9),
              child: Column(
                children: [
                  // HEADER
                  Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          menuTitles[selectedIndex],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Row(
                          children: [
                            Icon(Icons.notifications_none),
                            SizedBox(width: 20),
                            CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // CONTENT
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: getPageContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getPageContent() {
    switch (selectedIndex) {
      case 0:
        return dashboardPage();

      case 1:
        return const StudentsPage();
          

      case 2:
        return const Center(
          child: Text(
            'Trang quản lý lớp học',
            style: TextStyle(fontSize: 24),
          ),
        );

      case 3:
        return const Center(
          child: Text(
            'Trang quản lý môn học',
            style: TextStyle(fontSize: 24),
          ),
        );

      case 4:
        return const Center(
          child: Text(
            'Trang quản lý điểm',
            style: TextStyle(fontSize: 24),
          ),
        );

      default:
        return dashboardPage();
    }
  }

  Widget dashboardPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Xin chào 👋',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Chào mừng đến với hệ thống quản lý sinh viên',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 30),

        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            dashboardCard(
              title: 'Sinh viên',
              value: '0',
              icon: Icons.people,
            ),
            dashboardCard(
              title: 'Lớp học',
              value: '0',
              icon: Icons.class_,
            ),
            dashboardCard(
              title: 'Môn học',
              value: '0',
              icon: Icons.menu_book,
            ),
            dashboardCard(
              title: 'Điểm',
              value: '0',
              icon: Icons.grade,
            ),
          ],
        ),
      ],
    );
  }

  Widget dashboardCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: 220,
      height: 130,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            child: Icon(
              icon,
              size: 30,
            ),
          ),

          const SizedBox(width: 16),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}