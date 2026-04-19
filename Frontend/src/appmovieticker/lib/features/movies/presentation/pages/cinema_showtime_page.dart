import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../data/datasources/movies_remote_datasource.dart';
import '../../data/models/cinema_showtime_item.dart';
import '../../data/models/nearby_cinema_item.dart';
import 'seat_map_page.dart';
import '../widgets/movie_menu_dialog.dart';

class CinemaShowtimePage extends StatefulWidget {
  const CinemaShowtimePage({super.key, required this.cinema});

  final NearbyCinemaItem cinema;

  @override
  State<CinemaShowtimePage> createState() => _CinemaShowtimePageState();
}

class _CinemaShowtimePageState extends State<CinemaShowtimePage> {
  final MoviesRemoteDataSource _remoteDataSource = di.sl<MoviesRemoteDataSource>();

  bool _loading = true;
  String? _message;
  List<CinemaShowtimeMovieItem> _movies = const [];
  DateTime _selectedDate = DateTime.now();
  int? _expandedMovieIndex;

  @override
  void initState() {
    super.initState();
    _loadShowtimes();
  }

  Future<void> _loadShowtimes() async {
    setState(() {
      _loading = true;
      _message = null;
      _expandedMovieIndex = null;
    });

    try {
      final result = await _remoteDataSource.getCinemaShowtimes(
        cinemaId: widget.cinema.cinemaId,
        filterDate: _selectedDate,
      );
      if (!mounted) return;
      setState(() {
        _movies = result;
        _message = result.isEmpty ? 'Chưa có suất chiếu cho ngày này.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Không tải được suất chiếu của rạp này. Vui lòng thử lại.';
        _movies = const [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _uiScale(context);
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
                  cinema: widget.cinema,
                  onBack: () => Navigator.of(context).maybePop(),
                  onMenuTap: () => showMovieMenuDialog(context, scale: scale),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(12 * scale, 0, 12 * scale, 8 * scale),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'LOẠI RẠP',
                          style: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        'TẤT CẢ',
                        style: TextStyle(fontSize: 12 * scale, color: const Color(0xFFFF8A00), fontWeight: FontWeight.w700),
                      ),
                      SizedBox(width: 6 * scale),
                      Icon(Icons.chevron_right_rounded, size: 24 * scale),
                    ],
                  ),
                ),
                _DateStrip(
                  scale: scale,
                  dates: dates,
                  selectedDate: _selectedDate,
                  onSelected: (date) {
                    setState(() {
                      _selectedDate = DateTime(date.year, date.month, date.day);
                    });
                    _loadShowtimes();
                  },
                ),
                SizedBox(height: 6 * scale),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _message != null
                          ? _EmptyState(message: _message!, onRetry: _loadShowtimes)
                          : RefreshIndicator(
                              onRefresh: _loadShowtimes,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: _movies.length,
                                itemBuilder: (context, index) {
                                  final movie = _movies[index];
                                  final expanded = _expandedMovieIndex == index;
                                  return _MovieShowtimeCard(
                                    cinema: widget.cinema,
                                    movie: movie,
                                    scale: scale,
                                    expanded: expanded,
                                    onToggle: () {
                                      setState(() {
                                        _expandedMovieIndex = expanded ? null : index;
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

class _Header extends StatelessWidget {
  const _Header({required this.scale, required this.cinema, required this.onBack, required this.onMenuTap});

  final double scale;
  final NearbyCinemaItem cinema;
  final VoidCallback onBack;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54 * scale,
      padding: EdgeInsets.symmetric(horizontal: 10 * scale),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, size: 24 * scale, color: const Color(0xFFE14A4A)),
          ),
          Expanded(
            child: Text(
              '${cinema.cinemaName}',
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
                    child: Column(
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
            style: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _MovieShowtimeCard extends StatelessWidget {
  const _MovieShowtimeCard({
    required this.cinema,
    required this.movie,
    required this.scale,
    required this.expanded,
    required this.onToggle,
  });

  final NearbyCinemaItem cinema;
  final CinemaShowtimeMovieItem movie;
  final double scale;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final hasMultipleShowtimes = movie.showtimes.length > 1;
    final visibleShowtimes = expanded ? movie.showtimes : movie.showtimes.take(3).toList();

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5C55A))),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: hasMultipleShowtimes ? onToggle : null,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12 * scale, 12 * scale, 12 * scale, 12 * scale),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 2 * scale),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 2 * scale),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  movie.movieTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (hasMultipleShowtimes)
                                Icon(
                                  expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                  size: 26 * scale,
                                  color: Colors.black,
                                ),
                            ],
                          ),
                          SizedBox(height: 4 * scale),
                          Text(
                            '${movie.movieAge.isNotEmpty ? movie.movieAge : '2D'} ${movie.movieGenre.isNotEmpty ? movie.movieGenre : 'Phụ đề Việt'}',
                            style: TextStyle(fontSize: 10 * scale, color: const Color(0xFF444444), fontStyle: FontStyle.italic),
                          ),
                          SizedBox(height: 8 * scale),
                          Wrap(
                            spacing: 8 * scale,
                            runSpacing: 8 * scale,
                            children: visibleShowtimes
                                .map(
                                  (showtime) => _TimeChip(
                                    label: _formatTime(showtime.startTime),
                                    scale: scale,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => SeatMapPage(
                                          showId: showtime.showId,
                                          movieTitle: movie.movieTitle,
                                          moviePosterUrl: movie.imageUrl,
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
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasMultipleShowtimes && expanded)
            Padding(
              padding: EdgeInsets.fromLTRB(12 * scale, 0, 12 * scale, 10 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: movie.showtimes
                    .map(
                      (showtime) => Padding(
                        padding: EdgeInsets.only(bottom: 8 * scale),
                        child: Row(
                          children: [
                            Text(
                              '${showtime.experienceType.isNotEmpty ? showtime.experienceType : '2D'} ${showtime.hallName}',
                              style: TextStyle(fontSize: 11 * scale, color: const Color(0xFF444444), fontStyle: FontStyle.italic),
                            ),
                            const Spacer(),
                            Text(
                              _formatTime(showtime.startTime),
                              style: TextStyle(fontSize: 11 * scale, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
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
          borderRadius: BorderRadius.circular(6 * scale),
          border: Border.all(color: const Color(0xFFB7B7B7)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11 * scale, color: const Color(0xFF2C2C2C))),
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