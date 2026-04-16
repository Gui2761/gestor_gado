import 'package:flutter/material.dart';
// Importa o teu modelo offline!
import '../ml/modelo_ia.dart'; 
import '../models/animal.dart';
import '../models/manejo.dart';
import '../database/database_helper.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatDiagnosticoScreen extends StatefulWidget {
  final Animal animal;
  const ChatDiagnosticoScreen({Key? key, required this.animal}) : super(key: key);

  @override
  _ChatDiagnosticoScreenState createState() => _ChatDiagnosticoScreenState();
}

class _ChatDiagnosticoScreenState extends State<ChatDiagnosticoScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> mensagens = [];
  List<double> respostasIA = []; // Aqui guardamos os 11 números para a IA
  int perguntaAtualIndex = 0;
  bool diagnosticoConcluido = false;

  // As 11 perguntas que a IA vai fazer, pela mesma ordem do modelo!
  final List<String> perguntasIA = [
    "Olá! Sou o seu Assistente Veterinário Virtual. Vamos analisar o animal.\n\nQual é a Temperatura Corporal (ºC)? (Apenas números)",
    "Qual é a Frequência Cardíaca (bpm)? (Apenas números)",
    "O animal apresenta Perda de Apetite? (Responda Sim ou Não)",
    "O animal está com Vómitos? (Sim ou Não)",
    "Apresenta Diarreia? (Sim ou Não)",
    "Apresenta Tosse? (Sim ou Não)",
    "Tem Dificuldade Respiratória? (Sim ou Não)",
    "O animal apresenta Claudicação (está a mancar)? (Sim ou Não)",
    "Tem Lesões na Pele? (Sim ou Não)",
    "Apresenta Corrimento Nasal? (Sim ou Não)",
    "Apresenta Corrimento Ocular? (Sim ou Não)"
  ];

  final List<String> listaDoencas = [
    'Pleuropneumonia por Actinobacillus', 'Actinobacillus Suis', 'Peste Suína Africana', 
    'Rinite Alérgica', 'Artrite', 'Língua Azul', 'Doença da Língua Azul', 
    'Vírus da Língua Azul', 'Língua Azul (Variante)', 'Vírus da Língua Azul (Variante)', 'Infecção por Bordetella', 
    'Coccidiose Bovina', 'Gripe Bovina', "Doença de Johne Bovina", 
    'Vírus da Leucemia Bovina', 'Mastite Bovina', 'Parainfluenza Bovina', 
    'Pneumonia Bovina', 'Doença Respiratória Bovina', 'Complexo de Doença Respiratória Bovina', 
    'Vírus Sincicial Respiratório Bovino', 'Tuberculose Bovina', 'Diarreia Viral Bovina', 
    'Tosse dos Canis', 'Cinomose Canina', 'Gripe Canina', 'Verme do Coração Canino', 
    'Hepatite Canina', 'Hepatite Infecciosa Canina', 'Influenza Canina', 
    'Leptospirose Canina', 'Parvovirose Canina', 'Artrite Caprina', 
    'Encefalite da Artrite Caprina', 'Vírus da Encefalite da Artrite Caprina', 
    'Pleuropneumonia Caprina', 'Doença Respiratória Caprina', 'Artrite Viral Caprina', 
    'Linfadenite Caseosa', 'Clamídia em Ovinos', 'Bronquite Crônica', 
    'Coccidiose', 'Conjuntivite', 'Aborto Contagioso', 'Ectima Contagioso', 
    'Criptosporidiose', 'Doença Articular Degenerativa', 'Cinomose', 'Enterite', 
    'Artrite Equina', "Doença de Cushing Equina", 'Encefalite Equina', 
    'Encefalomielite Equina', 'Herpesvírus Equino', 'Anemia Infecciosa Equina', 
    'Gripe Equina', 'Vírus da Influenza Equina', 'Laminite Equina', 
    'Leptospirose Equina', 'Doença de Lyme Equina', 'Síndrome Metabólica Equina', 
    'Osteoartrite Equina', 'Piroplasmose Equina', 'Pneumonia Equina', 
    'Mieloencefalite Protozoária Equina', 'Rinopneumonite Equina', 'Arterite Viral Equina', 
    'Vírus do Nilo Ocidental Equino', 'Asma Felina', 'Calicivírus Felino', 'Clamídia Felina', 
    'Clamidiose Felina', 'Coronavírus Felino', 'Herpesvírus Felino', 
    'Vírus da Imunodeficiência Felina', 'Peritonite Infecciosa Felina', 'Leucemia Felina', 
    'Vírus da Leucemia Felina', 'Panleucopenia Felina', 'Vírus da Panleucopenia Felina', 
    'Doença Renal Felina', 'Complexo de Doença Respiratória Felina', 'Infecção Respiratória Felina', 
    'Rinotraqueíte Felina', 'Infecção Respiratória Superior Felina', 'Rinotraqueíte Viral Felina', 
    'Febre Aftosa', 'Febre Aftosa (Variante)', 'Podridão dos Pés (Footrot)', 'Infecção Fúngica', 
    'Gastroenterite', 'Infecção Gastrointestinal', 'Estase Gastrointestinal', 
    'Giardíase', 'Variola Caprina', 'Doença do Verme do Coração', 'Hipertireoidismo', 
    'Doença Inflamatória Intestinal', 'Parasitas Intestinais', "Doença de Johne", 
    'Tosse dos Canis (Kennel Cough)', 'Laminite', 'Leptospirose', 'Doença de Lyme', 'Maedi-Visna', 
    'Mastite', 'Mixomatose', 'Pancreatite', 'Panleucopenia', 'Parvovírus', 
    'Pasteurelose', 'Pneumonia', 'Doença do Circovírus Suíno', 'Diarreia Epidêmica Suína', 
    'Vírus da Diarreia Epidêmica Suína', 'Síndrome Respiratória e Reprodutiva Suína', 
    'Complexo de Doença Respiratória Suína', 'Calicivírus de Coelho', 'Doença Hemorrágica de Coelho', 
    'Sífilis de Coelho', 'Doença Hemorrágica Viral de Coelho', 'Infecção Respiratória', 
    'Vírus Sincicial Respiratório', 'Micose (Ringworm)', 'Salmonelose', 'Scrapie', 'Doença de Scrapie', 
    'Coriza (Snuffles)', 'Garrotilho', 'Disenteria Suína', 'Erisipela Suína', 'Peste Suína', 
    'Gripe Suína', 'Influenza Suína', 'Doença Transmitida por Carrapatos', 'Tuberculose', 
    'Infecção Respiratória Superior', 'Doença Hemorrágica Viral', 'Vírus do Nilo Ocidental'
  ];

  @override
  void initState() {
    super.initState();
    _adicionarMensagemIA(perguntasIA[0]);
  }

  void _adicionarMensagemIA(String texto) {
    setState(() {
      mensagens.add(ChatMessage(text: texto, isUser: false));
    });
    _rolarParaFundo();
  }

  void _adicionarMensagemUtilizador(String texto) {
    setState(() {
      mensagens.add(ChatMessage(text: texto, isUser: true));
    });
    _rolarParaFundo();
  }

  void _rolarParaFundo() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _processarResposta(String texto) async {
    if (texto.trim().isEmpty) return;

    _adicionarMensagemUtilizador(texto);
    _textController.clear();

    // Pequeno atraso para parecer que a IA está a "pensar"
    await Future.delayed(const Duration(milliseconds: 600));

    // Validar e guardar a resposta (Sinais vitais vs Sintomas)
    if (perguntaAtualIndex < 2) {
      // São perguntas numéricas (Temperatura e Batimentos)
      double? valor = double.tryParse(texto.replaceAll(',', '.'));
      if (valor == null) {
        _adicionarMensagemIA("Por favor, digite apenas números válidos (ex: 39.5).");
        return;
      }
      respostasIA.add(valor);
    } else {
      // São perguntas de Sim/Não
      String textoLimpo = texto.trim().toLowerCase();
      if (textoLimpo == 'sim' || textoLimpo == 's' || textoLimpo == 'yes') {
        respostasIA.add(1.0);
      } else if (textoLimpo == 'nao' || textoLimpo == 'não' || textoLimpo == 'n' || textoLimpo == 'no') {
        respostasIA.add(0.0);
      } else {
        _adicionarMensagemIA("Por favor, responda apenas com 'Sim' ou 'Não'.");
        return;
      }
    }

    perguntaAtualIndex++;

    // Verificar se já acabaram as perguntas
    if (perguntaAtualIndex < perguntasIA.length) {
      _adicionarMensagemIA(perguntasIA[perguntaAtualIndex]);
    } else {
      _realizarDiagnosticoOffline();
    }
  }

  void _realizarDiagnosticoOffline() {
    setState(() => diagnosticoConcluido = true);
    _adicionarMensagemIA("A analisar os sintomas offline... ⏳");

    Future.delayed(const Duration(seconds: 1), () {
      try {
        // MÁGICA OFFLINE: Chama a função "score" do ficheiro modelo_ia.dart
        List<double> resultados = score(respostasIA);

        // Encontrar a doença com a maior probabilidade (ArgMax)
        int maxIndex = 0;
        double maxScore = -1.0;
        
        for (int i = 0; i < resultados.length; i++) {
          if (resultados[i] > maxScore) {
            maxScore = resultados[i];
            maxIndex = i;
          }
        }

        String doencaPrevista = listaDoencas[maxIndex];
        String confianca = (maxScore * 100).toStringAsFixed(1);

        // --- SALVAR NO PRONTUÁRIO AUTOMATICAMENTE ---
        final novoManejo = Manejo(
          animalId: widget.animal.id!,
          categoria: 'IA - Diagnóstico',
          nome: doencaPrevista,
          data: DateTime.now().toString(),
          observacao: 'Confiança: $confianca%',
        );
        DatabaseHelper.instance.insertManejo(novoManejo.toMap());

        setState(() {
          mensagens.removeLast(); // Remove o "A analisar..."
          _adicionarMensagemIA("✅ **Diagnóstico Concluído!**\n\nPossível Doença: **$doencaPrevista**\nConfiança: $confianca%\n\nLembre-se: O registro foi guardado no prontuário do animal.");
        });
      } catch (e) {
        _adicionarMensagemIA("Ocorreu um erro ao processar os dados. Tente novamente.");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistente Virtual IA'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black, 
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: mensagens.length,
              itemBuilder: (context, index) {
                final msg = mensagens[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Colors.green[900] : Colors.grey[900],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: msg.isUser ? const Radius.circular(16) : const Radius.circular(0),
                        bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
                      ),
                      border: Border.all(color: msg.isUser ? Colors.green.withOpacity(0.3) : Colors.grey[800]!),
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          if (!diagnosticoConcluido)
            SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.black,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (perguntaAtualIndex >= 2) ...[
                      // BOTÕES DE RESPOSTA RÁPIDA (SIM/NÃO)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[900],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _processarResposta("Não"),
                              child: const Text("NÃO", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _processarResposta("Sim"),
                              child: const Text("SIM", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    // CAMPO DE TEXTO (Apenas para Temperatura/Batimentos ou se o utilizador quiser digitar)
                    if (perguntaAtualIndex < 2)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              style: const TextStyle(color: Colors.white),
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: "Digite o valor numérico...",
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.grey[900],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              keyboardType: TextInputType.number,
                              onSubmitted: _processarResposta,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.green[700],
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: () => _processarResposta(_textController.text),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}