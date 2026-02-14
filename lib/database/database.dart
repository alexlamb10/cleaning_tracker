import 'package:drift/drift.dart';
import 'connection/unsupported.dart'
    if (dart.library.html) 'connection/web.dart'
    if (dart.library.io) 'connection/native.dart';

part 'database.g.dart';

// Room table
class Rooms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text().withDefault(const Constant('🏠'))();
  TextColumn get color => text().withDefault(const Constant('#2196F3'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Task table
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get roomId => integer().references(Rooms, #id, onDelete: KeyAction.cascade)();
  IntColumn get frequencyDays => integer()();
  DateTimeColumn get lastCompletedDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Rooms, Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(constructDb());

  @override
  int get schemaVersion => 1;
}
