import 'package:flutter_riverpod/legacy.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/features/reports/models/report_models.dart';
import 'package:sahibz_inventory/features/reports/repositories/report_repository.dart';

class ReportState {
  final ReportFilter? currentFilter;
  final bool isLoading;
  final String? error;

  final List<InventoryReportRow>? inventoryReport;
  final List<InventoryValuationRow>? valuationReport;
  final List<StockMovementRow>? stockMovementReport;
  final List<SalesReportRow>? salesReport;
  final List<PurchaseReportRow>? purchaseReport;
  final List<SupplierReportRow>? supplierReport;
  final List<CustomerReportRow>? customerReport;
  final FinancialSummaryRow? financialSummary;
  final List<AuditReportRow>? auditReport;

  const ReportState({
    this.currentFilter,
    this.isLoading = false,
    this.error,
    this.inventoryReport,
    this.valuationReport,
    this.stockMovementReport,
    this.salesReport,
    this.purchaseReport,
    this.supplierReport,
    this.customerReport,
    this.financialSummary,
    this.auditReport,
  });

  bool get hasData =>
    inventoryReport != null ||
    valuationReport != null ||
    stockMovementReport != null ||
    salesReport != null ||
    purchaseReport != null ||
    supplierReport != null ||
    customerReport != null ||
    financialSummary != null ||
    auditReport != null;

  ReportState copyWith({
    ReportFilter? currentFilter,
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<InventoryReportRow>? inventoryReport,
    List<InventoryValuationRow>? valuationReport,
    List<StockMovementRow>? stockMovementReport,
    List<SalesReportRow>? salesReport,
    List<PurchaseReportRow>? purchaseReport,
    List<SupplierReportRow>? supplierReport,
    List<CustomerReportRow>? customerReport,
    FinancialSummaryRow? financialSummary,
    List<AuditReportRow>? auditReport,
  }) {
    return ReportState(
      currentFilter: currentFilter ?? this.currentFilter,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      inventoryReport: inventoryReport ?? this.inventoryReport,
      valuationReport: valuationReport ?? this.valuationReport,
      stockMovementReport: stockMovementReport ?? this.stockMovementReport,
      salesReport: salesReport ?? this.salesReport,
      purchaseReport: purchaseReport ?? this.purchaseReport,
      supplierReport: supplierReport ?? this.supplierReport,
      customerReport: customerReport ?? this.customerReport,
      financialSummary: financialSummary ?? this.financialSummary,
      auditReport: auditReport ?? this.auditReport,
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  final ReportRepository _repository;

  ReportNotifier(this._repository) : super(const ReportState());

  void setFilter(ReportFilter filter) {
    state = state.copyWith(currentFilter: filter);
  }

  void clearFilter() {
    state = state.copyWith(currentFilter: null);
  }

  Future<void> generateInventoryReport({ReportFilter? filters}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getInventoryReport(filters: filters ?? state.currentFilter);
    if (result.isSuccess) {
      state = state.copyWith(inventoryReport: result.value, isLoading: false, clearError: true);
      AppLogger.i('Inventory report generated: ${result.value.length} rows');
    } else {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  Future<void> generateValuationReport() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getInventoryValuationReport();
    if (result.isSuccess) {
      state = state.copyWith(valuationReport: result.value, isLoading: false, clearError: true);
    } else {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  Future<void> generateStockMovementReport({ReportFilter? filters}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getStockMovementReport(filters: filters ?? state.currentFilter);
    if (result.isSuccess) {
      state = state.copyWith(stockMovementReport: result.value, isLoading: false, clearError: true);
    } else {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  Future<void> generateSalesReport({ReportFilter? filters}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getSalesReport(filters: filters ?? state.currentFilter);
    if (result.isSuccess) {
      state = state.copyWith(salesReport: result.value, isLoading: false, clearError: true);
    } else {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  Future<void> generatePurchaseReport({ReportFilter? filters}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getPurchaseReport(filters: filters ?? state.currentFilter);
    if (result.isSuccess) {
      state = state.copyWith(purchaseReport: result.value, isLoading: false, clearError: true);
    } else {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  Future<void> generateSupplierReport({ReportFilter? filters}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getSupplierReport(filters: filters ?? state.currentFilter);
    if (result.isSuccess) {
      state = state.copyWith(supplierReport: result.value, isLoading: false, clearError: true);
    } else {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  Future<void> generateCustomerReport({ReportFilter? filters}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getCustomerReport(filters: filters ?? state.currentFilter);
    if (result.isSuccess) {
      state = state.copyWith(customerReport: result.value, isLoading: false, clearError: true);
    } else {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  Future<void> generateFinancialSummary({ReportFilter? filters}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getFinancialSummary(filters: filters ?? state.currentFilter);
    if (result.isSuccess) {
      state = state.copyWith(financialSummary: result.value, isLoading: false, clearError: true);
    } else {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  Future<void> generateAuditReport({ReportFilter? filters}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getAuditReport(filters: filters ?? state.currentFilter);
    if (result.isSuccess) {
      state = state.copyWith(auditReport: result.value, isLoading: false, clearError: true);
    } else {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  void clearData() {
    state = const ReportState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return ReportNotifier(repository);
});
