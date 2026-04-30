// ignore_for_file: deprecated_member_use

import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

Future<List<dynamic>> itemSelector({
  required BuildContext context,
  required List<String> items,
  required bool isSingleSelector,
  required FlutterStorageSetter storageSetter,
}) async {
  final result = await showCupertinoDialog<List<dynamic>>(
    context: context,
    builder: (context) {
      return KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: IntrinsicHeight(
                  child: IntrinsicWidth(
                    child: Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.darkBackgroundGray,
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width / 2.5,
                      ),
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 10.0,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 5.0),
                                child: Text(
                                  'Select Items',
                                  style: TextStyle(fontSize: 28.0),
                                ),
                              ),
                              CustomMouseCursor(
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: const Icon(
                                    CupertinoIcons.xmark,
                                    color: CupertinoColors.systemRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: _ItemSelector(
                              context: context,
                              items: items,
                              isSingleSelector: isSingleSelector,
                              storageSetter: storageSetter,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  return result ?? [];
}

class _ItemSelector extends StatefulWidget {
  final BuildContext context;
  final List<String> items;
  final bool isSingleSelector;
  final FlutterStorageSetter storageSetter;
  const _ItemSelector({
    required this.context,
    required this.items,
    required this.isSingleSelector,
    required this.storageSetter,
  });

  @override
  State<_ItemSelector> createState() => _ItemSelectorState();
}

class _ItemSelectorState extends State<_ItemSelector> {
  List<String> _items = [];
  List<String> _searchReservedItems = [];
  List<dynamic> selectedItems = [];
  List<dynamic> searchReservedSelectedItems = [];
  List<int> selectedIndexes = [];
  final TextEditingController searchController = TextEditingController();
  int? hoverIndex;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() {
    // Copy list to avoid mutating original
    List<String> itemss = List.from(widget.items);

    // Setting the state
    setState(() {
      _items = itemss;
      _searchReservedItems = itemss;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search field
        CupertinoTextField(
          placeholder: 'Search items...',
          controller: searchController,
          padding: .all(15.0),
          onChanged: (value) {
            if (widget.items.isEmpty) return;
            setState(() {
              _items = _searchReservedItems;
              _items = _items
                  .where(
                    (item) => item.toLowerCase().contains(
                      searchController.text.toLowerCase(),
                    ),
                  )
                  .toList();
            });
          },
        ),

        SizedBox(height: 15.0),

        // List of items
        widget.items.isEmpty
            ? Center(child: Text('No items found'))
            : Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    return CustomMouseCursor(
                      onEnter: (p0) {
                        setState(() {
                          hoverIndex = index;
                        });
                      },
                      onExit: (p0) {
                        setState(() {
                          hoverIndex = null;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: .all(
                            color: CupertinoColors.white.withOpacity(0.2),
                            width: 0.5,
                          ),
                          borderRadius: .circular(10.0),
                        ),
                        child: CupertinoListTile(
                          backgroundColor: selectedIndex == index
                              ? CupertinoColors.systemBlue.withOpacity(0.1)
                              : hoverIndex == index
                              ? CupertinoColors.systemGrey.withOpacity(0.1)
                              : null,
                          onTap: () {
                            setState(() {
                            if (selectedIndex == index) {
                              selectedIndex = null;
                            } else {
                              selectedIndex = index;
                            }
                              if (selectedIndexes.contains(index)) {
                                if (widget.isSingleSelector) {
                                  selectedItems.remove(_items[index]);
                                }
                                selectedIndexes.remove(index);
                              } else {
                                if (widget.isSingleSelector &&
                                    selectedIndexes.isNotEmpty) {
                                  setState(() {
                                    selectedIndexes.clear();
                                  });
                                }
                                if (widget.isSingleSelector) {
                                  selectedItems.add(_items[index]);
                                }
                                selectedIndexes.add(index);
                              }
                            });
                          },
                          leading: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (selectedIndexes.contains(index)) {
                                  if (widget.isSingleSelector) {
                                    selectedItems.remove(_items[index]);
                                  }
                                  selectedIndexes.remove(index);
                                } else {
                                  if (widget.isSingleSelector &&
                                      selectedIndexes.isNotEmpty) {
                                    setState(() {
                                      selectedIndexes.clear();
                                    });
                                  }
                                  if (widget.isSingleSelector) {
                                    selectedItems.add(_items[index]);
                                  }
                                  selectedIndexes.add(index);
                                }
                              });
                            },
                            child: selectedIndexes.contains(index)
                                ? Icon(
                                    CupertinoIcons.check_mark_circled_solid,
                                  )
                                : Icon(CupertinoIcons.add),
                          ),
                          title: Text(_items[index]),
                          trailing: widget.isSingleSelector
                              ? null
                              : Expanded(
                                  child: CupertinoTextField(
                                    placeholder: 'Quantity',
                                    onChanged: (value) {
                                      if (int.tryParse(value) == null) {
                                        ErrorDialog(
                                          context: context,
                                          error:
                                              'Quantity must be a non-negative, non-zero, non-decimal number',
                                          storageSetter: widget.storageSetter,
                                        );
                                        value = '';
                                        return;
                                      }
                        
                                      /// If Single Selector, add the item to the selected items list else add the map of item and quantity to the selected list
                                      setState(() {
                                        if (!widget.isSingleSelector &&
                                            !selectedItems.any(
                                              (item) => item.containsKey(
                                                _items[index],
                                              ),
                                            )) {
                                          selectedItems.add({
                                            _items[index].toString():
                                                int.parse(value),
                                          });
                                        } else if (!widget.isSingleSelector) {
                                          // Update the existing item's quantity
                                          for (var item in selectedItems) {
                                            if (item.containsKey(
                                              _items[index],
                                            )) {
                                              item[_items[index]] = int.parse(
                                                value,
                                              );
                                              break;
                                            }
                                          }
                                        }
                        
                                        if (widget.isSingleSelector) {
                                          selectedItems.add(_items[index]);
                                        }
                        
                                        searchReservedSelectedItems =
                                            selectedItems;
                                        selectedIndexes.add(index);
                                      });
                                    },
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),

        // Cancel and Select buttons
        Padding(
          padding: .symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              CustomMouseCursor(
                child: CupertinoButton.filled(
                  sizeStyle: CupertinoButtonSize.medium,
                  borderRadius: BorderRadius.circular(10.0),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
              ),
              CustomMouseCursor(
                child: CupertinoButton.filled(
                  sizeStyle: CupertinoButtonSize.medium,
                  borderRadius: BorderRadius.circular(10.0),
                  onPressed: () {
                    Navigator.of(widget.context).pop(selectedItems);
                  },
                  child: Text('Select'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
