// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../../../search/selected_tags/types.dart';

class NewTabRequest {
  const NewTabRequest({
    required this.tags,
    this.title,
  });

  final List<String> tags;
  final String? title;
}

Future<NewTabRequest?> showNewTabDialog(BuildContext context) {
  return showDialog<NewTabRequest>(
    context: context,
    builder: (context) => const _NewTabDialog(),
  );
}

class _NewTabDialog extends StatefulWidget {
  const _NewTabDialog();

  @override
  State<_NewTabDialog> createState() => _NewTabDialogState();
}

class _NewTabDialogState extends State<_NewTabDialog> {
  late final _tagsController = TextEditingController();
  late final _titleController = TextEditingController();

  @override
  void dispose() {
    _tagsController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New tab'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tagsController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'space-separated, leave empty for all',
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final tagsText = _tagsController.text.trim();
            final tags = tagsText.isEmpty ? <String>[] : queryAsList(tagsText);
            final title = _titleController.text.trim();
            Navigator.of(context).pop(
              NewTabRequest(
                tags: tags,
                title: title.isEmpty ? null : title,
              ),
            );
          },
          child: const Text('Open'),
        ),
      ],
    );
  }
}
