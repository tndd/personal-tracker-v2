import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/color_palette.dart';
import '../../../shared/validators/field_validators.dart';
import '../../../shared/db/database.dart';
import '../state/category_provider.dart';

/// カテゴリ追加/編集ダイアログ。
///
/// カラーパレットから色を選択し、カテゴリ名を入力する。
///
/// 使用例:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => CategoryDialog(),
/// );
/// ```
class CategoryDialog extends ConsumerStatefulWidget {
  const CategoryDialog({
    super.key,
    this.category,
  });

  /// 編集対象のカテゴリ（nullなら新規作成）
  final CategoryRecord? category;

  @override
  ConsumerState<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<CategoryDialog> {
  late TextEditingController _nameController;
  late String _selectedColor;
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedColor = widget.category?.color ?? ColorPalette.presets[0]['value']!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    final categoriesAsync = ref.watch(categoryListProvider);

    return AlertDialog(
      title: Text(isEditing ? 'カテゴリ編集' : 'カテゴリ追加'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // カテゴリ名入力
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'カテゴリ名',
                hintText: '例: 服薬',
                errorText: _errorText,
                counterText: '${_nameController.text.length}/50',
              ),
              maxLength: 50,
              onChanged: (value) {
                setState(() {
                  _errorText = null;
                });
              },
            ),
            const SizedBox(height: 24),
            // 色選択
            Text(
              '色',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ColorPalette.presets.map((preset) {
                final color = preset['value']!;
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: ColorPalette.fromHex(color),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        preset['name']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
    final categoriesAsync = ref.read(categoryListProvider);

    // バリデーション
    final existingNames = categoriesAsync.value
            ?.where((c) => c.id != widget.category?.id)
            .map((c) => c.name)
            .toList() ??
        [];

    final error = validateCategoryName(
      name,
      existingNames: existingNames,
      currentName: widget.category?.name,
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
      final notifier = ref.read(categoryNotifierProvider);

      if (widget.category != null) {
        // 編集
        await notifier.updateCategory(
          id: widget.category!.id,
          name: name,
          color: _selectedColor,
        );
      } else {
        // 新規作成
        await notifier.createCategory(
          name: name,
          color: _selectedColor,
        );
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
