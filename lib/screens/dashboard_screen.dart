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
  int _totalMachos = 0;
  int _totalFemeas = 0;
  double _receita = 0;
  double _despesa = 0;
  bool _isLoading = true;
  int _touchedIndex = -1;
  List<Map<String, dynamic>> _historicoMensal = [];

  @override
  void initState() {
    super.initState();
    _calcularDados();
  }

  String _obterNomeMesAbreviado(int mes) {
    const meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return meses[mes - 1];
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
      if (a.sexo == 'Macho') {
        machos++;
      } else {
        femeas++;
      }
    }

    // Agrupamento por mês para o fluxo de caixa (últimos 6 meses)
    List<Map<String, dynamic>> historicoMensal = [];
    DateTime hoje = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      DateTime dataMes = DateTime(hoje.year, hoje.month - i, 1);
      historicoMensal.add({
        'ano': dataMes.year,
        'mes': dataMes.month,
        'nome': _obterNomeMesAbreviado(dataMes.month),
        'receita': 0.0,
        'despesa': 0.0,
      });
    }

    // Calcula Finanças
    for (var f in financas) {
      if (f.tipo == 'VENDA') {
        rec += f.valor;
      } else {
        desp += f.valor;
      }

      try {
        DateTime dt = DateTime.parse(f.data);
        for (var h in historicoMensal) {
          if (h['ano'] == dt.year && h['mes'] == dt.month) {
            if (f.tipo == 'VENDA') {
              h['receita'] += f.valor;
            } else {
              h['despesa'] += f.valor;
            }
          }
        }
      } catch (_) {}
    }

    setState(() {
      _totalMachos = machos;
      _totalFemeas = femeas;
      _receita = rec;
      _despesa = desp;
      _historicoMensal = historicoMensal;
      _isLoading = false;
    });
  }

  List<PieChartSectionData> _obterSecoesGraficoPizza(bool isDark) {
    final total = _totalMachos + _totalFemeas;
    if (total == 0) return [];

    return List.generate(2, (i) {
      final isTouched = i == _touchedIndex;
      final double radius = isTouched ? 65 : 55;
      final double fontSize = isTouched ? 18 : 14;

      if (i == 0) {
        // Machos
        final double porcentagem = (_totalMachos / total) * 100;
        return PieChartSectionData(
          color: const Color(0xFF00B0FF),
          value: _totalMachos.toDouble(),
          title: '${porcentagem.toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [Shadow(color: Colors.black45, blurRadius: 2)],
          ),
        );
      } else {
        // Fêmeas
        final double porcentagem = (_totalFemeas / total) * 100;
        return PieChartSectionData(
          color: const Color(0xFFEC407A),
          value: _totalFemeas.toDouble(),
          title: '${porcentagem.toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [Shadow(color: Colors.black45, blurRadius: 2)],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalGeral = _totalMachos + _totalFemeas;
    final saldoGeral = _receita - _despesa;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Painel de Gestão",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.green[800],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? Colors.green[400] : Colors.green[800],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- SEÇÃO 1: RESUMO DOS BANERS (KPI) ---
                    Row(
                      children: [
                        Expanded(
                          child: _buildKPICard(
                            context,
                            "Total Rebanho",
                            "$totalGeral cab.",
                            Icons.pets,
                            const Color(0xFF4CAF50),
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildKPICard(
                            context,
                            "Lucro Líquido",
                            "R\$ ${saldoGeral.toStringAsFixed(0)}",
                            Icons.account_balance_wallet,
                            saldoGeral >= 0 ? const Color(0xFF00E676) : const Color(0xFFFF1744),
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- SEÇÃO 2: GRÁFICO DE PIZZA (DONUT) ---
                    Card(
                      elevation: isDark ? 0 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isDark ? Colors.grey[850]! : Colors.transparent,
                        ),
                      ),
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Composição do Rebanho",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "Sexo",
                                    style: TextStyle(
                                      color: isDark ? Colors.green[400] : Colors.green[800],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            
                            // Gráfico de Pizza Oco com Total no Centro
                            SizedBox(
                              height: 180,
                              child: totalGeral == 0
                                  ? Center(
                                      child: Text(
                                        "Nenhum animal registrado",
                                        style: TextStyle(color: Colors.grey[500]),
                                      ),
                                    )
                                  : Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        PieChart(
                                          PieChartData(
                                            pieTouchData: PieTouchData(
                                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                                setState(() {
                                                  if (!event.isInterestedForInteractions ||
                                                      pieTouchResponse == null ||
                                                      pieTouchResponse.touchedSection == null) {
                                                    _touchedIndex = -1;
                                                    return;
                                                  }
                                                  _touchedIndex = pieTouchResponse
                                                      .touchedSection!.touchedSectionIndex;
                                                });
                                              },
                                            ),
                                            borderData: FlBorderData(show: false),
                                            sectionsSpace: 4,
                                            centerSpaceRadius: 50,
                                            sections: _obterSecoesGraficoPizza(isDark),
                                          ),
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "$totalGeral",
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                            const Text(
                                              "Animais",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 25),
                            
                            // Legendas
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLegendItem(
                                  const Color(0xFF00B0FF),
                                  "Machos ($_totalMachos)",
                                  isDark,
                                ),
                                const SizedBox(width: 30),
                                _buildLegendItem(
                                  const Color(0xFFEC407A),
                                  "Fêmeas ($_totalFemeas)",
                                  isDark,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- SEÇÃO 3: GRÁFICO DE BARRAS AGRUPADAS (CASH FLOW MENSAL) ---
                    Card(
                      elevation: isDark ? 0 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isDark ? Colors.grey[850]! : Colors.transparent,
                        ),
                      ),
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Fluxo de Caixa Mensal",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    _buildSmallLegend(Colors.green[400]!, "Vendas", isDark),
                                    const SizedBox(width: 8),
                                    _buildSmallLegend(Colors.red[400]!, "Despesas", isDark),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),

                            // Gráfico de Barras Agrupadas
                            SizedBox(
                              height: 220,
                              child: _historicoMensal.isEmpty
                                  ? Center(
                                      child: Text(
                                        "Sem dados financeiros históricos",
                                        style: TextStyle(color: Colors.grey[500]),
                                      ),
                                    )
                                  : BarChart(
                                      BarChartData(
                                        alignment: BarChartAlignment.spaceAround,
                                        barTouchData: BarTouchData(
                                          touchTooltipData: BarTouchTooltipData(
                                            tooltipBgColor: isDark ? const Color(0xFF2E2E2E) : Colors.white,
                                            tooltipBorder: BorderSide(
                                              color: isDark ? Colors.grey[800]! : Colors.grey[350]!,
                                              width: 1,
                                            ),
                                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                              final String tipo = rodIndex == 0 ? "Venda" : "Despesa";
                                              final Color cor = rodIndex == 0
                                                  ? const Color(0xFF00E676)
                                                  : const Color(0xFFFF1744);
                                              return BarTooltipItem(
                                                "$tipo\n",
                                                TextStyle(
                                                  color: isDark ? Colors.white70 : Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                                children: <TextSpan>[
                                                  TextSpan(
                                                    text: "R\$ ${rod.toY.toStringAsFixed(0)}",
                                                    style: TextStyle(
                                                      color: cor,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          topTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (double value, TitleMeta meta) {
                                                int index = value.toInt();
                                                if (index >= 0 &&
                                                    index < _historicoMensal.length) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(top: 8.0),
                                                    child: Text(
                                                      _historicoMensal[index]['nome'],
                                                      style: TextStyle(
                                                        color: isDark
                                                            ? Colors.white70
                                                            : Colors.black87,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return const SizedBox.shrink();
                                              },
                                              reservedSize: 28,
                                            ),
                                          ),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 42,
                                              getTitlesWidget: (double value, TitleMeta meta) {
                                                if (value == 0) return const SizedBox.shrink();
                                                String texto = "";
                                                if (value >= 1000) {
                                                  texto =
                                                      "${(value / 1000).toStringAsFixed(1)}k";
                                                } else {
                                                  texto = value.toInt().toString();
                                                }
                                                return Text(
                                                  "R\$$texto",
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        gridData: FlGridData(
                                          show: true,
                                          drawVerticalLine: false,
                                          getDrawingHorizontalLine: (value) => FlLine(
                                            color: isDark
                                                ? Colors.grey[850]!
                                                : Colors.grey[200]!,
                                            strokeWidth: 1,
                                            dashArray: [5, 5],
                                          ),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        groupsSpace: 12,
                                        barGroups: List.generate(_historicoMensal.length, (index) {
                                          final h = _historicoMensal[index];
                                          final double receita = h['receita'];
                                          final double despesa = h['despesa'];

                                          return BarChartGroupData(
                                            x: index,
                                            barRods: [
                                              BarChartRodData(
                                                toY: receita,
                                                color: const Color(0xFF00E676),
                                                width: 8,
                                                borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(4),
                                                ),
                                              ),
                                              BarChartRodData(
                                                toY: despesa,
                                                color: const Color(0xFFFF1744),
                                                width: 8,
                                                borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(4),
                                                ),
                                              ),
                                            ],
                                          );
                                        }),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- SEÇÃO 4: RESUMO DETALHADO DO BALANÇO FINANCEIRO ---
                    Card(
                      elevation: isDark ? 0 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isDark ? Colors.grey[850]! : Colors.transparent,
                        ),
                      ),
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              "Balanço Consolidado",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _linhaFinanceira(
                              "Receita Total (Vendas)",
                              _receita,
                              const Color(0xFF00E676),
                              isDark,
                            ),
                            const Divider(),
                            _linhaFinanceira(
                              "Despesas Totais",
                              _despesa,
                              const Color(0xFFFF1744),
                              isDark,
                            ),
                            const Divider(),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "RESULTADO LÍQUIDO",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "R\$ ${saldoGeral.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: saldoGeral >= 0
                                        ? const Color(0xFF00E676)
                                        : const Color(0xFFFF1744),
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

  Widget _buildKPICard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[850]! : Colors.transparent,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text, bool isDark) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallLegend(Color color, String text, bool isDark) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _linhaFinanceira(String label, double valor, Color cor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 13,
            ),
          ),
          Text(
            "R\$ ${valor.toStringAsFixed(2)}",
            style: TextStyle(
              color: cor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}