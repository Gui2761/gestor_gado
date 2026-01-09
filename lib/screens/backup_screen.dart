import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/database_helper.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isLoading = false;

  // --- FUNÇÃO DE EXPORTAR (SALVAR) ---
  Future<void> _fazerBackup() async {
    setState(() => _isLoading = true);
    try {
      // 1. Pega o caminho do banco original
      final dbPath = await DatabaseHelper.instance.getDbPath();
      final File dbFile = File(dbPath);

      // 2. Cria uma cópia temporária
      final tempDir = await getTemporaryDirectory();
      final dataHoje = DateTime.now().toString().split(' ')[0]; // Data YYYY-MM-DD
      final backupPath = p.join(tempDir.path, "fazenda_backup_$dataHoje.db");
      
      await dbFile.copy(backupPath);

      // 3. Compartilha (WhatsApp, Drive, etc)
      await Share.shareXFiles([XFile(backupPath)], text: 'Backup Gestor de Gado ($dataHoje)');

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao criar backup: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- FUNÇÃO DE IMPORTAR (RESTAURAR) ---
  Future<void> _restaurarBackup() async {
    try {
      // 1. Escolher o arquivo
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        final confirmou = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text("Cuidado! ⚠️", style: TextStyle(color: Colors.redAccent)),
            content: const Text(
              "Restaurar um backup vai APAGAR todos os dados atuais do aplicativo e substituir pelos do arquivo.\n\nTem certeza?",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true), 
                child: const Text("SIM, RESTAURAR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))
              ),
            ],
          ),
        );

        if (confirmou == true) {
          setState(() => _isLoading = true);
          
          // 2. Fecha o banco atual
          await DatabaseHelper.instance.closeAndReset();

          // 3. Substitui o arquivo
          final File novoArquivo = File(result.files.single.path!);
          final String dbPath = await DatabaseHelper.instance.getDbPath();
          
          await novoArquivo.copy(dbPath);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Dados restaurados com sucesso!"), backgroundColor: Colors.green),
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Backup & Segurança"),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.green))
        : Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.cloud_sync, size: 80, color: Colors.blueGrey),
                const SizedBox(height: 20),
                const Text(
                  "Proteja seus dados",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Salve seus dados no WhatsApp ou Drive. Se mudar de celular, use Restaurar.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 50),

                _buildButton(
                  icon: Icons.upload,
                  titulo: "Fazer Backup (Salvar)",
                  subtitulo: "Envia seus dados para fora do app",
                  cor: Colors.green[800]!,
                  onTap: _fazerBackup,
                ),

                const SizedBox(height: 20),

                _buildButton(
                  icon: Icons.download,
                  titulo: "Restaurar Dados",
                  subtitulo: "Apaga o atual e carrega um arquivo antigo",
                  cor: Colors.blueGrey[800]!,
                  onTap: _restaurarBackup,
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildButton({
    required IconData icon, required String titulo, required String subtitulo, 
    required Color cor, required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitulo, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white30),
          ],
        ),
      ),
    );
  }
}