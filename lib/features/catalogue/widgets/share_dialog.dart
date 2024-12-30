import 'package:flutter/material.dart';

class ShareWorkoutDialog extends StatefulWidget {
  final String workoutId;
  final String workoutName;
  final Function(String workoutId, String description, List<String> tags)
      onShare;

  const ShareWorkoutDialog({
    Key? key,
    required this.workoutId,
    required this.workoutName,
    required this.onShare,
  }) : super(key: key);

  @override
  State<ShareWorkoutDialog> createState() => _ShareWorkoutDialogState();
}

class _ShareWorkoutDialogState extends State<ShareWorkoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _tags = [];

  @override
  void dispose() {
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share Workout'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Share "${widget.workoutName}" with the community'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Add a description of your workout...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please add a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma separated)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Share'),
                  content: const Text(
                    'Are you sure you want to share this workout? '
                    'It will be visible to all users.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        widget.onShare(
                          widget.workoutId,
                          _descriptionController.text,
                          _tags,
                        );
                        // Close both dialogs
                        Navigator.of(context)
                          ..pop() // Close confirmation dialog
                          ..pop(); // Close share dialog
                      },
                      child: const Text('Share'),
                    ),
                  ],
                ),
              );
            }
          },
          child: const Text('Share'),
        ),
      ],
    );
  }
}
