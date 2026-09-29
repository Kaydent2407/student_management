import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/registration_service.dart';

class CourseRegistrationPage extends StatefulWidget {
  const CourseRegistrationPage({
    super.key,
  });

  @override
  State<CourseRegistrationPage> createState() =>
      _CourseRegistrationPageState();
}

class _CourseRegistrationPageState
    extends State<CourseRegistrationPage> {
  final RegistrationService _service =
      RegistrationService();

  final TextEditingController
      _searchController =
      TextEditingController();

  String _searchText = '';

  final Set<String> _processing =
      {};

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
      ),
    );
  }

  Future<void> _register({
    required String subjectId,
    required Map<String, dynamic>
        subject,
  }) async {
    if (_processing.contains(
      subjectId,
    )) {
      return;
    }

    setState(() {
      _processing.add(
        subjectId,
      );
    });

    try {
      await _service
          .registerSubject(
        subjectId:
            subjectId,
        subjectData:
            subject,
      );

      _showMessage(
        'Đăng ký môn học thành công.',
      );
    } catch (e) {
      _showMessage(
        e.toString()
            .replaceFirst(
          'Exception: ',
          '',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing.remove(
            subjectId,
          );
        });
      }
    }
  }

  Future<void> _cancel({
    required String subjectId,
    required String subjectName,
  }) async {
    final confirm =
        await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) {
        return AlertDialog(
          title:
              const Text(
            'Hủy đăng ký',
          ),
          content: Text(
            'Bạn có chắc muốn hủy môn "$subjectName" không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text(
                'Không',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child:
                  const Text(
                'Hủy đăng ký',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await _service
          .cancelMyRegistration(
        subjectId:
            subjectId,
      );

      _showMessage(
        'Đã hủy đăng ký.',
      );
    } catch (e) {
      _showMessage(
        e.toString()
            .replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final user =
        FirebaseAuth
            .instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          'Bạn chưa đăng nhập.',
        ),
      );
    }

    return StreamBuilder<
        DocumentSnapshot<
            Map<String, dynamic>>>(
      stream: FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder:
          (context, userSnapshot) {
        if (userSnapshot
                .connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        if (!userSnapshot
                .hasData ||
            !userSnapshot
                .data!.exists) {
          return const Center(
            child: Text(
              'Không tìm thấy tài khoản.',
            ),
          );
        }

        final userData =
            userSnapshot
                .data!
                .data()!;

        final role =
            userData['role']
                    ?.toString() ??
                'student';

        if (role == 'admin') {
          return _buildAdminPage();
        }

        return FutureBuilder<
            Map<String, dynamic>>(
          future:
              _service
                  .getActiveSemester(),
          builder:
              (context,
                  semesterSnapshot) {
            if (semesterSnapshot
                    .connectionState ==
                ConnectionState
                    .waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            if (semesterSnapshot
                .hasError) {
              return Center(
                child: Text(
                  semesterSnapshot
                      .error
                      .toString()
                      .replaceFirst(
                        'Exception: ',
                        '',
                      ),
                ),
              );
            }

            final semester =
                semesterSnapshot
                    .data!;

            final semesterCode =
                semester[
                        'semesterCode']
                    .toString();

            final semesterName =
                semester[
                            'semesterName']
                        ?.toString() ??
                    semesterCode;

            return _buildStudentPage(
              userData:
                  userData,
              semesterCode:
                  semesterCode,
              semesterName:
                  semesterName,
            );
          },
        );
      },
    );
  }

  Widget _buildStudentPage({
    required Map<String, dynamic>
        userData,
    required String semesterCode,
    required String semesterName,
  }) {
    return Padding(
      padding:
          const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children: [
              const Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    'Đăng ký môn học',
                    style:
                        TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    'Chọn môn học muốn đăng ký',
                    style:
                        TextStyle(
                      color:
                          Colors.grey,
                    ),
                  ),
                ],
              ),

              Chip(
                avatar:
                    const Icon(
                  Icons
                      .calendar_month_outlined,
                ),
                label: Text(
                  semesterName,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 25,
          ),

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
                    Icon(
                  Icons.search,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 22,
          ),

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String,
                        dynamic>>>(
              stream:
                  _service
                      .getMyRegistrations(
                semesterCode:
                    semesterCode,
              ),
              builder:
                  (context,
                      regSnapshot) {
                if (regSnapshot
                        .connectionState ==
                    ConnectionState
                        .waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                final registeredIds =
                    (regSnapshot
                                .data?.docs ??
                            [])
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
                        Map<String,
                            dynamic>>>(
                  stream:
                      _service
                          .getSubjects(),
                  builder:
                      (context,
                          subjectSnapshot) {
                    if (subjectSnapshot
                            .connectionState ==
                        ConnectionState
                            .waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(),
                      );
                    }

                    final subjects =
                        (subjectSnapshot
                                    .data
                                    ?.docs ??
                                [])
                            .where(
                      (doc) {
                        final data =
                            doc.data();

                        final text =
                            '${data['subjectCode'] ?? ''} '
                                    '${data['subjectName'] ?? ''}'
                                .toLowerCase();

                        return text
                            .contains(
                          _searchText,
                        );
                      },
                    ).toList();

                    if (subjects
                        .isEmpty) {
                      return const Center(
                        child: Text(
                          'Chưa có môn học.',
                        ),
                      );
                    }

                    return GridView
                        .builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent:
                            390,
                        mainAxisExtent:
                            205,
                        crossAxisSpacing:
                            18,
                        mainAxisSpacing:
                            18,
                      ),
                      itemCount:
                          subjects
                              .length,
                      itemBuilder:
                          (context,
                              index) {
                        final doc =
                            subjects[
                                index];

                        final data =
                            doc.data();

                        final registered =
                            registeredIds
                                .contains(
                          doc.id,
                        );

                        final processing =
                            _processing
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
                                Colors
                                    .white,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                            border:
                                Border.all(
                              color: registered
                                  ? Colors
                                      .green
                                  : const Color(
                                      0xffe5e7eb,
                                    ),
                            ),
                          ),
                          child:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .menu_book_outlined,
                                    color:
                                        Color(
                                      0xff2563eb,
                                    ),
                                  ),

                                  const Spacer(),

                                  Chip(
                                    label:
                                        Text(
                                      '${data['credits'] ?? 0} tín chỉ',
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height:
                                    12,
                              ),

                              Text(
                                data['subjectCode']
                                        ?.toString() ??
                                    '',
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.grey,
                                ),
                              ),

                              const SizedBox(
                                height:
                                    5,
                              ),

                              Text(
                                data['subjectName']
                                        ?.toString() ??
                                    '',
                                maxLines:
                                    2,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  fontSize:
                                      17,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              const Spacer(),

                              SizedBox(
                                width: double
                                    .infinity,
                                child:
                                    registered
                                        ? OutlinedButton(
                                            onPressed: processing
                                                ? null
                                                : () {
                                                    _cancel(
                                                      subjectId: doc.id,
                                                      subjectName: data['subjectName']?.toString() ?? '',
                                                    );
                                                  },
                                            child:
                                                const Text(
                                              'Hủy đăng ký',
                                            ),
                                          )
                                        : FilledButton(
                                            onPressed: processing
                                                ? null
                                                : () {
                                                    _register(
                                                      subjectId: doc.id,
                                                      subject: data,
                                                    );
                                                  },
                                            child:
                                                const Text(
                                              'Đăng ký',
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

  Widget _buildAdminPage() {
    return Padding(
      padding:
          const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Quản lý đăng ký môn học',
            style: TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String,
                        dynamic>>>(
              stream:
                  _service
                      .getAllRegistrations(),
              builder:
                  (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                final docs =
                    snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có đăng ký.',
                    ),
                  );
                }

                return ListView
                    .builder(
                  itemCount:
                      docs.length,
                  itemBuilder:
                      (context,
                          index) {
                    final data =
                        docs[index]
                            .data();

                    return Card(
                      child: ListTile(
                        leading:
                            const Icon(
                          Icons.school,
                        ),
                        title: Text(
                          '${data['studentCode'] ?? ''} - ${data['studentName'] ?? ''}',
                        ),
                        subtitle: Text(
                          '${data['subjectCode'] ?? ''} - '
                          '${data['subjectName'] ?? ''}\n'
                          '${data['semesterName'] ?? ''} • '
                          '${data['credits'] ?? 0} tín chỉ',
                        ),
                      ),
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

  @override
  void dispose() {
    _searchController
        .dispose();
    super.dispose();
  }
}