import 'package:isar/isar.dart';

// Este archivo se generará automáticamente
part 'item_isar.g.dart';

@collection
class ItemIsar {
  Id id = Isar.autoIncrement; // ID autoincremental

  late String nombre;
}
