// ignore_for_file: deprecated_member_use

import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:flutter/cupertino.dart';

/// This class contains reusable dashboard components
/// 
/// `buildSummaryCard`: Creates a summary card for dashboard metrics
///
/// `buildShortcutButton`: Creates a shortcut button for dashboard Quick actions
class DashboardWidgets {

  /// Dashboard Summary Card Widget
  /// 
  /// Creates a summary card for dashboard metrics
  /// 
  /// [title] - The title text to display at the top of the card
  /// [value] - The value text to display prominently
  /// [icon] - The icon to display at the top of the card
  /// [color] - The color to use for the icon and value text
  Widget buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.darkBackgroundGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: .center,
        children: [
          Icon(icon, color: color, size: 40),
          SizedBox(height: 8),

          // Title
          Text(
            title,
            style: TextStyle(fontSize: 40, color: CupertinoColors.systemGrey),
            textAlign: .center,
          ),
          
          SizedBox(height: 8),

          // Value
          Text(
            value,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Creates a shortcut button for dashboard Quick actions
  /// 
  /// [icon] - The icon to display in the button
  /// [label] - The label text to display below the icon
  /// [onTap] - The callback function to execute when the button is tapped
  Widget buildShortcutButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CustomMouseCursor(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: CupertinoColors.darkBackgroundGray.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: CupertinoColors.systemGrey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Icon(icon, color: CupertinoColors.white, size: 24),

              SizedBox(height: 6),

              // Label
              Text(
                label,
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
