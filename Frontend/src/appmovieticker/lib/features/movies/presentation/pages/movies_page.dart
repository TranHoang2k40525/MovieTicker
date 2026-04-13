import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../data/datasources/movies_remote_datasource.dart';
import '../../data/models/movie_list_item.dart';
import 'nearby_cinemas_page.dart';
import 'movie_detail_page.dart';
import '../widgets/movie_menu_dialog.dart';

enum _MovieTab { nowShowing, special, upcoming }

class MoviesPage extends StatefulWidget {
  const MoviesPage({super.key});

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> {
  static const int _batchSize = 5;
  final MoviesRemoteDataSource _remoteDataSource = di.sl<MoviesRemoteDataSource>();

  bool _loading = true;
  String? _error;
  _MovieTab _selectedTab = _MovieTab.nowShowing;

  List<MovieListItem> _nowShowing = const [];
  List<MovieListItem> _special = const [];
  List<MovieListItem> _upcoming = const [];
  List<MovieListItem> _combined = const [];
  int _visibleCombinedCount = _batchSize;
  bool _tabPrefetchScheduled = false;
  bool _combinedPrefetchScheduled = false;
  final Map<_MovieTab, int> _visibleCount = {
    _MovieTab.nowShowing: _batchSize,
    _MovieTab.special: _batchSize,
    _MovieTab.upcoming: _batchSize,
  };

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  bool _isMobileLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide < 700;
  }

