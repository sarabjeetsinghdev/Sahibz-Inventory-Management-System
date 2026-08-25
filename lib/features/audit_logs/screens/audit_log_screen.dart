import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:sahibz_inventory/core/extensions.dart';
import 'package:sahibz_inventory/features/audit_logs/models/audit_log_model.dart';
import 'package:sahibz_inventory/features/audit_logs/providers/audit_log_provider.dart';
import 'package:sahibz_inventory/shared/custom_modal.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';
import 'package:sahibz_inventory/shared/item_selector.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/shared/widgets/list_screen_template.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const AuditLogScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  final _searchController = TextEditingController();

  String? _selectedAction;
  String? _selectedEntityType;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(auditLogProvider.notifier).fetchAll(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auditLogProvider);

    final hasFilters = state.hasSearch ||
        state.filterAction != null ||
        state.filterEntityType != null ||
        state.filterStartDate != null ||
        state.filterEndDate != null;

    return ListScreenTemplate(
      showAppBar: widget.showAppBar,
      title: 'audit_logs'.tr(),
      navTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPointer(
              child: GestureDetector(
            onTap: () => _showFilterDialog(context, state),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(CupertinoIcons.line_horizontal_3_decrease_circle,
                  color: context.primaryColor),
            ),
          )),
          if (hasFilters)
            CustomPointer(
                child: GestureDetector(
              onTap: () => ref.read(auditLogProvider.notifier).clearFilters(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(CupertinoIcons.clear, color: context.primaryColor),
              ),
            )),
        ],
      ),
      searchController: _searchController,
      searchPlaceholder: 'Search logs by action, entity or details...',
      hasSearch: state.hasSearch,
      onSearchChanged: (value) =>
          ref.read(auditLogProvider.notifier).search(value),
      filterChips: [
        if (state.hasSearch)
          _filterChip('Search: ${state.searchQuery}', () {
            _searchController.clear();
            ref.read(auditLogProvider.notifier).search('');
          }),
        if (state.filterAction != null)
          _filterChip('Action: ${state.filterAction}', () {
            _selectedAction = null;
            ref.read(auditLogProvider.notifier).applyFilters(
                  action: null,
                  entityType: _selectedEntityType,
                  startDate: _startDate,
                  endDate: _endDate,
                );
          }),
        if (state.filterEntityType != null)
          _filterChip('Entity: ${state.filterEntityType}', () {
            _selectedEntityType = null;
            ref.read(auditLogProvider.notifier).applyFilters(
                  action: _selectedAction,
                  entityType: null,
                  startDate: _startDate,
                  endDate: _endDate,
                );
          }),
        if (state.filterStartDate != null || state.filterEndDate != null)
          _filterChip(
            'Date: ${state.filterStartDate?.formattedDate ?? ''} - ${state.filterEndDate?.formattedDate ?? ''}',
            () {
              _startDate = null;
              _endDate = null;
              ref.read(auditLogProvider.notifier).applyFilters(
                    action: _selectedAction,
                    entityType: _selectedEntityType,
                    startDate: null,
                    endDate: null,
                  );
            },
          ),
      ],
      isLoading: state.isLoading,
      hasError: state.error != null,
      errorMessage: state.error,
      onRetry: () =>
          ref.read(auditLogProvider.notifier).fetchAll(refresh: true),
      isEmpty: state.logs.isEmpty,
      emptyIcon: 'clock',
      emptyMessage: 'No Audit Logs Found',
      hasMore: state.hasMore,
      onLoadMore: () => ref.read(auditLogProvider.notifier).loadMore(),
      totalCount: state.logs.length,
      countLabel: 'logs',
      contentBuilder: (context, scrollController) => ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.logs.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.logs.length) {
            return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CupertinoActivityIndicator()),
            );
          }
          return _buildLogCard(context, state.logs[index]);
        },
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onDeleted) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: AppTypography.poppins(fontSize: 11, color: context.primaryTextColor)),
          const SizedBox(width: 4),
          CustomPointer(
              child: GestureDetector(
                  onTap: onDeleted,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Icon(CupertinoIcons.xmark,
                        size: 12, color: context.primaryTextColor),
                  ))),
        ],
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, AuditLogModel log) {
    final actionColor = _getActionColor(log.action, context.primaryColor);
    final actionIcon = _getActionIcon(log.action);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: CustomPointer(
          child: GestureDetector(
        onTap: () => _showLogDetails(context, log),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(actionIcon, color: actionColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _actionBadge(log.action, actionColor),
                        const SizedBox(width: 8),
                        _entityBadge(log.entityType, context.primaryColor),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(CupertinoIcons.person,
                            size: 13, color: context.secondaryTextColor),
                        const SizedBox(width: 4),
                        Text(log.userName ?? 'System',
                            style: AppTypography.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: context.secondaryTextColor)),
                        if (log.entityId != null &&
                            log.entityId!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(CupertinoIcons.tag,
                              size: 13, color: context.secondaryTextColor),
                          const SizedBox(width: 4),
                          Text(
                            log.entityId!.length > 8
                                ? '...${log.entityId!.substring(log.entityId!.length - 8)}'
                                : log.entityId!,
                            style: AppTypography.poppins(
                                fontSize: 11,
                                color: context.secondaryTextColor),
                          ),
                        ],
                      ],
                    ),
                    if (log.details != null && log.details!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(log.details!,
                            style: AppTypography.poppins(
                                fontSize: 13,
                                color: context.secondaryTextColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    if (log.performedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.clock,
                                size: 12, color: context.secondaryTextColor),
                            const SizedBox(width: 4),
                            Text(log.performedAt!.formattedDateTime,
                                style: AppTypography.poppins(
                                    fontSize: 10,
                                    color: context.secondaryTextColor)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(CupertinoIcons.chevron_right,
                  size: 20, color: context.secondaryTextColor),
            ],
          ),
        ),
      )),
    );
  }

  Widget _actionBadge(String action, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(action.toUpperCase(),
          style: AppTypography.poppins(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _entityBadge(String entityType, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(entityType.toUpperCase(),
          style: AppTypography.poppins(
              fontSize: 10, fontWeight: FontWeight.w500, color: color)),
    );
  }

  void _showLogDetails(BuildContext context, AuditLogModel log) {
    final actionColor = _getActionColor(log.action, context.primaryColor);

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: actionColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getActionIcon(log.action),
                  color: actionColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${log.action.toUpperCase()} - ${log.entityType.toUpperCase()}',
                      style: AppTypography.poppins(
                          fontWeight: FontWeight.w600,
                          color: context.primaryTextColor)),
                  if (log.entityId != null && log.entityId!.isNotEmpty)
                    Text('ID: ${log.entityId}',
                        style: AppTypography.poppins(
                            fontSize: 13, color: context.secondaryTextColor)),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailSection('User Information', context.primaryColor, [
                _detailRow(
                    CupertinoIcons.person, 'User', log.userName ?? 'System'),
                if (log.userId != null && log.userId!.isNotEmpty)
                  _detailRow(CupertinoIcons.tag, 'User ID', log.userId!),
              ]),
              const SizedBox(height: 12),
              _detailSection('Action Details', context.primaryColor, [
                _detailRow(
                    CupertinoIcons.info, 'Action', log.action.toUpperCase()),
                _detailRow(CupertinoIcons.folder, 'Entity Type',
                    log.entityType.toUpperCase()),
                if (log.entityId != null && log.entityId!.isNotEmpty)
                  _detailRow(CupertinoIcons.tag, 'Entity ID', log.entityId!),
              ]),
              if (log.details != null && log.details!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _detailSection('Details', context.primaryColor, [
                  Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(log.details!,
                          style: AppTypography.poppins(color: context.primaryTextColor))),
                ]),
              ],
              if (log.oldValues != null && log.oldValues!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _detailSection('Old Values', context.primaryColor, [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.borderColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.oldValues!.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join('\n'),
                      style: AppTypography.poppins(
                          fontSize: 12,
                          color: context.secondaryTextColor),
                    ),
                  ),
                ]),
              ],
              if (log.newValues != null && log.newValues!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _detailSection('New Values', context.primaryColor, [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.borderColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.newValues!.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join('\n'),
                      style: AppTypography.poppins(
                          fontSize: 12,
                          color: context.secondaryTextColor),
                    ),
                  ),
                ]),
              ],
              if (log.ipAddress != null || log.userAgent != null) ...[
                const SizedBox(height: 12),
                _detailSection('Request Info', context.primaryColor, [
                  if (log.ipAddress != null && log.ipAddress!.isNotEmpty)
                    _detailRow(
                        CupertinoIcons.globe, 'IP Address', log.ipAddress!),
                  if (log.userAgent != null && log.userAgent!.isNotEmpty)
                    _detailRow(CupertinoIcons.device_desktop, 'User Agent',
                        log.userAgent!),
                ]),
              ],
              if (log.performedAt != null) ...[
                const SizedBox(height: 12),
                _detailSection('Timestamp', context.primaryColor, [
                  _detailRow(CupertinoIcons.calendar, 'Date',
                      log.performedAt!.formattedDate),
                  _detailRow(CupertinoIcons.clock, 'Time',
                      log.performedAt!.formattedTimeWithSeconds),
                ]),
              ],
            ],
          ),
        ),
        actions: [
          CustomPointer(
            child: CupertinoButton(
                child: Text('close'.tr()),
                onPressed: () => Navigator.pop(context)),
          ),
        ],
      ),
    );
  }

  Widget _detailSection(String title, Color color, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTypography.poppins(
                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(height: 6),
        ...children,
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: context.secondaryTextColor),
          const SizedBox(width: 8),
          Text('$label: ',
              style: AppTypography.poppins(
                  fontWeight: FontWeight.w500,
                  color: context.primaryTextColor)),
          Expanded(
              child: Text(value,
                  style: AppTypography.poppins(color: context.primaryTextColor))),
        ],
      ),
    );
  }

  Future<void> _showFilterDialog(
      BuildContext context, AuditLogState state) async {
    final result = await showCupertinoDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AuditFilterDialog(
        currentAction: state.filterAction,
        currentEntityType: state.filterEntityType,
        currentStartDate: state.filterStartDate,
        currentEndDate: state.filterEndDate,
      ),
    );

    if (result != null) {
      _selectedAction = result['action'] as String?;
      _selectedEntityType = result['entityType'] as String?;
      _startDate = result['startDate'] as DateTime?;
      _endDate = result['endDate'] as DateTime?;
      ref.read(auditLogProvider.notifier).applyFilters(
            action: _selectedAction,
            entityType: _selectedEntityType,
            startDate: _startDate,
            endDate: _endDate,
          );
    }
  }

  Color _getActionColor(String action, Color color) {
    switch (action) {
      case 'create':
        return color;
      case 'update':
        return CupertinoColors.systemBlue;
      case 'delete':
        return CupertinoColors.destructiveRed;
      case 'stock_in':
        return CupertinoColors.systemGreen;
      case 'stock_out':
        return CupertinoColors.systemOrange;
      case 'stock_adjust':
        return CupertinoColors.systemYellow;
      case 'stock_transfer':
        return CupertinoColors.systemPurple;
      case 'login':
        return CupertinoColors.systemPurple;
      case 'logout':
        return CupertinoColors.systemOrange;
      default:
        return color;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'create':
        return CupertinoIcons.add_circled;
      case 'update':
        return CupertinoIcons.pencil;
      case 'delete':
        return CupertinoIcons.trash;
      case 'stock_in':
        return CupertinoIcons.tray_arrow_down;
      case 'stock_out':
        return CupertinoIcons.tray_arrow_up;
      case 'stock_adjust':
        return CupertinoIcons.slider_horizontal_3;
      case 'stock_transfer':
        return CupertinoIcons.arrow_right_arrow_left;
      case 'login':
        return CupertinoIcons.arrow_right;
      case 'logout':
        return CupertinoIcons.arrow_left;
      default:
        return CupertinoIcons.info;
    }
  }
}

