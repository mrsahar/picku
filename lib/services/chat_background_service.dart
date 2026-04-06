import 'dart:async';

import 'package:get/get.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/models/message_screen_model.dart';
import 'package:pick_u/services/notification_service.dart';
import 'package:pick_u/services/signalr_service.dart';
import 'package:signalr_core/signalr_core.dart';

class ChatBackgroundService extends GetxService {
  static ChatBackgroundService get to => Get.find();

  // Use shared SignalR connection
  SignalRService get _signalRService => SignalRService.to;
  HubConnection? get hubConnection => _signalRService.connection;

  // Observables
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  RxBool get isConnected => _signalRService.connectionStatus.value == SignalRConnectionStatus.connected ? true.obs : false.obs;
  final RxBool isLoadingMessages = false.obs;

  // Required variables
  final RxString rideId = ''.obs;
  final RxString driverId = ''.obs;
  final RxString driverName = ''.obs;
  final RxString currentUserId = ''.obs;
  final Rx<RideStatus> currentRideStatus = RideStatus.pending.obs;


  // Service active flag
  final RxBool isServiceActive = false.obs;

  // Add notification service reference
  NotificationService get _notificationService => NotificationService.to;

  @override
  void onInit() {
    super.onInit();
    _setupRideStatusListener();
    _setupConnectionListener();
    _signalRService.registerAfterReconnect(_resyncChatAfterHubReconnect);
    print(' SAHAr 🔧 ChatBackgroundService initialized');
  }

  /// Setup listener for connection status
  void _setupConnectionListener() {
    // Listen to connection status to register handlers when connected
    ever(_signalRService.connectionStatus, (status) {
      if (status == SignalRConnectionStatus.connected) {
        // Re-bind handlers: automatic reconnect reuses the hub but [ever] runs again;
        // without [off] first, stacked anonymous handlers would duplicate messages.
        _registerSignalRListeners();
      }
    });

    // Also try immediately if already connected
    if (_signalRService.isConnected) {
      _registerSignalRListeners();
    }
  }

  /// Last identical payload from hub (multiple stacked handlers / hub echo).
  String? _lastInboundDedupeKey;

  /// Stable handler refs for SignalR — must match [MethodInvocationFunc].
  void _onReceiveMessage(List<dynamic>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    final first = arguments[0];
    if (first is! Map) return;
    _handleReceivedMessage(Map<String, dynamic>.from(first));
  }

  void _onReceiveRideChatHistory(List<dynamic>? arguments) {
    print(' SAHAr 📜 ReceiveRideChatHistory event triggered');
    if (arguments == null || arguments.isEmpty) return;
    final first = arguments[0];
    if (first is! List) return;
    final historyData = List<dynamic>.from(first);
    print(' SAHAr 📜 Chat history data received: ${historyData.length} messages');
    _handleChatHistory(historyData);
  }

  void _onReceiveMessageReplay(List<dynamic>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    final first = arguments[0];
    if (first is! List) return;
    for (final item in first) {
      if (item is Map) {
        _handleReceivedMessage(Map<String, dynamic>.from(item));
      }
    }
  }

