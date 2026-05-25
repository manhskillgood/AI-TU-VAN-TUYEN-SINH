import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../utils/birth_date_utils.dart';
import '../firebase_options.dart';

class UserService {
  final String _projectId = DefaultFirebaseOptions.currentPlatform.projectId!;

  String _docUrl(String userId) =>
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/users/$userId';

  String _collectionUrl() =>
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/users';

  // Create user document via Firestore REST API. Requires a valid idToken.
  Future<void> createUser({required User user, required String idToken}) async {
    final url = Uri.parse('${_collectionUrl()}?documentId=${user.id}');
    final body = jsonEncode({
      'fields': _userToFirestoreFields(user),
    });
    try {
      final resp = await http.post(url, body: body, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      });
      if (resp.statusCode != 200) {
        throw Exception('Tạo user thất bại: ${resp.body}');
      }
    } on SocketException {
      throw Exception('Lỗi mạng: không thể kết nối tới server. Vui lòng kiểm tra kết nối Internet.');
    }
  }

  // Get user document via REST. Returns User or throws if not found/invalid.
  Future<User> getUser({required String userId, String? idToken}) async {
    final url = Uri.parse(_docUrl(userId));
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (idToken != null && idToken.isNotEmpty) headers['Authorization'] = 'Bearer $idToken';
    try {
      final resp = await http.get(url, headers: headers);
      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(resp.body) as Map<String, dynamic>;
        final fieldsRaw = data['fields'];
        if (fieldsRaw is! Map<String, dynamic>) {
          throw Exception('Invalid user document format');
        }
        return _userFromFirestoreFields(fieldsRaw);
      } else if (resp.statusCode == 404) {
        throw Exception('User not found');
      } else {
        // Debug: log status and whether Authorization header was sent
        try {
          // Avoid printing full token; only indicate presence
          final authPresent = headers.containsKey('Authorization');
          debugPrint('getUser: status=${resp.statusCode}, authHeaderPresent=$authPresent');
          debugPrint('getUser: body=${resp.body}');
        } catch (_) {}
        throw Exception('Get user failed: ${resp.body}');
      }
    } on SocketException {
      throw Exception('Lỗi mạng: không thể kết nối tới server. Vui lòng kiểm tra kết nối Internet.');
    }
  }

  // Update user profile via REST (requires idToken)
  Future<void> updateUser({required User user, String? idToken}) async {
    final url = Uri.parse(_docUrl(user.id));
    final body = jsonEncode({'fields': _userToFirestoreFields(user)});
    final headers = {'Content-Type': 'application/json'};
    if (idToken != null && idToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $idToken';
    }
    final resp = await http.patch(url, body: body, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Update user failed: ${resp.body}');
    }
  }

  // Upload profile image via REST/Storage is not implemented here.
  Future<String> uploadProfileImage({required String userId, required String filePath}) async {
    throw Exception('uploadProfileImage not implemented for REST service');
  }

  Future<void> deleteUser({required String userId, required String idToken}) async {
    final url = Uri.parse(_docUrl(userId));
    final resp = await http.delete(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    });
    if (resp.statusCode != 200) {
      throw Exception('Delete user failed: ${resp.body}');
    }
  }

  Map<String, dynamic> _userToFirestoreFields(User user) {
    return {
      'id': {'stringValue': user.id},
      'email': {'stringValue': user.email},
      'fullName': {'stringValue': user.fullName},
      'phoneNumber': {'stringValue': user.phoneNumber},
      'profileImage': {'stringValue': user.profileImage ?? ''},
      // Firestore expects timestamps to end with 'Z' or include a timezone offset.
      // Ensure UTC ISO string ending with 'Z'.
      // Use explicit seconds/nanos object to avoid timestamp format issues
      'dateOfBirth': {
        'timestampValue': {
          'seconds': _secondsString(BirthDateUtils.forStorage(user.dateOfBirth)),
          'nanos': _nanosInt(BirthDateUtils.forStorage(user.dateOfBirth)),
        }
      },
      'region': {'stringValue': user.region},
      'role': {'stringValue': user.role},
      'createdAt': {
        'timestampValue': {
          'seconds': _secondsString(user.createdAt),
          'nanos': _nanosInt(user.createdAt)
        }
      },
      'updatedAt': {
        'timestampValue': {
          'seconds': _secondsString(user.updatedAt),
          'nanos': _nanosInt(user.updatedAt)
        }
      },
    };
  }

  String _secondsString(DateTime dt) {
    final ms = dt.toUtc().millisecondsSinceEpoch;
    return (ms ~/ 1000).toString();
  }

  int _nanosInt(DateTime dt) {
    final ms = dt.toUtc().millisecondsSinceEpoch;
    final remMs = ms % 1000;
    return remMs * 1000000;
  }

  String _isoUtcString(DateTime dt) {
    return dt.toUtc().toIso8601String();
  }

  User _userFromFirestoreFields(Map<String, dynamic> fields) {
    String _getString(String key) {
      final v = fields[key];
      if (v is Map<String, dynamic> && v['stringValue'] != null) {
        return v['stringValue'].toString();
      }
      return '';
    }

    String _getTimestamp(String key) {
      final v = fields[key];
      if (v is Map<String, dynamic> && v['timestampValue'] != null) {
        final tv = v['timestampValue'];
        if (tv is String) return tv;
        if (tv is Map<String, dynamic>) {
          // handle protobuf timestamp object {"seconds": "..", "nanos": ..}
          final seconds = int.tryParse(tv['seconds']?.toString() ?? '0') ?? 0;
          final nanos = (tv['nanos'] is int) ? tv['nanos'] as int : int.tryParse(tv['nanos']?.toString() ?? '0') ?? 0;
          final ms = seconds * 1000 + (nanos ~/ 1000000);
          return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String() + 'Z';
        }
      }
      throw Exception('Missing timestamp field: $key');
    }

    final id = _getString('id');
    final email = _getString('email');
    final fullName = _getString('fullName');
    final phoneNumber = _getString('phoneNumber');
    final profileImageRaw = _getString('profileImage');
    final dateOfBirthStr = _getTimestamp('dateOfBirth');
    final region = _getString('region');
    final role = _getString('role');
    final createdAtStr = _getTimestamp('createdAt');
    final updatedAtStr = _getTimestamp('updatedAt');

    if (id.isEmpty || email.isEmpty) {
      throw Exception('Invalid user document: missing id or email');
    }

    return User(
      id: id,
      email: email,
      fullName: fullName,
      phoneNumber: phoneNumber,
      profileImage: profileImageRaw.isEmpty ? null : profileImageRaw,
      dateOfBirth: BirthDateUtils.fromStored(DateTime.parse(dateOfBirthStr)),
      region: region,
      role: role.isEmpty ? 'user' : role,
      createdAt: DateTime.parse(createdAtStr),
      updatedAt: DateTime.parse(updatedAtStr),
    );
  }

  /// Danh sách người dùng — SDK khi đã có Firebase Auth; REST khi có idToken.
  Future<List<User>> listUsers({String? idToken, int pageSize = 50}) async {
    if (fb.FirebaseAuth.instance.currentUser != null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .limit(pageSize)
            .get();
        final users = <User>[];
        for (final doc in snap.docs) {
          try {
            users.add(_userFromFirestoreSdk(doc.data(), doc.id));
          } catch (e) {
            debugPrint('Skip user ${doc.id}: $e');
          }
        }
        if (users.isNotEmpty) {
          users.sort((a, b) => a.email.compareTo(b.email));
          return users;
        }
      } catch (e) {
        debugPrint('listUsers SDK failed: $e');
      }
    } else {
      debugPrint('listUsers: no FirebaseAuth.currentUser — using REST');
    }

    final url = Uri.parse('${_collectionUrl()}?pageSize=$pageSize');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (idToken != null && idToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $idToken';
    }
    final resp = await http.get(url, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Không tải được danh sách người dùng: ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final docs = data['documents'] as List<dynamic>? ?? [];
    final users = <User>[];
    for (final doc in docs) {
      if (doc is! Map<String, dynamic>) continue;
      final fields = doc['fields'];
      if (fields is Map<String, dynamic>) {
        try {
          users.add(_userFromFirestoreFields(fields));
        } catch (_) {}
      }
    }
    users.sort((a, b) => a.email.compareTo(b.email));
    return users;
  }

  User _userFromFirestoreSdk(Map<String, dynamic> data, String docId) {
    DateTime parseTs(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.parse(v);
      return DateTime.now();
    }

    DateTime parseBirth(dynamic v) {
      if (v == null) return BirthDateUtils.fromPicker(DateTime.now());
      return BirthDateUtils.fromStored(parseTs(v));
    }

    return User(
      id: (data['id'] as String?)?.isNotEmpty == true ? data['id'] as String : docId,
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String? ?? 'Người dùng',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      profileImage: data['profileImage'] as String?,
      dateOfBirth: parseBirth(data['dateOfBirth']),
      region: data['region'] as String? ?? '',
      role: data['role'] as String? ?? 'user',
      createdAt: parseTs(data['createdAt']),
      updatedAt: parseTs(data['updatedAt']),
    );
  }

  Future<void> updateUserRole({
    required String userId,
    required String role,
    required String idToken,
  }) async {
    final now = FieldValue.serverTimestamp();
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': role,
        'updatedAt': now,
      });
      return;
    } catch (e) {
      debugPrint('updateUserRole SDK failed, try REST: $e');
    }

    final url = Uri.parse(
      '${_docUrl(userId)}?updateMask.fieldPaths=role&updateMask.fieldPaths=updatedAt',
    );
    final nowUtc = DateTime.now().toUtc();
    final body = jsonEncode({
      'fields': {
        'role': {'stringValue': role},
        'updatedAt': {
          'timestampValue': {
            'seconds': _secondsString(nowUtc),
            'nanos': _nanosInt(nowUtc),
          },
        },
      },
    });
    final resp = await http.patch(
      url,
      body: body,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );
    if (resp.statusCode != 200) {
      throw Exception('Cập nhật quyền thất bại: ${resp.body}');
    }
  }
}
