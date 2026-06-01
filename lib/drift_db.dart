import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

// Este archivo se generará automáticamente
part 'drift_db.g.dart';

// Definición de la tabla para Drift
class ItemsDrift extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
}

@DriftDatabase(tables: [ItemsDrift])
class MyDriftDatabase extends _$MyDriftDatabase {
  MyDriftDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Consultas simples
  Future<List<ItemsDriftData>> get allItems => select(itemsDrift).get();
  Future<int> addItem(ItemsDriftCompanion entry) => into(itemsDrift).insert(entry);
  Future deleteItem(int id) => (delete(itemsDrift)..where((t) => t.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'drift_db.sqlite'));
    return NativeDatabase(file);
  });
}
