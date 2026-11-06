import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/post.dart';
import '../state/post_state.dart';
import 'post_details_page.dart';
import 'create_post_page.dart';

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final state = context.read<PostState>();
      state.loadPosts();
      state.loadUsers();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 300) {
      context.read<PostState>().loadMore();
    }
  }

  Future<void> _openCreatePostPage() async {
    final post = await Navigator.push<Post>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostPage()),
    );

    if (!mounted || post == null) return;

    await context.read<PostState>().addCreatedPost(post);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Публикация добавлена в ленту')),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PostState>();
    final posts = state.filteredPosts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Explorer'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Сбросить фильтры',
            onPressed: state.resetFilters,
            icon: const Icon(Icons.filter_alt_off),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePostPage,
        icon: const Icon(Icons.add),
        label: const Text('Создать пост'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Поиск по заголовку...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: state.search,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: state.selectedUserId,
                  decoration: InputDecoration(
                    labelText: 'Автор постов',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Все авторы'),
                    ),
                    ...state.users.map(
                      (user) => DropdownMenuItem<int?>(
                        value: user.id,
                        child: Text(
                          '${user.name} (ID: ${user.id})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: state.filterByUser,
                ),
              ],
            ),
          ),

          if (state.isCached)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.all(8),
              child: const Text(
                'Показаны сохранённые данные',
                textAlign: TextAlign.center,
              ),
            ),

          Expanded(child: _buildContent(state, posts)),
        ],
      ),
    );
  }

  Widget _buildContent(PostState state, List<Post> posts) {
    if (state.isLoading && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: state.loadPosts,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (posts.isEmpty) {
      return const Center(child: Text('Посты не найдены'));
    }

    return RefreshIndicator(
      onRefresh: state.refreshPosts,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        itemCount:
            posts.length +
            (state.isLoadingMore || state.paginationError != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= posts.length) {
            if (state.paginationError != null) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(state.paginationError!),
                    TextButton(
                      onPressed: state.loadMore,
                      child: const Text('Повторить загрузку'),
                    ),
                  ],
                ),
              );
            }

            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final post = posts[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailsPage(post: post),
                  ),
                );
              },
              leading: CircleAvatar(child: Text(post.id.toString())),
              title: Text(
                post.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${post.body}\n\nАвтор: ${post.userId}'),
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
