import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/animal.dart';
import '../models/transacao.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Variáveis para os totais
  int _totalMachos = 0;
  int _totalFemeas = 0;
  double _receita = 0;
  double _despesa = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calcularDados();
  }

  void _calcularDados() async {
    // 1. Busca Animais
    final animaisData = await DatabaseHelper.instance.queryAllAnimais();
    final animais = animaisData.map((e) => Animal.fromMap(e)).toList();

    // 2. Busca Finanças
    final financasData = await DatabaseHelper.instance.queryAllTransacoes();
    final financas = financasData.map((e) => Transacao.fromMap(e)).toList();

    int machos = 0;
    int femeas = 0;
    double rec = 0;
    double desp = 0;

    // Calcula Animais
    for (var a in animais) {
      if (a.sexo == 'Macho') machos++;
      else femeas++;
    }

    // Calcula Finanças
    for (var f in financas) {
      if (f.tipo == 'VENDA') rec += f.valor;
      else desp += f.valor;
    }

    setState(() {
      _totalMachos = machos;
      _totalFemeas = femeas;
      _receita = rec;
      _despesa = desp;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Painel de Gestão")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  const SizedBox(height: 20),
  
                  // --- CARD 1: REBANHO (GRÁFICO PIZZA) ---
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text("Composição do Rebanho", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child: (_totalMachos == 0 && _totalFemeas == 0) 
                              ? const Center(child: Text("Sem dados"))
                              : PieChart(
                                  PieChartData(
                                    sections: [
                                      PieChartSectionData(
                                        value: _totalMachos.toDouble(),
                                        title: "$_totalMachos",
                                        color: Colors.blue,
                                        radius: 50,
                                        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                                      ),
                                      PieChartSectionData(
                                        value: _totalFemeas.toDouble(),
                                        title: "$_totalFemeas",
                                        color: Colors.pinkAccent,
                                        radius: 50,
                                        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                                      ),
                                    ],
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                  ),
                                ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _legenda(Colors.blue, "Machos"),
                              const SizedBox(width: 20),
                              _legenda(Colors.pinkAccent, "Fêmeas"),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
  
                  const SizedBox(height: 20),
  
                  // --- CARD 2: RESUMO FINANCEIRO ---
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text("Balanço Financeiro", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          _linhaFinanceira("Receita Total", _receita, Colors.green),
                          const Divider(),
                          _linhaFinanceira("Despesas", _despesa, Colors.red),
                          const Divider(),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("LUCRO LÍQUIDO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(
                                "R\$ ${(_receita - _despesa).toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 18,
                                  color: (_receita - _despesa) >= 0 ? Colors.green[700] : Colors.red[700]
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _legenda(Color cor, String texto) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: cor),
        const SizedBox(width: 4),
        Text(texto),
      ],
    );
  }

  Widget _linhaFinanceira(String texto, double valor, Color cor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(texto),
        Text("R\$ ${valor.toStringAsFixed(2)}", style: TextStyle(color: cor, fontWeight: FontWeight.bold)),
      ],
    );
  }
}