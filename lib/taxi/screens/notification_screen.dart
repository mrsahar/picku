import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
              // Icon with status badge
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: MColor.primaryNavy.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        notification.actionIcon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  // Status badge
                  if (notification.status != null)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: MColor.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            notification.statusBadge,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      notification.notificationTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: MColor.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      notification.notificationSubtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: MColor.darkGrey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Metadata chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (notification.action != null)
                          _buildChip(
                            notification.action!,
                            Icons.label,
                            MColor.primaryNavy,
                          ),
                        if (notification.entityType != null)
                          _buildChip(
                            notification.entityType!,
                            Icons.category,
                            MColor.trackingOrange,
                          ),
                        if (notification.userType != null)
                          _buildChip(
                            notification.userType!,
                            Icons.person,
                            MColor.warning,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Time and duration
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: MColor.mediumGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notification.relativeTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: MColor.mediumGrey,
                          ),
                        ),
                        if (notification.duration != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.timer,
                            size: 14,
                            color: MColor.mediumGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.formattedDuration,
                            style: TextStyle(
                              fontSize: 12,
                              color: MColor.mediumGrey,
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
              // Header
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: MColor.primaryNavy.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Center(
                      child: Text(
                        notification.actionIcon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.notificationTitle,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: MColor.primaryNavy,
                                ),
                              ),
                            ),
                            Text(
                              notification.statusBadge,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.relativeTime,
                          style: TextStyle(
                            fontSize: 14,
                            color: MColor.mediumGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Status
              if (notification.status != null)
                _buildDetailRow('Status', notification.status!),

              // User Type
              if (notification.userType != null)
                _buildDetailRow('User Type', notification.userType!),

              // Action
              if (notification.action != null)
                _buildDetailRow('Action', notification.action!),

              // Entity Type
              if (notification.entityType != null)
                _buildDetailRow('Entity Type', notification.entityType!),

              // Entity ID
              if (notification.entityId != null)
                _buildDetailRow('Entity ID', notification.entityId!),

              // Duration
              if (notification.duration != null)
                _buildDetailRow('Duration', notification.formattedDuration),

              // IP Address
              if (notification.ipAddress != null)
                _buildDetailRow('IP Address', notification.ipAddress!),

              // Timestamp
              if (notification.timestamp != null)
                _buildDetailRow('Date & Time', notification.formattedTimestamp),

              // Error Message
              if (notification.errorMessage != null && notification.errorMessage!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MColor.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: MColor.danger.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: MColor.danger, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Error Message',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: MColor.danger,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.errorMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: MColor.darkGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Old Values
              if (notification.oldValues != null && notification.oldValues!.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Old Values',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MColor.primaryNavy,
                  ),
                ),
                const SizedBox(height: 12),
                ...notification.oldValues!.entries.map((entry) =>
                  _buildDetailRow(entry.key, entry.value.toString()),
                ),
              ],

              // New Values
              if (notification.newValues != null && notification.newValues!.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'New Values',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MColor.primaryNavy,
                  ),
                ),
                const SizedBox(height: 12),
                ...notification.newValues!.entries.map((entry) =>
                  _buildDetailRow(entry.key, entry.value.toString()),
                ),
              ],

              // Request Data
              if (notification.requestData != null && notification.requestData!.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Request Data',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MColor.primaryNavy,
                  ),
                ),
                const SizedBox(height: 12),
                ...notification.requestData!.entries.map((entry) =>
                  _buildDetailRow(entry.key, entry.value.toString()),
                ),
              ],

              // Response Data
              if (notification.responseData != null && notification.responseData!.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Response Data',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MColor.primaryNavy,
                  ),
                ),
                const SizedBox(height: 12),
                ...notification.responseData!.entries.map((entry) =>
                  _buildDetailRow(entry.key, entry.value.toString()),
                ),
              ],

              // User Agent
              if (notification.userAgent != null && notification.userAgent!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow('User Agent', notification.userAgent!),
              ],
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: MColor.mediumGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: MColor.darkGrey,
            ),
          ),
        ],
      ),
    );
  }
}
