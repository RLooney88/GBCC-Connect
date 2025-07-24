import 'package:gbcc_connect_app/src/core/constants/constants.dart';

import 'user.dart';
import 'message.dart';

class Conversation {
  final String id;
  final String ownerId; // The user who owns this conversation view
  final String participantId; // The other user in the conversation
  final User? owner; // Owner user object
  final User? participant; // Participant user object
  final Message? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive; // Whether the conversation is active/archived
  final int unreadCount; // Number of unread messages

  Conversation({
    required this.id,
    required this.ownerId,
    required this.participantId,
    this.owner,
    this.participant,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    User? owner;
    User? participant;
    Message? lastMessage;

    // Parse owner
    if (json['owner'] != null && json['owner'] is Map<String, dynamic>) {
      try {
        owner = User.fromJson(json['owner'] as Map<String, dynamic>);
      } catch (e) {
        // Handle parsing error
      }
    }

    // Parse participant
    if (json['participant'] != null &&
        json['participant'] is Map<String, dynamic>) {
      try {
        participant =
            User.fromJson(json['participant'] as Map<String, dynamic>);
      } catch (e) {
        // Handle parsing error
      }
    }

    // Parse lastMessage
    if (json['lastMessage'] != null &&
        json['lastMessage'] is Map<String, dynamic>) {
      try {
        lastMessage =
            Message.fromJson(json['lastMessage'] as Map<String, dynamic>);
      } catch (e) {
        // Handle parsing error
      }
    }

    return Conversation(
      id: json['id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      participantId: json['participantId'] ?? '',
      owner: owner,
      participant: participant,
      lastMessage: lastMessage,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      isActive: json['isActive'] ?? true,
      unreadCount: json['unreadCount'] ?? 0,
    );
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
        final timestamp = dateTimeValue as dynamic;
        if (timestamp.toDate != null) {
          return timestamp.toDate();
        }
      } catch (e) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    final json = {
      'ownerId': ownerId,
      'participantId': participantId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'unreadCount': unreadCount,
    };

    // Only include ID if it's not empty
    if (id.isNotEmpty) {
      json['id'] = id;
    }

    // Include owner object if available
    if (owner != null) {
      json['owner'] = owner!.toJson();
    }

    // Include participant object if available
    if (participant != null) {
      json['participant'] = participant!.toJson();
    }

    // Include last message if available
    if (lastMessage != null) {
      json['lastMessage'] = lastMessage!.toJson();
    }

    return json;
  }

  Conversation copyWith({
    String? id,
    String? ownerId,
    String? participantId,
    User? owner,
    User? participant,
    Message? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? unreadCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      participantId: participantId ?? this.participantId,
      owner: owner ?? this.owner,
      participant: participant ?? this.participant,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  /// Get the other user's ID (participant from owner's perspective)
  String getOtherUserId(String currentUserId) {
    if (currentUserId == ownerId) {
      return participantId;
    } else if (currentUserId == participantId) {
      return ownerId;
    }
    return '';
  }

  /// Get the other user's object (participant from owner's perspective)
  User? getOtherUser(String currentUserId) {
    if (currentUserId == ownerId) {
      return participant;
    } else if (currentUserId == participantId) {
      return owner;
    }
    return null;
  }

  /// Check if this conversation involves the given user
  bool involvesUser(String userId) {
    return ownerId == userId || participantId == userId;
  }

  /// Check if the given user is the owner of this conversation
  bool isOwner(String userId) {
    return ownerId == userId;
  }

  /// Check if the given user is the participant of this conversation
  bool isParticipant(String userId) {
    return participantId == userId;
  }

  /// Get conversation display name for a user
  String getDisplayName(String currentUserId) {
    final otherUser = getOtherUser(currentUserId);
    return otherUser?.displayName ??
        otherUser?.name ??
        AppConstants.defaultDisplayName;
  }
}
