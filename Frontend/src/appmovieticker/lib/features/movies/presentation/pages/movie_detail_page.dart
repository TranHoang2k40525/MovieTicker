import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../data/datasources/movies_remote_datasource.dart';
import '../../data/models/movie_list_item.dart';
import 'movie_showtime_page.dart';
import '../widgets/movie_menu_dialog.dart';

class MovieDetailPage extends StatefulWidget {
  final MovieListItem movie;

  const MovieDetailPage({super.key, required this.movie});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  final MoviesRemoteDataSource _remoteDataSource = di.sl<MoviesRemoteDataSource>();
  MovieListItem? _movieDetail;
  bool _loadingDetail = false;

  MovieListItem get _movie => _movieDetail ?? widget.movie;

  @override
  void initState() {
    super.initState();
    _loadMovieDetail();
  }

  Future<void> _loadMovieDetail() async {
    setState(() {
      _loadingDetail = true;
    });

    try {
      final detail = await _remoteDataSource.getMovieDetail(movieId: widget.movie.movieId);
      if (!mounted) return;
      setState(() {
        _movieDetail = detail;
      });
    } catch (_) {
      // Keep fallback to initial movie data if detail API fails.
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingDetail = false;
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
            child: _loadingDetail
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _Header(
                        scale: scale,
                        onMenuTap: () => showMovieMenuDialog(context, scale: scale),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(8 * scale, 2 * scale, 8 * scale, 16 * scale),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TrailerBlock(movie: _movie, scale: scale),
                              SizedBox(height: 10 * scale),
                              _DescriptionBlock(movie: _movie, scale: scale),
                              SizedBox(height: 8 * scale),
                              Container(
                                height: 1,
                                color: const Color(0xFFD6BE55),
                              ),
                              SizedBox(height: 14 * scale),
                              _BookButton(scale: scale, onTap: _bookTicket),
                            ],
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

  void _bookTicket() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MovieShowtimePage(movie: _movie)),
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
  const _Header({required this.scale, required this.onMenuTap});

  final double scale;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56 * scale,
      padding: EdgeInsets.symmetric(horizontal: 8 * scale),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.arrow_back, size: 24 * scale, color: Colors.black87),
          ),
          SizedBox(width: 10 * scale),
          Text(
            'Quay lại',
            style: TextStyle(
              fontSize: 22 * scale,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF111111),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onMenuTap,
            child: Icon(Icons.menu_rounded, size: 34 * scale, color: const Color(0xFFE04A4A)),
          ),
        ],
      ),
    );
  }
}

class _TrailerBlock extends StatelessWidget {
  const _TrailerBlock({required this.movie, required this.scale});

