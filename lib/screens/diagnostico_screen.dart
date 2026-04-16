import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  void _analisarDiagnostico() async {
    if (_formKey.currentState!.validate()) {
      // 1. Preparar os dados exatamente como a IA espera
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A analisar os dados na IA...')),
      );

      try {
        // 2. IP do teu computador onde está a correr a API em Python
        final url = Uri.parse('http://192.168.68.105:8000/prever_doenca');
        
        // 3. Fazer o pedido POST com um tempo limite de 10 segundos
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(dadosBovino),
        ).timeout(const Duration(seconds: 10));

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (response.statusCode == 200) {
          final resultado = jsonDecode(response.body);
          
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Diagnóstico da IA', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text(
                'Risco Detetado:\n${resultado['doenca_prevista']}\n\nConfiança: ${resultado['confianca_percentual']}%',
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ENTENDIDO'),
                ),
              ],
            ),
          );
        } else {
          throw Exception('Erro de servidor: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        print("\n\n====== ERRO NA LIGAÇÃO ======");
        print(e.toString());
        print("=============================\n\n");
        
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Erro de Ligação'),
            content: Text('Não foi possível comunicar com o servidor da IA.\n\nDetalhe: $e'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
            ],
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico Inteligente (IA)'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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
                  if (value == null || value.isEmpty) return 'Insira a temperatura.';
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
                  if (value == null || value.isEmpty) return 'Insira a frequência cardíaca.';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Sintomas Apresentados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
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
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _analisarDiagnostico,
                child: const Text('Analisar Diagnóstico', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}