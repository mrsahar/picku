import 'package:get/get.dart';
import 'package:pick_u/models/audit_log_model.dart';
import 'package:pick_u/providers/api_provider.dart';

class NotificationController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  // Observable variables
  final _auditLogResponse = Rxn<AuditLogResponse>();
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _currentPage = 1.obs;
  final _isLoadingMore = false.obs;

  // Filter options
  final _selectedActionFilter = Rxn<String>();
  final _selectedEntityFilter = Rxn<String>();

  // Getters
  AuditLogResponse? get auditLogResponse => _auditLogResponse.value;
  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  String get errorMessage => _errorMessage.value;
  int get currentPage => _currentPage.value;
  String? get selectedActionFilter => _selectedActionFilter.value;
  String? get selectedEntityFilter => _selectedEntityFilter.value;

  List<AuditLogDto> get notifications => auditLogResponse?.data ?? [];
  int get totalCount => auditLogResponse?.totalCount ?? 0;
  int get totalPages => auditLogResponse?.totalPages ?? 0;
  bool get hasNextPage => auditLogResponse?.hasNextPage ?? false;
  bool get hasPreviousPage => auditLogResponse?.hasPreviousPage ?? false;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  /// Fetch notifications (audit logs) from the API
  Future<void> fetchNotifications({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        _currentPage.value = 1;
        _isLoading.value = true;
      } else {
        _isLoading.value = true;
      }

      _errorMessage.value = '';

      final request = AuditLogRequest(
        pageNumber: _currentPage.value,
        pageSize: 20,
        actionFilter: _selectedActionFilter.value,
        entityTypeFilter: _selectedEntityFilter.value,
      );

      final endpoint = '/api/AuditLog/get-my-audit-logs';
      print(' SAHArSAHAr MRSAHAr: Fetching notifications from $endpoint');
      print(' SAHArSAHAr MRSAHAr: Request body = ${request.toJson()}');

      final response = await _apiProvider.postData(endpoint, request.toJson());

      print(' SAHArSAHAr MRSAHAr: response.statusCode = ${response.statusCode}');
      print(' SAHArSAHAr MRSAHAr: response.body = ${response.body}');

      if (response.statusCode == 200) {
        final auditResponse = AuditLogResponse.fromJson(response.body);

        if (isRefresh) {
          _auditLogResponse.value = auditResponse;
        } else {
          _auditLogResponse.value = auditResponse;
        }

        print(' SAHArSAHAr MRSAHAr: Notifications loaded successfully. Total: ${auditResponse.totalCount}');
      } else if (response.statusCode == 401) {
        _errorMessage.value = 'Unauthorized. Please login again.';
        print(' SAHArSAHAr MRSAHAr: 401 Unauthorized');
      } else {
        _errorMessage.value = 'Failed to load notifications: ${response.statusText}';
        print(' SAHArSAHAr MRSAHAr: Failed with status ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage.value = 'Error loading notifications: $e';
      print(' SAHArSAHAr MRSAHAr: Exception = $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load more notifications (next page)
  Future<void> loadMore() async {
    if (!hasNextPage || _isLoadingMore.value) return;

    try {
      _isLoadingMore.value = true;
      _currentPage.value++;

      final request = AuditLogRequest(
        pageNumber: _currentPage.value,
        pageSize: 20,
        actionFilter: _selectedActionFilter.value,
        entityTypeFilter: _selectedEntityFilter.value,
      );

      final endpoint = '/api/AuditLog/get-my-audit-logs';
      final response = await _apiProvider.postData(endpoint, request.toJson());

      if (response.statusCode == 200) {
        final newResponse = AuditLogResponse.fromJson(response.body);

        // Append new data to existing list
        final existingData = _auditLogResponse.value?.data ?? [];
        final combinedData = [...existingData, ...newResponse.data];

        _auditLogResponse.value = AuditLogResponse(
          data: combinedData,
          totalCount: newResponse.totalCount,
          pageNumber: newResponse.pageNumber,
          pageSize: newResponse.pageSize,
          totalPages: newResponse.totalPages,
          hasPreviousPage: newResponse.hasPreviousPage,
          hasNextPage: newResponse.hasNextPage,
        );

        print(' SAHArSAHAr MRSAHAr: Loaded more notifications. Total: ${combinedData.length}');
      }
    } catch (e) {
      print(' SAHArSAHAr MRSAHAr: Error loading more: $e');
    } finally {
      _isLoadingMore.value = false;
    }
  }

  /// Refresh notifications (pull to refresh)
  Future<void> refreshNotifications() async {
    await fetchNotifications(isRefresh: true);
  }

  /// Set action filter and refresh
  void setActionFilter(String? action) {
    _selectedActionFilter.value = action;
    _currentPage.value = 1;
    fetchNotifications(isRefresh: true);
  }

  /// Set entity type filter and refresh
  void setEntityFilter(String? entityType) {
    _selectedEntityFilter.value = entityType;
    _currentPage.value = 1;
    fetchNotifications(isRefresh: true);
  }

  /// Clear all filters
  void clearFilters() {
    _selectedActionFilter.value = null;
    _selectedEntityFilter.value = null;
    _currentPage.value = 1;
    fetchNotifications(isRefresh: true);
  }
}

