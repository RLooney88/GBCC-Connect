import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gbcc_connect_app/src/core/models/conversation.dart';
import 'package:gbcc_connect_app/src/core/utils/functions.dart';

enum MessageStatus {
  pending,
  sent,
  delivered,
  read,
}

class Message {
  final String id;
  final String conversationId;
  final String from; // from email
  final String to; // to email
  final String content;
  final MessageStatus status;
  final String? attachmentUrl;
  final String messageType; // 'text', 'image', 'file'
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool
      removedOwner; // Whether the conversation owner has removed this message
  final bool
      removedParticipant; // Whether the conversation participant has removed this message

  Message({
    required this.id,
    required this.conversationId,
    required this.from,
    required this.to,
    required this.content,
    this.status = MessageStatus.pending,
    this.attachmentUrl,
    this.messageType = 'text',
    this.createdAt,
    this.updatedAt,
    this.removedOwner = false,
    this.removedParticipant = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      content: json['content'] ?? '',
      status: _parseMessageStatus(json['status']),
      attachmentUrl: json['attachmentUrl'],
      messageType: json['messageType'] ?? 'text',
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
      removedOwner: json['removedOwner'] ?? false,
      removedParticipant: json['removedParticipant'] ?? false,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'from': from,
      'to': to,
      'content': content,
      'status': status.name,
      'attachmentUrl': attachmentUrl,
      'messageType': messageType,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'removedOwner': removedOwner,
      'removedParticipant': removedParticipant,
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    Conversation? conversation,
    String? from,
    String? to,
    String? content,
    MessageStatus? status,
    String? attachmentUrl,
    String? messageType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? removedOwner,
    bool? removedParticipant,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      from: from ?? this.from,
      to: to ?? this.to,
      content: content ?? this.content,
      status: status ?? this.status,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      removedOwner: removedOwner ?? this.removedOwner,
      removedParticipant: removedParticipant ?? this.removedParticipant,
    );
  }

  /// Check if this message should be displayed for a given user
  /// Returns true if the message should be shown, false if it should be hidden
  bool shouldDisplayForUser(
      String userEmail, String ownerEmail, String participantEmail) {
    if (userEmail == ownerEmail) {
      return !removedOwner;
    } else if (userEmail == participantEmail) {
      return !removedParticipant;
    }
    return true; // Default to showing if user is neither owner nor participant
  }

  /// Check if this message should be permanently deleted
  /// Returns true if both owner and participant have removed it
  bool shouldBePermanentlyDeleted() {
    return removedOwner && removedParticipant;
  }
}
