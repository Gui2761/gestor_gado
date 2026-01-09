class Vacina {
  final int? id;
  final String nome; // Ex: Aftosa, Raiva, Ivermectina
  final String dataAplicacao;
  final String? dataProxima; // Pode ser nulo se não tiver reforço
  final String observacao; // Ex: "Todo o rebanho" ou "Só nos bezerros"

  Vacina({
    this.id,
    required this.nome,
    required this.dataAplicacao,
    this.dataProxima,
    required this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'data_aplicacao': dataAplicacao,
      'data_proxima': dataProxima,
      'observacao': observacao,
    };
  }

  factory Vacina.fromMap(Map<String, dynamic> map) {
    return Vacina(
      id: map['id'],
      nome: map['nome'],
      dataAplicacao: map['data_aplicacao'],
      dataProxima: map['data_proxima'],
      observacao: map['observacao'],
    );
  }
}