  final MovieListItem movie;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl(movie.imageUrl);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(2 * scale),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 190 * scale,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: imageUrl == null
                          ? Container(color: const Color(0xFF303030))
                          : Image.network(imageUrl, fit: BoxFit.cover),
                    ),
                    Positioned.fill(
                      child: Container(color: Colors.black.withValues(alpha: 0.18)),
                    ),
                    Positioned(
                      left: 8 * scale,
                      top: 8 * scale,
                      right: 110 * scale,
                      child: Text(
                        movie.movieTitle.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: 14 * scale, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Positioned(
                      right: 8 * scale,
                      top: 8 * scale,
                      child: Row(
                        children: [
                          _topIcon(Icons.volume_up_rounded, scale),
                          SizedBox(width: 4 * scale),
                          _topIcon(Icons.closed_caption_outlined, scale),
                          SizedBox(width: 4 * scale),
                          _topIcon(Icons.settings, scale),
                        ],
                      ),
                    ),
                    Center(
                      child: Icon(Icons.play_circle_fill_rounded, size: 58 * scale, color: Colors.white70),
                    ),
                    Positioned(
                      right: 8 * scale,
                      bottom: 8 * scale,
                      child: _topIcon(Icons.open_in_full, scale),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 35 * scale,
                child: Center(
                  child: Text(
                    'Video khác        YouTube',
                    style: TextStyle(color: Colors.white, fontSize: 13 * scale, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 4 * scale,
          bottom: -46 * scale,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14 * scale),
            child: SizedBox(
              width: 100 * scale,
              height: 146 * scale,
              child: imageUrl == null
                  ? Container(
                      color: const Color(0xFFB9C2CF),
                      child: const Icon(Icons.movie, color: Colors.white, size: 36),
                    )
                  : Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned(
          left: 116 * scale,
          right: 0,
          bottom: -34 * scale,
          child: Row(
            children: [
              _chip(icon: Icons.calendar_today_outlined, text: _formatDate(movie.movieReleaseDate), scale: scale),
              SizedBox(width: 8 * scale),
              _chip(icon: Icons.watch_later_outlined, text: '${movie.movieRuntime ?? 0} phút', scale: scale),
              SizedBox(width: 8 * scale),
              Icon(Icons.double_arrow_rounded, size: 24 * scale, color: const Color(0xFFE52A2A)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topIcon(IconData icon, double scale) {
    return Container(
      width: 22 * scale,
      height: 22 * scale,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(4 * scale),
      ),
      child: Icon(icon, color: Colors.white, size: 14 * scale),
    );
  }

  Widget _chip({required IconData icon, required String text, required double scale}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 5 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(5 * scale),
        border: Border.all(color: const Color(0xFFBBBBBB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12 * scale, color: Colors.black87),
          SizedBox(width: 4 * scale),
          Text(text, style: TextStyle(fontSize: 10 * scale, color: Colors.black87)),
        ],
      ),
    );
  }

  String? _resolveImageUrl(String imageUrl) {
    final normalized = imageUrl.trim();
    if (normalized.isEmpty) return null;
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) return normalized;
    final host = ApiConstants.mediaBaseUrl.replaceAll(RegExp(r'/$'), '');
    final path = normalized.startsWith('/') ? normalized : '/$normalized';
    return '$host$path';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Dang cap nhat';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _DescriptionBlock extends StatelessWidget {
  const _DescriptionBlock({required this.movie, required this.scale});

  final MovieListItem movie;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 52 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (movie.movieDescription ?? '').isNotEmpty
                ? movie.movieDescription!
                : 'Không có mô tả.',
            style: TextStyle(fontSize: 12 * scale, height: 1.35, color: const Color(0xFF1E1E1E)),
            textAlign: TextAlign.justify,
          ),
          SizedBox(height: 14 * scale),
          _infoRow('Kiểm duyệt', 'T18 - Phim được phổ biến đến người xem từ đủ 18 tuổi trở lên.', scale),
          SizedBox(height: 10 * scale),
          _infoRow('Thể loại', movie.movieGenre.isNotEmpty ? movie.movieGenre : 'Dang cap nhat', scale),
          SizedBox(height: 10 * scale),
          _infoRow('Đạo diễn', movie.movieActor.isNotEmpty ? movie.movieActor : 'Dang cap nhat', scale),
          SizedBox(height: 10 * scale),
          _infoRow('Diễn viên', movie.movieActor.isNotEmpty ? movie.movieActor : 'Dang cap nhat', scale),
          SizedBox(height: 10 * scale),
          _infoRow('Ngôn ngữ', movie.movieLanguage.isNotEmpty ? movie.movieLanguage : 'Tiếng Việt', scale),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, double scale) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95 * scale,
          child: Text(
            label,
            style: TextStyle(fontSize: 12 * scale, color: const Color(0xFF3E3E3E)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12 * scale, color: const Color(0xFF111111), height: 1.3),
          ),
        ),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  const _BookButton({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 44 * scale,
        decoration: BoxDecoration(
          color: const Color(0xFFFD1010),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          'ĐẶT VÉ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16 * scale,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