  double _uiScale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (_isMobileLayout(context)) {
      return (size.width / 390).clamp(0.75, 0.95);
    }
    return (size.width / 1200).clamp(0.9, 1.25);
  }

  Future<void> _loadMovies() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<List<MovieListItem>>([
        _remoteDataSource.getNowShowingMovies(),
        _remoteDataSource.getSpecialMovies(),
        _remoteDataSource.getUpcomingMovies(),
        _remoteDataSource.getShowingAndUpcomingMovies(page: 1, sizePage: 30),
      ]);

      if (!mounted) return;
      setState(() {
        _nowShowing = results[0];
        _special = results[1];
        _upcoming = results[2];
        _combined = results[3].isNotEmpty ? results[3] : [...results[0], ...results[1], ...results[2]];
        _visibleCount[_MovieTab.nowShowing] = _batchSize;
        _visibleCount[_MovieTab.special] = _batchSize;
        _visibleCount[_MovieTab.upcoming] = _batchSize;
        _visibleCombinedCount = _batchSize;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Khong tai duoc du lieu (${error.message ?? 'loi mang'}).';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Khong tai duoc du lieu ($error).';
      });
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  List<MovieListItem> get _tabMovies {
    switch (_selectedTab) {
      case _MovieTab.nowShowing:
        return _nowShowing;
      case _MovieTab.special:
        return _special;
      case _MovieTab.upcoming:
        return _upcoming;
    }
  }

  List<MovieListItem> get _visibleTabMovies {
    final limit = _visibleCount[_selectedTab] ?? _batchSize;
    final maxCount = limit.clamp(0, _tabMovies.length);
    return _tabMovies.take(maxCount).toList();
  }

  void _prefetchNextBatchIfNeeded(int index) {
    final currentVisible = _visibleCount[_selectedTab] ?? _batchSize;
    final total = _tabMovies.length;

    // Trigger preload when reaching 2 items before the end of current visible batch
    // E.g. batch 1: show 0-4, trigger at index 3; batch 2: show 0-9, trigger at index 8, etc.
    if (index >= currentVisible - 2 && currentVisible < total && !_tabPrefetchScheduled) {
      _tabPrefetchScheduled = true;
      final tab = _selectedTab;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tabPrefetchScheduled = false;
        if (!mounted) return;
        final visible = _visibleCount[tab] ?? _batchSize;
        final tabTotal = switch (tab) {
          _MovieTab.nowShowing => _nowShowing.length,
          _MovieTab.special => _special.length,
          _MovieTab.upcoming => _upcoming.length,
        };
        if (visible >= tabTotal) return;
        final nextVisible = (visible + _batchSize).clamp(0, tabTotal);
        setState(() {
          _visibleCount[tab] = nextVisible;
        });
      });
    }
  }

  void _prefetchCombinedIfNeeded(int index) {
    final total = _combined.length;

    // Preload when reaching index 3, 8, 13, etc. (every batch of 5, trigger 2 items before end)
    if (index >= _visibleCombinedCount - 2 && _visibleCombinedCount < total && !_combinedPrefetchScheduled) {
      _combinedPrefetchScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _combinedPrefetchScheduled = false;
        if (!mounted) return;
        if (_visibleCombinedCount >= _combined.length) return;
        final nextVisible = (_visibleCombinedCount + _batchSize).clamp(0, _combined.length);
        setState(() {
          _visibleCombinedCount = nextVisible;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _uiScale(context);

    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(8 * scale, 6 * scale, 8 * scale, 8 * scale),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(28 * scale),
              border: Border.all(color: const Color(0xFF3A3A3A), width: 1.2),
            ),
            child: Column(
              children: [
                _TopHeader(
                  scale: scale,
                  onMenuTap: _openMenu,
                ),
                _TopTabs(
                  scale: scale,
                  selectedTab: _selectedTab,
                  onChanged: (tab) {
                    setState(() {
                      _selectedTab = tab;
                    });
                  },
                ),
                SizedBox(height: 8 * scale),
                _NearbyButton(
                  scale: scale,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const NearbyCinemasPage()),
                    );
                  },
                ),
                SizedBox(height: 10 * scale),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? _ErrorView(message: _error!, onRetry: _loadMovies)
                          : RefreshIndicator(
                              onRefresh: _loadMovies,
                              child: _MovieContent(
                                scale: scale,
                                tabMovies: _visibleTabMovies,
                                combinedMovies: _combined,
                                visibleCombinedCount: _visibleCombinedCount,
                                onPosterVisible: _prefetchNextBatchIfNeeded,
                                onCombinedVisible: _prefetchCombinedIfNeeded,
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

  Future<void> _openMenu() async {
    await showMovieMenuDialog(
      context,
      scale: _uiScale(context),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.scale, required this.onMenuTap});

  final double scale;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58 * scale,
      padding: EdgeInsets.symmetric(horizontal: 10 * scale),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Image.asset(
              'assets/images/avatramacdinh.png',
              width: 34 * scale,
              height: 34 * scale,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                radius: 17,
                child: Icon(Icons.public),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '67CS',
                style: TextStyle(
                  color: Color(0xFFE35D5D),
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onMenuTap,
            icon: Icon(
              Icons.menu_rounded,
              color: const Color(0xFFE04A4A),
              size: 30 * scale,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopTabs extends StatelessWidget {
  const _TopTabs({
    required this.scale,
    required this.selectedTab,
    required this.onChanged,
  });

  final double scale;
  final _MovieTab selectedTab;
  final ValueChanged<_MovieTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 1 * scale),
      height: 52 * scale,
      decoration: BoxDecoration(
        color: const Color(0xFFF5A3B0),
        border: Border.all(color: const Color(0xFF6A52FF), width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              scale: scale,
              title: 'Đang chiếu',
              selected: selectedTab == _MovieTab.nowShowing,
              onTap: () => onChanged(_MovieTab.nowShowing),
            ),
          ),
          Expanded(
            child: _TabButton(
              scale: scale,
              title: 'Phim đặc biệt',
              selected: selectedTab == _MovieTab.special,
              onTap: () => onChanged(_MovieTab.special),
            ),
          ),
          Expanded(
            child: _TabButton(
              scale: scale,
              title: 'Sắp Chiếu',
              selected: selectedTab == _MovieTab.upcoming,
              onTap: () => onChanged(_MovieTab.upcoming),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.scale,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final double scale;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            color: selected ? const Color(0xFF141414) : const Color(0xFF343434),
          ),
        ),
      ),
    );
  }
}

class _NearbyButton extends StatelessWidget {
  const _NearbyButton({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18 * scale),
      child: Container(
        height: 40 * scale,
        margin: EdgeInsets.symmetric(horizontal: 18 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFFD8D8D8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF7D7D7D)),
        ),
        alignment: Alignment.center,
        child: Text(
          'Rạp gần bạn',
          style: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _MovieContent extends StatelessWidget {
  const _MovieContent({
    required this.scale,
    required this.tabMovies,
    required this.combinedMovies,
    required this.visibleCombinedCount,
    required this.onPosterVisible,
    required this.onCombinedVisible,
  });

  final double scale;
  final List<MovieListItem> tabMovies;
  final List<MovieListItem> combinedMovies;
  final int visibleCombinedCount;
  final ValueChanged<int> onPosterVisible;
  final ValueChanged<int> onCombinedVisible;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: 250 * scale,
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(8 * scale, 10 * scale, 8 * scale, 6 * scale),
            scrollDirection: Axis.horizontal,
            itemCount: tabMovies.length,
            separatorBuilder: (context, index) => SizedBox(width: 10 * scale),
            itemBuilder: (context, index) {
              onPosterVisible(index);
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => MovieDetailPage(movie: tabMovies[index])),
                ),
                child: _PosterOnly(scale: scale, movie: tabMovies[index]),
              );
            },
          ),
        ),
        Container(
          margin: EdgeInsets.fromLTRB(0, 4 * scale, 0, 0),
          decoration: const BoxDecoration(
            color: Color(0xFFF2F2F2),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: combinedMovies
                .take(visibleCombinedCount)
                .toList()
                .asMap()
                .entries
                .map((entry) {
                  onCombinedVisible(entry.key);
                  return _MovieDetailRow(scale: scale, movie: entry.value);
                })
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _PosterOnly extends StatelessWidget {
  const _PosterOnly({required this.scale, required this.movie});

  final double scale;
  final MovieListItem movie;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24 * scale),
      child: Container(
        width: 136 * scale,
        color: Colors.black12,
        child: _NetworkPoster(movie: movie),
      ),
    );
  }
}

