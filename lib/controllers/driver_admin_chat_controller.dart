import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:signalr_core/signalr_core.dart';
import '../models/message_screen_model.dart';
import '../services/share_pref.dart';
import '../services/signalr_service.dart';

class DriverAdminChatController extends GetxController {
  // Use shared SignalR service
  SignalRService get _signalRService => SignalRService.to;
  HubConnection? get _hubConnection => _signalRService.connection;

  // Observable variables
  final messages = <ChatMessage>[].obs;
  RxBool get isConnected => _signalRService.connectionStatus.value == SignalRConnectionStatus.connected ? true.obs : false.obs;
  final isLoading = false.obs;
  final isSending = false.obs;
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  // Driver info
  String? driverId;
  String? senderId;
  final senderRole = 'Driver';


  @override
  void onInit() {
    super.onInit();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      isLoading.value = true;

      // Get driver ID from SharedPreferences
      final driverData = await SharedPrefsService.getDriverID();
      driverId = driverData['userId'];
      senderId = driverData['userId'];

      if (driverId == null || driverId!.isEmpty) {
        Get.snackbar(
          'Error',
          'Driver ID not found. Please login again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
        return;
      }

      // Initialize SignalR connection
      await _setupSignalR();

    } catch (e) {
      print('💥 Chat initialization error: $e');
      Get.snackbar(
        'Connection Error',
        'Failed to initialize chat',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _setupSignalR() async {
    try {
      // Ensure shared SignalR connection is active
      if (!_signalRService.isConnected) {
        print('🔄 Waiting for SignalR connection...');
        await _signalRService.initializeConnection();
      }

      final connection = _signalRService.connection;
      if (connection == null) {
        throw Exception('SignalR connection not available');
      }

      // Register event handlers for driver-admin chat
      connection.on('ReceiveDriverAdminMessage', _handleNewMessage);
      connection.on('ReceiveDriverAdminChatHistory', _handleChatHistory);

      print('✅ Driver admin chat handlers registered on shared SignalR connection');

      await _joinDriverSupport();
      await _loadChatHistory();

    } catch (e) {
      print('❌ SignalR connection error: $e');
    }
  }

  void _handleNewMessage(List<Object?>? args) {
    if (args == null || args.isEmpty) return;

    try {
      final messageData = args[0] as Map<String, dynamic>;
      final newMessage = ChatMessage.fromJson(messageData);

      // Mark if message is from current driver
      final isFromCurrentUser = newMessage.senderId == driverId;
      final messageWithFlag = newMessage.copyWith(isFromCurrentUser: isFromCurrentUser);

      messages.add(messageWithFlag);
      _scrollToBottom();
      print('📨 New message received: ${newMessage.message} (From current user: $isFromCurrentUser)');
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  void _handleChatHistory(List<Object?>? args) {
    if (args == null || args.isEmpty) return;

    try {
      final historyList = args[0] as List<dynamic>;
      messages.clear();

      for (var item in historyList) {
        final message = ChatMessage.fromJson(item as Map<String, dynamic>);

        // Mark if message is from current driver
        final isFromCurrentUser = message.senderId == driverId;
        final messageWithFlag = message.copyWith(isFromCurrentUser: isFromCurrentUser);

        messages.add(messageWithFlag);
      }

      _scrollToBottom();
      print('📜 Loaded ${messages.length} messages from history');
    } catch (e) {
      print('Error handling history: $e');
    }
  }

  Future<void> _joinDriverSupport() async {
    try {
      await _hubConnection?.invoke('JoinDriverSupport', args: [driverId]);
      print('🔔 Joined driver support group for: $driverId');
    } catch (e) {
      print('Failed to join driver support: $e');
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      await _hubConnection?.invoke('GetDriverAdminChatHistory', args: [driverId]);
    } catch (e) {
      print('Failed to load chat history: $e');
    }
  }

  Future<void> sendMessage() async {
    final messageText = messageController.text.trim();

    if (messageText.isEmpty) return;

    if (!_signalRService.isConnected) {
      Get.snackbar(
        'Not Connected',
        'Please wait for connection',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
      );
      return;
    }

    try {
      isSending.value = true;

      await _hubConnection?.invoke(
        'SendDriverAdminMessage',
        args: [driverId, senderId, senderRole, messageText],
      );

      messageController.clear();
      print('📤 Message sent: $messageText');

      await _loadChatHistory();

    } catch (e) {
      print('Failed to send message: $e');
      Get.snackbar(
        'Send Failed',
        'Could not send message',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    } finally {
      isSending.value = false;
    }
  }

  Future<void> retryConnection() async {
    await _setupSignalR();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    // Don't stop the shared SignalR connection
    // Just clear local data
    messages.clear();
    super.onClose();
  }
}