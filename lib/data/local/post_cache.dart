import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/post.dart';

class PostCache {
  static const String _postsKey = 'cached_posts';

  Future<void> savePosts(List<Post> posts) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonList = posts.map((post) => post.toJson()).toList();

    await prefs.setString(_postsKey, jsonEncode(jsonList));
  }

  Future<List<Post>?> getPosts() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedData = prefs.getString(_postsKey);

    if (cachedData == null) {
      return null;
    }

    try {
      final List<dynamic> jsonList = jsonDecode(cachedData);

      return jsonList
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      await prefs.remove(_postsKey);
      return null;
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_postsKey);
  }
}
