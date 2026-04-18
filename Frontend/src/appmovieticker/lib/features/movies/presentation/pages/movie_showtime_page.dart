import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../data/datasources/movies_remote_datasource.dart';
import '../../data/models/movie_list_item.dart';
import '../../data/models/movie_showtime_item.dart';
import 'seat_map_page.dart';
import '../widgets/movie_menu_dialog.dart';

class MovieShowtimePage extends StatefulWidget {
  const MovieShowtimePage({super.key, required this.movie});

  final MovieListItem movie;

  @override
  State<MovieShowtimePage> createState() => _MovieShowtimePageState();
}

class _MovieShowtimePageState extends State<MovieShowtimePage> {
  final MoviesRemoteDataSource _remoteDataSource = di.sl<MoviesRemoteDataSource>();

  bool _loading = false;
  String? _message;
  List<MovieShowtimeCinemaItem> _cinemas = const [];
  int? _expandedCinemaIndex;
  DateTime _selectedDate = DateTime.now();
  Position? _position;

  @override
  void initState() {
    super.initState();
    _loadLocationAndShowtimes();
  }

  Future<void> _loadLocationAndShowtimes() async {
    final position = await _resolvePosition();
    if (!mounted) return;
    if (position == null) {
      setState(() {
        _position = null;
        _message = 'Vui lòng bật định vị để xem suất chiếu gần bạn.';
        _cinemas = const [];
      });
      return;
    }

    setState(() {
      _position = position;
    });
    await _loadShowtimesForDate(_selectedDate);
  }

  Future<void> _loadShowtimesForDate(DateTime date) async {
    final position = _position;
    if (position == null) {
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
      _selectedDate = DateTime(date.year, date.month, date.day);
      _expandedCinemaIndex = null;
    });

