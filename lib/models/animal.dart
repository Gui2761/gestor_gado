class Animal {
  final int? id;
  final String brinco;
  final String? nome;
  final String raca;
  final String sexo; // <--- NOVO CAMPO
  final double peso;
  final String status; 
  final String? fotoPath;
  final String dataNascimento;

  Animal({
    this.id,
    required this.brinco,
    this.nome,
    required this.raca,
    required this.sexo, // <--- NOVO
    required this.peso,
    required this.status,
    this.fotoPath,
    required this.dataNascimento,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brinco': brinco,
      'nome': nome,
      'raca': raca,
      'sexo': sexo, // <--- NOVO
      'peso': peso,
      'status': status,
      'foto_path': fotoPath,
      'data_nascimento': dataNascimento,
    };
  }

  factory Animal.fromMap(Map<String, dynamic> map) {
    return Animal(
      id: map['id'],
      brinco: map['brinco'],
      nome: map['nome'],
      raca: map['raca'],
      sexo: map['sexo'] ?? 'Macho', // <--- NOVO (Com valor padrão para evitar erro em dados antigos)
      peso: map['peso'] ?? 0.0, 
      status: map['status'],
      fotoPath: map['foto_path'],
      dataNascimento: map['data_nascimento'],
    );
  }
}