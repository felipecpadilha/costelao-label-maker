import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'label_maker.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            tempo_de_validade INTEGER NOT NULL,
            vencimento_dinamico INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE responsaveis(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE fichas_tecnicas(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome_produto TEXT NOT NULL,
            imagem_produto_base64 TEXT,
            modo_preparo_json TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE ficha_tecnica_ingredientes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ficha_tecnica_id INTEGER NOT NULL,
            nome TEXT NOT NULL,
            quantidade TEXT NOT NULL,
            FOREIGN KEY (ficha_tecnica_id) REFERENCES fichas_tecnicas(id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            ALTER TABLE products
            ADD COLUMN vencimento_dinamico INTEGER NOT NULL DEFAULT 0
          ''');
        }

        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS fichas_tecnicas(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nome_produto TEXT NOT NULL,
              imagem_produto_base64 TEXT,
              modo_preparo_json TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS ficha_tecnica_ingredientes(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              ficha_tecnica_id INTEGER NOT NULL,
              nome TEXT NOT NULL,
              quantidade TEXT NOT NULL,
              FOREIGN KEY (ficha_tecnica_id) REFERENCES fichas_tecnicas(id) ON DELETE CASCADE
            )
          ''');
        }
      },
    );
  }
}
