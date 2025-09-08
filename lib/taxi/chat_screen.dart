import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/controllers/chat_controller.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ChatController controller = Get.find<ChatController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          'Chat with ${controller.driverName.value}',
          style: const TextStyle(fontSize: 18),
        )),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Connection status indicator
          Obx(() => Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: controller.isConnected.value ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  controller.isConnected.value ? Icons.wifi : Icons.wifi_off,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  controller.isConnected.value ? 'Online' : 'Offline',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          )),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Obx(() {
              if (controller.isLoadingMessages.value && controller.messages.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading chat history...'),
                    ],
                  ),
                );
              }

              if (controller.messages.isEmpty && !controller.isLoadingMessages.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start a conversation with your driver',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  return _buildMessageBubble(message, theme);
                },
              );
            }),
          ),

          // Connection error banner
          Obx(() => !controller.isConnected.value
              ? Container(
                  width: double.infinity,
                  color: Colors.red.shade100,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Connection lost. Messages may not be delivered.',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                      TextButton(
                        onPressed: controller.retryConnection,
                        child: Text(
                          'Retry',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink()),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => controller.sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                Obx(() => CircleAvatar(
                  backgroundColor: theme.primaryColor,
                  child: IconButton(
                    onPressed: controller.isSending.value || !controller.isConnected.value
                        ? null
                        : controller.sendMessage,
                    icon: controller.isSending.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.white,
                          ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic message, ThemeData theme) {
    final isFromCurrentUser = message.isFromCurrentUser;

    return Align(
      alignment: isFromCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: Get.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isFromCurrentUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromCurrentUser
                    ? theme.primaryColor
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isFromCurrentUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                  bottomLeft: !isFromCurrentUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  color: isFromCurrentUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.dateTime.toTimeString(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
