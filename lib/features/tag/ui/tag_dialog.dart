import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/validators/field_validators.dart';
import '../../../shared/db/database.dart';
import '../state/tag_provider.dart';

/// タグ追加/編集ダイアログ。
///
/// カテゴリに属するタグ名を入力する。
///
/// 使用例:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => TagDialog(categoryId: 'xxx', categoryName: '服薬'),
/// );
/// ```
class TagDialog extends ConsumerStatefulWidget {
  const TagDialog({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.tag,
  });

  final String categoryId;
  final String categoryName;

  /// 編集対象のタグ（nullなら新規作成）
  final TagRecord? tag;

  @override
  ConsumerState<TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends ConsumerState<TagDialog> {
  late TextEditingController _nameController;
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tag?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.tag != null;

    return AlertDialog(
      title: Text(isEditing ? 'タグ編集 - ${widget.categoryName}' : 'タグ追加 - ${widget.categoryName}'),
      content: SizedBox(
        width: 400,
        child: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'タグ名',
            hintText: '例: デパス',
            errorText: _errorText,
            counterText: '${_nameController.text.length}/50',
          ),
          maxLength: 50,
          autofocus: true,
          onChanged: (value) {
            setState(() {
              _errorText = null;
            });
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: Text(isEditing ? '更新' : '追加'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final tagsAsync = ref.read(tagListByCategoryProvider(widget.categoryId));

    // バリデーション
    final existingNames = tagsAsync.value
            ?.where((t) => t.id != widget.tag?.id)
            .map((t) => t.name)
            .toList() ??
        [];

    final error = validateTagName(
      name,
      existingNamesInCategory: existingNames,
      currentName: widget.tag?.name,
    );

    if (error != null) {
      setState(() {
        _errorText = error;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final notifier = ref.read(tagListByCategoryProvider(widget.categoryId).notifier);

      if (widget.tag != null) {
        // 編集
        await notifier.updateTag(
          id: widget.tag!.id,
          name: name,
        );
      } else {
        // 新規作成
        await notifier.createTag(name: name);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }
}
