import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/vacina.dart';
import '../services/notification_service.dart';

class CadastroVacinaScreen extends StatefulWidget {
  const CadastroVacinaScreen({super.key});

  @override
  State<CadastroVacinaScreen> createState() => _CadastroVacinaScreenState();
}

class _CadastroVacinaScreenState extends State<CadastroVacinaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _obsController = TextEditingController();
  final _dataProximaController = TextEditingController();
  DateTime? _dataEscolhida;
  
  // Variável de controle do carregamento
  bool _isLoading = false;

  // Função para abrir o calendário
  Future<void> _selecionarData() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale("pt", "BR"),
    );
    if (picked != null) {
      setState(() {
        _dataEscolhida = picked;
        _dataProximaController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _salvarVacina() async {
    if (_formKey.currentState!.validate()) {
      
      // 1. ATIVA O LOADING E RECONSTRÓI A TELA
      setState(() => _isLoading = true);

      try {
        final nova = Vacina(
          nome: _nomeController.text,
          observacao: _obsController.text.isEmpty ? "Geral" : _obsController.text,
          dataAplicacao: DateTime.now().toString(),
          dataProxima: _dataProximaController.text.isEmpty ? null : _dataProximaController.text,
        );
        
        // Salva no Banco
        int idGerado = await DatabaseHelper.instance.insertVacina(nova.toMap());
        
        // Agenda Notificação
        if (_dataEscolhida != null) {
          try {
            await NotificationService().agendarNotificacao(
              id: idGerado,
              titulo: "Vacina: ${nova.nome}",
              corpo: "Hoje é dia de reforço para: ${nova.observacao}",
              dataAgendada: _dataEscolhida!,
            );
          } catch (e) {
            print("Erro notificação: $e");
            // Não mostramos erro visual aqui para não travar o fluxo, pois o banco já salvou
          }
        }
        
        if (mounted) {
          Navigator.pop(context, true); // Fecha a tela se deu tudo certo
        }

      } catch (e) {
        // Se deu erro fatal, desliga o loading e mostra aviso
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nova Aplicação Sanitária")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.notifications_active_outlined, size: 60, color: Colors.redAccent),
              const Center(
                child: Text(
                  "O app avisará às 08:00 da data escolhida", 
                  style: TextStyle(color: Colors.grey)
                )
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _nomeController,
                enabled: !_isLoading, // Bloqueia digitação enquanto carrega
                decoration: const InputDecoration(
                  labelText: "Nome do Medicamento/Vacina *", 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication)
                ),
                validator: (val) => val!.isEmpty ? "Obrigatório" : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _obsController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: "Observação (Em quem foi aplicado?)", 
                  border: OutlineInputBorder(),
                  hintText: "Ex: Todo o rebanho, Apenas bezerros...",
                  prefixIcon: Icon(Icons.note_alt_outlined)
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _dataProximaController,
                enabled: !_isLoading,
                readOnly: true,
                onTap: _isLoading ? null : _selecionarData, // Bloqueia clique
                decoration: const InputDecoration(
                  labelText: "Data do Próximo Reforço", 
                  border: OutlineInputBorder(),
                  hintText: "Toque para agendar lembrete",
                  prefixIcon: Icon(Icons.calendar_today),
                  suffixIcon: Icon(Icons.arrow_drop_down)
                ),
              ),

              const SizedBox(height: 40),
              
              // BOTÃO COM LOADING
              ElevatedButton.icon(
                // Se estiver carregando, o botão fica desabilitado (null) para não clicar 2x
                onPressed: _isLoading ? null : _salvarVacina,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  disabledBackgroundColor: Colors.redAccent.withOpacity(0.6) // Cor quando travado
                ),
                // Se carregando, mostra rodinha. Se não, mostra ícone Salvar.
                icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save),
                
                // Se carregando, muda texto para "Salvando..."
                label: Text(
                  _isLoading ? "AGENDANDO..." : "SALVAR E AGENDAR", 
                  style: const TextStyle(fontSize: 16)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}