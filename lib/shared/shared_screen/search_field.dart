// ignore_for_file: deprecated_member_use

import 'package:sahibz_inventory_management_system/utils/animations.dart';
import 'package:flutter/cupertino.dart';

/// Reusable search field widget for data management screens.
///
/// This widget provides a styled Cupertino search text field with consistent
/// placeholder text and padding. It's used for filtering data in tables
/// across inventory, expense, and activity screens.
///
/// The search field provides real-time filtering as the user types,
/// with debouncing handled by the parent widget.
///
/// Usage:
/// ```dart
/// SearchField(
///   controller: searchController,
///   onChanged: (query) => filterData(query),
/// )
/// ```
class SearchField extends StatelessWidget {
  /// Controller for managing the search text.
  final TextEditingController controller;

  /// Dark mode flag to determine text color
  final bool isDarkMode;

  /// Callback invoked when the search text changes.
  ///
  /// Receives the current query string for filtering operations.
  final void Function(String)? onChanged;

  /// Creates a search field widget.
  const SearchField({
    super.key,
    required this.controller,
    required this.isDarkMode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SlideInAnimation(
      delay: Duration(milliseconds: 500),
      child: CupertinoSearchTextField(
        placeholder: 'Search here...',
        placeholderStyle: TextStyle(
          color: isDarkMode ? null : CupertinoColors.black.withOpacity(0.7),
        ),
        padding: EdgeInsets.all(16.0),
        prefixInsets: EdgeInsets.only(left: 15.0),
        prefixIcon: Icon(
          CupertinoIcons.search,
          color: isDarkMode ? null : CupertinoColors.black.withOpacity(0.7),
        ),
        backgroundColor: isDarkMode
            ? null
            : CupertinoColors.black.withOpacity(0.1),
        controller: controller,
        onChanged: onChanged,
      ),
    );
  }
}
