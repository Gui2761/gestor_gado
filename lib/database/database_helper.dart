import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton: Garante que só exista uma conexão com o banco aberta
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fazenda.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Tipos do SQLite
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL'; // 'REAL' é o double do SQLite

    // 1. Tabela de Animais
    await db.execute('''
CREATE TABLE animais ( 
  id $idType, 
  brinco $textType,
  nome $textType,
  raca $textType,
  sexo $textType,
  status $textType, 
  peso $doubleType,
  data_nascimento $textType,
  foto_path TEXT -- Pode ser nulo se não tiver foto
  )
''');

    // 2. Tabela de Finanças (Vendas/Despesas)
    await db.execute('''
CREATE TABLE financas (
  id $idType,
  tipo $textType, -- 'VENDA' ou 'DESPESA'
  descricao $textType,
  valor $doubleType,
  data $textType
  )
''');

    // 3. Tabela de Vacinas/Sanitário
    await db.execute('''
CREATE TABLE vacinas (
  id $idType,
  nome $textType,
  data_aplicacao $textType,
  data_proxima TEXT, -- Pode ser nulo
  observacao $textType
  )
''');
  }

  // Método genérico para fechar o banco
  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // --- FUNÇÕES NOVAS PARA O BACKUP ---
  
  // 1. Descobre onde o arquivo do banco está no celular
  Future<String> getDbPath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'fazenda.db');
  }

  // 2. Fecha a conexão e limpa a variável (Essencial para Restauração)
  Future<void> closeAndReset() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
  // -----------------------------------

  // MÉTODOS: ANIMAIS
  Future<int> insertAnimal(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('animais', row);
  }
  Future<int> updateAnimal(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db.update('animais', row, where: 'id = ?', whereArgs: [id]);
  }
  Future<List<Map<String, dynamic>>> queryAllAnimais() async {
    Database db = await instance.database;
    return await db.query('animais', orderBy: "id DESC");
  }
  Future<int> deleteAnimal(int id) async {
    Database db = await instance.database;
    return await db.delete('animais', where: 'id = ?', whereArgs: [id]);
  }

  // MÉTODOS: FINANÇAS
  Future<int> insertTransacao(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('financas', row);
  }
  Future<List<Map<String, dynamic>>> queryAllTransacoes() async {
    Database db = await instance.database;
    return await db.query('financas', orderBy: "id DESC"); 
  }
  Future<int> deleteTransacao(int id) async {
    Database db = await instance.database;
    return await db.delete('financas', where: 'id = ?', whereArgs: [id]);
  }

  // MÉTODOS: VACINAS
  Future<int> insertVacina(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('vacinas', row);
  }
  Future<List<Map<String, dynamic>>> queryAllVacinas() async {
    Database db = await instance.database;
    return await db.query('vacinas', orderBy: "data_aplicacao DESC");
  }
  Future<int> deleteVacina(int id) async {
    Database db = await instance.database;
    return await db.delete('vacinas', where: 'id = ?', whereArgs: [id]);
  }
}