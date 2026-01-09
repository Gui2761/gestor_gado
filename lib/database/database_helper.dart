import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart'; // Importante para o ZIP
import '../database/database_helper.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isLoading = false;

  // --- FAZER BACKUP (ZIP = BANCO + FOTOS) ---
  Future<void> _fazerBackup() async {
    setState(() => _isLoading = true);
    try {
      // 1. Caminhos
      final dbPath = await DatabaseHelper.instance.getDbPath();
      final appDir = await getApplicationDocumentsDirectory();
      
      // 2. Cria o codificador ZIP
      var encoder = ZipFileEncoder();
      final tempDir = await getTemporaryDirectory();
      final zipPath = p.join(tempDir.path, "backup_fazenda_${DateTime.now().day}_${DateTime.now().month}.zip");
      
      encoder.create(zipPath);

      // 3. Adiciona o Banco de Dados no ZIP
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        encoder.addFile(dbFile);
      }

      // 4. Adiciona TODAS as fotos (.jpg) no ZIP
      // Procura arquivos na pasta do app
      final arquivos = appDir.listSync();
      int fotosContadas = 0;
      for (var arquivo in arquivos) {
        if (arquivo is File && arquivo.path.endsWith('.jpg')) {
          encoder.addFile(arquivo);
          fotosContadas++;
        }
      }

      encoder.close();

      // 5. Compartilha o ZIP
      await Share.shareXFiles(
        [XFile(zipPath)], 
        text: 'Backup Completo (Dados + $fotosContadas fotos)'
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro no backup: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- RESTAURAR BACKUP (DESCOMPACTAR ZIP) ---
  Future<void> _restaurarBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'], // Só aceita ZIP
      );

      if (result != null) {
        final confirmou = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Restaurar Backup?"),
            content: const Text(
              "Isso vai SUBSTITUIR todos os dados atuais pelos do arquivo.\nTem certeza?",
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true), 
                child: const Text("SIM", style: TextStyle(color: Colors.red))
              ),
            ],
          ),
        );

        if (confirmou == true) {
          setState(() => _isLoading = true);
          
          // 1. Fecha o banco atual para não corromper
          await DatabaseHelper.instance.closeAndReset();

          // 2. Prepara diretórios
          final File zipFile = File(result.files.single.path!);
          final appDir = await getApplicationDocumentsDirectory();
          final dbPath = await DatabaseHelper.instance.getDbPath();

          // 3. Lê o ZIP
          final bytes = await zipFile.readAsBytes();
          final archive = ZipDecoder().decodeBytes(bytes);

          // 4. Extrai arquivo por arquivo
          for (final file in archive) {
            if (file.isFile) {
              final data = file.content as List<int>;
              
              if (file.name == 'fazenda.db') {
                // Se for o banco, salva no lugar certo
                File(dbPath)
                  ..createSync(recursive: true)
                  ..writeAsBytesSync(data);
              } else if (file.name.endsWith('.jpg')) {
                // Se for foto, salva na pasta do app
                final fotoPath = p.join(appDir.path, file.name);
                File(fotoPath)
                  ..createSync(recursive: true)
                  ..writeAsBytesSync(data);
              }
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Backup restaurado com sucesso!"), backgroundColor: Colors.green),
            );
            Navigator.pop(context, true); 
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao restaurar: $e"), backgroundColor: Colors.red),
        );
      }
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
                const Icon(Icons.folder_zip, size: 80, color: Colors.green),
                const SizedBox(height: 20),
                const Text(
                  "Backup com Fotos",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "O sistema agora gera um arquivo .ZIP contendo todos os dados e as fotos dos animais.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),

                ElevatedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text("GERAR ARQUIVO DE BACKUP (ZIP)"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(15)
                  ),
                  onPressed: _fazerBackup,
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text("RESTAURAR ARQUIVO (ZIP)"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(15)
                  ),
                  onPressed: _restaurarBackup,
                ),
              ],
            ),
          ),
    );
  }
}