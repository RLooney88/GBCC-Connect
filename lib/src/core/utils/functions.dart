import 'package:intl/intl.dart';

String formatTime(DateTime? timestamp) {
  if (timestamp == null) {
    return 'N/A';
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

  if (messageDate == today) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  } else {
    return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

String formatRelativeTime(DateTime? timestamp) {
  if (timestamp == null) {
    return '';
  }

  final now = DateTime.now();
  final dateTime = timestamp;
  final difference = now.difference(dateTime);

  if (difference.inDays > 7) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  } else if (difference.inDays > 0) {
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} hr${difference.inHours == 1 ? '' : 's'} ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} min${difference.inMinutes == 1 ? '' : 's'} ago';
  } else {
    return 'Just now';
  }
}

String formatDefaultDate(DateTime? datetime) {
  if (datetime == null) {
    return 'N/A';
  }

  return DateFormat('EEEE, MMMM d, yyyy').format(datetime);
}

// Helper method to parse DateTime safely
DateTime? parseDateTime(dynamic dateTimeValue) {
  if (dateTimeValue == null) {
    return null;
  }

  if (dateTimeValue is DateTime) {
    return dateTimeValue;
  }

  if (dateTimeValue is String) {
    try {
      return DateTime.parse(dateTimeValue);
    } catch (e) {
      return null;
    }
  }

  // Handle Firestore Timestamp objects
  if (dateTimeValue.toString().contains('Timestamp')) {
    try {
      // This is a Firestore Timestamp, convert to DateTime
      final timestamp = dateTimeValue as dynamic;
      if (timestamp.toDate != null) {
        return timestamp.toDate();
      }
    } catch (e) {
      return null;
    }
  }

  return null;
}
