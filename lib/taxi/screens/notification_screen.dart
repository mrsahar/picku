import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pick_u/controllers/notification_controller.dart';
import 'package:pick_u/models/audit_log_model.dart';
import 'package:pick_u/utils/theme/mcolors.dart';
import 'package:pick_u/widget/picku_appbar.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();

    return Scaffold(
      backgroundColor: MColor.lightBg,
      appBar: PickUAppBar(
        title: "Notifications",
        onBackPressed: () {
          Get.back();
        },
        actions: [
          // Filter button
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: MColor.primaryNavy,
            ),
            onPressed: () => _showFilterDialog(context, controller),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading && controller.notifications.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: MColor.primaryNavy,
            ),
          );
        }

        if (controller.errorMessage.isNotEmpty && controller.notifications.isEmpty) {
          return _buildErrorView(controller);
        }

        if (controller.notifications.isEmpty) {
          return _buildEmptyView();
        }

        return _buildNotificationList(controller);
      }),
    );
  }

  Widget _buildNotificationList(NotificationController controller) {
    return RefreshIndicator(
      color: MColor.primaryNavy,
      onRefresh: controller.refreshNotifications,
      child: Column(
        children: [
          // Filter chips if any filters are active
          Obx(() {
            final hasFilters = controller.selectedActionFilter != null ||
                controller.selectedEntityFilter != null;

            if (!hasFilters) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: MColor.lightGrey,
              child: Row(
                children: [
                  const Text(
                    'Filters: ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  if (controller.selectedActionFilter != null)
                    Chip(
                      label: Text(controller.selectedActionFilter!),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => controller.setActionFilter(null),
                      backgroundColor: MColor.primaryNavy.withOpacity(0.1),
                    ),
                  if (controller.selectedEntityFilter != null) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(controller.selectedEntityFilter!),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => controller.setEntityFilter(null),
                      backgroundColor: MColor.primaryNavy.withOpacity(0.1),
                    ),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed: controller.clearFilters,
                    child: Text(
                      'Clear All',
                      style: TextStyle(color: MColor.primaryNavy),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Notification count header
          Obx(() => Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      '${controller.totalCount} Notification${controller.totalCount != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: MColor.primaryNavy,
                      ),
                    ),
                    const Spacer(),
                    if (controller.totalPages > 1)
                      Text(
                        'Page ${controller.currentPage} of ${controller.totalPages}',
                        style: TextStyle(
                          fontSize: 14,
                          color: MColor.mediumGrey,
                        ),
                      ),
                  ],
                ),
              )),

          // Notification list
          Expanded(
            child: Obx(() => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.notifications.length + (controller.hasNextPage ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == controller.notifications.length) {
                      // Load more indicator
                      return Obx(() {
                        if (controller.isLoadingMore) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: MColor.primaryNavy,
                              ),
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: ElevatedButton(
                            onPressed: controller.loadMore,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MColor.primaryNavy,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Load More'),
                          ),
                        );
                      });
                    }

                    final notification = controller.notifications[index];
                    return _buildNotificationCard(notification);
                  },
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AuditLogDto notification) {
    // Extract message from responseData if available
    String? message;
    if (notification.responseData != null && notification.responseData!.containsKey('message')) {
      message = notification.responseData!['message'].toString();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showNotificationDetails(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getStatusColor(notification.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Icon(
                    _getStatusIcon(notification.status),
                    color: _getStatusColor(notification.status),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status
                    if (notification.status != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(notification.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          notification.status!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(notification.status),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Message
                    if (message != null)
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: MColor.darkGrey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right,
                color: MColor.mediumGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return MColor.mediumGrey;
    switch (status.toLowerCase()) {
      case 'success':
        return MColor.primaryNavy; // Green
      case 'failed':
      case 'error':
        return MColor.danger;
      default:
        return MColor.primaryNavy;
    }
  }

  IconData _getStatusIcon(String? status) {
    if (status == null) return Icons.info_outline;
    switch (status.toLowerCase()) {
      case 'success':
        return Icons.check_circle_outline;
      case 'failed':
      case 'error':
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }


  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: MColor.mediumGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MColor.darkGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your activity notifications will appear here',
            style: TextStyle(
              fontSize: 14,
              color: MColor.mediumGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(NotificationController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: MColor.danger,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: MColor.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: MColor.mediumGrey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.refreshNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MColor.primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, NotificationController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: MColor.primaryNavy,
              ),
            ),
            const SizedBox(height: 24),

            // Action filter
            Text(
              'By Action',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: MColor.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('Login', controller),
                _buildFilterChip('Logout', controller),
                _buildFilterChip('Create', controller),
                _buildFilterChip('Update', controller),
                _buildFilterChip('UpdateRide', controller),
                _buildFilterChip('Delete', controller),
              ],
            ),
            const SizedBox(height: 24),

            // Entity type filter
            Text(
              'By Entity Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: MColor.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildEntityFilterChip('Driver', controller),
                _buildEntityFilterChip('User', controller),
                _buildEntityFilterChip('Ride', controller),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  controller.clearFilters();
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MColor.lightGrey,
                  foregroundColor: MColor.darkGrey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Clear Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String action, NotificationController controller) {
    return Obx(() {
      final isSelected = controller.selectedActionFilter == action;
      return FilterChip(
        label: Text(action),
        selected: isSelected,
        onSelected: (selected) {
          controller.setActionFilter(selected ? action : null);
        },
        selectedColor: MColor.primaryNavy.withOpacity(0.2),
        checkmarkColor: MColor.primaryNavy,
      );
    });
  }

  Widget _buildEntityFilterChip(String entity, NotificationController controller) {
    return Obx(() {
      final isSelected = controller.selectedEntityFilter == entity;
      return FilterChip(
        label: Text(entity),
        selected: isSelected,
        onSelected: (selected) {
          controller.setEntityFilter(selected ? entity : null);
        },
        selectedColor: MColor.trackingOrange.withOpacity(0.2),
        checkmarkColor: MColor.trackingOrange,
      );
    });
  }

  void _showNotificationDetails(AuditLogDto notification) {
    // Extract data from responseData if available
    Map<String, dynamic>? responseData = notification.responseData;

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: MColor.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notification Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: MColor.primaryNavy,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Status Badge
              if (notification.status != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getStatusColor(notification.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(notification.status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(notification.status),
                        color: _getStatusColor(notification.status),
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 12,
                                color: MColor.mediumGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.status!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(notification.status),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Message
              if (responseData != null && responseData.containsKey('message'))
                _buildDetailCard(
                  icon: Icons.message,
                  title: 'Message',
                  content: responseData['message'].toString(),
                  color: MColor.primaryNavy,
                ),

              // Full Name
              if (responseData != null && responseData.containsKey('fullName'))
                _buildDetailCard(
                  icon: Icons.person,
                  title: 'Full Name',
                  content: responseData['fullName'].toString(),
                  color: MColor.primaryNavy,
                ),

              // Email
              if (responseData != null && responseData.containsKey('email'))
                _buildDetailCard(
                  icon: Icons.email,
                  title: 'Email',
                  content: responseData['email'].toString(),
                  color: MColor.primaryNavy,
                ),

              // Expires Time
              if (responseData != null && responseData.containsKey('expires'))
                _buildDetailCard(
                  icon: Icons.schedule,
                  title: 'Token Expires',
                  content: _formatExpiryTime(responseData['expires'].toString()),
                  color: MColor.warning,
                ),

              const SizedBox(height: 16),

              // Timestamp
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MColor.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: MColor.mediumGrey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      notification.relativeTime,
                      style: TextStyle(
                        fontSize: 13,
                        color: MColor.darkGrey,
                      ),
                    ),
                    const Spacer(),
                    if (notification.timestamp != null)
                      Text(
                        notification.formattedTimestamp,
                        style: TextStyle(
                          fontSize: 12,
                          color: MColor.mediumGrey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MColor.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MColor.lightGrey,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: MColor.mediumGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: MColor.darkGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatExpiryTime(String expiryString) {
    try {
      final DateTime expiryTime = DateTime.parse(expiryString);
      final now = DateTime.now();
      final difference = expiryTime.difference(now);

      String formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(expiryTime);

      if (difference.isNegative) {
        return '$formattedDate (Expired)';
      } else if (difference.inDays > 0) {
        return '$formattedDate (${difference.inDays} days remaining)';
      } else if (difference.inHours > 0) {
        return '$formattedDate (${difference.inHours} hours remaining)';
      } else if (difference.inMinutes > 0) {
        return '$formattedDate (${difference.inMinutes} minutes remaining)';
      } else {
        return '$formattedDate (Expires soon)';
      }
    } catch (e) {
      return expiryString;
    }
  }

}

