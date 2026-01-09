import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart'; 
import '../database/database_helper.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isLoading = false;

  // --- FAZER BACKUP (SEMPRE GERA ZIP AGORA) ---
  Future<void> _fazerBackup() async {
    setState(() => _isLoading = true);
    try {
      final dbPath = await DatabaseHelper.instance.getDbPath();
      final appDir = await getApplicationDocumentsDirectory();
      
      var encoder = ZipFileEncoder();
      final tempDir = await getTemporaryDirectory();
      // Nome do arquivo com data
      final zipPath = p.join(tempDir.path, "backup_fazenda_${DateTime.now().day}_${DateTime.now().month}.zip");
      
      encoder.create(zipPath);

      // Adiciona o banco de dados
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        encoder.addFile(dbFile);
      }

      // Adiciona as fotos
      final arquivos = appDir.listSync();
      int fotosContadas = 0;
      for (var arquivo in arquivos) {
        if (arquivo is File && arquivo.path.endsWith('.jpg')) {
          encoder.addFile(arquivo);
          fotosContadas++;
        }
      }
      encoder.close();

      await Share.shareXFiles([XFile(zipPath)], text: 'Backup Gestor de Gado ($fotosContadas fotos)');

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- RESTAURAR (ACEITA ZIP E DB) ---
  Future<void> _restaurarBackup() async {
    try {
      // 1. Agora permitimos 'zip' (novo) e 'db' (antigo)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, 
        allowedExtensions: ['zip', 'db']
      );

      if (result != null) {
        final confirmou = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Restaurar?"),
            content: const Text("Isso substituirá todos os dados atuais do aplicativo.\nTem certeza?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("SIM", style: TextStyle(color: Colors.red))),
            ],
          ),
        );

        if (confirmou == true) {
          setState(() => _isLoading = true);
          
          // Fecha conexão com o banco para poder substituir o arquivo
          await DatabaseHelper.instance.closeAndReset();

          final File arquivoSelecionado = File(result.files.single.path!);
          final String extensao = p.extension(arquivoSelecionado.path).toLowerCase();
          final dbPath = await DatabaseHelper.instance.getDbPath();
          final appDir = await getApplicationDocumentsDirectory();

          // --- CENÁRIO 1: É UM BACKUP NOVO (.ZIP) ---
          if (extensao == '.zip') {
            final bytes = await arquivoSelecionado.readAsBytes();
            final archive = ZipDecoder().decodeBytes(bytes);

            for (final file in archive) {
              if (file.isFile) {
                final data = file.content as List<int>;
                if (file.name == 'fazenda.db') {
                  File(dbPath)
                    ..createSync(recursive: true)
                    ..writeAsBytesSync(data);
                } else if (file.name.endsWith('.jpg')) {
                  File(p.join(appDir.path, file.name))
                    ..createSync(recursive: true)
                    ..writeAsBytesSync(data);
                }
              }
            }
          } 
          // --- CENÁRIO 2: É UM BACKUP ANTIGO (.DB) ---
          else {
            // Apenas copia o arquivo selecionado para o lugar do banco oficial
            await arquivoSelecionado.copy(dbPath);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Restaurado com sucesso!"), backgroundColor: Colors.green));
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Backup Completo")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.history_edu, size: 80, color: Colors.blueGrey),
                const SizedBox(height: 20),
                const Text("Central de Backup", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text(
                  "Gera um arquivo ZIP com dados e fotos.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save), 
                  label: const Text("CRIAR BACKUP"), 
                  onPressed: _fazerBackup,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.restore), 
                  label: const Text("RESTAURAR"), 
                  onPressed: _restaurarBackup,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
                ),
              ],
            ),
          ),
    );
  }
}