import 'package:flutter/foundation.dart';

import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';

class PostState extends ChangeNotifier {
  final PostRepository repository;

  PostState({required this.repository});

  List<Post> _posts = [];
  final List<Post> _createdPosts = [];
  List<User> _users = [];

  String _searchQuery = '';
  int? _selectedUserId;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isCached = false;
  bool _hasMore = true;

  String? _error;
  String? _paginationError;

  int _currentPage = 1;
  static const int _pageSize = 10;

  List<Post> get posts => [..._createdPosts, ..._posts];

  List<User> get users => _users;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isCached => _isCached;
  bool get hasMore => _hasMore;

  String? get error => _error;
  String? get paginationError => _paginationError;

  int? get selectedUserId => _selectedUserId;
  String get searchQuery => _searchQuery;

  List<Post> get filteredPosts {
    final result = posts.where((post) {
      final matchesSearch = post.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );

      final matchesUser =
          _selectedUserId == null || post.userId == _selectedUserId;

      return matchesSearch && matchesUser;
    }).toList();

    result.sort((a, b) => a.id.compareTo(b.id));

    return result;
  }

  // Первичная загрузка: сначала кэш, затем сервер.
  Future<void> loadPosts() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _paginationError = null;

    notifyListeners();

    try {
      final cachedPosts = await repository.getCachedPosts();

      if (cachedPosts.isNotEmpty && _posts.isEmpty) {
        _posts = cachedPosts;
        _isCached = true;
        notifyListeners();
      }

      await _fetchFirstPage();
    } catch (e) {
      if (_posts.isEmpty) {
        _error = e.toString();
      } else {
        _isCached = true;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchFirstPage() async {
    try {
      final result = await repository.getPosts(
        page: 1,
        limit: _pageSize,
        userId: _selectedUserId,
      );

      _posts = result;
      _currentPage = 1;
      _hasMore = result.length == _pageSize;
      _isCached = false;
      _error = null;
      _paginationError = null;

      if (_selectedUserId == null) {
        await repository.saveCachedPosts(posts);
      }
    } catch (e) {
      if (posts.isEmpty) {
        _error = e.toString();
      } else {
        _isCached = true;
      }
    }
  }

  // Ручное обновление.
  Future<void> refreshPosts() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;

    notifyListeners();

    await _fetchFirstPage();

    _isLoading = false;
    notifyListeners();
  }

  // Загрузка следующей страницы.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    _paginationError = null;

    notifyListeners();

    final nextPage = _currentPage + 1;

    try {
      final result = await repository.getPosts(
        page: nextPage,
        limit: _pageSize,
        userId: _selectedUserId,
      );

      final existingIds = posts.map((post) => post.id).toSet();

      final uniquePosts = result
          .where((post) => !existingIds.contains(post.id))
          .toList();

      _posts = [..._posts, ...uniquePosts];

      _currentPage = nextPage;
      _hasMore = result.length == _pageSize;
      _isCached = false;

      if (_selectedUserId == null) {
        await repository.saveCachedPosts(posts);
      }
    } catch (e) {
      _paginationError = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Добавление созданной публикации в ленту.
  Future<void> addCreatedPost(Post post) async {
    _createdPosts.insert(0, post);

    if (_selectedUserId == null) {
      await repository.saveCachedPosts(posts);
    }

    notifyListeners();
  }

  // Поиск по заголовку.
  void search(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  // Фильтрация по автору.
  Future<void> filterByUser(int? userId) async {
    if (_selectedUserId == userId) return;

    _selectedUserId = userId;
    _posts = [];
    _currentPage = 1;
    _hasMore = true;
    _error = null;
    _paginationError = null;

    await refreshPosts();
  }

  // Сброс фильтров и поиска.
  Future<void> resetFilters() async {
    _searchQuery = '';
    notifyListeners();

    if (_selectedUserId != null) {
      await filterByUser(null);
    }
  }

  // Загрузка списка авторов.
  Future<void> loadUsers() async {
    try {
      _users = await repository.getUsers();
      notifyListeners();
    } catch (_) {
      // Ошибка загрузки авторов не блокирует загрузку постов.
    }
  }
}
