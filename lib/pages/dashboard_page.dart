import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  final String role;
  final Map<String, dynamic> userData;
  final ValueChanged<int>? onNavigate;

  const DashboardPage({
    super.key,
    required this.role,
    required this.userData,
    this.onNavigate,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late Future<Map<String, dynamic>> _dashboardFuture;

  bool get _isAdmin => widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role ||
        oldWidget.userData['studentId'] != widget.userData['studentId']) {
      _dashboardFuture = _loadDashboardData();
    }
  }

  Future<Map<String, dynamic>> _loadDashboardData() async {
    if (_isAdmin) {
      return _loadAdminData();
    }
    return _loadStudentData();
  }

  Future<Map<String, dynamic>> _loadAdminData() async {
    final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
      _db.collection('students').get(),
      _db.collection('classes').get(),
      _db.collection('subjects').get(),
      _db.collection('registrations').get(),
      _db.collection('schedules').get(),
      _db.collection('tuition').get(),
      _db.collection('attendance').get(),
      _db.collection('notifications').get(),
    ]);

    final students = results[0].docs;
    final classes = results[1].docs;
    final subjects = results[2].docs;
    final registrations = results[3].docs;
    final schedules = results[4].docs;
    final tuition = results[5].docs;
    final attendance = results[6].docs;
    final notifications = results[7].docs;

    double totalTuition = 0;
    double paidTuition = 0;
    int unpaidStudents = 0;

    for (final doc in tuition) {
      final data = doc.data();
      totalTuition += (data['totalAmount'] as num? ?? 0).toDouble();
      paidTuition += (data['paidAmount'] as num? ?? 0).toDouble();
      if ((data['status']?.toString() ?? 'unpaid') != 'paid') {
        unpaidStudents++;
      }
    }

    final presentCount = attendance
        .where((doc) => doc.data()['status']?.toString() == 'Có mặt')
        .length;
    final attendanceRate = attendance.isEmpty
        ? null
        : presentCount * 100 / attendance.length;

    final sortedNotifications = notifications.toList()
      ..sort((a, b) => _timestampOf(b.data()['createdAt'])
          .compareTo(_timestampOf(a.data()['createdAt'])));

    return {
      'students': students.length,
      'classes': classes.length,
      'subjects': subjects.length,
      'registrations': registrations.length,
      'schedules': schedules.length,
      'attendanceRecords': attendance.length,
      'attendanceRate': attendanceRate,
      'notifications': notifications.length,
      'totalTuition': totalTuition,
      'paidTuition': paidTuition,
      'remainingTuition': totalTuition - paidTuition,
      'unpaidStudents': unpaidStudents,
      'recentNotifications': sortedNotifications.take(5).map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList(),
    };
  }

  Future<Map<String, dynamic>> _loadStudentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return <String, dynamic>{};
    }

    final studentId = widget.userData['studentId']?.toString() ?? '';
    Map<String, dynamic> student = {};
    if (studentId.isNotEmpty) {
      final studentDoc = await _db.collection('students').doc(studentId).get();
      if (studentDoc.exists) {
        student = studentDoc.data() ?? {};
      }
    }

    final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
      _db.collection('registrations').where('userId', isEqualTo: user.uid).get(),
      _db.collection('grades').where('userId', isEqualTo: user.uid).get(),
      _db.collection('attendance').where('userId', isEqualTo: user.uid).get(),
      if (studentId.isNotEmpty)
        _db.collection('tuition').where('studentId', isEqualTo: studentId).get()
      else
        _db.collection('tuition').where('studentId', isEqualTo: '__none__').get(),
      _db.collection('schedules').get(),
      _db.collection('notifications').get(),
    ]);

    final registrations = results[0].docs;
    final grades = results[1].docs;
    final attendance = results[2].docs;
    final tuition = results[3].docs;
    final schedules = results[4].docs;
    final allNotifications = results[5].docs;

    final subjectIds = registrations
        .map((doc) => doc.data()['subjectId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final classId = student['classId']?.toString() ?? '';

    final mySchedules = schedules.where((doc) {
      final data = doc.data();
      if (classId.isNotEmpty && data['classId']?.toString() != classId) {
        return false;
      }
      if (subjectIds.isNotEmpty &&
          !subjectIds.contains(data['subjectId']?.toString() ?? '')) {
        return false;
      }
      return classId.isNotEmpty || subjectIds.isNotEmpty;
    }).toList()
      ..sort((a, b) {
        final aData = a.data();
        final bData = b.data();
        final dayCompare = (aData['dayIndex'] as num? ?? 99)
            .toInt()
            .compareTo((bData['dayIndex'] as num? ?? 99).toInt());
        if (dayCompare != 0) return dayCompare;
        return (aData['startPeriod'] as num? ?? 99)
            .toInt()
            .compareTo((bData['startPeriod'] as num? ?? 99).toInt());
      });

    double scoreTotal = 0;
    int scoreCount = 0;
    for (final doc in grades) {
      final value = doc.data()['averageScore'];
      if (value is num) {
        scoreTotal += value.toDouble();
        scoreCount++;
      }
    }
    final averageScore = scoreCount == 0 ? null : scoreTotal / scoreCount;

    final presentCount = attendance
        .where((doc) => doc.data()['status']?.toString() == 'Có mặt')
        .length;
    final attendanceRate = attendance.isEmpty
        ? null
        : presentCount * 100 / attendance.length;

    double remainingTuition = 0;
    for (final doc in tuition) {
      remainingTuition +=
          (doc.data()['remainingAmount'] as num? ?? 0).toDouble();
    }

    final notifications = allNotifications.where((doc) {
      final audience = doc.data()['audience']?.toString() ?? 'all';
      return audience == 'all' || audience == 'student';
    }).toList()
      ..sort((a, b) => _timestampOf(b.data()['createdAt'])
          .compareTo(_timestampOf(a.data()['createdAt'])));

    final sortedGrades = grades.toList()
      ..sort((a, b) => _timestampOf(b.data()['updatedAt'])
          .compareTo(_timestampOf(a.data()['updatedAt'])));

    return {
      'student': student,
      'registrations': registrations.length,
      'grades': grades.length,
      'averageScore': averageScore,
      'attendanceRecords': attendance.length,
      'attendanceRate': attendanceRate,
      'remainingTuition': remainingTuition,
      'schedules': mySchedules.length,
      'notifications': notifications.length,
      'scheduleItems': mySchedules.take(5).map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList(),
      'recentNotifications': notifications.take(4).map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList(),
      'recentGrades': sortedGrades.take(4).map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList(),
    };
  }

  DateTime _timestampOf(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _money(num value) {
    final digits = value.round().abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    final prefix = value < 0 ? '-' : '';
    return '$prefix${buffer.toString()} đ';
  }

  String _score(dynamic value) {
    if (value is! num) return '--';
    return value.toDouble().toStringAsFixed(1);
  }

  String _percent(dynamic value) {
    if (value is! num) return '--';
    return '${value.toDouble().toStringAsFixed(0)}%';
  }

  String _dateText(dynamic value) {
    if (value is! Timestamp) return '-';
    final date = value.toDate();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _refresh() {
    setState(() {
      _dashboardFuture = _loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.userData['fullName']?.toString().trim() ?? '';

    return Container(
      color: const Color(0xfff5f7fb),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined,
                      size: 54, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('Không thể tải Dashboard: ${snapshot.error}'),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? <String, dynamic>{};

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(30, 28, 30, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(name),
                  const SizedBox(height: 24),
                  if (_isAdmin)
                    _buildAdminDashboard(data)
                  else
                    _buildStudentDashboard(data),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String name) {
    final greeting = _isAdmin
        ? 'Tổng quan hệ thống quản lý sinh viên'
        : 'Theo dõi nhanh việc học của bạn trong một nơi';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Dashboard' : 'Xin chào, $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                greeting,
                style: const TextStyle(
                  color: Color(0xff6b7280),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Làm mới'),
        ),
      ],
    );
  }

  Widget _buildAdminDashboard(Map<String, dynamic> data) {
    final metrics = <_MetricData>[
      _MetricData('Sinh viên', '${data['students'] ?? 0}', Icons.people_outline,
          const Color(0xff2563eb), const Color(0xffeff6ff)),
      _MetricData('Lớp học', '${data['classes'] ?? 0}', Icons.class_outlined,
          const Color(0xff7c3aed), const Color(0xfff5f3ff)),
      _MetricData('Môn học', '${data['subjects'] ?? 0}', Icons.menu_book_outlined,
          const Color(0xff0891b2), const Color(0xffecfeff)),
      _MetricData('Đăng ký môn', '${data['registrations'] ?? 0}',
          Icons.app_registration, const Color(0xff16a34a), const Color(0xfff0fdf4)),
      _MetricData('Lịch học', '${data['schedules'] ?? 0}',
          Icons.calendar_month_outlined, const Color(0xffea580c), const Color(0xfffff7ed)),
      _MetricData('Chuyên cần', _percent(data['attendanceRate']),
          Icons.fact_check_outlined, const Color(0xff0f766e), const Color(0xfff0fdfa)),
      _MetricData('Chưa hoàn tất HP', '${data['unpaidStudents'] ?? 0}',
          Icons.payments_outlined, const Color(0xffdc2626), const Color(0xfffef2f2)),
      _MetricData('Thông báo', '${data['notifications'] ?? 0}',
          Icons.notifications_none, const Color(0xff4f46e5), const Color(0xffeef2ff)),
    ];

    final recentNotifications =
        (data['recentNotifications'] as List? ?? const []).cast<Map<String, dynamic>>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _metricGrid(metrics),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 940;
            final finance = _buildFinancePanel(data);
            final notifications = _buildNotificationPanel(
              recentNotifications,
              admin: true,
            );
            if (!wide) {
              return Column(
                children: [
                  finance,
                  const SizedBox(height: 18),
                  notifications,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: finance),
                const SizedBox(width: 18),
                Expanded(flex: 4, child: notifications),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        _buildQuickActions(admin: true),
      ],
    );
  }

  Widget _buildStudentDashboard(Map<String, dynamic> data) {
    final student = (data['student'] as Map<String, dynamic>? ?? {});
    final classText = student['classCode']?.toString().isNotEmpty == true
        ? student['classCode'].toString()
        : (student['className']?.toString() ?? '-');

    final metrics = <_MetricData>[
      _MetricData('Môn đã đăng ký', '${data['registrations'] ?? 0}',
          Icons.app_registration, const Color(0xff2563eb), const Color(0xffeff6ff)),
      _MetricData('Điểm trung bình', _score(data['averageScore']),
          Icons.grade_outlined, const Color(0xff7c3aed), const Color(0xfff5f3ff)),
      _MetricData('Chuyên cần', _percent(data['attendanceRate']),
          Icons.fact_check_outlined, const Color(0xff16a34a), const Color(0xfff0fdf4)),
      _MetricData('Học phí còn lại', _money(data['remainingTuition'] as num? ?? 0),
          Icons.payments_outlined, const Color(0xffdc2626), const Color(0xfffef2f2)),
      _MetricData('Lịch học', '${data['schedules'] ?? 0}',
          Icons.calendar_month_outlined, const Color(0xffea580c), const Color(0xfffff7ed)),
      _MetricData('Thông báo', '${data['notifications'] ?? 0}',
          Icons.notifications_none, const Color(0xff4f46e5), const Color(0xffeef2ff)),
    ];

    final scheduleItems =
        (data['scheduleItems'] as List? ?? const []).cast<Map<String, dynamic>>();
    final recentNotifications =
        (data['recentNotifications'] as List? ?? const []).cast<Map<String, dynamic>>();
    final recentGrades =
        (data['recentGrades'] as List? ?? const []).cast<Map<String, dynamic>>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xffeef2ff),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffdbe4ff)),
          ),
          child: Wrap(
            spacing: 28,
            runSpacing: 10,
            children: [
              _inlineInfo(Icons.badge_outlined, 'MSSV',
                  widget.userData['studentCode']?.toString() ?? '-'),
              _inlineInfo(Icons.class_outlined, 'Lớp', classText),
              _inlineInfo(Icons.email_outlined, 'Email',
                  widget.userData['email']?.toString() ?? '-'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _metricGrid(metrics),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 940;
            final schedule = _buildSchedulePanel(scheduleItems);
            final grades = _buildGradesPanel(recentGrades);
            if (!wide) {
              return Column(
                children: [
                  schedule,
                  const SizedBox(height: 18),
                  grades,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: schedule),
                const SizedBox(width: 18),
                Expanded(flex: 4, child: grades),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _buildNotificationPanel(recentNotifications, admin: false),
        const SizedBox(height: 22),
        _buildQuickActions(admin: false),
      ],
    );
  }

  Widget _metricGrid(List<_MetricData> metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1180
            ? 4
            : width >= 820
                ? 3
                : width >= 560
                    ? 2
                    : 1;
        final cardWidth = (width - ((columns - 1) * 16)) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: metrics
              .map((metric) => SizedBox(
                    width: cardWidth,
                    child: _metricCard(metric),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _metricCard(_MetricData metric) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe5e7eb)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: metric.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(metric.icon, color: metric.color, size: 27),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff6b7280),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff111827),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancePanel(Map<String, dynamic> data) {
    final total = (data['totalTuition'] as num? ?? 0).toDouble();
    final paid = (data['paidTuition'] as num? ?? 0).toDouble();
    final remaining = (data['remainingTuition'] as num? ?? 0).toDouble();
    final progress = total <= 0 ? 0.0 : (paid / total).clamp(0.0, 1.0);

    return _sectionCard(
      title: 'Tình hình học phí',
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _smallValue('Tổng học phí', _money(total))),
              const SizedBox(width: 12),
              Expanded(child: _smallValue('Đã thu', _money(paid))),
              const SizedBox(width: 12),
              Expanded(child: _smallValue('Còn lại', _money(remaining))),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tiến độ thu học phí',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: Color(0xff2563eb), fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: const Color(0xffe5e7eb),
              valueColor: const AlwaysStoppedAnimation(Color(0xff2563eb)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${data['unpaidStudents'] ?? 0} hồ sơ học phí chưa hoàn tất thanh toán.',
            style: const TextStyle(color: Color(0xff6b7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePanel(List<Map<String, dynamic>> items) {
    return _sectionCard(
      title: 'Lịch học của bạn',
      icon: Icons.calendar_month_outlined,
      trailing: TextButton(
        onPressed: () => widget.onNavigate?.call(3),
        child: const Text('Xem thời khóa biểu'),
      ),
      child: items.isEmpty
          ? _empty('Chưa có lịch học phù hợp.')
          : Column(
              children: items.map((item) {
                final start = item['startPeriod']?.toString() ?? '-';
                final end = item['endPeriod']?.toString() ?? '-';
                final time = item['startTime']?.toString().isNotEmpty == true &&
                        item['endTime']?.toString().isNotEmpty == true
                    ? '${item['startTime']} - ${item['endTime']}'
                    : 'Tiết $start-$end';
                return _listRow(
                  icon: Icons.schedule_outlined,
                  iconBackground: const Color(0xfffff7ed),
                  iconColor: const Color(0xffea580c),
                  title:
                      '${item['subjectCode'] ?? ''} - ${item['subjectName'] ?? ''}',
                  subtitle:
                      '${item['dayName'] ?? ''} • $time • Phòng ${item['room'] ?? '-'}',
                );
              }).toList(),
            ),
    );
  }

  Widget _buildGradesPanel(List<Map<String, dynamic>> items) {
    return _sectionCard(
      title: 'Kết quả học tập gần đây',
      icon: Icons.grade_outlined,
      trailing: TextButton(
        onPressed: () => widget.onNavigate?.call(2),
        child: const Text('Xem điểm'),
      ),
      child: items.isEmpty
          ? _empty('Chưa có dữ liệu điểm.')
          : Column(
              children: items.map((item) {
                return _listRow(
                  icon: Icons.school_outlined,
                  iconBackground: const Color(0xfff5f3ff),
                  iconColor: const Color(0xff7c3aed),
                  title:
                      '${item['subjectCode'] ?? ''} - ${item['subjectName'] ?? ''}',
                  subtitle:
                      'Giữa kỳ: ${_score(item['midtermScore'])} • Cuối kỳ: ${_score(item['finalScore'])}',
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xffeef2ff),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _score(item['averageScore']),
                      style: const TextStyle(
                        color: Color(0xff4f46e5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildNotificationPanel(
    List<Map<String, dynamic>> items, {
    required bool admin,
  }) {
    return _sectionCard(
      title: 'Thông báo mới',
      icon: Icons.notifications_none,
      trailing: TextButton(
        onPressed: () => widget.onNavigate?.call(admin ? 11 : 6),
        child: const Text('Xem tất cả'),
      ),
      child: items.isEmpty
          ? _empty('Chưa có thông báo.')
          : Column(
              children: items.map((item) {
                return _listRow(
                  icon: Icons.campaign_outlined,
                  iconBackground: const Color(0xffeef2ff),
                  iconColor: const Color(0xff4f46e5),
                  title: item['title']?.toString() ?? '',
                  subtitle: item['content']?.toString() ?? '',
                  trailing: Text(
                    _dateText(item['createdAt']),
                    style: const TextStyle(
                      color: Color(0xff9ca3af),
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildQuickActions({required bool admin}) {
    final actions = admin
        ? <_ActionData>[
            _ActionData('Sinh viên', Icons.people_outline, 1),
            _ActionData('Lịch học', Icons.calendar_month_outlined, 7),
            _ActionData('Báo cáo', Icons.bar_chart, 10),
            _ActionData('Tạo thông báo', Icons.add_alert_outlined, 11),
          ]
        : <_ActionData>[
            _ActionData('Đăng ký môn', Icons.app_registration, 1),
            _ActionData('Xem điểm', Icons.grade_outlined, 2),
            _ActionData('Lịch học', Icons.calendar_month_outlined, 3),
            _ActionData('Thông báo', Icons.notifications_none, 6),
          ];

    return _sectionCard(
      title: 'Truy cập nhanh',
      icon: Icons.bolt,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: actions.map((action) {
          return OutlinedButton.icon(
            onPressed: () => widget.onNavigate?.call(action.index),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              side: const BorderSide(color: Color(0xffdbe1ea)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: Icon(action.icon, size: 20),
            label: Text(action.label),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: const Color(0xff374151)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _smallValue(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xff6b7280), fontSize: 12)),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
        ],
      ),
    );
  }

  Widget _listRow({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff6b7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _inlineInfo(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: const Color(0xff4f46e5)),
        const SizedBox(width: 7),
        Text('$label: ',
            style: const TextStyle(
                color: Color(0xff6b7280), fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _empty(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(color: Color(0xff9ca3af))),
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  const _MetricData(
    this.title,
    this.value,
    this.icon,
    this.color,
    this.background,
  );
}

class _ActionData {
  final String label;
  final IconData icon;
  final int index;

  const _ActionData(this.label, this.icon, this.index);
}
