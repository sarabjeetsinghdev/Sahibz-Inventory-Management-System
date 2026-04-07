import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchField extends ConsumerWidget {
  final TextEditingController controller;
  final void Function(String)? onChanged;
  const SearchField({super.key, required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoSearchTextField(
      placeholder: 'Search here...',
      padding: .all(16.0),
      prefixInsets: .only(left: 15.0),
      controller: controller,
      onChanged: onChanged,
    );
  }
}
