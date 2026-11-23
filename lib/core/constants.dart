import 'package:flutter_dotenv/flutter_dotenv.dart';

// main() loads the bundled .env before the app makes any API requests.
String get baseUrl =>
    dotenv.get('API_BASE_URL').trim().replaceFirst(RegExp(r'/+$'), '');
