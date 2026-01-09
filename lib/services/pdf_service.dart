import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/animal.dart';

class PdfService {

  // --- 1. RELATÓRIO GERAL (Simples) ---
  Future<void> gerarRelatorioGeral(List<Animal> animais) async {
    final pdf = pw.Document();
    // Ordena por nome para ficar organizado
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

  // --- 2. RELATÓRIO ESPECIAL PARA GTA (Novo) ---
  Future<void> gerarRelatorioGTA(List<Animal> animais) async {
    final pdf = pw.Document();

    // A MÁGICA: Calcula os totais por faixa etária automaticamente
    final dadosGTA = _calcularFaixasEtarias(animais);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          _buildHeader("Relatório Auxiliar para GTA", cor: PdfColors.blue800),
          pw.SizedBox(height: 10),
          pw.Text(
            "Utilize os dados abaixo para preencher o formulário de trânsito animal (GTA).",
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)
          ),
          pw.SizedBox(height: 20),
          
          // TABELA 1: O RESUMO QUE O GOVERNO PEDE
          pw.Text("1. Contagem por Faixa Etária e Sexo", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 5),
          _buildTabelaFaixaEtaria(dadosGTA),
          
          pw.SizedBox(height: 30),

          // TABELA 2: LISTA DETALHADA DOS ANIMAIS (Para conferência)
          pw.Text("2. Animais Desta Carga (Anexo)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 5),
          _buildTabelaDetalhadaGTA(animais),
        ],
      ),
    );
    await _abrirPDF(pdf, "auxiliar_gta");
  }

  // --- CÁLCULOS MATEMÁTICOS PARA GTA ---
  Map<String, Map<String, int>> _calcularFaixasEtarias(List<Animal> animais) {
    // Inicializa o mapa com as faixas padrão da GTA zeradas
    final map = {
      '0 a 12 meses': {'M': 0, 'F': 0},
      '13 a 24 meses': {'M': 0, 'F': 0},
      '25 a 36 meses': {'M': 0, 'F': 0},
      'Acima de 36 meses': {'M': 0, 'F': 0},
    };

    final hoje = DateTime.now();

    for (var boi in animais) {
      // 1. Descobre a idade em meses
      int meses = 0;
      try {
        if (boi.dataNascimento.isNotEmpty) {
           final nasc = DateTime.parse(boi.dataNascimento);
           meses = (hoje.difference(nasc).inDays / 30).floor();
        } else {
           meses = 37; // Sem data = Adulto (segurança)
        }
      } catch (e) {
        meses = 37; 
      }

      // 2. Define a Faixa
      String faixa = 'Acima de 36 meses';
      if (meses <= 12) faixa = '0 a 12 meses';
      else if (meses <= 24) faixa = '13 a 24 meses';
      else if (meses <= 36) faixa = '25 a 36 meses';

      // 3. Define o Sexo (M ou F)
      String sexo = (boi.sexo.toUpperCase().startsWith('M')) ? 'M' : 'F';

      // 4. Soma +1 na categoria certa
      map[faixa]![sexo] = (map[faixa]![sexo] ?? 0) + 1;
    }
    return map;
  }

  // --- COMPONENTES VISUAIS (TABELAS) ---

  pw.Widget _buildHeader(String titulo, {PdfColor cor = PdfColors.green700}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: cor, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(titulo, style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
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
          (machos + femeas),
        ];
      }).toList(),
    );
  }

  pw.Widget _buildTabelaDetalhadaGTA(List<Animal> animais) {
    return pw.TableHelper.fromTextArray(
      headers: ['Brinco', 'Nome', 'Sexo', 'Raça', 'Idade Est.'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      data: animais.map((a) {
        int meses = 0;
        try {
           if (a.dataNascimento.isNotEmpty) {
             meses = (DateTime.now().difference(DateTime.parse(a.dataNascimento)).inDays / 30).floor();
           }
        } catch (_) {}
        
        return [
          a.brinco,
          a.nome ?? '-',
          a.sexo,
          a.raca,
          "$meses meses",
        ];
      }).toList(),
    );
  }

  pw.Widget _buildTabelaGeral(List<Animal> animais) {
    return pw.TableHelper.fromTextArray(
      border: null,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
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