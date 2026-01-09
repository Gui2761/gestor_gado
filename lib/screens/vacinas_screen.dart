import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/vacina.dart';
import 'cadastro_vacina_screen.dart'; // <--- Importante: Importar a nova tela

class VacinasScreen extends StatefulWidget {
  const VacinasScreen({super.key});

  @override
  State<VacinasScreen> createState() => _VacinasScreenState();
}

class _VacinasScreenState extends State<VacinasScreen> {
  List<Vacina> _lista = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() async {
    setState(() => _isLoading = true);
    final dados = await DatabaseHelper.instance.queryAllVacinas();
    setState(() {
      _lista = dados.map((e) => Vacina.fromMap(e)).toList();
      _isLoading = false;
    });
  }

  // Verifica se a data de reforço já passou (Lógica simples para alerta visual)
  bool _isAtrasado(String? dataProxima) {
    if (dataProxima == null) return false;
    try {
      // Converte "dd/mm/aaaa" para DateTime
      final parts = dataProxima.split('/');
      final dataReforco = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      // Verifica se a data de reforço é ANTES de hoje
      return dataReforco.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Controle Sanitário")),
      
      // Botão flutuante agora leva para a tela cheia
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CadastroVacinaScreen()),
          );
          // Se salvou, recarrega a lista
          if (result == true) {
            _carregarDados();
          }
        },
        label: const Text("Nova Aplicação"),
        icon: const Icon(Icons.add),
      ),

      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _lista.isEmpty 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medical_services_outlined, size: 60, color: Colors.grey),
                  Text("Nenhuma vacina registrada."),
                ],
              )
            )
          : ListView.builder(
            itemCount: _lista.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final item = _lista[index];
              final atrasado = _isAtrasado(item.dataProxima);

              return Card(
                // Se estiver atrasado, borda vermelha
                shape: atrasado ? RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(12)
                ) : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: atrasado ? Colors.red : Colors.redAccent,
                    child: Icon(atrasado ? Icons.warning : Icons.medical_services, color: Colors.white),
                  ),
                  title: Text(item.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Em: ${item.observacao}"),
                      if (item.dataProxima != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.event_repeat, size: 16, color: atrasado ? Colors.red : Colors.orange[800]),
                              const SizedBox(width: 4),
                              Text(
                                "Reforço: ${item.dataProxima} ${atrasado ? '(ATRASADO!)' : ''}",
                                style: TextStyle(
                                  color: atrasado ? Colors.red : Colors.orange[800], 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () {
                      // Diálogo de confirmação
                       showDialog(
                        context: context, 
                        builder: (ctx) => AlertDialog(
                          title: const Text("Excluir registro?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                            TextButton(
                              onPressed: () async {
                                await DatabaseHelper.instance.deleteVacina(item.id!);
                                Navigator.pop(ctx);
                                _carregarDados();
                              }, 
                              child: const Text("Excluir")
                            ),
                          ],
                        )
                      );
                    },
                  ),
                ),
              );
            },
          ),
    );
  }
}