  /// Register global SignalR listeners
  void _registerSignalRListeners() {
    final connection = _signalRService.connection;
    if (connection == null) return;

    try {
      // Automatic reconnect sets status to "connected" again; anonymous closures
      // stack because signalr_core only dedupes identical function references.
      connection.off('ReceiveMessage');
      connection.off('ReceiveRideChatHistory');
      connection.off('ReceiveMessageReplay');

      connection.on('ReceiveMessage', _onReceiveMessage);
      connection.on('ReceiveRideChatHistory', _onReceiveRideChatHistory);
      connection.on('ReceiveMessageReplay', _onReceiveMessageReplay);

      print(' SAHAr ✅ Chat event handlers registered on shared SignalR connection');

      // If we have an active ride ID, join the chat group
      if (rideId.value.isNotEmpty && isServiceActive.value) {
        Future.microtask(() => _joinRideChat());
      }
    } catch (e) {
      print(' SAHAr ❌ Error registering listeners: $e');
    }
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
    currentRideStatus.value = status;

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

      // Don't stop the shared SignalR connection, just clear chat messages
      // The shared connection is used by other services too
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

      // Use shared SignalR connection - ensure it's connected
      if (!_signalRService.isConnected) {
        print(' SAHAr 🔄 Waiting for SignalR connection...');
        await _signalRService.initializeConnection();
      }


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

  int get _maxKnownChatSequence {
    var m = 0;
    for (final msg in messages) {
      final s = msg.sequence;
      if (s != null && s > m) m = s;
    }
    return m;
  }

  Future<void> _resyncChatAfterHubReconnect() async {
    if (!isServiceActive.value || rideId.value.isEmpty) return;
    if (!_signalRService.isConnected) return;
    await _joinRideChat();
  }

  /// Join ride chat room (sends last hub [Sequence] so server replays missed rows).
  Future<void> _joinRideChat() async {
    if (hubConnection != null && rideId.value.isNotEmpty) {
      try {
        final lastSeq = _maxKnownChatSequence;
        await hubConnection?.invoke('JoinRideChat', args: [rideId.value, lastSeq]);
        print(' SAHAr 📌 Joined ride chat for: ${rideId.value} (afterSequence=$lastSeq)');
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

      final dedupeKey =
          '${messageData['senderId']}|${messageData['dateTime']}|${messageData['message']}';
      if (_lastInboundDedupeKey == dedupeKey) {
        print(' SAHAr 📨 Skipping duplicate chat payload');
        return;
      }
      _lastInboundDedupeKey = dedupeKey;

      final chatMessage = ChatMessage.fromJson(messageData);
      final isFromCurrentUser = chatMessage.senderId == currentUserId.value;

      final messageWithUserFlag = chatMessage.copyWith(
        isFromCurrentUser: isFromCurrentUser,
      );

      messages.add(messageWithUserFlag);

      // Show notification only if message is not from current user
      if (!isFromCurrentUser) {
        _showChatNotification(messageWithUserFlag);
      }
      print(' SAHAr 📨 Received message: ${chatMessage.message}');
    } catch (e) {
      print(' SAHAr ❌ Error handling received message: $e');
    }
  }

  /// Show notification for new chat message - Enhanced with error handling
  Future<void> _showChatNotification(ChatMessage message) async {
    try {
      // Determine sender name (use driver name if message is from driver)
      String senderName = driverName.value.isNotEmpty ? driverName.value : 'Driver';

      // Enhanced notification with debug logging
      print(' SAHAr 🔔 Preparing notification for message from: $senderName');
      print(' SAHAr 🔔 Message content: ${message.message}');
      print(' SAHAr 🔔 Ride ID: ${rideId.value}');

      // Check if notification service is properly initialized
      if (!_notificationService.isInitialized) {
        print(' SAHAr ⚠️ Notification service not initialized, attempting to initialize...');
        try {
          await _notificationService.initializeNotifications();
          if (!_notificationService.isInitialized) {
            print(' SAHAr ❌ Failed to initialize notification service');
            return;
          }
        } catch (initError) {
          print(' SAHAr ❌ Error initializing notification service: $initError');
          return;
        }
      }

      // Check if notifications are enabled
      if (!_notificationService.notificationsEnabled) {
        print(' SAHAr ⚠️ Notifications not enabled, checking permissions...');
        try {
          final permissionResult = await _notificationService.checkAndRequestPermissions();
          if (!permissionResult) {
            print(' SAHAr ❌ Notification permissions not granted');
            return;
          }
        } catch (permError) {
          print(' SAHAr ❌ Error checking notification permissions: $permError');
          return;
        }
      }

      // Show notification via notification service
      await _notificationService.showChatNotification(
        senderName: senderName,
        message: message.message,
        rideId: rideId.value,
      );

      print(' SAHAr 🔔 Notification request sent successfully for message from: $senderName');
    } catch (e) {
      print(' SAHAr ❌ Failed to show notification: $e');

      // Try to debug notification service status
      try {
        await _notificationService.debugNotificationStatus();

        // Attempt to send a test notification to verify the service is working
        print(' SAHAr 🧪 Attempting test notification...');
        await _notificationService.testNotification();
      } catch (debugError) {
        print(' SAHAr ❌ Debug and test also failed: $debugError');

        // Last resort: try to refresh notification permissions
        try {
          print(' SAHAr 🔄 Refreshing notification permissions as last resort...');
          await _notificationService.refreshPermissionStatus();
        } catch (refreshError) {
          print(' SAHAr ❌ Permission refresh also failed: $refreshError');
        }
      }
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

    if (hubConnection == null || !_signalRService.isConnected) {
      print(' SAHAr ❌ Not connected to chat service');
      return false;
    }

    try {
      print(' SAHAr 📤 Sending message via SignalR: $messageText');
      print(' SAHAr    RideId: ${rideId.value}');
      print(' SAHAr    SenderId: ${currentUserId.value}');
      print(' SAHAr    SenderRole: Rider');

      await hubConnection?.invoke('SendMessage', args: [
        rideId.value,
        currentUserId.value,
        messageText,
        'Rider', // Add senderRole parameter
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
    if (_signalRService.isConnected) {
      await _loadChatHistory();
    } else {
      print(' SAHAr ⚠️ Cannot refresh - not connected to chat service');
    }
  }

  @override
  void onClose() {
    _signalRService.unregisterAfterReconnect(_resyncChatAfterHubReconnect);
    messages.clear();
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
