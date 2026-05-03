import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:appmovieticker/core/constants/api_constants.dart';
import 'package:appmovieticker/core/di/injection_container.dart' as di;
import 'package:appmovieticker/features/movies/movie/data/datasources/movie/movies_remote_datasource.dart';
import 'package:appmovieticker/features/movies/movie/data/models/movie/movie_list_item.dart';
import 'package:appmovieticker/features/movies/show/presentation/pages/showtime/movie_showtime_page.dart';
import 'package:appmovieticker/features/movies/movie/presentation/widgets/movie/movie_menu_dialog.dart';

class MovieBookingListPage extends StatefulWidget {
  const MovieBookingListPage({super.key});

  @override
  State<MovieBookingListPage> createState() => _MovieBookingListPageState();
}

class _MovieBookingListPageState extends State<MovieBookingListPage> {
  static const int _batchSize = 6;
  static const int _pageSize = 10;

  final MoviesRemoteDataSource _remoteDataSource = di.sl<MoviesRemoteDataSource>();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _loadingMore = false;
  bool _showNowShowingOnly = false;
  String? _error;

  List<MovieListItem> _movies = const [];
  int _visibleCount = _batchSize;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMovies();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _loading = true;
      _error = null;
      _visibleCount = _batchSize;
      _page = 1;
      _hasMore = true;
      _movies = const [];
    });

    try {
      if (_showNowShowingOnly) {
        final nowShowing = await _remoteDataSource.getNowShowingMovies();
        if (!mounted) return;
        setState(() {
          _movies = nowShowing;
          _hasMore = nowShowing.length > _batchSize;
        });
      } else {
        final combined = await _remoteDataSource.getShowingAndUpcomingMovies(page: _page, sizePage: _pageSize);
        if (!mounted) return;
        setState(() {
          _movies = combined;
          _hasMore = combined.length >= _pageSize;
          _page = 2;
        });
      }
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được danh sách phim (${error.message ?? 'lỗi mạng'}).';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được danh sách phim ($error).';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) {
      return;
    }

    setState(() {
      _loadingMore = true;
    });

    try {
      if (_showNowShowingOnly) {
        if (_visibleCount < _movies.length) {
          setState(() {
            _visibleCount = (_visibleCount + _batchSize).clamp(0, _movies.length);
          });
        }
      } else {
        final nextPage = await _remoteDataSource.getShowingAndUpcomingMovies(page: _page, sizePage: _pageSize);
        if (!mounted) return;
        setState(() {
          if (nextPage.isEmpty) {
            _hasMore = false;
          } else {
            _movies = [..._movies, ...nextPage];
            _page += 1;
            _hasMore = nextPage.length >= _pageSize;
          }
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasMore = false;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 220) {
      _loadMore();
    }
  }

  void _setNowShowingOnly(bool value) {
    if (_showNowShowingOnly == value) {
      return;
    }
    setState(() {
      _showNowShowingOnly = value;
    });
    _loadMovies();
  }

  @override
  Widget build(BuildContext context) {
    final scale = _uiScale(context);
    final visibleMovies = _showNowShowingOnly ? _movies.take(_visibleCount).toList() : _movies;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1E5),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(8 * scale, 6 * scale, 8 * scale, 8 * scale),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28 * scale),
              border: Border.all(color: const Color(0xFF3A3A3A), width: 1.2),
            ),
            child: Column(
              children: [
                _Header(
                  scale: scale,
                  onBack: () => Navigator.of(context).maybePop(),
                  onMenuTap: () => showMovieMenuDialog(context, scale: scale),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(14 * scale, 2 * scale, 14 * scale, 10 * scale),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Chọn phim của bạn',
                          style: TextStyle(
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Đang chiếu',
                            style: TextStyle(
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w600,
                              color: _showNowShowingOnly ? const Color(0xFFE0B84D) : const Color(0xFFBFA96A),
                            ),
                          ),
                          SizedBox(width: 6 * scale),
                          Switch.adaptive(
                            value: _showNowShowingOnly,
                            activeColor: const Color(0xFFE63C39),
                            onChanged: _setNowShowingOnly,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  color: const Color(0xFFFF6A70),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? _ErrorState(message: _error!, onRetry: _loadMovies)
                          : RefreshIndicator(
                              onRefresh: _loadMovies,
                              child: ListView.builder(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: visibleMovies.length + (_loadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (_loadingMore && index == visibleMovies.length) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16 * scale),
                                      child: const Center(child: CircularProgressIndicator()),
                                    );
                                  }

                                  final movie = visibleMovies[index];
                                  return _MovieRow(
                                    movie: movie,
                                    scale: scale,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => MovieShowtimePage(movie: movie)),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _uiScale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.shortestSide < 700) {
      return (size.width / 390).clamp(0.75, 0.95);
    }
    return (size.width / 1200).clamp(0.9, 1.25);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.scale, required this.onBack, required this.onMenuTap});

  final double scale;
  final VoidCallback onBack;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58 * scale,
      padding: EdgeInsets.symmetric(horizontal: 10 * scale),
      decoration: const BoxDecoration(
        color: Color(0xFFE9D272),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, color: const Color(0xFFE63C39), size: 24 * scale),
          ),
          Expanded(
            child: Text(
              'Chọn phim của bạn',
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF111111),
              ),
            ),
          ),
          IconButton(
            onPressed: onMenuTap,
            icon: Icon(Icons.menu_rounded, color: const Color(0xFFE63C39), size: 28 * scale),
          ),
        ],
      ),
    );
  }
}

class _MovieRow extends StatelessWidget {
  const _MovieRow({required this.movie, required this.scale, required this.onTap});

  final MovieListItem movie;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl(movie.imageUrl);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 10 * scale),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFFFB6B6), width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2 * scale),
              child: SizedBox(
                width: 98 * scale,
                height: 126 * scale,
                child: imageUrl == null
                    ? Container(color: const Color(0xFFE5E5E5), child: const Icon(Icons.movie, size: 36))
                    : Image.network(imageUrl, fit: BoxFit.cover),
              ),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 18 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.movieTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF2B2B2B),
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Text(
                      _formatDate(movie.movieReleaseDate),
                      style: TextStyle(fontSize: 11 * scale, color: const Color(0xFF444444)),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      '${movie.movieRuntime ?? 0} phút',
                      style: TextStyle(fontSize: 11 * scale, color: const Color(0xFF444444)),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 40 * scale, right: 6 * scale),
              child: Icon(Icons.chevron_right_rounded, size: 30 * scale, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  String? _resolveImageUrl(String imageUrl) {
    final normalized = imageUrl.trim();
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }

    final host = ApiConstants.mediaBaseUrl.replaceAll(RegExp(r'/$'), '');
    final path = normalized.startsWith('/') ? normalized : '/$normalized';
    return '$host$path';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Đang cập nhật';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40, color: Color(0xFF606060)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () => onRetry(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}