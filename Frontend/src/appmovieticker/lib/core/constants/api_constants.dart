import 'dart:io' show Platform;

class ApiConstants {
  static const String _lanHost = '192.168.0.149';

  static String get _host {
    if (Platform.isAndroid || Platform.isIOS) {
      return _lanHost;
    }
    return 'localhost';
  }

  static String get _scheme {
    if (Platform.isAndroid || Platform.isIOS) {
      return 'http';
    }
    return 'https';
  }

  static String get baseUrl => '$_scheme://$_host:7084/api';
  static String get mediaBaseUrl => '$_scheme://$_host:7084';

  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh-token';
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String movieNowShowing = '/MoviePub/now-showing';
  static const String movieUpcoming = '/MoviePub/upcoming';
  static const String movieSpecial = '/MoviePub/special';
  static const String movieShowingAndUpcoming = '/MoviePub/showing-and-upcoming';
  static const String movieSearch = '/MoviePub/search';
  static const String movieDetail = '/MoviePub';
  static const String cinemaNearby = '/CinemaPub/nearby';
  static const String cinemaMovieShowtimes = '/CinemaPub/movie-showtimes';
}



