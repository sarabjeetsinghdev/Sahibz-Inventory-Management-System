// ignore_for_file: non_constant_identifier_names

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/screens/recentactivity_screen.dart';
import 'package:flutter/cupertino.dart';

void RecentActivitiesDialog({required BuildContext context}) {
  CoreDialogFramework(context: context, content: RecentactivityScreen());
}
