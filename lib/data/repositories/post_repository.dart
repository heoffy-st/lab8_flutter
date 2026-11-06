import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../local/post_cache.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/user.dart';
import '../remote/post_api.dart';

class PostRepository {
  final PostApi api;
  final PostCache cache;

  PostRepository({required this.api, required this.cache});

  // Получение постов с сервера.
  Future<List<Post>> getPosts({
    int page = 1,
    int limit = 10,
    int? userId,
  }) async {
    try {
      final posts = await api.getPosts(page, limit, userId);

      if (page == 1 && userId == null) {
        await cache.savePosts(posts);
      }

      return posts;
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    } catch (error) {
      if (error is AppException) rethrow;
      throw AppException(message: 'Не удалось загрузить посты');
    }
  }

  // Получение локально сохранённых постов.
  Future<List<Post>> getCachedPosts() async {
    return await cache.getPosts() ?? [];
  }

  // Получение подробной информации о посте.
  Future<Post> getPost(int id) async {
    try {
      return await api.getPost(id);
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  // Получение комментариев к посту.
  Future<List<Comment>> getComments(int postId) async {
    try {
      return await api.getComments(postId);
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  // Получение постов конкретного пользователя.
  Future<List<Post>> getPostsByUser(int userId) async {
    try {
      return await api.getPostsByUser(userId);
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  // Получение списка авторов.
  Future<List<User>> getUsers() async {
    try {
      return await api.getUsers();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  // Получение информации об авторе.
  Future<User> getUser(int id) async {
    try {
      return await api.getUser(id);
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  // Создание нового поста.
  Future<Post> createPost({
    required String title,
    required String body,
    required int userId,
  }) async {
    if (title.trim().isEmpty) {
      throw const AppException(message: 'Введите заголовок поста');
    }

    if (body.trim().isEmpty) {
      throw const AppException(message: 'Введите текст поста');
    }

    try {
      return await api.createPost({
        'title': title.trim(),
        'body': body.trim(),
        'userId': userId,
      });
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  // Создание комментария.
  Future<Comment> createComment({
    required int postId,
    required String name,
    required String email,
    required String body,
  }) async {
    try {
      return await api.createComment({
        'postId': postId,
        'name': name.trim(),
        'email': email.trim(),
        'body': body.trim(),
      });
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  // Сохранение полного списка постов в кэш.
  Future<void> saveCachedPosts(List<Post> posts) async {
    await cache.savePosts(posts);
  }
}
