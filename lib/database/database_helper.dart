import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fazenda_v3.db'); // Mudei para v3 para aplicar a nova tabela
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const intType = 'INTEGER'; // Pode ser nulo (se for uma despesa avulsa)

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
        foto_path TEXT
      )
    ''');

    // Tabela Finanças ATUALIZADA (com animal_id)
    await db.execute('''
      CREATE TABLE financas (
        id $idType,
        tipo $textType,
        descricao $textType,
        valor $doubleType,
        data $textType,
        animal_id $intType 
      )
    ''');

    await db.execute('''
      CREATE TABLE manejo (
        id $idType,
        animal_id INTEGER NOT NULL,
        categoria $textType,
        nome $textType,
        data $textType,
        observacao TEXT,
        FOREIGN KEY (animal_id) REFERENCES animais (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> closeAndReset() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<String> getDbPath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'fazenda_v3.db');
  }

  // --- ANIMAIS ---
  Future<int> insertAnimal(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('animais', row);
  }

  Future<int> updateAnimal(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.update('animais', row, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<List<Map<String, dynamic>>> queryAllAnimais() async {
    Database db = await instance.database;
    return await db.query('animais', orderBy: "id DESC");
  }

  Future<int> deleteAnimal(int id) async {
    Database db = await instance.database;
    await db.delete('manejo', where: 'animal_id = ?', whereArgs: [id]);
    // Opcional: Apagar vendas associadas também? Por segurança, vamos manter o financeiro.
    return await db.delete('animais', where: 'id = ?', whereArgs: [id]);
  }

  // --- FINANÇAS ---
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

  // --- FUNÇÕES NOVAS DE VINCULO (Venda <-> Boi) ---
  
  // 1. Busca a venda associada a um boi
  Future<Map<String, dynamic>?> getVendaPorAnimal(int animalId) async {
    Database db = await instance.database;
    final res = await db.query('financas', 
      where: 'animal_id = ? AND tipo = ?', 
      whereArgs: [animalId, 'VENDA'],
      limit: 1
    );
    return res.isNotEmpty ? res.first : null;
  }

  // 2. Atualiza o valor da venda se ela já existir
  Future<int> updateValorVenda(int animalId, double novoValor) async {
    Database db = await instance.database;
    return await db.update('financas', 
      {'valor': novoValor}, 
      where: 'animal_id = ?', 
      whereArgs: [animalId]
    );
  }

  // 3. Remove a venda se o boi deixar de ser vendido (ex: voltou a ser ativo)
  Future<int> deleteVendaPorAnimal(int animalId) async {
    Database db = await instance.database;
    return await db.delete('financas', where: 'animal_id = ?', whereArgs: [animalId]);
  }

  // --- MANEJO ---
  Future<int> insertManejo(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('manejo', row);
  }

  Future<List<Map<String, dynamic>>> queryManejoPorAnimal(int animalId) async {
    Database db = await instance.database;
    return await db.query('manejo', where: 'animal_id = ?', whereArgs: [animalId], orderBy: "data DESC");
  }

  Future<List<Map<String, dynamic>>> queryUltimosManejos() async {
    Database db = await instance.database;
    return await db.rawQuery('SELECT manejo.*, animais.brinco FROM manejo INNER JOIN animais ON manejo.animal_id = animais.id ORDER BY manejo.data DESC LIMIT 5');
  }

  Future<List<Map<String, dynamic>>> queryTodosManejos() async {
    Database db = await instance.database;
    return await db.query('manejo', orderBy: "data DESC");
  }

  Future<int> deleteManejo(int id) async {
    Database db = await instance.database;
    return await db.delete('manejo', where: 'id = ?', whereArgs: [id]);
  }
}