import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class ItemSelector extends StatefulWidget {
  final List<String> items;
  final List<String>? labels;
  final String? initialValue;
  final ValueChanged<String> onSelected;
  final VoidCallback? onCancel;

  const ItemSelector({
    super.key,
    required this.items,
    required this.onSelected,
    this.labels,
    this.initialValue,
    this.onCancel,
  });

  @override
  State<ItemSelector> createState() => _ItemSelectorState();
}

class _ItemSelectorState extends State<ItemSelector> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedValue;
  List<int> _filteredIndices = [];
  int? _hoveredIndex;
  int? _pressedIndex;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    _applyFilter();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredIndices = List.generate(widget.items.length, (i) => i);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredIndices = [
        for (var i = 0; i < widget.items.length; i++)
          if (_labelAt(i).toLowerCase().contains(query)) i
      ];
    }
  }

  String _labelAt(int index) {
    if (widget.labels != null && index < widget.labels!.length) {
      return widget.labels![index];
    }
    return widget.items[index];
  }

  void _onItemTap(int index) {
    setState(() {
      _selectedValue = widget.items[index];
      _pressedIndex = null;
    });
  }

  void _onDone() {
    if (_selectedValue != null) {
      widget.onSelected(_selectedValue!);
    }
    Navigator.pop(context);
  }

  void _onCancel() {
    widget.onCancel?.call();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final brightness =
        CupertinoTheme.of(context).brightness ?? Brightness.light;
    final isDark = brightness == Brightness.dark;
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final screenHeight = MediaQuery.of(context).size.height;
    final bgColor = isDark ? const Color(0xFF1E293B) : CupertinoColors.white;
    final hoverColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final selectedColor =
        isDark ? const Color.fromARGB(255, 16, 82, 168) : const Color.fromARGB(255, 154, 201, 255);
    final dividerColor =
        isDark ? const Color(0xFF334155) : CupertinoColors.systemGrey5;
    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.65,
        minWidth: 280,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomPointer(
                  child: GestureDetector(
                    onTap: _onCancel,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(CupertinoIcons.xmark,
                          color: CupertinoColors.destructiveRed, size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search...',
                placeholderStyle: TextStyle(
                    fontSize: 16.0,
                    letterSpacing: 1.1,
                    color: textColor!.withValues(alpha: 0.6)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                prefixInsets: const EdgeInsets.only(left: 14.0),
                decoration: BoxDecoration(
                  border: Border.all(color: textColor, width: 0.1),
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applyFilter();
                  });
                },
              ),
            ),
          ],
          Flexible(
            child: _filteredIndices.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.search,
                            size: 32, color: CupertinoColors.systemGrey3),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No items available'
                              : 'No matching items',
                          style: AppTypography.poppins(
                              color: CupertinoColors.systemGrey, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: dividerColor),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredIndices.length,
                      itemBuilder: (context, i) {
                        final index = _filteredIndices[i];
                        final label = _labelAt(index);
                        final value = widget.items[index];
                        final isSelected = _selectedValue == value;
                        final isHovered = _hoveredIndex == index;
                        final isPressed = _pressedIndex == index;
                  
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          onEnter: (_) => setState(() => _hoveredIndex = index),
                          onExit: (_) => setState(() => _hoveredIndex = null),
                          child: GestureDetector(
                            onTapDown: (_) =>
                                setState(() => _pressedIndex = index),
                            onTapUp: (_) => _onItemTap(index),
                            onTapCancel: () =>
                                setState(() => _pressedIndex = null),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 20),
                              decoration: BoxDecoration(
                                color: isPressed
                                    ? primaryColor.withValues(alpha: 0.2)
                                    : isSelected
                                        ? selectedColor
                                        : isHovered
                                            ? hoverColor
                                            : bgColor,
                                border: Border(
                                  bottom:
                                      BorderSide(color: dividerColor, width: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? primaryColor
                                          : const Color(0x00000000),
                                      border: Border.all(
                                        color: isSelected
                                            ? primaryColor
                                            : dividerColor,
                                        width: isSelected ? 0 : 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(CupertinoIcons.check_mark,
                                            size: 15,
                                            color: CupertinoColors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 150),
                                      style: AppTypography.poppins(
                                        fontSize: 15,
                                        color: textColor,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                      child: Text(label),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomPointer(
                  child: CupertinoButton.filled(
                    sizeStyle: CupertinoButtonSize.medium,
                    color: CupertinoColors.systemRed,
                    onPressed: _onCancel,
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.xmark, size: 15),
                        const SizedBox(width: 8),
                        Text('cancel'.tr()),
                      ],
                    ),
                  ),
                ),
                CustomPointer(
                  child: CupertinoButton.filled(
                    sizeStyle: CupertinoButtonSize.medium,
                    onPressed: _selectedValue != null ? _onDone : null,
                    child: const Row(
                      children: [
                        Text('Done'),
                        SizedBox(width: 8),
                        Icon(CupertinoIcons.chevron_right, size: 15),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
