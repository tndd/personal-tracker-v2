import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// アーカイブされたカテゴリとタグの管理画面。
///
/// アーカイブ済みのカテゴリとタグを一覧表示し、
/// レストアまたは削除を行う。
class ArchivedTagsPage extends ConsumerWidget {
  const ArchivedTagsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/tags');
          },
        ),
      ),
      body: const Center(
        child: Text('アーカイブ画面（未実装）'),
      ),
    );
  }
}
