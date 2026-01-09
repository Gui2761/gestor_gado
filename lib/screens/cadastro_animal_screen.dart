import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../database/database_helper.dart';
import '../models/animal.dart';
import '../models/transacao.dart';
import 'historico_saude_screen.dart';

class CadastroAnimalScreen extends StatefulWidget {
  final Animal? animalParaEditar;

  const CadastroAnimalScreen({super.key, this.animalParaEditar});

  @override
  State<CadastroAnimalScreen> createState() => _CadastroAnimalScreenState();
}

class _CadastroAnimalScreenState extends State<CadastroAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _brincoController;
  late TextEditingController _nomeController;
  late TextEditingController _racaController;
  late TextEditingController _pesoController;
  final _valorVendaController = TextEditingController();
  final _dataNascimentoController = TextEditingController();

  String _statusSelecionado = 'Ativo';
  String _sexoSelecionado = 'Macho';
  File? _imagemSelecionada;
  DateTime _dataNascimento = DateTime.now();

  @override
  void initState() {
    super.initState();
    _brincoController = TextEditingController();
    _nomeController = TextEditingController();
    _racaController = TextEditingController();
    _pesoController = TextEditingController();
    
    _dataNascimentoController.text = DateFormat('dd/MM/yyyy').format(_dataNascimento);

    if (widget.animalParaEditar != null) {
      final a = widget.animalParaEditar!;
      _brincoController.text = a.brinco;
      _nomeController.text = a.nome ?? '';
      _racaController.text = a.raca;
      _pesoController.text = a.peso.toString();
      _statusSelecionado = a.status;
      _sexoSelecionado = a.sexo;
      
      if (a.fotoPath != null) {
        _imagemSelecionada = File(a.fotoPath!);
      }

      try {
        if (a.dataNascimento.isNotEmpty) {
          _dataNascimento = DateTime.parse(a.dataNascimento);
          _dataNascimentoController.text = DateFormat('dd/MM/yyyy').format(_dataNascimento);
        }
      } catch (_) {}

      if (a.status == 'Vendido') {
        _carregarValorVenda(a.id!);
      }
    }
  }

  Future<void> _carregarValorVenda(int animalId) async {
    final venda = await DatabaseHelper.instance.getVendaPorAnimal(animalId);
    if (venda != null) {
      setState(() {
        _valorVendaController.text = venda['valor'].toString();
      });
    }
  }

  @override
  void dispose() {
    _brincoController.dispose();
    _nomeController.dispose();
    _racaController.dispose();
    _pesoController.dispose();
    _valorVendaController.dispose();
    _dataNascimentoController.dispose();
    super.dispose();
  }

  void _mostrarOpcoesFoto() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tirar Foto (Câmera)'),
                onTap: () { Navigator.pop(context); _pegarImagem(ImageSource.camera); },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da Galeria'),
                onTap: () { Navigator.pop(context); _pegarImagem(ImageSource.gallery); },
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> _pegarImagem(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);

    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String localPath = path.join(directory.path, fileName);
      final File imageFile = File(pickedFile.path);
      final File savedImage = await imageFile.copy(localPath);
      setState(() { _imagemSelecionada = savedImage; });
    }
  }

  // --- CALENDÁRIO PRETO ---
  Future<void> _selecionarData() async {
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataNascimento,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        // TEMA ESCURO FORÇADO
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.green, // Cabeçalho Verde
              onPrimary: Colors.white,
              surface: Colors.grey[900]!, // Fundo Preto/Cinza
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[900],
          ),
          child: child!,
        );
      },
    );

    if (dataEscolhida != null) {
      setState(() {
        _dataNascimento = dataEscolhida;
        _dataNascimentoController.text = DateFormat('dd/MM/yyyy').format(dataEscolhida);
      });
    }
  }

  Future<void> _salvarAnimal() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (_statusSelecionado == 'Vendido' && _valorVendaController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Informe o VALOR DA VENDA!"), backgroundColor: Colors.orange));
          return;
        }

        final animalEditado = Animal(
          id: widget.animalParaEditar?.id,
          brinco: _brincoController.text,
          nome: _nomeController.text,
          raca: _racaController.text,
          sexo: _sexoSelecionado,
          peso: double.parse(_pesoController.text.replaceAll(',', '.')),
          status: _statusSelecionado,
          dataNascimento: _dataNascimento.toString(),
          fotoPath: _imagemSelecionada?.path,
        );

        int animalId;
        if (widget.animalParaEditar == null) {
          animalId = await DatabaseHelper.instance.insertAnimal(animalEditado.toMap());
        } else {
          animalId = widget.animalParaEditar!.id!;
          await DatabaseHelper.instance.updateAnimal(animalEditado.toMap());
        }

        bool eraVendidoAntes = widget.animalParaEditar?.status == 'Vendido';
        bool agoraEstaVendido = _statusSelecionado == 'Vendido';

        if (agoraEstaVendido) {
          final valorVenda = double.parse(_valorVendaController.text.replaceAll(',', '.'));
          
          if (!eraVendidoAntes) {
            final novaVenda = Transacao(
              tipo: 'VENDA',
              descricao: "Venda Boi ${_brincoController.text} (${_racaController.text})",
              valor: valorVenda,
              data: DateTime.now().toString(),
              animalId: animalId,
            );
            await DatabaseHelper.instance.insertTransacao(novaVenda.toMap());
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Venda registrada!"), backgroundColor: Colors.green));
          
          } else {
            await DatabaseHelper.instance.updateValorVenda(animalId, valorVenda);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Valor atualizado!"), backgroundColor: Colors.blue));
          }
        } 
        else if (eraVendidoAntes && !agoraEstaVendido) {
          await DatabaseHelper.instance.deleteVendaPorAnimal(animalId);
        }

        if (mounted) Navigator.pop(context, true);

      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.animalParaEditar == null ? "Novo Animal" : "Editar Animal")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _mostrarOpcoesFoto,
                child: Container(
                  height: 150, width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[300], borderRadius: BorderRadius.circular(75),
                    image: (_imagemSelecionada != null && _imagemSelecionada!.existsSync()) ? DecorationImage(image: FileImage(_imagemSelecionada!), fit: BoxFit.cover) : null
                  ),
                  child: _imagemSelecionada == null ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey) : null,
                ),
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _brincoController,
                decoration: const InputDecoration(labelText: "Nº Brinco *", border: OutlineInputBorder(), prefixIcon: Icon(Icons.tag)),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next, 
                validator: (val) => val!.isEmpty ? "Obrigatório" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _nomeController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: "Nome/Apelido", border: OutlineInputBorder(), prefixIcon: Icon(Icons.edit)),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _racaController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: "Raça *", border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? "Obrigatório" : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _pesoController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: "Peso (kg) *", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? "Obrigatório" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // CAMPO DATA BONITO
              TextFormField(
                controller: _dataNascimentoController,
                readOnly: true, 
                onTap: _selecionarData,
                decoration: const InputDecoration(
                  labelText: "Nascimento (Para GTA)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today, color: Colors.green),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
              ),
              
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _sexoSelecionado,
                      decoration: const InputDecoration(labelText: "Sexo", border: OutlineInputBorder()),
                      items: ['Macho', 'Fêmea'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) => setState(() => _sexoSelecionado = val!),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _statusSelecionado,
                      decoration: const InputDecoration(labelText: "Status", border: OutlineInputBorder()),
                      items: ['Ativo', 'Vendido', 'Morto', 'Doente'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) => setState(() => _statusSelecionado = val!),
                    ),
                  ),
                ],
              ),

              if (_statusSelecionado == 'Vendido') ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: _valorVendaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: InputDecoration(
                    labelText: "Valor da Venda (R\$)",
                    prefixIcon: const Icon(Icons.monetization_on, color: Colors.green),
                    filled: true,
                    fillColor: Colors.green.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green, width: 2)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 5, left: 10),
                  child: Text("Alterando este valor, o Financeiro atualiza automaticamente.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],

              const SizedBox(height: 30),

              if (widget.animalParaEditar != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => HistoricoSaudeScreen(animal: widget.animalParaEditar!)));
                    },
                    icon: const Icon(Icons.health_and_safety, color: Colors.teal),
                    label: const Text("ABRIR PRONTUÁRIO VETERINÁRIO", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 15),
              ],

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  onPressed: _salvarAnimal,
                  icon: const Icon(Icons.save),
                  label: Text(widget.animalParaEditar == null ? "CADASTRAR" : "SALVAR ALTERAÇÕES"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ),
              
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 80),
            ],
          ),
        ),
      ),
    );
  }
}