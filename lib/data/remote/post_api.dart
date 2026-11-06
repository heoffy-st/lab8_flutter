import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/post.dart';
import '../models/comment.dart';
import '../models/user.dart';

part 'post_api.g.dart';

@RestApi()
abstract class PostApi {
  factory PostApi(Dio dio, {String? baseUrl}) = _PostApi;

  // Получение постов с пагинацией и фильтром по автору.
  @GET('/posts')
  Future<List<Post>> getPosts(
    @Query('_page') int page,
    @Query('_limit') int limit,
    @Query('userId') int? userId,
  );

  // Получение подробной информации о посте.
  @GET('/posts/{id}')
  Future<Post> getPost(@Path('id') int id);

  // Получение постов конкретного пользователя.
  @GET('/posts')
  Future<List<Post>> getPostsByUser(@Query('userId') int userId);

  // Получение комментариев к посту.
  @GET('/posts/{id}/comments')
  Future<List<Comment>> getComments(@Path('id') int postId);

  // Создание нового поста.
  @POST('/posts')
  Future<Post> createPost(@Body() Map<String, dynamic> body);

  // Получение списка пользователей.
  @GET('/users')
  Future<List<User>> getUsers();

  // Получение информации о пользователе.
  @GET('/users/{id}')
  Future<User> getUser(@Path('id') int id);

  // Создание комментария.
  @POST('/comments')
  Future<Comment> createComment(@Body() Map<String, dynamic> body);
}
