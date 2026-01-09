import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/animal.dart';
import '../models/manejo.dart';
import '../services/pdf_service.dart';

class HistoricoSaudeScreen extends StatefulWidget {
  final Animal animal;

  const HistoricoSaudeScreen({super.key, required this.animal});

  @override
  State<HistoricoSaudeScreen> createState() => _HistoricoSaudeScreenState();
}

class _HistoricoSaudeScreenState extends State<HistoricoSaudeScreen> {
  List<Manejo> _historico = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _isLoading = true);
    try {
      final dados = await DatabaseHelper.instance.queryManejoPorAnimal(widget.animal.id!);
      setState(() {
        _historico = dados.map((e) => Manejo.fromMap(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _imprimirFicha() async {
    final pdfService = PdfService();
    await pdfService.gerarFichaAnimal(widget.animal, _historico);
  }

  Future<void> _adicionarEvento() async {
    final nomeController = TextEditingController();
    final obsController = TextEditingController();
    String categoriaSelecionada = 'Vacina';
    DateTime dataSelecionada = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Importante para o teclado
      backgroundColor: Colors.transparent, 
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              // ESSE PADDING AQUI RESOLVE O TECLADO COBRINDO
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: 550, 
                decoration: BoxDecoration(
                  color: Colors.grey[900], 
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Novo Registro", style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.grey))
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: ListView(
                          children: [
                            _buildLabel("Tipo de Aplicação"),
                            DropdownButtonFormField<String>(
                              value: categoriaSelecionada,
                              dropdownColor: Colors.grey[800],
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              items: ['Vacina', 'Vermífugo', 'Vitamina', 'Medicamento', 'Outro']
                                  .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (v) => setModalState(() => categoriaSelecionada = v!),
                              decoration: _inputDecoration(Icons.category),
                            ),
                            const SizedBox(height: 20),

                            _buildLabel("Nome do Produto"),
                            TextField(
                              controller: nomeController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(Icons.medication),
                            ),
                            const SizedBox(height: 20),

                            _buildLabel("Data da Aplicação"),
                            InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context, 
                                  initialDate: dataSelecionada, 
                                  firstDate: DateTime(2000), 
                                  lastDate: DateTime.now(),
                                  builder: (context, child) {
                                    // TEMA ESCURO NO CALENDÁRIO TBM
                                    return Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: ColorScheme.dark(
                                          primary: Colors.green,
                                          onPrimary: Colors.white,
                                          surface: Colors.grey[900]!,
                                          onSurface: Colors.white,
                                        ),
                                        dialogBackgroundColor: Colors.grey[900],
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (d != null) setModalState(() => dataSelecionada = d);
                              },
                              child: InputDecorator(
                                decoration: _inputDecoration(Icons.calendar_today),
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(dataSelecionada), 
                                  style: const TextStyle(fontSize: 16, color: Colors.white)
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            _buildLabel("Observação (Opcional)"),
                            TextField(
                              controller: obsController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(Icons.note),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 30),

                            SizedBox(
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  if (nomeController.text.isEmpty) return;
                                  final novo = Manejo(
                                    animalId: widget.animal.id!,
                                    categoria: categoriaSelecionada,
                                    nome: nomeController.text,
                                    data: dataSelecionada.toString(),
                                    observacao: obsController.text,
                                  );
                                  await DatabaseHelper.instance.insertManejo(novo.toMap());
                                  Navigator.pop(ctx);
                                  _carregarHistorico();
                                },
                                child: const Text("SALVAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(text, style: TextStyle(color: Colors.green[300], fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[800],
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), 
        borderSide: const BorderSide(color: Colors.green, width: 1.5)
      ),
      prefixIcon: Icon(icon, color: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Prontuário Veterinário", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Animal: ${widget.animal.brinco}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.black, 
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.green),
            tooltip: "Imprimir Ficha",
            onPressed: _imprimirFicha, 
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarEvento,
        label: const Text("Novo Registro"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _historico.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.grey[900], 
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green.withOpacity(0.3))
                        ),
                        child: Icon(Icons.health_and_safety, size: 60, color: Colors.green[700]),
                      ),
                      const SizedBox(height: 20),
                      const Text("Nenhum registro.", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      const Text("Toque no botão para adicionar.", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
                  itemCount: _historico.length,
                  itemBuilder: (context, index) {
                    final item = _historico[index];
                    final data = DateFormat('dd/MM/yyyy').format(DateTime.parse(item.data));
                    
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 2, height: 20, 
                                color: index == 0 ? Colors.transparent : Colors.grey[800]
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _getCor(item.categoria), width: 2),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Icon(_getIcone(item.categoria), size: 18, color: _getCor(item.categoria)),
                              ),
                              Expanded(child: Container(width: 2, color: index == _historico.length - 1 ? Colors.transparent : Colors.grey[800])),
                            ],
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Card(
                              elevation: 0,
                              color: Colors.grey[900], 
                              margin: const EdgeInsets.only(bottom: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(color: Colors.grey[800]!)
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _getCor(item.categoria).withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(4)
                                                ),
                                                child: Text(item.categoria.toUpperCase(), style: TextStyle(color: _getCor(item.categoria), fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                              Text(data, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(item.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                          if (item.observacao != null && item.observacao!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 5),
                                              child: Text(item.observacao!, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                                      onPressed: () async {
                                        await DatabaseHelper.instance.deleteManejo(item.id!);
                                        _carregarHistorico();
                                      },
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Color _getCor(String cat) {
    if (cat == 'Vacina') return Colors.blueAccent; 
    if (cat == 'Vermífugo') return Colors.purpleAccent; 
    if (cat == 'Vitamina') return Colors.orangeAccent; 
    return Colors.greenAccent; 
  }

  IconData _getIcone(String cat) {
    if (cat == 'Vacina') return Icons.vaccines;
    if (cat == 'Vermífugo') return Icons.bug_report;
    if (cat == 'Vitamina') return Icons.bolt;
    return Icons.medication;
  }
}