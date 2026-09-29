import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/registration_service.dart';

class CourseRegistrationPage extends StatefulWidget {
  const CourseRegistrationPage({super.key});

  @override
  State<CourseRegistrationPage> createState() =>
      _CourseRegistrationPageState();
}

class _CourseRegistrationPageState
    extends State<CourseRegistrationPage> {
  final RegistrationService _service =
      RegistrationService();

  final TextEditingController _searchController =
      TextEditingController();

  String _searchText = '';

  final Set<String> _processingSubjects = {};

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return '-';
    }

    final date = value.toDate();

    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${twoDigits(date.day)}/'
        '${twoDigits(date.month)}/'
        '${date.year} '
        '${twoDigits(date.hour)}:'
        '${twoDigits(date.minute)}';
  }

  // =========================================================
  // ĐĂNG KÝ
  // =========================================================

  Future<void> _registerSubject({
    required String subjectId,
    required Map<String, dynamic> subjectData,
  }) async {
    if (_processingSubjects.contains(subjectId)) {
      return;
    }

    setState(() {
      _processingSubjects.add(subjectId);
    });

    try {
      await _service.registerSubject(
        subjectId: subjectId,
        subjectData: subjectData,
      );

      _showMessage(
        'Đăng ký môn học thành công.',
      );
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingSubjects.remove(
            subjectId,
          );
        });
      }
    }
  }

  // =========================================================
  // HỦY MÔN
  // =========================================================

  Future<void> _cancelRegistration({
    required String subjectId,
    required String subjectName,
  }) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Hủy đăng ký môn học',
          ),
          content: Text(
            'Bạn có chắc muốn hủy đăng ký môn '
            '"$subjectName" không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text('Không'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Hủy đăng ký',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (_processingSubjects.contains(subjectId)) {
      return;
    }

    setState(() {
      _processingSubjects.add(subjectId);
    });

    try {
      await _service.cancelMyRegistration(
        subjectId: subjectId,
      );

      _showMessage(
        'Đã hủy đăng ký môn học.',
      );
    } catch (e) {
      _showMessage(
        'Không thể hủy đăng ký: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingSubjects.remove(
            subjectId,
          );
        });
      }
    }
  }

  // =========================================================
  // ADMIN HỦY
  // =========================================================

  Future<void> _adminDeleteRegistration({
    required String registrationId,
    required String studentName,
    required String subjectName,
  }) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Hủy đăng ký',
          ),
          content: Text(
            'Hủy đăng ký môn "$subjectName" '
            'của sinh viên "$studentName"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text('Không'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _service.deleteRegistration(
        registrationId,
      );

      _showMessage(
        'Đã hủy đăng ký.',
      );
    } catch (e) {
      _showMessage(
        'Không thể hủy đăng ký: $e',
      );
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          'Bạn chưa đăng nhập.',
        ),
      );
    }

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Lỗi: ${snapshot.error}',
            ),
          );
        }

        if (!snapshot.hasData ||
            !snapshot.data!.exists) {
          return const Center(
            child: Text(
              'Không tìm thấy tài khoản.',
            ),
          );
        }

        final userData =
            snapshot.data!.data()!;

        final role =
            userData['role']?.toString() ??
                'student';

        if (role == 'admin') {
          return _buildAdminPage();
        }

        return _buildStudentPage(
          userData,
        );
      },
    );
  }

  // =========================================================
  // STUDENT PAGE
  // =========================================================

  Widget _buildStudentPage(
    Map<String, dynamic> userData,
  ) {
    final studentCode =
        userData['studentCode']
                ?.toString() ??
            '';

    final fullName =
        userData['fullName']?.toString() ??
            '';

    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đăng ký môn học',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Chọn các môn học bạn muốn đăng ký',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      const Color(0xffeff6ff),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color:
                          Color(0xff2563eb),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$studentCode - $fullName',
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: 430,
            child: TextField(
              controller:
                  _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText =
                      value
                          .trim()
                          .toLowerCase();
                });
              },
              decoration:
                  const InputDecoration(
                hintText:
                    'Tìm mã môn hoặc tên môn...',
                prefixIcon:
                    Icon(Icons.search),
              ),
            ),
          ),

          const SizedBox(height: 22),

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream:
                  _service.getMyRegistrations(),
              builder:
                  (context, registrationSnapshot) {
                if (registrationSnapshot
                        .connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (registrationSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Không thể tải đăng ký: '
                      '${registrationSnapshot.error}',
                    ),
                  );
                }

                final registrations =
                    registrationSnapshot
                            .data?.docs ??
                        [];

                final registeredSubjectIds =
                    registrations
                        .map(
                          (doc) => doc
                                  .data()[
                                      'subjectId']
                                  ?.toString() ??
                              '',
                        )
                        .toSet();

                return StreamBuilder<
                    QuerySnapshot<
                        Map<String, dynamic>>>(
                  stream:
                      _service.getSubjects(),
                  builder:
                      (context, subjectSnapshot) {
                    if (subjectSnapshot
                            .connectionState ==
                        ConnectionState
                            .waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(),
                      );
                    }

                    if (subjectSnapshot
                        .hasError) {
                      return Center(
                        child: Text(
                          'Không thể tải môn học: '
                          '${subjectSnapshot.error}',
                        ),
                      );
                    }

                    final subjects =
                        subjectSnapshot
                                .data?.docs ??
                            [];

                    final filtered =
                        subjects.where((doc) {
                      final data =
                          doc.data();

                      final code =
                          (data['subjectCode'] ??
                                  '')
                              .toString()
                              .toLowerCase();

                      final name =
                          (data['subjectName'] ??
                                  '')
                              .toString()
                              .toLowerCase();

                      return code.contains(
                              _searchText) ||
                          name.contains(
                              _searchText);
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Icon(
                              Icons
                                  .menu_book_outlined,
                              size: 55,
                              color:
                                  Colors.grey,
                            ),
                            SizedBox(
                              height: 12,
                            ),
                            Text(
                              'Chưa có môn học.',
                              style: TextStyle(
                                color:
                                    Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent:
                            420,
                        mainAxisExtent:
                            210,
                        crossAxisSpacing:
                            18,
                        mainAxisSpacing:
                            18,
                      ),
                      itemCount:
                          filtered.length,
                      itemBuilder:
                          (context, index) {
                        final doc =
                            filtered[index];

                        final data =
                            doc.data();

                        final code =
                            data['subjectCode']
                                    ?.toString() ??
                                '';

                        final name =
                            data['subjectName']
                                    ?.toString() ??
                                '';

                        final credits =
                            data['credits'] ??
                                0;

                        final registered =
                            registeredSubjectIds
                                .contains(
                                  doc.id,
                                );

                        final processing =
                            _processingSubjects
                                .contains(
                                  doc.id,
                                );

                        return Container(
                          padding:
                              const EdgeInsets
                                  .all(20),
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,
                            borderRadius:
                                BorderRadius
                                    .circular(12),
                            border:
                                Border.all(
                              color:
                                  registered
                                      ? const Color(
                                          0xff86efac,
                                        )
                                      : const Color(
                                          0xffe5e7eb,
                                        ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 45,
                                    height: 45,
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          const Color(
                                        0xffeff6ff,
                                      ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        10,
                                      ),
                                    ),
                                    child:
                                        const Icon(
                                      Icons
                                          .menu_book,
                                      color:
                                          Color(
                                        0xff2563eb,
                                      ),
                                    ),
                                  ),

                                  const Spacer(),

                                  Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal:
                                          10,
                                      vertical: 5,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          const Color(
                                        0xfff3f4f6,
                                      ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        20,
                                      ),
                                    ),
                                    child: Text(
                                      '$credits tín chỉ',
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 15,
                              ),

                              Text(
                                code,
                                style:
                                    const TextStyle(
                                  fontSize: 13,
                                  color:
                                      Colors.grey,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                name,
                                maxLines: 2,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              const Spacer(),

                              SizedBox(
                                width:
                                    double.infinity,
                                child: registered
                                    ? OutlinedButton
                                        .icon(
                                        onPressed:
                                            processing
                                                ? null
                                                : () {
                                                    _cancelRegistration(
                                                      subjectId:
                                                          doc.id,
                                                      subjectName:
                                                          name,
                                                    );
                                                  },
                                        icon:
                                            const Icon(
                                          Icons
                                              .close,
                                        ),
                                        label:
                                            const Text(
                                          'Hủy đăng ký',
                                        ),
                                      )
                                    : FilledButton
                                        .icon(
                                        onPressed:
                                            processing
                                                ? null
                                                : () {
                                                    _registerSubject(
                                                      subjectId:
                                                          doc.id,
                                                      subjectData:
                                                          data,
                                                    );
                                                  },
                                        icon:
                                            processing
                                                ? const SizedBox(
                                                    width:
                                                        17,
                                                    height:
                                                        17,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth:
                                                          2,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons
                                                        .add,
                                                  ),
                                        label: Text(
                                          processing
                                              ? 'Đang xử lý...'
                                              : 'Đăng ký',
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ADMIN PAGE
  // =========================================================

  Widget _buildAdminPage() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Quản lý đăng ký môn học',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Danh sách sinh viên đã đăng ký môn học',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: 430,
            child: TextField(
              controller:
                  _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText =
                      value
                          .trim()
                          .toLowerCase();
                });
              },
              decoration:
                  const InputDecoration(
                hintText:
                    'Tìm MSSV, sinh viên hoặc môn học...',
                prefixIcon:
                    Icon(Icons.search),
              ),
            ),
          ),

          const SizedBox(height: 22),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color:
                      const Color(0xffe5e7eb),
                ),
              ),
              child: StreamBuilder<
                  QuerySnapshot<
                      Map<String, dynamic>>>(
                stream:
                    _service.getAllRegistrations(),
                builder:
                    (context, snapshot) {
                  if (snapshot
                          .connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Lỗi: ${snapshot.error}',
                      ),
                    );
                  }

                  final registrations =
                      snapshot.data?.docs ??
                          [];

                  final filtered =
                      registrations.where(
                    (doc) {
                      final data =
                          doc.data();

                      final studentCode =
                          (data['studentCode'] ??
                                  '')
                              .toString()
                              .toLowerCase();

                      final studentName =
                          (data['studentName'] ??
                                  '')
                              .toString()
                              .toLowerCase();

                      final subjectCode =
                          (data['subjectCode'] ??
                                  '')
                              .toString()
                              .toLowerCase();

                      final subjectName =
                          (data['subjectName'] ??
                                  '')
                              .toString()
                              .toLowerCase();

                      return studentCode
                              .contains(
                                _searchText,
                              ) ||
                          studentName.contains(
                            _searchText,
                          ) ||
                          subjectCode.contains(
                            _searchText,
                          ) ||
                          subjectName.contains(
                            _searchText,
                          );
                    },
                  ).toList();

                  return Column(
                    children: [
                      _buildAdminHeader(),

                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'Chưa có đăng ký môn học.',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount:
                                    filtered.length,
                                itemBuilder:
                                    (context,
                                        index) {
                                  return _buildAdminRow(
                                    filtered[
                                        index],
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ADMIN HEADER
  // =========================================================

  Widget _buildAdminHeader() {
    const style = TextStyle(
      fontWeight: FontWeight.w600,
      color: Color(0xff374151),
    );

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xfff8fafc),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 15,
            child: Text(
              'MSSV',
              style: style,
            ),
          ),
          Expanded(
            flex: 22,
            child: Text(
              'Sinh viên',
              style: style,
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(
              'Mã môn',
              style: style,
            ),
          ),
          Expanded(
            flex: 25,
            child: Text(
              'Môn học',
              style: style,
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              'Tín chỉ',
              style: style,
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              'Ngày đăng ký',
              style: style,
            ),
          ),
          Expanded(
            flex: 10,
            child: Center(
              child: Text(
                'Thao tác',
                style: style,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ADMIN ROW
  // =========================================================

  Widget _buildAdminRow(
    QueryDocumentSnapshot<Map<String, dynamic>>
        doc,
  ) {
    final data = doc.data();

    final studentCode =
        data['studentCode']?.toString() ?? '';

    final studentName =
        data['studentName']?.toString() ?? '';

    final subjectCode =
        data['subjectCode']?.toString() ?? '';

    final subjectName =
        data['subjectName']?.toString() ?? '';

    final credits =
        data['credits']?.toString() ?? '0';

    return Container(
      constraints: const BoxConstraints(
        minHeight: 66,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xffe5e7eb),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 15,
            child: Text(
              studentCode,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            flex: 22,
            child: Text(
              studentName,
              overflow:
                  TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            flex: 14,
            child: Text(
              subjectCode,
              overflow:
                  TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            flex: 25,
            child: Text(
              subjectName,
              overflow:
                  TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            flex: 10,
            child: Text(
              credits,
            ),
          ),

          Expanded(
            flex: 18,
            child: Text(
              _formatDate(
                data['registeredAt'],
              ),
            ),
          ),

          Expanded(
            flex: 10,
            child: Center(
              child: IconButton(
                tooltip:
                    'Hủy đăng ký',
                onPressed: () {
                  _adminDeleteRegistration(
                    registrationId:
                        doc.id,
                    studentName:
                        studentName,
                    subjectName:
                        subjectName,
                  );
                },
                icon: const Icon(
                  Icons
                      .delete_outline,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}