class _AuditFilterDialog extends StatefulWidget {
  final String? currentAction;
  final String? currentEntityType;
  final DateTime? currentStartDate;
  final DateTime? currentEndDate;

  const _AuditFilterDialog({
    this.currentAction,
    this.currentEntityType,
    this.currentStartDate,
    this.currentEndDate,
  });

  @override
  State<_AuditFilterDialog> createState() => _AuditFilterDialogState();
}

class _AuditFilterDialogState extends State<_AuditFilterDialog> {
  String? _localAction;
  String? _localEntityType;
  DateTime? _localStartDate;
  DateTime? _localEndDate;

  @override
  void initState() {
    super.initState();
    _localAction = widget.currentAction;
    _localEntityType = widget.currentEntityType;
    _localStartDate = widget.currentStartDate;
    _localEndDate = widget.currentEndDate;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text('filter_audit_logs'.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPointer(
                child: GestureDetector(
              onTap: () => _showActionPicker(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('Action: ',
                        style: AppTypography.poppins(color: context.secondaryTextColor)),
                    Text(
                      _localAction != null
                          ? _localAction![0].toUpperCase() +
                              _localAction!.substring(1)
                          : 'All Actions',
                      style: AppTypography.poppins(color: context.primaryTextColor),
                    ),
                    const Spacer(),
                    Icon(CupertinoIcons.chevron_down,
                        size: 16, color: context.secondaryTextColor),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 12),
            CustomPointer(
                child: GestureDetector(
              onTap: () => _showEntityPicker(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('Entity: ',
                        style: AppTypography.poppins(color: context.secondaryTextColor)),
                    Text(
                      _localEntityType != null
                          ? _localEntityType![0].toUpperCase() +
                              _localEntityType!.substring(1)
                          : 'All Entities',
                      style: AppTypography.poppins(color: context.primaryTextColor),
                    ),
                    const Spacer(),
                    Icon(CupertinoIcons.chevron_down,
                        size: 16, color: context.secondaryTextColor),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: CustomPointer(
                        child: GestureDetector(
                  onTap: () => _showDatePicker(context, true),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('start_date'.tr(),
                            style: AppTypography.poppins(
                                fontSize: 11,
                                color: context.secondaryTextColor)),
                        const SizedBox(height: 4),
                        Text(_localStartDate?.formattedDate ?? 'Select',
                            style: AppTypography.poppins(
                                color: _localStartDate != null
                                    ? context.primaryTextColor
                                    : context.secondaryTextColor)),
                      ],
                    ),
                  ),
                ))),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomPointer(
                      child: GestureDetector(
                    onTap: () => _showDatePicker(context, false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: context.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
Text('end_date'.tr(),
                            style: AppTypography.poppins(
                                fontSize: 11,
                                color: context.secondaryTextColor)),
                          const SizedBox(height: 4),
                          Text(_localEndDate?.formattedDate ?? 'Select',
                              style: AppTypography.poppins(
                                  color: _localEndDate != null
                                      ? context.primaryTextColor
                                      : context.secondaryTextColor)),
                        ],
                      ),
                    ),
                  )),
                ),
              ],
            )
          ],
        ),
      ),
      actions: [
        CustomPointer(
          child: CupertinoButton(
            child: Text('clear_all'.tr()),
            onPressed: () => Navigator.pop(context, {
              'action': null,
              'entityType': null,
              'startDate': null,
              'endDate': null,
            }),
          ),
        ),
        CupertinoButton.filled(
          child: Text('apply'.tr()),
          onPressed: () => Navigator.pop(context, {
            'action': _localAction,
            'entityType': _localEntityType,
            'startDate': _localStartDate,
            'endDate': _localEndDate,
          }),
        ),
      ],
    );
  }

  void _showActionPicker(BuildContext context) {
    final actions = [
      'All Actions',
      'Create',
      'Update',
      'delete'.tr(),
      'stock_in'.tr(),
      'stock_out'.tr(),
      'Stock Adjust',
      'Stock Transfer',
      'login'.tr(),
      'logout'.tr(),
    ];
    const values = [
      null,
      'create',
      'update',
      'delete',
      'stock_in',
      'stock_out',
      'stock_adjust',
      'stock_transfer',
      'login',
      'logout',
    ];

    showCustomModal(
      context: context,
      builder: (_) => ItemSelector(
        items: actions,
        initialValue: actions[values.indexOf(_localAction)],
        onSelected: (value) {
          final idx = actions.indexOf(value);
          setState(() => _localAction = values[idx]);
        },
      ),
    );
  }

  void _showEntityPicker(BuildContext context) {
    const entities = [
      'All Entities',
      'Product',
      'Category',
      'Supplier',
      'Customer',
      'Purchase',
      'Sale',
      'User',
      'Role',
      'Setting'
    ];
    const values = [
      null,
      'product',
      'category',
      'supplier',
      'customer',
      'purchase',
      'sale',
      'user',
      'role',
      'setting'
    ];

    showCustomModal(
      context: context,
      builder: (_) => ItemSelector(
        items: entities,
        initialValue: entities[values.indexOf(_localEntityType)],
        onSelected: (value) {
          final idx = entities.indexOf(value);
          setState(() => _localEntityType = values[idx]);
        },
      ),
    );
  }

  void _showDatePicker(BuildContext context, bool isStart) {
    showCustomModal(
      context: context,
      builder: (ctx) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomPointer(
                child: CupertinoButton(
                  child: Text('done'.tr()),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: isStart
                  ? (_localStartDate ?? DateTime.now())
                  : (_localEndDate ?? DateTime.now()),
              minimumDate: DateTime(2020),
              maximumDate: DateTime.now(),
              onDateTimeChanged: (date) {
                setState(() {
                  if (isStart) {
                    _localStartDate = date;
                  } else {
                    _localEndDate = date;
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
