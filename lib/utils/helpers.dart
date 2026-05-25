import 'package:uuid/uuid.dart';

class UUIDGenerator {
  static String generate() {
    return const Uuid().v4();
  }
}

class ValidationUtils {
  static bool isValidEmail(String email) {
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return regex.hasMatch(email);
  }

  static bool isValidPhoneNumber(String phoneNumber) {
    final regex = RegExp(r'^[0-9]{10,11}$');
    return regex.hasMatch(phoneNumber);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }
}

class DateTimeUtils {
  static String formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return formatDate(dateTime);
    }
  }
}

class StringUtils {
  static String capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }

  static String truncate(String str, int length) {
    if (str.length <= length) return str;
    return '${str.substring(0, length)}...';
  }
}
