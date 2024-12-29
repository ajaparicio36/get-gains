// exercise_search_widget.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../data/services/exercise_search_service.dart';

class ExerciseSearchWidget extends StatefulWidget {
  final Function(String) onExerciseSelected;
  final ExerciseSearchService searchService;
  final InputDecoration? decoration;

  const ExerciseSearchWidget({
    Key? key,
    required this.onExerciseSelected,
    required this.searchService,
    this.decoration,
  }) : super(key: key);

  @override
  _ExerciseSearchWidgetState createState() => _ExerciseSearchWidgetState();
}

class _ExerciseSearchWidgetState extends State<ExerciseSearchWidget> {
  final _searchController = TextEditingController();
  List<String> _suggestions = [];
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (_searchController.text.length >= 2) {
        setState(() => _isLoading = true);
        final results =
            await widget.searchService.searchExercises(_searchController.text);
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      } else {
        setState(() => _suggestions = []);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            return _suggestions;
          },
          onSelected: (String selection) {
            widget.onExerciseSelected(selection);
          },
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController controller,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: widget.decoration?.copyWith(
                    suffixIcon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ) ??
                  InputDecoration(
                    hintText: 'Search exercises...',
                    border: const OutlineInputBorder(),
                    suffixIcon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<String> onSelected,
            Iterable<String> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return ListTile(
                        title: Text(option),
                        onTap: () {
                          onSelected(option);
                        },
                      );
                    },
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
