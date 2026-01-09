import 'dart:io';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/animal.dart';
import '../services/pdf_service.dart';
import 'cadastro_animal_screen.dart';
import 'financas_screen.dart';
import 'vacinas_screen.dart';
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
    final data = await DatabaseHelper.instance.queryAllAnimais();
    
    setState(() {
      _todosAnimais = data.map((e) => Animal.fromMap(e)).toList();
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

  // --- NOVA FUNÇÃO DE EXPORTAR ---
  void _menuExportarPDF() {
    if (_animaisFiltrados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("A lista está vazia!")));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Escolha o Relatório", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              // OPÇÃO 1: GTA
              ListTile(
                leading: const Icon(Icons.description, color: Colors.blue, size: 30),
                title: const Text("Documento para GTA", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Contagem oficial por idade e sexo"),
                onTap: () async {
                  Navigator.pop(context); // Fecha o menu
                  final pdfService = PdfService();
                  await pdfService.gerarRelatorioGTA(_animaisFiltrados);
                },
              ),
              const Divider(),
              
              // OPÇÃO 2: GERAL
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green, size: 30),
                title: const Text("Relatório da Fazenda"),
                subtitle: const Text("Lista simples com peso e status"),
                onTap: () async {
                  Navigator.pop(context); // Fecha o menu
                  final pdfService = PdfService();
                  await pdfService.gerarRelatorioGeral(_animaisFiltrados);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestão de Gado"),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: "Painel",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const DashboardScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.medical_services),
            tooltip: "Vacinas",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const VacinasScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.attach_money),
            tooltip: "Financeiro",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const FinancasScreen())),
          ),
          // BOTAO PDF AGORA ABRE O MENU
          IconButton(
            onPressed: _menuExportarPDF, 
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Gerar Relatórios",
          ),
          
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'backup') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const BackupScreen()),
                );
                if (result == true) _atualizarLista();
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
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CadastroAnimalScreen()),
          );
          if (result == true) _atualizarLista();
        },
      ),

      body: Column(
        children: [
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
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _filtroBusca = "";
                              _aplicarFiltros();
                            });
                          },
                        ) 
                      : null,
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
                      
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CadastroAnimalScreen(animalParaEditar: animal)
                              ),
                            );
                            if (result == true) _atualizarLista();
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
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getCorStatus(animal.status),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      animal.status,
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text("${animal.peso} kg", style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              )
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context, 
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Excluir?"),
                                  content: const Text("Essa ação não pode ser desfeita."),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                                    TextButton(
                                      onPressed: () async {
                                        await DatabaseHelper.instance.deleteAnimal(animal.id!);
                                        Navigator.pop(ctx);
                                        _atualizarLista();
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