import 'dart:async';
import 'package:get/get.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/services/chat_background_service.dart';
import 'package:pick_u/services/share_pref.dart';
import 'package:pick_u/models/message_screen_model.dart';


import 'package:flutter/material.dart';

class ChatController extends GetxController {
  // Get reference to background service
  final ChatBackgroundService _chatService = ChatBackgroundService.to;

  // Message input
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // Observables from service (for UI binding)
  final RxBool isSending = false.obs;

  // Getters to access service data
  RxList<ChatMessage> get messages => _chatService.messages;
  RxBool get isConnected => _chatService.isConnected;
  RxBool get isLoadingMessages => _chatService.isLoadingMessages;
  RxString get rideId => _chatService.rideId;
  RxString get driverId => _chatService.driverId;
  RxString get driverName => _chatService.driverName;
  RxString get currentUserId => _chatService.currentUserId;

  @override
  void onInit() {
    super.onInit();
    _initializeFromArguments();
    _setupMessageListener();
  }

  Future<void> _initializeFromArguments() async {
    // Get parameters passed from previous screen
    final args = Get.arguments as Map<String, dynamic>?;

    if (args != null) {
      final rideId = args['rideId'] ?? '';
      final driverId = args['driverId'] ?? '';
      final driverName = args['driverName'] ?? 'Driver';

      print('📱 ChatController initialized with:');
      print('   Ride ID: $rideId');
      print('   Driver ID: $driverId');
      print('   Driver Name: $driverName');

      // Get user ID and update service
      SharedPrefsService.getUserId().then((userId) {
        if (userId != null) {
          print('👤 Current User ID loaded: $userId');

          // Update the background service with all info
          // Note: You need to pass the current RideStatus here
          _chatService.updateRideInfo(
            rideId: rideId,
            driverId: driverId,
            driverName: driverName,
            currentUserId: userId,
            status: RideStatus.driverAssigned, // Get actual status from your ride controller
          );
        }
      });
    }
  }

  /// Setup listener for new messages to auto-scroll
  void _setupMessageListener() {
    ever(_chatService.messages, (_) {
      _scrollToBottom();
    });
  }

  /// Scroll to bottom of message list
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Send message through background service
  Future<void> sendMessage() async {
    final messageText = messageController.text.trim();

    if (messageText.isEmpty) {
      return;
    }

    try {
      isSending.value = true;

      final success = await _chatService.sendMessage(messageText);

      if (success) {
        messageController.clear();
        _scrollToBottom();
      } else {
        //Get.snackbar('Error', 'Failed to send message');
      }
    } finally {
      isSending.value = false;
    }
  }

  /// Retry connection
  void retryConnection() async {
    if (!_chatService.isConnected.value) {
      await _chatService.startService();
    }
  }

  /// Manual refresh method
  void refreshChatHistory() {
    if (_chatService.isConnected.value) {
      _chatService.refreshChatHistory();
    }
  }

  /// Update ride information when ChatScreen is already in stack
  void updateRideInfo({
    required String rideId,
    required String driverId,
    required String driverName,
    required RideStatus status,
  }) {
    print('📱 Updating ride info from ChatController');

    _chatService.updateRideInfo(
      rideId: rideId,
      driverId: driverId,
      driverName: driverName,
      currentUserId: _chatService.currentUserId.value,
      status: status,
    );

    _scrollToBottom();
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
    // Note: Don't stop the service here as it should run in background
  }
}

// Extension for easy date formatting
extension DateTimeExtension on DateTime {
  String toTimeString() {
    final hour = this.hour > 12 ? this.hour - 12 : this.hour == 0 ? 12 : this.hour;
    final minute = this.minute.toString().padLeft(2, '0');
    final period = this.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String toDateTimeString() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays == 0) {
      return toTimeString();
    } else if (difference.inDays == 1) {
      return 'Yesterday ${toTimeString()}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${this.day}/${this.month}/${this.year}';
    }
  }
}