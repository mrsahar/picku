import 'dart:async';

import 'package:get/get.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/models/message_screen_model.dart';
import 'package:signalr_core/signalr_core.dart';

class ChatBackgroundService extends GetxService {
  static ChatBackgroundService get to => Get.find();

  // SignalR Connection
  HubConnection? hubConnection;

  // Observables
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isConnected = false.obs;
  final RxBool isLoadingMessages = false.obs;

  // Required variables
  final RxString rideId = ''.obs;
  final RxString driverId = ''.obs;
  final RxString driverName = ''.obs;
  final RxString currentUserId = ''.obs;
  final Rx<RideStatus> currentRideStatus = RideStatus.pending.obs;

  // Hub URL
  final String hubUrl = "http://pickurides.com/ridechathub";

  // Service active flag
  final RxBool isServiceActive = false.obs;

  @override
  void onInit() {
    super.onInit();
    _setupRideStatusListener();
    print(' SAHAr 🔧 ChatBackgroundService initialized');
  }

  /// Setup listener for ride status changes
  void _setupRideStatusListener() {
    ever(currentRideStatus, (RideStatus status) {
      print(' SAHAr 📊 Ride status changed to: $status');

      if (status == RideStatus.driverAssigned && !isServiceActive.value) {
        _checkAndStartService();
      } else if (status == RideStatus.tripCompleted && isServiceActive.value) {
        stopService();
      }
    });
  }

  /// Check if all required variables are set and start service
  void _checkAndStartService() {
    if (rideId.value.isNotEmpty &&
        driverId.value.isNotEmpty &&
        driverName.value.isNotEmpty &&
        currentUserId.value.isNotEmpty) {
      print(' SAHAr ✅ All required variables set, starting service...');
      startService();
    } else {
      print(' SAHAr ⚠️ Waiting for all required variables...');
      print(' SAHAr    RideId: ${rideId.value.isEmpty ? "MISSING" : rideId.value}');
      print(' SAHAr    DriverId: ${driverId.value.isEmpty ? "MISSING" : driverId.value}');
      print(' SAHAr    DriverName: ${driverName.value.isEmpty ? "MISSING" : driverName.value}');
      print(' SAHAr    UserId: ${currentUserId.value.isEmpty ? "MISSING" : currentUserId.value}');
    }
  }

  /// Update ride information
  void updateRideInfo({
    required String rideId,
    required String driverId,
    required String driverName,
    required String currentUserId,
    required RideStatus status,
  }) {
    print(' SAHAr 🔄 Updating ride info...');
    print(' SAHAr    Ride: $rideId');
    print(' SAHAr    Driver: $driverId ($driverName)');
    print(' SAHAr    User: $currentUserId');
    print(' SAHAr    Status: $status');

    String oldRideId = this.rideId.value;

    this.rideId.value = rideId;
    this.driverId.value = driverId;
    this.driverName.value = driverName;
    this.currentUserId.value = currentUserId;
    this.currentRideStatus.value = status;

    // If service is active and ride changed, rejoin
    if (isServiceActive.value && oldRideId != rideId && oldRideId.isNotEmpty) {
      _rejoinRideChat();
    }
  }

  /// Start the SignalR service
  Future<void> startService() async {
    if (isServiceActive.value) {
      print(' SAHAr ⚠️ Service already active');
      return;
    }

    try {
      print(' SAHAr 🚀 Starting ChatBackgroundService...');
      isServiceActive.value = true;

      await _initializeSignalR();
    } catch (e) {
      print(' SAHAr ❌ Failed to start service: $e');
      isServiceActive.value = false;
    }
  }

  /// Stop the SignalR service
  Future<void> stopService() async {
    if (!isServiceActive.value) {
      print(' SAHAr ⚠️ Service already stopped');
      return;
    }

    try {
      print(' SAHAr 🛑 Stopping ChatBackgroundService...');
      isServiceActive.value = false;

      await hubConnection?.stop();
      hubConnection = null;
      isConnected.value = false;

      // Clear messages
      messages.clear();

      print(' SAHAr ✅ ChatBackgroundService stopped');
    } catch (e) {
      print(' SAHAr ❌ Error stopping service: $e');
    }
  }

  /// Initialize SignalR connection
  Future<void> _initializeSignalR() async {
    try {
      isLoadingMessages.value = true;

      hubConnection = HubConnectionBuilder()
          .withUrl(hubUrl)
          .build();

      // Listen for incoming messages
      hubConnection?.on('ReceiveMessage', (List<Object?>? arguments) {
        if (arguments != null && arguments.isNotEmpty) {
          final messageData = arguments[0] as Map<String, dynamic>;
          _handleReceivedMessage(messageData);
        }
      });

      // Listen for chat history
      hubConnection?.on('ReceiveRideChatHistory', (List<Object?>? arguments) {
        print(' SAHAr 📜 ReceiveRideChatHistory event triggered');
        if (arguments != null && arguments.isNotEmpty) {
          final historyData = arguments[0] as List<dynamic>;
          print(' SAHAr 📜 Chat history data received: ${historyData.length} messages');
          _handleChatHistory(historyData);
        }
      });

      // Handle connection events
      hubConnection?.onclose((error) {
        print(' SAHAr 🔌 SignalR connection closed: $error');
        isConnected.value = false;

        // Attempt to reconnect if service is still active
        if (isServiceActive.value) {
          _attemptReconnect();
        }
      });

      hubConnection?.onreconnecting((error) {
        print(' SAHAr 🔄 SignalR reconnecting: $error');
        isConnected.value = false;
      });

      hubConnection?.onreconnected((connectionId) {
        print(' SAHAr ✅ SignalR reconnected: $connectionId');
        isConnected.value = true;
        _joinRideChat();
      });

      // Start connection
      await hubConnection?.start();
      isConnected.value = true;
      print(' SAHAr ✅ Connected to SignalR hub');

      // Join ride chat group
      await _joinRideChat();

      // Load chat history
      await _loadChatHistory();

    } catch (e) {
      print(' SAHAr ❌ SignalR connection error: $e');
      isLoadingMessages.value = false;

      // Attempt to reconnect if service is still active
      if (isServiceActive.value) {
        _attemptReconnect();
      }
    }
  }

