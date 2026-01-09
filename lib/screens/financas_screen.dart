import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transacao.dart';

class FinancasScreen extends StatefulWidget {
  const FinancasScreen({super.key});

  @override
  State<FinancasScreen> createState() => _FinancasScreenState();
}

class _FinancasScreenState extends State<FinancasScreen> {
  List<Transacao> _todasTransacoes = [];
  List<Transacao> _transacoesFiltradas = [];
  DateTime _mesAtual = DateTime.now();

  double _saldoTotal = 0;
  double _receitaTotal = 0;
  double _despesaTotal = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() async {
    setState(() => _isLoading = true);
    final dados = await DatabaseHelper.instance.queryAllTransacoes();
    final lista = dados.map((e) => Transacao.fromMap(e)).toList();

    setState(() {
      _todasTransacoes = lista;
      _isLoading = false;
      _aplicarFiltroData();
    });
  }

  void _aplicarFiltroData() {
    double receita = 0;
    double despesa = 0;

    final filtradas = _todasTransacoes.where((t) {
      try {
        final dataTransacao = DateTime.parse(t.data);
        return dataTransacao.month == _mesAtual.month && 
               dataTransacao.year == _mesAtual.year;
      } catch (e) {
        return false;
      }
    }).toList();

    for (var t in filtradas) {
      if (t.tipo == 'VENDA') {
        receita += t.valor;
      } else {
        despesa += t.valor;
      }
    }

    setState(() {
      _transacoesFiltradas = filtradas;
      _receitaTotal = receita;
      _despesaTotal = despesa;
      _saldoTotal = receita - despesa;
    });
  }

  void _mesAnterior() {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month - 1);
      _aplicarFiltroData();
    });
  }

  void _proximoMes() {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + 1);
      _aplicarFiltroData();
    });
  }

  void _adicionarTransacao() {
    final descricaoController = TextEditingController();
    final valorController = TextEditingController();
    String tipoSelecionado = 'DESPESA'; 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E), // Fundo escuro do alerta
              title: const Text("Nova Movimentação", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("Entrada"),
                          selected: tipoSelecionado == 'VENDA',
                          selectedColor: Colors.green.withOpacity(0.8),
                          backgroundColor: Colors.grey[800],
                          labelStyle: const TextStyle(color: Colors.white),
                          onSelected: (bool selected) {
                            setStateDialog(() => tipoSelecionado = 'VENDA');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("Saída"),
                          selected: tipoSelecionado == 'DESPESA',
                          selectedColor: Colors.red.withOpacity(0.8),
                          backgroundColor: Colors.grey[800],
                          labelStyle: const TextStyle(color: Colors.white),
                          onSelected: (bool selected) {
                            setStateDialog(() => tipoSelecionado = 'DESPESA');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descricaoController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Descrição (Ex: Sal, Venda)",
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    ),
                  ),
                  TextField(
                    controller: valorController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Valor (R\$)",
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("Cancelar", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (valorController.text.isNotEmpty) {
                      final nova = Transacao(
                        tipo: tipoSelecionado,
                        descricao: descricaoController.text,
                        valor: double.parse(valorController.text.replaceAll(',', '.')),
                        data: DateTime.now().toString(),
                      );
                      await DatabaseHelper.instance.insertTransacao(nova.toMap());
                      Navigator.pop(context);
                      _carregarDados();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                  child: const Text("Salvar", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nomeMes = DateFormat('MMMM yyyy', 'pt_BR').format(_mesAtual);

    return Scaffold(
      backgroundColor: Colors.black, // Fundo PRETO total
      appBar: AppBar(
        title: const Text("Financeiro"),
        elevation: 0,
        backgroundColor: Colors.green[900], // Verde mais escuro
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarTransacao,
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Nova Conta"),
      ),
      body: Column(
        children: [
          // 1. CABEÇALHO (Verde Escuro)
          Container(
            padding: const EdgeInsets.only(bottom: 30),
            decoration: BoxDecoration(
              color: Colors.green[900],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Seletor de Mês
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
                        onPressed: _mesAnterior
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          nomeMes.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 15
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
                        onPressed: _proximoMes
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 15),

                // Card Flutuante de Resumo (AGORA ESCURO)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E), // Cinza Grafite
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        icon: Icons.arrow_circle_up, 
                        corIcon: Colors.greenAccent, // Verde neon para contraste
                        label: "Receita", 
                        valor: _receitaTotal,
                        corValor: Colors.greenAccent
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[700]), // Divisória
                      _buildInfoItem(
                        icon: Icons.arrow_circle_down, 
                        corIcon: Colors.redAccent, 
                        label: "Despesa", 
                        valor: _despesaTotal,
                        corValor: Colors.redAccent
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[700]), // Divisória
                      _buildInfoItem(
                        icon: Icons.account_balance_wallet, 
                        corIcon: Colors.blueAccent, 
                        label: "Saldo", 
                        valor: _saldoTotal,
                        corValor: _saldoTotal >= 0 ? Colors.blueAccent : Colors.orangeAccent
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. LISTA DE TRANSAÇÕES (FUNDO PRETO)
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.green))
              : _transacoesFiltradas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.monetization_on_outlined, size: 60, color: Colors.grey[800]),
                        const SizedBox(height: 10),
                        Text("Sem movimentações.", style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 20, bottom: 80),
                    itemCount: _transacoesFiltradas.length,
                    itemBuilder: (context, index) {
                      final t = _transacoesFiltradas[index];
                      final isVenda = t.tipo == 'VENDA';
                      final dataFormatada = DateFormat('dd/MM').format(DateTime.parse(t.data));
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E), // Cartão Cinza Grafite
                          borderRadius: BorderRadius.circular(15),
                          // Borda fina para destacar do fundo preto
                          border: Border.all(color: Colors.grey[850]!), 
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              // Fundo do ícone translúcido
                              color: isVenda ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isVenda ? Icons.trending_up : Icons.trending_down,
                              color: isVenda ? Colors.greenAccent : Colors.redAccent,
                              size: 28,
                            ),
                          ),
                          title: Text(t.descricao, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          subtitle: Text("Dia $dataFormatada", style: TextStyle(color: Colors.grey[500])),
                          trailing: Text(
                            "R\$ ${t.valor.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: isVenda ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16
                            ),
                          ),
                          onLongPress: () {
                            showDialog(
                              context: context, 
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E1E),
                                title: const Text("Excluir?", style: TextStyle(color: Colors.white)),
                                content: const Text("Deseja apagar esse registro?", style: TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
                                  TextButton(onPressed: () {
                                    DatabaseHelper.instance.deleteTransacao(t.id!);
                                    Navigator.pop(ctx);
                                    _carregarDados();
                                  }, child: const Text("Excluir", style: TextStyle(color: Colors.redAccent))),
                                ]
                              )
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon, 
    required Color corIcon, 
    required String label, 
    required double valor, 
    required Color corValor
  }) {
    return Column(
      children: [
        Icon(icon, color: corIcon, size: 26),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(
          "R\$ ${valor.toStringAsFixed(0)}", 
          style: TextStyle(color: corValor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}