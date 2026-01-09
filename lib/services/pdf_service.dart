import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/animal.dart';

class PdfService {

  // --- 1. FUNÇÃO PRINCIPAL: RELATÓRIO GERAL (Aquele simples) ---
  Future<void> gerarRelatorioGeral(List<Animal> animais) async {
    final pdf = pw.Document();
    
    // Ordena por nome
    animais.sort((a, b) => (a.nome ?? '').compareTo(b.nome ?? ''));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          _buildHeader("Relatório Geral de Rebanho"),
          pw.SizedBox(height: 20),
          _buildTabelaGeral(animais),
          pw.SizedBox(height: 20),
          _buildRodape(animais),
        ],
      ),
    );
    await _abrirPDF(pdf, "relatorio_geral");
  }

  // --- 2. NOVA FUNÇÃO: RELATÓRIO PARA GTA (O Completo) ---
  Future<void> gerarRelatorioGTA(List<Animal> animais) async {
    final pdf = pw.Document();

    // Filtra apenas os animais que vão viajar (Ativos ou Vendidos)
    // Se quiser todos, pode remover esse filtro
    final listaParaGTA = animais; 

    // Calcula os totais por faixa etária (A MÁGICA ACONTECE AQUI)
    final dadosGTA = _calcularFaixasEtarias(listaParaGTA);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          _buildHeader("Auxiliar para Emissão de GTA", cor: PdfColors.blue800),
          pw.SizedBox(height: 10),
          pw.Text("Use os dados abaixo para preencher o formulário do governo.", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 20),
          
          // Tabela Resumo (Para preencher a guia)
          pw.Text("1. Resumo por Idade e Sexo", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 5),
          _buildTabelaFaixaEtaria(dadosGTA),
          
          pw.SizedBox(height: 30),

          // Tabela Detalhada (Para anexo)
          pw.Text("2. Lista Detalhada (Anexo)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 5),
          _buildTabelaDetalhadaGTA(listaParaGTA),
        ],
      ),
    );
    await _abrirPDF(pdf, "auxiliar_gta");
  }

  // --- CÁLCULOS DA GTA ---
  Map<String, Map<String, int>> _calcularFaixasEtarias(List<Animal> animais) {
    // Inicializa zerado
    final map = {
      '0 a 12 meses': {'M': 0, 'F': 0},
      '13 a 24 meses': {'M': 0, 'F': 0},
      '25 a 36 meses': {'M': 0, 'F': 0},
      'Acima de 36 meses': {'M': 0, 'F': 0},
    };

    final hoje = DateTime.now();

    for (var boi in animais) {
      // Calcula meses
      int meses = 0;
      try {
        final nasc = DateTime.parse(boi.dataNascimento);
        meses = (hoje.difference(nasc).inDays / 30).floor();
      } catch (e) {
        meses = 37; // Se não tiver data, joga para adulto por segurança
      }

      String faixa = 'Acima de 36 meses';
      if (meses <= 12) faixa = '0 a 12 meses';
      else if (meses <= 24) faixa = '13 a 24 meses';
      else if (meses <= 36) faixa = '25 a 36 meses';

      // Define sexo (Macho ou Fêmea)
      String sexo = (boi.sexo.toUpperCase().startsWith('M') || boi.sexo.toUpperCase().startsWith('T')) ? 'M' : 'F';

      map[faixa]![sexo] = (map[faixa]![sexo] ?? 0) + 1;
    }
    return map;
  }

  // --- COMPONENTES VISUAIS ---

  pw.Widget _buildHeader(String titulo, {PdfColor cor = PdfColors.green700}) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(color: cor, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(titulo, style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text(
            "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
            style: const pw.TextStyle(color: PdfColors.white)
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTabelaFaixaEtaria(Map<String, Map<String, int>> dados) {
    return pw.TableHelper.fromTextArray(
      headers: ['Faixa Etária (Idade)', 'Machos', 'Fêmeas', 'Total'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700),
      cellAlignment: pw.Alignment.center,
      data: dados.entries.map((entry) {
        final machos = entry.value['M']!;
        final femeas = entry.value['F']!;
        return [
          entry.key,
          machos,
          femeas,
          (machos + femeas), // Total da linha
        ];
      }).toList(),
    );
  }

  pw.Widget _buildTabelaDetalhadaGTA(List<Animal> animais) {
    return pw.TableHelper.fromTextArray(
      headers: ['Brinco', 'Nome', 'Sexo', 'Raça', 'Idade (Meses)'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      data: animais.map((a) {
        int meses = 0;
        try {
          meses = (DateTime.now().difference(DateTime.parse(a.dataNascimento)).inDays / 30).floor();
        } catch (_) {}
        
        return [
          a.brinco,
          a.nome ?? '-',
          a.sexo,
          a.raca,
          "$meses m",
        ];
      }).toList(),
    );
  }

  // Tabela Antiga (para o relatório geral)
  pw.Widget _buildTabelaGeral(List<Animal> animais) {
    return pw.TableHelper.fromTextArray(
      border: null,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      headerHeight: 30,
      cellHeight: 30,
      headers: <String>['Brinco', 'Nome/Raça', 'Sexo', 'Peso', 'Status'],
      data: animais.map((animal) {
        return [
          animal.brinco,
          "${animal.nome ?? ''}\n${animal.raca}",
          animal.sexo,
          "${animal.peso.toStringAsFixed(1)} kg",
          animal.status,
        ];
      }).toList(),
    );
  }

  pw.Widget _buildRodape(List<Animal> animais) {
    double pesoTotal = animais.fold(0, (sum, item) => sum + item.peso);
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text("Total: ${animais.length} animais | Peso Total: ${pesoTotal.toStringAsFixed(1)} kg", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _abrirPDF(pw.Document pdf, String nomeArquivo) async {
    await Printing.sharePdf(bytes: await pdf.save(), filename: '${nomeArquivo}_${DateTime.now().day}.pdf');
  }
}