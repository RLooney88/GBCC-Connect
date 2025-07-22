import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gbcc_connect_app/src/core/models/conversation.dart';

enum MessageStatus {
  pending,
  sent,
  delivered,
  read,
}

class Message {
  final String id;
  final String conversationId;
  final Conversation? conversation; // Make optional
  final String from; // from email
  final String to; // to email
  final String content;
  final DateTime timestamp;
  final MessageStatus status;
  final String? attachmentUrl;
  final String messageType; // 'text', 'image', 'file'

  Message({
    required this.id,
    required this.conversationId,
    this.conversation, // Make optional
    required this.from,
    required this.to,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.pending,
    this.attachmentUrl,
    this.messageType = 'text',
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    Conversation? conversation;

    // Parse conversation if available
    if (json['conversation'] != null &&
        json['conversation'] is Map<String, dynamic>) {
      try {
        conversation =
            Conversation.fromJson(json['conversation'] as Map<String, dynamic>);
      } catch (e) {
        // Handle parsing error
      }
    }

    return Message(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      conversation: conversation,
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      content: json['content'] ?? '',
      timestamp: _parseDateTime(json['timestamp']),
      status: _parseMessageStatus(json['status']),
      attachmentUrl: json['attachmentUrl'],
      messageType: json['messageType'] ?? 'text',
    );
  }

  static MessageStatus _parseMessageStatus(String status) {
    switch (status) {
      case 'pending':
        return MessageStatus.pending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      default:
        return MessageStatus.pending;
    }
  }

  // Helper method to parse DateTime safely
  static DateTime _parseDateTime(dynamic dateTimeValue) {
    if (dateTimeValue == null) {
      return DateTime.now();
    }

    if (dateTimeValue is DateTime) {
      return dateTimeValue;
    }

    if (dateTimeValue is String) {
      try {
        return DateTime.parse(dateTimeValue);
      } catch (e) {
        return DateTime.now();
      }
    }

    // Handle Firestore Timestamp objects
    if (dateTimeValue.toString().contains('Timestamp')) {
      try {
        // This is a Firestore Timestamp, convert to DateTime
        final timestamp = dateTimeValue as Timestamp;
        return timestamp.toDate();
      } catch (e) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'conversation': conversation?.toJson(), // Handle null conversation
      'from': from,
      'to': to,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'attachmentUrl': attachmentUrl,
      'messageType': messageType,
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    Conversation? conversation,
    String? from,
    String? to,
    String? content,
    DateTime? timestamp,
    MessageStatus? status,
    String? attachmentUrl,
    String? messageType,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      conversation: conversation ?? this.conversation,
      from: from ?? this.from,
      to: to ?? this.to,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      messageType: messageType ?? this.messageType,
    );
  }
}
