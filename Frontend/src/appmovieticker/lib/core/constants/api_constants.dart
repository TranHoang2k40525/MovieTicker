import 'dart:io' show Platform;

class ApiConstants {
  static String get _host {
    if (Platform.isAndroid) {
      return '10.0.2.2';
    }
    return 'localhost';
  }

  static String get _scheme {
    if (Platform.isAndroid) {
      return 'http';
    }
    return 'https';
  }

  static String get baseUrl => '$_scheme://$_host:7084/api';
  static String get mediaBaseUrl => '$_scheme://$_host:7084';

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String movieNowShowing = '/MoviePub/now-showing';
  static const String movieUpcoming = '/MoviePub/upcoming';
  static const String movieSpecial = '/MoviePub/special';
  static const String movieShowingAndUpcoming = '/MoviePub/showing-and-upcoming';
  static const String movieSearch = '/MoviePub/search';
  static const String cinemaNearby = '/CinemaPub/nearby';
}



