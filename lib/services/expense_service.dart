import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/models/expense.dart';

class ExpenseService {
  final CoreService core = CoreService(tableName: 'expense');

  Future<int> count({
    String? where,
    List<Object?>? whereArgs,
  }) async {
    return await core.countTotal();
  }

  Future<num> totalExpenses() async {
    return await core.totalExpenses();
  }

  Future<List<Map<String, Object?>>> getAll() async {
    return await core.getAll();
  }

  Future<int> insert({required Expense expense}) async {
    Map<String, Object?> data = expense.toJson();
    data.remove('id');
    return await core.insert(data: data);
  }

  Future<int> update({
    required int id,
    required Expense expense,
    String? idColumnName,
  }) async {
    return await core.update(
      id: id,
      data: expense.toJson(),
      idColumnName: idColumnName,
    );
  }

  Future<int> delete({required int id, String? idColumnName}) async {
    return await core.delete(id: id, idColumnName: idColumnName);
  }
}
