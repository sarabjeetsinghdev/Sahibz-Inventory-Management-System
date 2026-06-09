// // ignore_for_file: deprecated_member_use, non_constant_identifier_names

// import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
// import 'package:flutter/cupertino.dart';


// class PickerWidget extends StatefulWidget {
//   final List<String> Function() getItems;
//   final FlutterStorageSetter storageSetter;
//   const PickerWidget({super.key, required this.getItems, required this.storageSetter});

//   @override
//   State<PickerWidget> createState() => _PickerWidgetState();
// }

// class _PickerWidgetState extends State<PickerWidget> {
//   int selectedIndex = 0;
//   String selectedValue = '';
//   bool isDarkMode = false;

//   @override
//   void initState() {
//     super.initState();
//     init();
//   }

//   void init() async {
//     isDarkMode = await widget.storageSetter.getDarkMode() ?? false;
//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       spacing: 16.0,
//       children: [
//         CupertinoPicker(
//           useMagnifier: true,
//           magnification: 1.5,
//           backgroundColor: isDarkMode
//               ? CupertinoColors.black.withOpacity(0.5)
//               : CupertinoColors.systemGrey6.withOpacity(0.95),
//           itemExtent: widget.getItems().length.toDouble(),
//           onSelectedItemChanged: (index) {
//             selectedIndex = index;
//             selectedValue = widget.getItems()[index];
//             setState(() {});
//           },
//           children: widget.getItems().map((item) => Text(item)).toList(),
//         ),
//         CupertinoButton(
//           child: const Text('Close'),
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//         ),
//         CupertinoButton(
//           child: const Text('Select'),
//           onPressed: () {
//             Navigator.of(context).pop(selectedValue);
//           },
//         ),
//       ],
//     );
//   }
// }