  /// Attempt to reconnect after delay
  Future<void> _attemptReconnect() async {
    await Future.delayed(const Duration(seconds: 5));

    if (isServiceActive.value && !isConnected.value) {
      print(' SAHAr 🔄 Attempting to reconnect...');
      await _initializeSignalR();
    }
  }

  /// Join ride chat room
  Future<void> _joinRideChat() async {
    if (hubConnection != null && rideId.value.isNotEmpty) {
      try {
        await hubConnection?.invoke('JoinRideChat', args: [rideId.value]);
        print(' SAHAr 📌 Joined ride chat for: ${rideId.value}');
      } catch (e) {
        print(' SAHAr ❌ Failed to join ride chat: $e');
      }
    }
  }

  /// Rejoin ride chat (when ride changes)
  Future<void> _rejoinRideChat() async {
    print(' SAHAr 🔄 Rejoining ride chat for new ride...');
    messages.clear();
    await _joinRideChat();
    await _loadChatHistory();
  }

  /// Handle received message
  void _handleReceivedMessage(Map<String, dynamic> messageData) {
    try {
      print(' SAHAr 📨 Raw message data: $messageData');
      final chatMessage = ChatMessage.fromJson(messageData);
      final isFromCurrentUser = chatMessage.senderId == currentUserId.value;

      final messageWithUserFlag = chatMessage.copyWith(
        isFromCurrentUser: isFromCurrentUser,
      );

      messages.add(messageWithUserFlag);

      print(' SAHAr 📨 Received message: ${chatMessage.message}');
    } catch (e) {
      print(' SAHAr ❌ Error handling received message: $e');
    }
  }

  /// Load chat history
  Future<void> _loadChatHistory() async {
    if (rideId.value.isEmpty) {
      print(' SAHAr ⚠️ Cannot load chat history - empty ride ID');
      return;
    }

    if (hubConnection == null || !isConnected.value) {
      print(' SAHAr ⚠️ Cannot load chat history - not connected to SignalR');
      return;
    }

    try {
      isLoadingMessages.value = true;
      print(' SAHAr 📜 Loading chat history via SignalR for ride: ${rideId.value}');

      await hubConnection?.invoke('GetRideChatHistory', args: [rideId.value]);
      print(' SAHAr ✅ Chat history request sent successfully via SignalR');

    } catch (e) {
      print(' SAHAr ❌ Failed to request chat history: $e');
      isLoadingMessages.value = false;
    }
  }

  /// Handle chat history
  void _handleChatHistory(List<dynamic> chatHistory) {
    try {
      print(' SAHAr 📜 Processing chat history: ${chatHistory.length} messages');

      if (chatHistory.isEmpty) {
        print(' SAHAr 📜 No chat history found');
        messages.clear();
        isLoadingMessages.value = false;
        return;
      }

      List<ChatMessage> loadedMessages = [];

      for (var messageData in chatHistory) {
        try {
          final chatMessage = ChatMessage.fromJson(messageData);
          final isFromCurrentUser = chatMessage.senderId == currentUserId.value;

          loadedMessages.add(chatMessage.copyWith(isFromCurrentUser: isFromCurrentUser));
        } catch (e) {
          print(' SAHAr ❌ Error processing individual message: $e');
        }
      }

      messages.assignAll(loadedMessages);

      print(' SAHAr ✅ Loaded ${loadedMessages.length} messages via SignalR');
    } catch (e) {
      print(' SAHAr ❌ Error handling chat history: $e');
    } finally {
      isLoadingMessages.value = false;
    }
  }

  /// Send a message
  Future<bool> sendMessage(String messageText) async {
    if (messageText.trim().isEmpty) {
      return false;
    }

    if (rideId.value.isEmpty || currentUserId.value.isEmpty) {
      print(' SAHAr ❌ Missing ride or user information');
      return false;
    }

    if (hubConnection == null || !isConnected.value) {
      print(' SAHAr ❌ Not connected to chat service');
      return false;
    }

    try {
      print(' SAHAr 📤 Sending message via SignalR: $messageText');
      print(' SAHAr    RideId: ${rideId.value}');
      print(' SAHAr    SenderId: ${currentUserId.value}');

      await hubConnection?.invoke('SendMessage', args: [
        rideId.value,
        currentUserId.value,
        messageText,
      ]);

      print(' SAHAr ✅ Message sent successfully via SignalR');
      return true;

    } catch (e) {
      print(' SAHAr ❌ Failed to send message: $e');
      return false;
    }
  }

  /// Refresh chat history manually
  Future<void> refreshChatHistory() async {
    if (isConnected.value) {
      await _loadChatHistory();
    } else {
      print(' SAHAr ⚠️ Cannot refresh - not connected to chat service');
    }
  }

  @override
  void onClose() {
    hubConnection?.stop();
    super.onClose();
  }
}

// Initialize service in your app
class ChatServiceBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ChatBackgroundService(), permanent: true);
  }
}
