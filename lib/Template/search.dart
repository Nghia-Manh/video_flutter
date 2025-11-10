import 'package:flutter/material.dart';

class SearchField<T> extends StatefulWidget {
  final Widget label;
  final Icon prefixIcon;
  final Icon suffixIcon;
  final TextStyle? textStyle;
  final Icon iconCheck;
  final bool isEnabled;
  final bool isfilled;
  final Color? fillColor;
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<T> items;
  final Function(String) onSearch;
  final Function(T) onSelect;
  final String Function(T) getLabel;
  final String? errorText;
  final bool isLoading;
  final GlobalKey? fieldKey;
  final bool showSelected;
  final bool showDropdownOnFocus;
  final InputDecoration? decoration;

  const SearchField({
    Key? key,
    required this.label,
    required this.prefixIcon,
    required this.suffixIcon,
    required this.iconCheck,
    required this.controller,
    required this.focusNode,
    required this.items,
    required this.onSearch,
    required this.onSelect,
    required this.getLabel,
    this.textStyle,
    this.errorText,
    this.isLoading = false,
    this.isEnabled = true,
    this.isfilled = false,
    this.fillColor,
    this.fieldKey,
    this.showSelected = true,
    this.showDropdownOnFocus = true,
    this.decoration,
  }) : super(key: key);

  @override
  State<SearchField<T>> createState() => _SearchFieldState<T>();
}

class _SearchFieldState<T> extends State<SearchField<T>> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: widget.fieldKey,
          controller: widget.controller,
          focusNode: widget.focusNode,
          decoration:
              widget.decoration ??
              InputDecoration(
                label: widget.label,
                prefixIcon: widget.prefixIcon,
                contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.blue.shade200,
                    // width: 2
                  ),
                ),
                enabled: widget.isEnabled,
                filled: widget.isfilled,
                fillColor: widget.fillColor,
                labelStyle: widget.textStyle,
                suffixIcon: widget.suffixIcon,
                errorText: widget.errorText,
              ),
          onChanged: widget.onSearch,
          style: const TextStyle(color: Colors.black),
        ),
        if (widget.isEnabled &&
            widget.items.isNotEmpty &&
            (widget.showSelected || widget.focusNode.hasFocus))
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            margin: const EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 4),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: widget.isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: widget.items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      return InkWell(
                        onTap: () => widget.onSelect(item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                child:
                                    widget.getLabel(widget.items[index]) ==
                                        widget.controller.text
                                    ? widget.iconCheck
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  widget.getLabel(item),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}

String normalizeString(String str) {
  final _vietnamese = <String, String>{
    'à': 'a',
    'á': 'a',
    'ạ': 'a',
    'ả': 'a',
    'ã': 'a',
    'â': 'a',
    'ầ': 'a',
    'ấ': 'a',
    'ậ': 'a',
    'ẩ': 'a',
    'ẫ': 'a',
    'ă': 'a',
    'ằ': 'a',
    'ắ': 'a',
    'ặ': 'a',
    'ẳ': 'a',
    'ẵ': 'a',
    'è': 'e',
    'é': 'e',
    'ẹ': 'e',
    'ẻ': 'e',
    'ẽ': 'e',
    'ê': 'e',
    'ề': 'e',
    'ế': 'e',
    'ệ': 'e',
    'ể': 'e',
    'ễ': 'e',
    'ì': 'i',
    'í': 'i',
    'ị': 'i',
    'ỉ': 'i',
    'ĩ': 'i',
    'ò': 'o',
    'ó': 'o',
    'ọ': 'o',
    'ỏ': 'o',
    'õ': 'o',
    'ô': 'o',
    'ồ': 'o',
    'ố': 'o',
    'ộ': 'o',
    'ổ': 'o',
    'ỗ': 'o',
    'ơ': 'o',
    'ờ': 'o',
    'ớ': 'o',
    'ợ': 'o',
    'ở': 'o',
    'ỡ': 'o',
    'ù': 'u',
    'ú': 'u',
    'ụ': 'u',
    'ủ': 'u',
    'ũ': 'u',
    'ư': 'u',
    'ừ': 'u',
    'ứ': 'u',
    'ự': 'u',
    'ử': 'u',
    'ữ': 'u',
    'ỳ': 'y',
    'ý': 'y',
    'ỵ': 'y',
    'ỷ': 'y',
    'ỹ': 'y',
    'đ': 'd',
  };

  String result = str.toLowerCase();
  _vietnamese.forEach((k, v) => result = result.replaceAll(k, v));
  return result;
}
