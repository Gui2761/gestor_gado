import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/animal.dart';

class PdfService {
  
  // Função principal que gera e abre o PDF
  Future<void> gerarRelatorioGado(List<Animal> animais) async {
    final pdf = pw.Document();

    // Cria a página do PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        // Margens do papel
        margin: const pw.EdgeInsets.all(20),
        
        build: (pw.Context context) {
          return [
            _buildHeader(),
            pw.SizedBox(height: 20),
            _buildTabela(animais),
            pw.SizedBox(height: 20),
            _buildRodape(animais),
          ];
        },
      ),
    );

    // Abre a pré-visualização e menu de compartilhamento do Android
    await Printing.sharePdf(
        bytes: await pdf.save(), 
        filename: 'relatorio_gado_${DateTime.now().day}_${DateTime.now().month}.pdf'
    );
  }

  // Cabeçalho
  pw.Widget _buildHeader() {
    return pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text("Relatório de Rebanho", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text("Data: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}"),
        ],
      ),
    );
  }

  // Tabela de Dados
  pw.Widget _buildTabela(List<Animal> animais) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headers: <String>['Brinco', 'Nome', 'Raça', 'Peso (kg)', 'Status'],
      cellAlignment: pw.Alignment.centerLeft,
      data: animais.map((animal) {
        return [
          animal.brinco,
          animal.nome ?? '-',
          animal.raca,
          animal.peso.toStringAsFixed(1),
          animal.status,
        ];
      }).toList(),
    );
  }

  // Rodapé com totais
  pw.Widget _buildRodape(List<Animal> animais) {
    // Calculando peso total só para mostrar que dá pra fazer contas no PDF
    double pesoTotal = animais.fold(0, (sum, item) => sum + item.peso);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          "Total de Animais: ${animais.length}  |  Peso Total: ${pesoTotal.toStringAsFixed(1)} kg",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)
        ),
      ],
    );
  }
}