class _MovieDetailRow extends StatelessWidget {
  const _MovieDetailRow({required this.scale, required this.movie});

  final double scale;
  final MovieListItem movie;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MovieDetailPage(movie: movie)),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(10 * scale, 8 * scale, 10 * scale, 10 * scale),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFDDDDDD))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 98 * scale,
              height: 138 * scale,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16 * scale),
                child: _NetworkPoster(movie: movie),
              ),
            ),
            SizedBox(width: 10 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.movieTitle.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 18 * scale, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    'Đạo diễn: ${movie.movieActor.isNotEmpty ? movie.movieActor : 'Dang cap nhat'}',
                    style: TextStyle(fontSize: 12 * scale, height: 1.3),
                  ),
                  Text(
                    'Thể loại: ${movie.movieGenre.isNotEmpty ? movie.movieGenre : 'Dang cap nhat'}',
                    style: TextStyle(fontSize: 12 * scale, height: 1.3),
                  ),
                  Text(
                    'Khởi chiếu: ${_formatDate(movie.movieReleaseDate)}',
                    style: TextStyle(fontSize: 12 * scale, height: 1.3),
                  ),
                  Text(
                    'Thời lượng: ${movie.movieRuntime ?? 0} phút',
                    style: TextStyle(fontSize: 12 * scale, height: 1.3),
                  ),
                  Text(
                    'Phụ đề ${movie.movieLanguage.isNotEmpty ? movie.movieLanguage : 'Tieng Viet'}',
                    style: TextStyle(fontSize: 12 * scale, height: 1.3),
                  ),
                  SizedBox(height: 8 * scale),
                  Center(
                    child: Container(
                      width: 156 * scale,
                      height: 34 * scale,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4766C),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Đặt vé',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Dang cap nhat';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _NetworkPoster extends StatelessWidget {
  const _NetworkPoster({required this.movie});

  final MovieListItem movie;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl(movie.imageUrl);

    if (imageUrl == null) {
      return Container(
        color: const Color(0xFFB9C2CF),
        child: const Icon(Icons.movie, color: Colors.white, size: 44),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFB9C2CF),
        child: const Icon(Icons.movie, color: Colors.white, size: 44),
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
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
              onPressed: onRetry,
              child: const Text('Thu lai'),
            ),
          ],
        ),
      ),
    );
  }
}
