import 'package:flutter/material.dart';
// Importa o teu modelo offline!
import '../ml/modelo_ia.dart'; 

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatDiagnosticoScreen extends StatefulWidget {
  const ChatDiagnosticoScreen({Key? key}) : super(key: key);

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
    'Actinobacillus Pleuropneumonia', 'Actinobacillus Suis', 'African Swine Fever', 
    'Allergic Rhinitis', 'Arthritis', 'Blue Tongue', 'Blue Tongue Disease', 
    'Blue Tongue Virus', 'Bluetongue', 'Bluetongue Virus', 'Bordetella Infection', 
    'Bovine Coccidiosis', 'Bovine Influenza', "Bovine Johne's Disease", 
    'Bovine Leukemia Virus', 'Bovine Mastitis', 'Bovine Parainfluenza', 
    'Bovine Pneumonia', 'Bovine Respiratory Disease', 'Bovine Respiratory Disease Complex', 
    'Bovine Respiratory Syncytial Virus', 'Bovine Tuberculosis', 'Bovine Viral Diarrhea', 
    'Canine Cough', 'Canine Distemper', 'Canine Flu', 'Canine Heartworm Disease', 
    'Canine Hepatitis', 'Canine Infectious Hepatitis', 'Canine Influenza', 
    'Canine Leptospirosis', 'Canine Parvovirus', 'Caprine Arthritis', 
    'Caprine Arthritis Encephalitis', 'Caprine Arthritis Encephalitis Virus', 
    'Caprine Pleuropneumonia', 'Caprine Respiratory Disease', 'Caprine Viral Arthritis', 
    'Caseous Lymphadenitis', 'Chlamydia in Sheep', 'Chronic Bronchitis', 
    'Coccidiosis', 'Conjunctivitis', 'Contagious Abortion', 'Contagious Ecthyma', 
    'Cryptosporidiosis', 'Degenerative Joint Disease', 'Distemper', 'Enteritis', 
    'Equine Arthritis', "Equine Cushing's Disease", 'Equine Encephalitis', 
    'Equine Encephalomyelitis', 'Equine Herpesvirus', 'Equine Infectious Anemia', 
    'Equine Influenza', 'Equine Influenza Virus', 'Equine Laminitis', 
    'Equine Leptospirosis', 'Equine Lyme Disease', 'Equine Metabolic Syndrome', 
    'Equine Osteoarthritis', 'Equine Piroplasmosis', 'Equine Pneumonia', 
    'Equine Protozoal Myeloencephalitis', 'Equine Rhinopneumonitis', 'Equine Viral Arteritis', 
    'Equine West Nile Virus', 'Feline Asthma', 'Feline Calicivirus', 'Feline Chlamydia', 
    'Feline Chlamydiosis', 'Feline Coronavirus', 'Feline Herpesvirus', 
    'Feline Immunodeficiency Virus', 'Feline Infectious Peritonitis', 'Feline Leukemia', 
    'Feline Leukemia Virus', 'Feline Panleukopenia', 'Feline Panleukopenia Virus', 
    'Feline Renal Disease', 'Feline Respiratory Disease Complex', 'Feline Respiratory Infection', 
    'Feline Rhinotracheitis', 'Feline Upper Respiratory Infection', 'Feline Viral Rhinotracheitis', 
    'Foot and Mouth Disease', 'Foot-and-Mouth Disease', 'Footrot', 'Fungal Infection', 
    'Gastroenteritis', 'Gastrointestinal Infection', 'Gastrointestinal Stasis', 
    'Giardiasis', 'Goat Pox', 'Heartworm Disease', 'Hyperthyroidism', 
    'Inflammatory Bowel Disease', 'Intestinal Parasites', "Johne's Disease", 
    'Kennel Cough', 'Laminitis', 'Leptospirosis', 'Lyme Disease', 'Maedi-Visna', 
    'Mastitis', 'Myxomatosis', 'Pancreatitis', 'Panleukopenia', 'Parvovirus', 
    'Pasteurellosis', 'Pneumonia', 'Porcine Circovirus Disease', 'Porcine Epidemic Diarrhea', 
    'Porcine Epidemic Diarrhea Virus', 'Porcine Reproductive and Respiratory Syndrome', 
    'Porcine Respiratory Disease Complex', 'Rabbit Calicivirus', 'Rabbit Hemorrhagic Disease', 
    'Rabbit Syphilis', 'Rabbit Viral Hemorrhagic Disease', 'Respiratory Infection', 
    'Respiratory Syncytial Virus', 'Ringworm', 'Salmonellosis', 'Scrapie', 'Scrapie Disease', 
    'Snuffles', 'Strangles', 'Swine Dysentery', 'Swine Erysipelas', 'Swine Fever', 
    'Swine Flu', 'Swine Influenza', 'Tick-Borne Disease', 'Tuberculosis', 
    'Upper Respiratory Infection', 'Viral Hemorrhagic Disease', 'West Nile Virus'
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

        setState(() {
          mensagens.removeLast(); // Remove o "A analisar..."
          _adicionarMensagemIA("✅ **Diagnóstico Concluído!**\n\nPossível Doença: **$doencaPrevista**\nConfiança: $confianca%\n\nLembre-se: Consulte sempre um veterinário para confirmar.");
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
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
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
                      color: msg.isUser ? Colors.deepPurple[100] : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: msg.isUser ? const Radius.circular(16) : const Radius.circular(0),
                        bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          if (!diagnosticoConcluido)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: perguntaAtualIndex < 2 ? "Digite o valor..." : "Digite Sim ou Não...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      keyboardType: perguntaAtualIndex < 2 ? TextInputType.number : TextInputType.text,
                      onSubmitted: _processarResposta,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => _processarResposta(_textController.text),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}