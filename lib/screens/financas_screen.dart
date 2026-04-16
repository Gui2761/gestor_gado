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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                // ESSE PADDING AQUI EMPURRA O MODAL PRA CIMA DO TECLADO
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Container(
                  height: 600, 
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E), 
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
                  ),
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                  child: Column(
                    children: [
                      Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(10))),
                      const SizedBox(height: 20),
                      
                      const Text("Nova Movimentação", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),
  
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => tipoSelecionado = 'VENDA'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  color: tipoSelecionado == 'VENDA' ? Colors.green.withOpacity(0.2) : Colors.grey[900],
                                  border: Border.all(color: tipoSelecionado == 'VENDA' ? Colors.green : Colors.transparent, width: 2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.arrow_upward, color: Colors.green),
                                    const SizedBox(height: 5),
                                    Text("ENTRADA", style: TextStyle(color: tipoSelecionado == 'VENDA' ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => tipoSelecionado = 'DESPESA'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  color: tipoSelecionado == 'DESPESA' ? Colors.red.withOpacity(0.2) : Colors.grey[900],
                                  border: Border.all(color: tipoSelecionado == 'DESPESA' ? Colors.red : Colors.transparent, width: 2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.arrow_downward, color: Colors.red),
                                    const SizedBox(height: 5),
                                    Text("SAÍDA", style: TextStyle(color: tipoSelecionado == 'DESPESA' ? Colors.red : Colors.grey, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
  
                      TextField(
                        controller: descricaoController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Descrição",
                          hintText: "Ex: Venda de gado, Ração...",
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.description, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 15),
  
                      TextField(
                        controller: valorController,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: "Valor (R\$)",
                          hintText: "0.00",
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.attach_money, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 30),
  
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (valorController.text.isNotEmpty && descricaoController.text.isNotEmpty) {
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tipoSelecionado == 'VENDA' ? Colors.green[700] : Colors.red[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text("SALVAR MOVIMENTAÇÃO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
      backgroundColor: Colors.black, // Fundo Preto
      appBar: AppBar(
        title: const Text("Financeiro"),
        backgroundColor: Colors.green[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarTransacao,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Nova Conta"),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 30),
            decoration: BoxDecoration(
              color: Colors.green[900],
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20), onPressed: _mesAnterior),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                        child: Text(nomeMes.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      IconButton(icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20), onPressed: _proximoMes),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(Icons.arrow_circle_up, Colors.greenAccent, "Receita", _receitaTotal, Colors.greenAccent),
                      Container(width: 1, height: 40, color: Colors.grey[700]),
                      _buildInfoItem(Icons.arrow_circle_down, Colors.redAccent, "Despesa", _despesaTotal, Colors.redAccent),
                      Container(width: 1, height: 40, color: Colors.grey[700]),
                      _buildInfoItem(Icons.account_balance_wallet, Colors.blueAccent, "Saldo", _saldoTotal, _saldoTotal >= 0 ? Colors.blueAccent : Colors.orangeAccent),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.green))
              : _transacoesFiltradas.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.monetization_on_outlined, size: 60, color: Colors.grey[800]), const SizedBox(height: 10), Text("Sem movimentações.", style: TextStyle(color: Colors.grey[600]))]))
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
                          color: const Color(0xFF1E1E1E), 
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[850]!),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: isVenda ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                            child: Icon(isVenda ? Icons.trending_up : Icons.trending_down, color: isVenda ? Colors.greenAccent : Colors.redAccent, size: 28),
                          ),
                          title: Text(t.descricao, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          subtitle: Text("Dia $dataFormatada", style: TextStyle(color: Colors.grey[500])),
                          trailing: Text("R\$ ${t.valor.toStringAsFixed(2)}", style: TextStyle(color: isVenda ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                          onLongPress: () {
                            showDialog(
                              context: context, 
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E1E),
                                title: const Text("Excluir?", style: TextStyle(color: Colors.white)),
                                content: const Text("Deseja apagar esse registro?", style: TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
                                  TextButton(onPressed: () { DatabaseHelper.instance.deleteTransacao(t.id!); Navigator.pop(ctx); _carregarDados(); }, child: const Text("Excluir", style: TextStyle(color: Colors.redAccent))),
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

  Widget _buildInfoItem(IconData icon, Color corIcon, String label, double valor, Color corValor) {
    return Column(
      children: [
        Icon(icon, color: corIcon, size: 26),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text("R\$ ${valor.toStringAsFixed(0)}", style: TextStyle(color: corValor, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}