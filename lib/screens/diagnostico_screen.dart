import 'package:flutter/material.dart';

class DiagnosticoScreen extends StatefulWidget {
  const DiagnosticoScreen({Key? key}) : super(key: key);

  @override
  _DiagnosticoScreenState createState() => _DiagnosticoScreenState();
}

class _DiagnosticoScreenState extends State<DiagnosticoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para os campos numéricos
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _heartRateController = TextEditingController();

  // Variáveis booleanas para os sintomas (Sim/Não)
  bool _appetiteLoss = false;
  bool _vomiting = false;
  bool _diarrhea = false;
  bool _coughing = false;
  bool _laboredBreathing = false;
  bool _lameness = false;
  bool _skinLesions = false;
  bool _nasalDischarge = false;
  bool _eyeDischarge = false;

  void _analisarDiagnostico() {
    if (_formKey.currentState!.validate()) {
      // Este mapa (Map) já está estruturado com os nomes exatos das colunas do nosso dataset!
      // Mais tarde, enviaremos este Map convertido em JSON para a nossa API em FastAPI.
      final dadosBovino = {
        "Body_Temperature": double.tryParse(_tempController.text) ?? 0.0,
        "Heart_Rate": int.tryParse(_heartRateController.text) ?? 0,
        "Appetite_Loss": _appetiteLoss ? "Yes" : "No",
        "Vomiting": _vomiting ? "Yes" : "No",
        "Diarrhea": _diarrhea ? "Yes" : "No",
        "Coughing": _coughing ? "Yes" : "No",
        "Labored_Breathing": _laboredBreathing ? "Yes" : "No",
        "Lameness": _lameness ? "Yes" : "No",
        "Skin_Lesions": _skinLesions ? "Yes" : "No",
        "Nasal_Discharge": _nasalDischarge ? "Yes" : "No",
        "Eye_Discharge": _eyeDischarge ? "Yes" : "No",
      };

      // Feedback visual temporário para o utilizador
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A processar os dados na Inteligência Artificial...')),
      );
      
      // Imprime na consola para podermos testar a estrutura de dados
      print(dadosBovino);
      
      // TODO: Adicionar o pacote 'http' e fazer o pedido POST à API aqui.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico Inteligente (IA)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sinais Vitais',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _tempController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Temperatura Corporal (ºC)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.thermostat),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Por favor, insira a temperatura.';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _heartRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Frequência Cardíaca (bpm)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.favorite),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Por favor, insira a frequência cardíaca.';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Sintomas Apresentados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              
              // Interruptores para os sintomas
              SwitchListTile(
                title: const Text('Perda de Apetite'),
                value: _appetiteLoss,
                onChanged: (val) => setState(() => _appetiteLoss = val),
              ),
              SwitchListTile(
                title: const Text('Vómitos'),
                value: _vomiting,
                onChanged: (val) => setState(() => _vomiting = val),
              ),
              SwitchListTile(
                title: const Text('Diarreia'),
                value: _diarrhea,
                onChanged: (val) => setState(() => _diarrhea = val),
              ),
              SwitchListTile(
                title: const Text('Tosse'),
                value: _coughing,
                onChanged: (val) => setState(() => _coughing = val),
              ),
              SwitchListTile(
                title: const Text('Dificuldade Respiratória'),
                value: _laboredBreathing,
                onChanged: (val) => setState(() => _laboredBreathing = val),
              ),
              SwitchListTile(
                title: const Text('Claudicação (Mancar)'),
                value: _lameness,
                onChanged: (val) => setState(() => _lameness = val),
              ),
              SwitchListTile(
                title: const Text('Lesões na Pele'),
                value: _skinLesions,
                onChanged: (val) => setState(() => _skinLesions = val),
              ),
              SwitchListTile(
                title: const Text('Corrimento Nasal'),
                value: _nasalDischarge,
                onChanged: (val) => setState(() => _nasalDischarge = val),
              ),
              SwitchListTile(
                title: const Text('Corrimento Ocular'),
                value: _eyeDischarge,
                onChanged: (val) => setState(() => _eyeDischarge = val),
              ),
              const SizedBox(height: 30),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: _analisarDiagnostico,
                child: const Text('Analisar Diagnóstico', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}