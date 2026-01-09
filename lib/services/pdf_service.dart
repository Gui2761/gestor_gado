import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/animal.dart';
import '../models/manejo.dart';

class PdfService {

  // --- 1. RELATÓRIO GERAL ---
  Future<void> gerarRelatorioGeral(List<Animal> animais) async {
    final pdf = pw.Document();
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

  // --- 2. RELATÓRIO GTA ---
  Future<void> gerarRelatorioGTA(List<Animal> animais) async {
    final pdf = pw.Document();
    final dadosGTA = _calcularFaixasEtarias(animais);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          _buildHeader("Auxiliar para GTA", cor: PdfColors.blue800),
          pw.SizedBox(height: 20),
          pw.Text("1. Contagem por Faixa Etária e Sexo", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          _buildTabelaFaixaEtaria(dadosGTA),
          pw.SizedBox(height: 20),
          pw.Text("2. Animais (Anexo)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          _buildTabelaDetalhadaGTA(animais),
        ],
      ),
    );
    await _abrirPDF(pdf, "auxiliar_gta");
  }

  // --- 3. FICHA INDIVIDUAL (COM REMÉDIOS) ---
  Future<void> gerarFichaAnimal(Animal animal, List<Manejo> historico) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader("Ficha Individual do Animal", cor: PdfColors.teal800),
              pw.SizedBox(height: 20),
              
              // DADOS DO ANIMAL
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Se tivesse foto, seria complexo por aqui, vamos focar nos dados
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _itemFicha("Brinco:", animal.brinco, destaque: true),
                          _itemFicha("Nome:", animal.nome ?? '-'),
                          _itemFicha("Raça:", animal.raca),
                          _itemFicha("Sexo:", animal.sexo),
                        ]
                      )
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _itemFicha("Peso:", "${animal.peso} kg"),
                          _itemFicha("Status:", animal.status),
                          _itemFicha("Nascimento:", _formatarData(animal.dataNascimento)),
                        ]
                      )
                    ),
                  ]
                )
              ),

              pw.SizedBox(height: 30),
              pw.Text("Histórico Sanitário (Vacinas e Medicamentos)", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
              pw.Divider(color: PdfColors.teal),
              pw.SizedBox(height: 10),

              // TABELA DE REMÉDIOS
              if (historico.isEmpty)
                pw.Text("Nenhum registro encontrado.", style: const pw.TextStyle(color: PdfColors.grey))
              else
                pw.TableHelper.fromTextArray(
                  headers: ['Data', 'Tipo', 'Produto', 'Observação'],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.teal600),
                  rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                  cellPadding: const pw.EdgeInsets.all(8),
                  data: historico.map((m) {
                    return [
                      _formatarData(m.data),
                      m.categoria,
                      m.nome,
                      m.observacao ?? ''
                    ];
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );

    await _abrirPDF(pdf, "ficha_animal_${animal.brinco}");
  }

  pw.Widget _itemFicha(String label, String value, {bool destaque = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: "$label ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: destaque ? 18 : 12)),
            pw.TextSpan(text: value, style: pw.TextStyle(fontSize: destaque ? 18 : 12)),
          ]
        )
      )
    );
  }

  String _formatarData(String dataIso) {
    try {
      final d = DateTime.parse(dataIso);
      return "${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}";
    } catch (e) {
      return dataIso;
    }
  }

  // --- MÉTODOS AUXILIARES ---
  Map<String, Map<String, int>> _calcularFaixasEtarias(List<Animal> animais) {
    // (Código igual ao anterior)
     final map = {
      '0 a 12 meses': {'M': 0, 'F': 0},
      '13 a 24 meses': {'M': 0, 'F': 0},
      '25 a 36 meses': {'M': 0, 'F': 0},
      'Acima de 36 meses': {'M': 0, 'F': 0},
    };
    final hoje = DateTime.now();
    for (var boi in animais) {
      int meses = 0;
      try {
        if (boi.dataNascimento.isNotEmpty) {
           final nasc = DateTime.parse(boi.dataNascimento);
           meses = (hoje.difference(nasc).inDays / 30).floor();
        } else { meses = 37; }
      } catch (_) { meses = 37; }

      String faixa = 'Acima de 36 meses';
      if (meses <= 12) faixa = '0 a 12 meses';
      else if (meses <= 24) faixa = '13 a 24 meses';
      else if (meses <= 36) faixa = '25 a 36 meses';

      String sexo = (boi.sexo.toUpperCase().startsWith('M')) ? 'M' : 'F';
      map[faixa]![sexo] = (map[faixa]![sexo] ?? 0) + 1;
    }
    return map;
  }

  pw.Widget _buildHeader(String titulo, {PdfColor cor = PdfColors.green700}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: cor, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(titulo, style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text("${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}", style: const pw.TextStyle(color: PdfColors.white)),
        ],
      ),
    );
  }

  pw.Widget _buildTabelaGeral(List<Animal> animais) {
    return pw.TableHelper.fromTextArray(
      border: null,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      headers: <String>['Brinco', 'Nome/Raça', 'Sexo', 'Peso', 'Status'],
      data: animais.map((animal) => [animal.brinco, "${animal.nome ?? ''}\n${animal.raca}", animal.sexo, "${animal.peso} kg", animal.status]).toList(),
    );
  }

  pw.Widget _buildTabelaFaixaEtaria(Map<String, Map<String, int>> dados) {
    return pw.TableHelper.fromTextArray(
      headers: ['Faixa Etária', 'Machos', 'Fêmeas', 'Total'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700),
      data: dados.entries.map((entry) => [entry.key, entry.value['M']!, entry.value['F']!, (entry.value['M']! + entry.value['F']!)]).toList(),
    );
  }

  pw.Widget _buildTabelaDetalhadaGTA(List<Animal> animais) {
     return pw.TableHelper.fromTextArray(
      headers: ['Brinco', 'Raça', 'Idade Est.'],
      data: animais.map((a) => [a.brinco, a.raca, _formatarData(a.dataNascimento)]).toList(),
    );
  }

  pw.Widget _buildRodape(List<Animal> animais) {
    double pesoTotal = animais.fold(0, (sum, item) => sum + item.peso);
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [pw.Text("Total: ${animais.length} animais | Peso: $pesoTotal kg", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))],
      ),
    );
  }

  Future<void> _abrirPDF(pw.Document pdf, String nomeArquivo) async {
    await Printing.sharePdf(bytes: await pdf.save(), filename: '$nomeArquivo.pdf');
  }
}