    try {
      final cinemas = await _remoteDataSource.getMovieShowtimes(
        movieId: widget.movie.movieId,
        latitude: position.latitude,
        longitude: position.longitude,
        filterDate: _selectedDate,
      );
      if (!mounted) return;
      setState(() {
        _cinemas = cinemas;
        _message = cinemas.isEmpty ? 'Chưa có suất chiếu cho ngày đã chọn.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Không tải được suất chiếu. Vui lòng thử lại.';
        _cinemas = const [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<Position?> _resolvePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _uiScale(context);
    final movie = widget.movie;
    final dates = List.generate(30, (index) => DateTime.now().add(Duration(days: index)));

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
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
                  title: movie.movieTitle,
                  onBack: () => Navigator.of(context).maybePop(),
                  onMenuTap: () => showMovieMenuDialog(context, scale: scale),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(10 * scale, 0, 10 * scale, 8 * scale),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          movie.movieTitle.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${movie.movieRuntime ?? 0} phút',
                        style: TextStyle(fontSize: 12 * scale, color: const Color(0xFF666666)),
                      ),
                    ],
                  ),
                ),
                _DateStrip(
                  scale: scale,
                  dates: dates,
                  selectedDate: _selectedDate,
                  onSelected: (date) => _loadShowtimesForDate(date),
                ),
                SizedBox(height: 6 * scale),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _message != null
                          ? _EmptyState(message: _message!, onRetry: _loadLocationAndShowtimes)
                          : RefreshIndicator(
                              onRefresh: _loadLocationAndShowtimes,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(10 * scale, 8 * scale, 10 * scale, 16 * scale),
                                itemCount: _cinemas.length,
                                itemBuilder: (context, index) {
                                  final cinema = _cinemas[index];
                                  final expanded = _expandedCinemaIndex == index;
                                  return _CinemaShowtimeCard(
                                    movie: movie,
                                    cinema: cinema,
                                    scale: scale,
                                    expanded: expanded,
                                    onToggle: () {
                                      setState(() {
                                        _expandedCinemaIndex = expanded ? null : index;
                                      });
                                    },
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

class _DateStrip extends StatelessWidget {
  const _DateStrip({
    required this.scale,
    required this.dates,
    required this.selectedDate,
    required this.onSelected,
  });

  final double scale;
  final List<DateTime> dates;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedLabel = _formatSelectedDate(selectedDate);

    return Container(
      color: const Color(0xFF0A0A0A),
      padding: EdgeInsets.only(top: 10 * scale, bottom: 8 * scale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 78 * scale,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 8 * scale),
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              separatorBuilder: (_, __) => SizedBox(width: 12 * scale),
              itemBuilder: (context, index) {
                final date = dates[index];
                final isSelected = _isSameDay(date, selectedDate);
                final isToday = _isSameDay(date, DateTime.now());

                return SizedBox(
                  width: 54 * scale,
                  child: InkWell(
                    onTap: () => onSelected(date),
                    borderRadius: BorderRadius.circular(18 * scale),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          isToday ? 'Hôm nay' : _weekdayLabel(date.weekday),
                          style: TextStyle(
                            fontSize: 10 * scale,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? const Color(0xFFE63C39) : const Color(0xFFE0C75A),
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        Container(
                          width: 44 * scale,
                          height: 44 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? const Color(0xFFE63C39) : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? const Color(0xFFE63C39) : const Color(0xFF666666),
                              width: 1.1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${date.day.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 13 * scale,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : const Color(0xFFE8D99A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            selectedLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
      default:
        return 'CN';
    }
  }

  String _formatSelectedDate(DateTime date) {
    return '${_fullWeekdayLabel(date.weekday)} ${date.day} tháng ${date.month}, ${date.year}';
  }

  String _fullWeekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Thứ hai';
      case DateTime.tuesday:
        return 'Thứ ba';
      case DateTime.wednesday:
        return 'Thứ tư';
      case DateTime.thursday:
        return 'Thứ năm';
      case DateTime.friday:
        return 'Thứ sáu';
      case DateTime.saturday:
        return 'Thứ bảy';
      case DateTime.sunday:
      default:
        return 'Chủ nhật';
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _CinemaShowtimeCard extends StatelessWidget {
  const _CinemaShowtimeCard({
    required this.movie,
    required this.cinema,
    required this.scale,
    required this.expanded,
    required this.onToggle,
  });

  final MovieListItem movie;
  final MovieShowtimeCinemaItem cinema;
  final double scale;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10 * scale),
        border: Border.all(color: const Color(0xFFE2C85D)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12 * scale, 12 * scale, 12 * scale, 10 * scale),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cinema.cinemaName,
                          style: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 4 * scale),
                        Text(
                          cinema.cityAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11 * scale,
                            color: const Color(0xFF555555),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10 * scale),
                  Text(
                    '${cinema.distanceInKm.toStringAsFixed(1)}Km',
                    style: TextStyle(fontSize: 12 * scale, color: const Color(0xFFFF3B30), fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 8 * scale),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.keyboard_arrow_down_rounded, size: 22 * scale),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Container(
              width: double.infinity,
              color: const Color(0xFFFAF7E6),
              padding: EdgeInsets.fromLTRB(12 * scale, 6 * scale, 12 * scale, 12 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cinema.showtimes.isEmpty
                    ? [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6 * scale),
                          child: Text(
                            'Không có suất chiếu trong khung ngày này.',
                            style: TextStyle(fontSize: 11 * scale, color: const Color(0xFF666666)),
                          ),
                        ),
                      ]
                    : _buildShowtimeGroups(scale, movie),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildShowtimeGroups(double scale, MovieListItem movie) {
    final grouped = <String, List<MovieShowtimeItem>>{};
    for (final showtime in cinema.showtimes) {
      final key = '${showtime.experienceType}::${showtime.hallName}';
      grouped.putIfAbsent(key, () => <MovieShowtimeItem>[]).add(showtime);
    }

    return grouped.entries
        .map(
          (entry) => _ShowtimeGroup(
            movie: movie,
            cinema: cinema,
            hallName: entry.value.first.hallName,
            experienceType: entry.value.first.experienceType,
            showtimes: entry.value,
            scale: scale,
          ),
        )
        .toList();
  }
}

class _ShowtimeGroup extends StatelessWidget {
  const _ShowtimeGroup({
    required this.movie,
    required this.cinema,
    required this.hallName,
    required this.experienceType,
    required this.showtimes,
    required this.scale,
  });

  final MovieListItem movie;
  final MovieShowtimeCinemaItem cinema;
  final String hallName;
  final String experienceType;
  final List<MovieShowtimeItem> showtimes;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${experienceType.isNotEmpty ? experienceType : '2D'} $hallName'.trim(),
            style: TextStyle(fontSize: 11 * scale, color: const Color(0xFF3F3F3F), fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 6 * scale),
          Wrap(
            spacing: 8 * scale,
            runSpacing: 8 * scale,
            children: showtimes
                .map(
                  (showtime) => _TimeChip(
                    label: _formatTime(showtime.startTime),
                    scale: scale,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SeatMapPage(
                          showId: showtime.showId,
                          movieTitle: movie.movieTitle,
                          movieRuntime: movie.movieRuntime,
                          movieAge: movie.movieAge,
                          movieGenre: movie.movieGenre,
                          cinemaName: cinema.cinemaName,
                          cinemaAddress: cinema.cityAddress,
                          hallName: showtime.hallName,
                          experienceType: showtime.experienceType,
                          startTime: _formatTime(showtime.startTime),
                          showDate: showtime.showDate,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  String _formatTime(String raw) {
    final parts = raw.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return raw;
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.scale, this.onTap});

  final String label;
  final double scale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6 * scale),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 7 * scale),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6 * scale),
          border: Border.all(color: const Color(0xFFB7B7B7)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11 * scale, color: const Color(0xFF2C2C2C)),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry});

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
            const Icon(Icons.event_busy_outlined, size: 40, color: Color(0xFF606060)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            FilledButton(onPressed: () => onRetry(), child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.scale,
    required this.title,
    required this.onBack,
    required this.onMenuTap,
  });

  final double scale;
  final String title;
  final VoidCallback onBack;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56 * scale,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, size: 24 * scale, color: const Color(0xFFE14A4A)),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic),
            ),
          ),
          IconButton(
            onPressed: onMenuTap,
            icon: Icon(Icons.menu_rounded, size: 34 * scale, color: const Color(0xFFE14A4A)),
          ),
        ],
      ),
    );
  }
}
