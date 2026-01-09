class Manejo {
  final int? id;
  final int animalId;
  final String categoria; // Vacina, Vermífugo, Vitamina...
  final String nome;      // Ex: Aftosa, Ivermectina
  final String data;
  final String? observacao;

  Manejo({
    this.id,
    required this.animalId,
    required this.categoria,
    required this.nome,
    required this.data,
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animal_id': animalId,
      'categoria': categoria,
      'nome': nome,
      'data': data,
      'observacao': observacao,
    };
  }

  factory Manejo.fromMap(Map<String, dynamic> map) {
    return Manejo(
      id: map['id'],
      animalId: map['animal_id'],
      categoria: map['categoria'],
      nome: map['nome'],
      data: map['data'],
      observacao: map['observacao'],
    );
  }
}