import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../database/database_helper.dart';
import '../models/animal.dart';
import '../models/manejo.dart';
import '../services/pdf_service.dart';
import 'cadastro_animal_screen.dart';
import 'financas_screen.dart';
import 'dashboard_screen.dart';
import 'backup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Animal> _todosAnimais = [];
  List<Animal> _animaisFiltrados = [];
  Map<int, Manejo> _ultimoManejoPorAnimal = {}; 
  
  bool _isLoading = true;
  String _filtroBusca = "";
  String _filtroStatus = "Todos"; 
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _atualizarLista();
  }

  void _atualizarLista() async {
    setState(() => _isLoading = true);
    
    // Busca Animais e Histórico
    final dataAnimais = await DatabaseHelper.instance.queryAllAnimais();
    final todosManejos = await DatabaseHelper.instance.queryTodosManejos();
    
    // Mapeia o último tratamento de cada boi
    Map<int, Manejo> mapTemp = {};
    for (var m in todosManejos) {
       final manejo = Manejo.fromMap(m);
       if (!mapTemp.containsKey(manejo.animalId)) {
         mapTemp[manejo.animalId] = manejo;
       }
    }

    setState(() {
      _todosAnimais = dataAnimais.map((e) => Animal.fromMap(e)).toList();
      _ultimoManejoPorAnimal = mapTemp;
      _isLoading = false;
      _aplicarFiltros(); 
    });
  }

  void _aplicarFiltros() {
    setState(() {
      _animaisFiltrados = _todosAnimais.where((boi) {
        final termo = _filtroBusca.toLowerCase();
        final matchTexto = 
          boi.brinco.toLowerCase().contains(termo) ||
          (boi.nome != null && boi.nome!.toLowerCase().contains(termo));
        final matchStatus = _filtroStatus == "Todos" ? true : boi.status == _filtroStatus;
        return matchTexto && matchStatus;
      }).toList();
    });
  }

  // --- PDF ATUALIZADO (AGORA PUXA DADOS DE VACINA) ---
  void _mostrarOpcoesPDF() async {
    if (_animaisFiltrados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lista vazia!")));
      return;
    }

    // Busca as últimas movimentações gerais para o relatório GTA
    final dadosManejo = await DatabaseHelper.instance.queryTodosManejos();
    final listaManejo = dadosManejo.map((e) => Manejo.fromMap(e)).toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.description, color: Colors.blue),
            title: const Text("Documento para GTA"),
            subtitle: const Text("Contagem + Vacinas Recentes"),
            onTap: () { 
              Navigator.pop(ctx); 
              // Passa a lista de animais E a lista de vacinas
              PdfService().gerarRelatorioGTA(_animaisFiltrados, listaManejo); 
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt, color: Colors.green),
            title: const Text("Relatório Geral"),
            subtitle: const Text("Lista simples do rebanho"),
            onTap: () { Navigator.pop(ctx); PdfService().gerarRelatorioGeral(_animaisFiltrados); },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestão de Gado"),
        elevation: 0,
        actions: [
          // 1. Painel
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: "Painel",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const DashboardScreen())),
          ),
          // 2. Financeiro
          IconButton(
            icon: const Icon(Icons.attach_money),
            tooltip: "Financeiro",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const FinancasScreen())),
          ),
          // 3. PDF
          IconButton(
            onPressed: _mostrarOpcoesPDF, 
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Relatórios",
          ),
          
          // 4. Menu (Backup)
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'backup') {
                await Navigator.push(context, MaterialPageRoute(builder: (c) => const BackupScreen()));
                _atualizarLista();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'backup',
                  child: Row(
                    children: [
                      Icon(Icons.settings_backup_restore, color: Colors.black54),
                      SizedBox(width: 10),
                      Text('Backup e Dados'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        tooltip: "Novo Animal",
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const CadastroAnimalScreen()));
          _atualizarLista();
        },
      ),

      body: Column(
        children: [
          // BARRA DE BUSCA
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 5),
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Buscar por Brinco ou Nome...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty 
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() { _filtroBusca = ""; _aplicarFiltros(); }); }) : null,
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _filtroBusca = val;
                      _aplicarFiltros();
                    });
                  },
                ),
                
                const SizedBox(height: 10),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("Todos"),
                      _buildFilterChip("Ativo"),
                      _buildFilterChip("Vendido"),
                      _buildFilterChip("Morto"),
                      _buildFilterChip("Doente"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // LISTA DE ANIMAIS
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _animaisFiltrados.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        Text(
                          _todosAnimais.isEmpty ? "Nenhum animal cadastrado." : "Nenhum resultado encontrado.",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _animaisFiltrados.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final animal = _animaisFiltrados[index];
                      // PEGA O ÚLTIMO REMÉDIO DESTE BOI
                      final ultimoManejo = _ultimoManejoPorAnimal[animal.id];
                      
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => CadastroAnimalScreen(animalParaEditar: animal)));
                            _atualizarLista(); 
                          },
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundImage: (animal.fotoPath != null && File(animal.fotoPath!).existsSync())
                                ? FileImage(File(animal.fotoPath!))
                                : null,
                            child: (animal.fotoPath == null || !File(animal.fotoPath!).existsSync())
                                ? const Icon(Icons.pets) : null,
                          ),
                          title: Row(
                            children: [
                              Text(
                                "Brinco: ${animal.brinco}", 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                              ),
                              if (animal.nome != null && animal.nome!.isNotEmpty)
                                Flexible(
                                  child: Text(" (${animal.nome})", overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text("${animal.raca} • ${animal.sexo}"),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  // Status
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getCorStatus(animal.status),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      animal.status,
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text("${animal.peso} kg", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),

                              // --- LINHA VERDE DO ÚLTIMO REMÉDIO ---
                              if (ultimoManejo != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      Icon(Icons.health_and_safety, size: 14, color: Colors.green[700]),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          "${ultimoManejo.categoria}: ${ultimoManejo.nome} (${DateFormat('dd/MM').format(DateTime.parse(ultimoManejo.data))})",
                                          style: TextStyle(fontSize: 12, color: Colors.green[800], fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _filtroStatus == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _filtroStatus = label;
            _aplicarFiltros();
          });
        },
        selectedColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color
        ),
        backgroundColor: Theme.of(context).cardColor,
      ),
    );
  }

  Color _getCorStatus(String status) {
    switch (status) {
      case 'Ativo': return Colors.green;
      case 'Vendido': return Colors.blue;
      case 'Morto': return Colors.black87;
      case 'Doente': return Colors.orange;
      default: return Colors.grey;
    }
  }
}