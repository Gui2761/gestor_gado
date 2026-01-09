class Transacao {
  final int? id;
  final String tipo; // 'VENDA' ou 'DESPESA'
  final String descricao;
  final double valor;
  final String data;
  final int? animalId; // <--- NOVO CAMPO: Vínculo com o animal

  Transacao({
    this.id,
    required this.tipo,
    required this.descricao,
    required this.valor,
    required this.data,
    this.animalId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'descricao': descricao,
      'valor': valor,
      'data': data,
      'animal_id': animalId, // Salva no banco
    };
  }

  factory Transacao.fromMap(Map<String, dynamic> map) {
    return Transacao(
      id: map['id'],
      tipo: map['tipo'],
      descricao: map['descricao'],
      valor: map['valor'],
      data: map['data'],
      animalId: map['animal_id'], // Lê do banco
    );
  }
}