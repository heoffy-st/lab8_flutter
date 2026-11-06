import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/post.dart';
import '../state/post_state.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  int? _selectedUserId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PostState>().loadUsers();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите автора публикации')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final Post post = await context.read<PostState>().repository.createPost(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        userId: _selectedUserId!,
      );

      if (!mounted) return;

      Navigator.pop(context, post);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось создать публикацию: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PostState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Создать публикацию')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Новая публикация',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Заполните информацию о вашей публикации.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _titleController,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Заголовок',
                hintText: 'Введите заголовок публикации',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                final title = value?.trim() ?? '';

                if (title.isEmpty) {
                  return 'Введите заголовок';
                }

                if (title.length < 5) {
                  return 'Минимум 5 символов';
                }

                if (title.length > 100) {
                  return 'Максимум 100 символов';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _bodyController,
              minLines: 5,
              maxLines: 8,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Текст публикации',
                hintText: 'Напишите содержание публикации',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final body = value?.trim() ?? '';

                if (body.isEmpty) {
                  return 'Введите текст публикации';
                }

                if (body.length < 10) {
                  return 'Минимум 10 символов';
                }

                if (body.length > 1000) {
                  return 'Максимум 1000 символов';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              initialValue: _selectedUserId,
              decoration: const InputDecoration(
                labelText: 'Автор публикации',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: state.users.map((user) {
                return DropdownMenuItem<int>(
                  value: user.id,
                  child: Text(
                    '${user.name} (ID: ${user.id})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _isSending
                  ? null
                  : (value) {
                      setState(() {
                        _selectedUserId = value;
                      });
                    },
              validator: (value) {
                if (value == null) {
                  return 'Выберите автора';
                }

                return null;
              },
            ),

            if (state.users.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: state.loadUsers,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Загрузить список авторов'),
                ),
              ),

            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _createPost,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSending ? 'Публикация...' : 'Опубликовать'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
