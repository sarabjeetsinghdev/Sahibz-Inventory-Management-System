import 'package:flutter/foundation.dart';
import 'package:sahibz_inventory_management_system/database_helper.dart';
import 'package:sahibz_inventory_management_system/models/recent_activity.dart';
import 'package:sahibz_inventory_management_system/utils/export_data/data_selection_layer.dart';
import 'package:sahibz_inventory_management_system/utils/export_timings_enum.dart';

Future<void> insertDummyData() async {
  if (!kDebugMode) return;

  final db = await DatabaseHelper.instance.database;

  final tables = [
    DatabaseTableNames.saleItem.value,
    DatabaseTableNames.purchaseItem.value,
    DatabaseTableNames.sale.value,
    DatabaseTableNames.purchase.value,
    DatabaseTableNames.expense.value,
    DatabaseTableNames.recentactivity.value,
    DatabaseTableNames.supplier.value,
    DatabaseTableNames.inventory.value,
  ];

  for (final table in tables) {
    await db.delete(table);
  }

  final now = DateTime.now();
  String fmt(DateTime d) => d.toIso8601String();
  final today = DateTime(now.year, now.month, now.day, 10, 15);
  final yesterday = today.subtract(const Duration(days: 1));
  final thisWeekStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  final thisWeekMid = thisWeekStart.add(const Duration(days: 2, hours: 11));
  final lastWeekMid = thisWeekStart.subtract(const Duration(days: 6, hours: 4));
  final thisMonthEarly = DateTime(now.year, now.month, 2, 9, 30);
  final lastMonthMid = DateTime(now.year, now.month - 1, 15, 14, 0);
  final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
  final thisQuarterMid = DateTime(now.year, quarterStartMonth + 1, 10, 12, 0);
  final lastQuarterMid = DateTime(
    now.year,
    quarterStartMonth - 2,
    20,
    16,
    45,
  );
  final thisYearEarly = DateTime(now.year, 1, 8, 8, 0);
  final lastYearMid = DateTime(now.year - 1, 6, 18, 13, 20);

  final datePool = <DateTime>[
    today,
    yesterday,
    thisWeekMid,
    lastWeekMid,
    thisMonthEarly,
    lastMonthMid,
    thisQuarterMid,
    lastQuarterMid,
    thisYearEarly,
    lastYearMid,
  ];
  int dateIndex = 0;
  DateTime nextDate() {
    final d = datePool[dateIndex % datePool.length];
    dateIndex++;
    return d;
  }

  final inventoryItems = [
    {
      'name': 'Intel Core i5-12400F (6C/12T) - Tray',
      'company': 'Intel',
      'unit': 'Unit',
      'date': fmt(nextDate()),
      'update_date': null,
    },
    {
      'name': 'NVIDIA GeForce RTX 3060 12GB GDDR6 - Dual Fan',
      'company': 'NVIDIA',
      'unit': 'Unit',
      'date': fmt(nextDate()),
      'update_date': fmt(nextDate()),
    },
    {
      'name': 'Samsung 970 EVO Plus NVMe M.2 1TB (MZ-V7S1T0)',
      'company': 'Samsung',
      'unit': 'Unit',
      'date': fmt(nextDate()),
      'update_date': null,
    },
    {
      'name': 'Corsair Vengeance LPX 16GB (2x8GB) DDR4 3200MHz',
      'company': 'Corsair',
      'unit': 'Unit',
      'date': fmt(nextDate()),
      'update_date': fmt(nextDate()),
    },
    {
      'name': 'ASUS ROG STRIX B660-F GAMING WIFI',
      'company': 'ASUS',
      'unit': 'Unit',
      'date': fmt(nextDate()),
      'update_date': null,
    },
    {
      'name': 'Seagate BarraCuda 2TB HDD 7200RPM SATA 6Gb/s',
      'company': 'Seagate',
      'unit': 'Unit',
      'date': fmt(nextDate()),
      'update_date': null,
    },
    {
      'name': 'Logitech MX Master 3S Wireless Mouse (Graphite)',
      'company': 'Logitech',
      'unit': 'Unit',
      'date': fmt(nextDate()),
      'update_date': fmt(nextDate()),
    },
    {
      'name': 'Dell UltraSharp U2723QE 27" 4K IPS USB-C Hub Monitor',
      'company': 'Dell',
      'unit': 'Unit',
      'date': fmt(nextDate()),
      'update_date': null,
    },
    {
      'name': 'HP LaserJet Pro M404dn - Printer (A4, Duplex)',
      'company': 'HP',
      'unit': 'Unit',
      'date': fmt(nextDate()),
      'update_date': null,
    },
    {
      'name': 'TP-Link Archer AX73 AX5400 Wi-Fi 6 Router',
      'company': 'TP-Link',
      'unit': 'Unit',
      'date': fmt(nextDate()),
      'update_date': fmt(nextDate()),
    },
  ];
  for (final item in inventoryItems) {
    await db.insert(DatabaseTableNames.inventory.value, item);
  }

  final supplierRows = [
    {
      'name': 'TechDistro Inc.',
      'contact': '1234567890',
      'email': 'orders@techdistro.com',
      'address': '123 Tech Street, Suite 11',
      'date': fmt(nextDate()),
    },
    {
      'name': 'GlobalParts Ltd.',
      'contact': '9876543210',
      'email': 'info@globalparts.com',
      'address': '456 Global Ave',
      'date': fmt(nextDate()),
    },
    {
      'name': 'ElectroSource Co.',
      'contact': '5551234567',
      'email': 'sales@electrosource.com',
      'address': '789 Electro Blvd',
      'date': fmt(nextDate()),
    },
    {
      'name': 'Prime Components & Co.',
      'contact': '5550001112',
      'email': 'support@primecomponents.com',
      'address': '22 Prime Road, Block B',
      'date': fmt(nextDate()),
    },
    {
      'name': 'OfficeSupplies Depot',
      'contact': '5559998887',
      'email': 'hello@officesuppliesdepot.com',
      'address': '9 Stationery Lane',
      'date': fmt(nextDate()),
    },
  ];
  for (final s in supplierRows) {
    await db.insert(DatabaseTableNames.supplier.value, s);
  }

  final supplierMaps = await db.query(DatabaseTableNames.supplier.value, orderBy: 'id ASC');
  final supplierIds = supplierMaps
      .map((e) => e['supplier_id'])
      .whereType<String>()
      .toList();

  final expenses = [
    {
      'title': 'Office Rent',
      'amount': 1500.0,
      'type': 'Rent',
      'description': 'Monthly office rent',
      'date': fmt(thisMonthEarly),
    },
    {
      'title': 'Internet Bill',
      'amount': 200.0,
      'type': 'Utilities',
      'description': 'Monthly internet service',
      'date': fmt(yesterday),
    },
    {
      'title': 'Electricity (Warehouse)',
      'amount': 325.75,
      'type': 'Utilities',
      'description': 'Metered electricity charges',
      'date': fmt(lastMonthMid),
    },
    {
      'title': 'Software Licenses',
      'amount': 500.0,
      'type': 'Software Licenses',
      'description': 'Annual software licenses',
      'date': fmt(thisYearEarly),
    },
    {
      'title': 'Marketing Campaign - Search Ads',
      'amount': 1000.0,
      'type': 'Marketing',
      'description': 'Campaign spend',
      'date': fmt(thisQuarterMid),
    },
    {
      'title': 'Courier / Delivery',
      'amount': 89.99,
      'type': 'Logistics',
      'description': 'Local deliveries',
      'date': fmt(today),
    },
    {
      'title': 'Stationery & Printing',
      'amount': 45.20,
      'type': 'Office',
      'description': 'Stationery purchases',
      'date': fmt(lastYearMid),
    },
  ];
  for (final e in expenses) {
    await db.insert(DatabaseTableNames.expense.value, e);
  }

  final purchaseSeeds = [
    {
      'invoice_number': 'INV-1001',
      'payment_method': 'Cash',
      'total_cost_before_tax': 3750.0,
      'total_tax_amount': 137.50,
      'total_discount': 0.0,
      'date': fmt(today),
    },
    {
      'invoice_number': 'INV-1002',
      'payment_method': 'Bank Transfer',
      'total_cost_before_tax': 2700.0,
      'total_tax_amount': 45.0,
      'total_discount': 50.0,
      'date': fmt(yesterday),
    },
    {
      'invoice_number': 'INV-1003',
      'payment_method': 'Card',
      'total_cost_before_tax': 520.0,
      'total_tax_amount': 0.0,
      'total_discount': 0.0,
      'date': fmt(thisWeekMid),
    },
    {
      'invoice_number': 'INV-1004',
      'payment_method': 'Cash',
      'total_cost_before_tax': 1899.99,
      'total_tax_amount': 85.50,
      'total_discount': 0.0,
      'date': fmt(lastMonthMid),
    },
    {
      'invoice_number': 'INV-1005',
      'payment_method': 'Bank Transfer',
      'total_cost_before_tax': 999.0,
      'total_tax_amount': 0.0,
      'total_discount': 0.0,
      'date': fmt(lastYearMid),
    },
  ];
  for (final p in purchaseSeeds) {
    await db.insert(DatabaseTableNames.purchase.value, p);
  }

  final purchaseMaps = await db.query(
    DatabaseTableNames.purchase.value,
    orderBy: 'id ASC',
  );
  final purchaseIds = purchaseMaps
      .map((e) => e['purchase_id'])
      .whereType<String>()
      .toList();

  final productCatalog = <Map<String, dynamic>>[
    {'name': 'Intel Core i5-12400F (6C/12T) - Tray', 'cost': 200.0, 'sp': 250.0},
    {'name': 'NVIDIA GeForce RTX 3060 12GB GDDR6 - Dual Fan', 'cost': 350.0, 'sp': 450.0},
    {'name': 'Samsung 970 EVO Plus NVMe M.2 1TB (MZ-V7S1T0)', 'cost': 100.0, 'sp': 130.0},
    {'name': 'Corsair Vengeance LPX 16GB (2x8GB) DDR4 3200MHz', 'cost': 80.0, 'sp': 110.0},
    {'name': 'Logitech MX Master 3S Wireless Mouse (Graphite)', 'cost': 75.0, 'sp': 99.0},
    {'name': 'Dell UltraSharp U2723QE 27" 4K IPS USB-C Hub Monitor', 'cost': 410.0, 'sp': 550.0},
    {'name': 'TP-Link Archer AX73 AX5400 Wi-Fi 6 Router', 'cost': 120.0, 'sp': 160.0},
  ];

  int productIndex = 0;
  Map<String, dynamic> nextProduct() {
    final p = productCatalog[productIndex % productCatalog.length];
    productIndex++;
    return p;
  }

  final purchaseItemRows = <Map<String, dynamic>>[];
  for (int i = 0; i < purchaseIds.length; i++) {
    final purchaseId = purchaseIds[i];
    final supplierId = supplierIds.isEmpty
        ? 'unknown'
        : supplierIds[i % supplierIds.length];
    for (int j = 0; j < 3; j++) {
      final product = nextProduct();
      final quantity = 5 + ((i + j) % 6);
      final discount = (j % 2 == 0) ? 0.0 : 10.0;
      final tax = (j % 3 == 0) ? 0.0 : 12.50;
      purchaseItemRows.add({
        'purchase_id': purchaseId,
        'supplier_id': supplierId,
        'product_name': product['name'],
        'cost': product['cost'],
        'quantity': quantity,
        'quantity_left': quantity,
        'discount': discount,
        'tax': tax,
        'selling_price': product['sp'],
        'date': fmt(nextDate()),
      });
    }
  }
  for (final row in purchaseItemRows) {
    await db.insert(DatabaseTableNames.purchaseItem.value, row);
  }

  final pItems = await db.query(
    DatabaseTableNames.purchaseItem.value,
    orderBy: 'id ASC',
  );
  final purchaseItemRefs = pItems
      .where((e) => e['unique_id'] is String && e['product_name'] is String)
      .map(
        (e) => {
          'unique_id': e['unique_id'] as String,
          'product_name': e['product_name'] as String,
          'purchase_id': e['purchase_id'] as String?,
          'supplier_id': e['supplier_id'] as String?,
        },
      )
      .toList();

  final sales = [
    {
      'payment_method': 'Cash',
      'gross_total': 1150.0,
      'total_tax': 57.50,
      'total_discount': 0.0,
      'date': fmt(today),
    },
    {
      'payment_method': 'Card',
      'gross_total': 260.0,
      'total_tax': 0.0,
      'total_discount': 15.0,
      'date': fmt(thisWeekMid),
    },
    {
      'payment_method': 'Bank Transfer',
      'gross_total': 999.0,
      'total_tax': 0.0,
      'total_discount': 0.0,
      'date': fmt(lastQuarterMid),
    },
  ];
  for (final s in sales) {
    await db.insert(DatabaseTableNames.sale.value, s);
  }

  final saleMaps = await db.query(DatabaseTableNames.sale.value, orderBy: 'id ASC');
  final saleIds = saleMaps
      .map((e) => e['sale_id'])
      .whereType<String>()
      .toList();

  int saleItemIndex = 0;
  for (int i = 0; i < saleIds.length; i++) {
    final saleId = saleIds[i];
    for (int j = 0; j < 2; j++) {
      if (purchaseItemRefs.isEmpty) continue;
      final ref = purchaseItemRefs[saleItemIndex % purchaseItemRefs.length];
      saleItemIndex++;

      await db.insert(DatabaseTableNames.saleItem.value, {
        'sale_id': saleId,
        'purchase_id': ref['purchase_id'],
        'supplier_id': ref['supplier_id'],
        'unique_id': ref['unique_id'],
        'product_name': ref['product_name'],
        'quantity': 1 + ((i + j) % 3),
        'price': 0.0,
        'discount': (j % 2 == 0) ? 0.0 : 5.0,
        'tax': (j % 3 == 0) ? 0.0 : 2.5,
        'cost': 0.0,
        'date': fmt(nextDate()),
      });
    }
  }

  final List<String> activities = [
    RecentActivityType.inventoryAdded.value,
    RecentActivityType.expenseAdded.value,
    RecentActivityType.supplierAdded.value,
    RecentActivityType.purchaseAdded.value,
    RecentActivityType.saleAdded.value,
    RecentActivityType.purchaseItemAdded.value,
    RecentActivityType.saleItemAdded.value,
  ];
  for (int i = 0; i < activities.length; i++) {
    await db.insert(DatabaseTableNames.recentactivity.value, {
      'type': activities[i],
      'date': fmt(nextDate()),
    });
  }

  await _runExportDataLayerSmokeTest();
}

Future<void> _runExportDataLayerSmokeTest() async {
  final timings = ExportTimingsEnum.values;
  final tables = [
    DatabaseTableNames.saleItem,
    DatabaseTableNames.purchaseItem,
    DatabaseTableNames.sale,
    DatabaseTableNames.purchase,
    DatabaseTableNames.expense,
    DatabaseTableNames.recentactivity,
    DatabaseTableNames.supplier,
    DatabaseTableNames.inventory,
  ];

  for (final timing in timings) {
    int total = 0;
    for (final table in tables) {
      final rows = await DataLayer(tableName: table, timings: timing);
      total += rows.length;
    }
    debugPrint('DataLayer smoke test: ${timing.name} -> totalRows=$total');
  }
}
