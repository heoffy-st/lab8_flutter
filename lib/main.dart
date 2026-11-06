import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/dio_client.dart';
import 'data/local/post_cache.dart';
import 'data/remote/post_api.dart';
import 'data/repositories/post_repository.dart';
import 'presentation/screens/posts_page.dart';
import 'presentation/state/post_state.dart';

void main() {
  final dio = DioClient.create();
  final api = PostApi(dio);
  final cache = PostCache();

  final repository = PostRepository(api: api, cache: cache);

  runApp(
    ChangeNotifierProvider(
      create: (_) => PostState(repository: repository),
      child: const PostExplorerApp(),
    ),
  );
}

class PostExplorerApp extends StatelessWidget {
  const PostExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Post Explorer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PostsPage(),
    );
  }
}
