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

  /// Callback invoked when the search text changes.
  ///
  /// Receives the current query string for filtering operations.
  final void Function(String)? onChanged;

  /// Creates a search field widget.
  const SearchField({super.key, required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CupertinoSearchTextField(
      placeholder: 'Search here...',
      padding: .all(16.0),
      prefixInsets: .only(left: 15.0),
      controller: controller,
      onChanged: onChanged,
    );
  }
}
