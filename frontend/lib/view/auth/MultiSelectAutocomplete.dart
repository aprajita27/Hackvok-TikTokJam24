import 'package:flutter/material.dart';

class MultiSelectAutocomplete extends StatefulWidget {
  final Map<String, String> options;
  final List<String> selectedOptions;
  final Function(List<String>) onSelectionChanged;

  MultiSelectAutocomplete({
    required this.options,
    required this.selectedOptions,
    required this.onSelectionChanged,
  });

  @override
  _MultiSelectAutocompleteState createState() => _MultiSelectAutocompleteState();
}

class _MultiSelectAutocompleteState extends State<MultiSelectAutocomplete> {
  late TextEditingController _textEditingController;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          children: widget.selectedOptions.map((option) {
            return Chip(
              label: Text(option),
              onDeleted: () {
                setState(() {
                  widget.selectedOptions.remove(option);
                  widget.onSelectionChanged(widget.selectedOptions);
                });
              },
            );
          }).toList(),
        ),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return widget.options.keys.where((String option) {
              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            setState(() {
              if (!widget.selectedOptions.contains(selection)) {
                widget.selectedOptions.add(selection);
                widget.onSelectionChanged(widget.selectedOptions);
              }
              _textEditingController.clear();
            });
          },
          fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
            _textEditingController = fieldTextEditingController;
            _focusNode = fieldFocusNode;
            return SizedBox(
              height: 50,
              width: 350,
              child: TextField(
                controller: fieldTextEditingController,
                focusNode: fieldFocusNode,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.language, size: 15),
                  hintText: "Known Languages",
                  // contentPadding: EdgeInsets.symmetric(vertical: 5.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
