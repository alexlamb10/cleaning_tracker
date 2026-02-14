import 'package:drift/drift.dart';

QueryExecutor constructDb() {
  throw UnsupportedError(
    'No suitable database implementation was found on this platform.',
  );
}
