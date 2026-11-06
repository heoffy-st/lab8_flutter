import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/post.dart';
import '../../data/models/comment.dart';
import '../state/post_state.dart';

class PostDetailsPage extends StatefulWidget {
  final Post post;

  const PostDetailsPage({super.key, required this.post});

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  late Future<Post> _postFuture;
  late Future<List<Comment>> _commentsFuture;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  final List<Comment> _createdComments = [];

  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    final repository = context.read<PostState>().repository;

    _postFuture = repository.getPost(widget.post.id);
    _commentsFuture = repository.getComments(widget.post.id);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final body = _commentController.text.trim();

    if (name.isEmpty || email.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Заполните все поля')));
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректную электронную почту')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final comment = await context.read<PostState>().repository.createComment(
        postId: widget.post.id,
        name: name,
        email: email,
        body: body,
      );

      if (!mounted) return;

      setState(() {
        _createdComments.insert(0, comment);
        _commentController.clear();
        _isSending = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Комментарий опубликован')));
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось отправить комментарий: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Публикация')),
      body: FutureBuilder<Post>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final post = snapshot.data ?? widget.post;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(post.body),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 18),
                          const SizedBox(width: 6),
                          Text('Автор: ${post.userId}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID публикации: ${post.id}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Комментарии',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 12),

              FutureBuilder<List<Comment>>(
                future: _commentsFuture,
                builder: (context, commentsSnapshot) {
                  if (commentsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (commentsSnapshot.hasError) {
                    return Column(
                      children: [
                        const Text('Не удалось загрузить комментарии'),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _commentsFuture = context
                                  .read<PostState>()
                                  .repository
                                  .getComments(widget.post.id);
                            });
                          },
                          child: const Text('Повторить'),
                        ),
                      ],
                    );
                  }

                  final comments = [
                    ..._createdComments,
                    ...?commentsSnapshot.data,
                  ];

                  if (comments.isEmpty) {
                    return const Text('Комментариев пока нет');
                  }

                  return Column(
                    children: comments.map((comment) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(comment.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comment.email),
                              const SizedBox(height: 8),
                              Text(comment.body),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 24),

              Text(
                'Оставить комментарий',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ваше имя',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Электронная почта',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Текст комментария',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendComment,
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isSending ? 'Отправка...' : 'Опубликовать комментарий',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
