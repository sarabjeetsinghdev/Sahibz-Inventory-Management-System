// ignore_for_file: must_be_immutable, implementation_imports

import 'package:sahibz_inventory_management_system/shared/shared_screen/refresh_button.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/search_field.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/table_data.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/add_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';

class SharedScreen extends StatefulWidget {
  final String toptitle;
  final String title;
  List<Map<String, dynamic>> data;
  List<Map<String, dynamic>> searchReserveddata;
  void Function(VoidCallback onadd) onAdd;
  void Function(VoidCallback onupdate, dynamic data) onUpdate;
  void Function(VoidCallback ondelete, int dataId) onDelete;
  void Function() onRefresh;
  SharedScreen({
    super.key,
    required this.toptitle,
    required this.title,
    required this.data,
    required this.searchReserveddata,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  State<StatefulWidget> createState() => _SharedScreenState();
}

class _SharedScreenState extends State<SharedScreen> {
  final TextEditingController searchController = TextEditingController();

  void searchData(String query) {
    setState(() {
      if (query.isEmpty) {
        widget.data = widget.searchReserveddata;
      } else {
        widget.data = widget.searchReserveddata.where((item) {
          return item.values.any(
            (value) =>
                value.toString().toLowerCase().contains(query.toLowerCase()),
          );
        }).toList();
      }
    });
  }

  void refreshData() {
    setState(() {
      widget.data = [];
    });
    if (searchController.text.isNotEmpty) {
      searchData(searchController.text);
    } else {
      widget.onRefresh();
      setState(() {
        widget.data = widget.searchReserveddata;
      });
    }
  }

  void addData() {
    widget.onAdd(widget.onRefresh);
  }

  void updateData(VoidCallback onupdate, dynamic data) {
    widget.onUpdate(onupdate, data);
  }

  void deleteData(VoidCallback ondelete, int dataId) {
    widget.onDelete(ondelete, dataId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Row
          Row(
            spacing: 16.0,
            children: [
              // Title
              Text(
                widget.title,
                style: GoogleFonts.robotoSlab(fontSize: 50.0),
              ),
              // Searchbar
              Expanded(
                child: SearchField(
                  controller: searchController,
                  onChanged: (query) => searchData(query),
                ),
              ),
              // Refresh button
              RefreshButton(onRefresh: refreshData),
              // Add Button
              AddButton(onAdd: addData),
            ],
          ),
          // SizedBox
          SizedBox(height: 25.0),
          // Table
          TableData(
            data: widget.data,
            onUpdate: updateData,
            onDelete: deleteData,
            onRefresh: widget.onRefresh,
          ),
        ],
      ),
    );
  }
}
