import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // Para formatar a data
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../database/database_helper.dart';
import '../models/animal.dart';
import '../models/transacao.dart';

class CadastroAnimalScreen extends StatefulWidget {
  final Animal? animalParaEditar;

  const CadastroAnimalScreen({super.key, this.animalParaEditar});

  @override
  State<CadastroAnimalScreen> createState() => _CadastroAnimalScreenState();
}

class _CadastroAnimalScreenState extends State<CadastroAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  late TextEditingController _brincoController;
  late TextEditingController _nomeController;
  late TextEditingController _racaController;
  late TextEditingController _pesoController;
  final _valorVendaController = TextEditingController(); // Controlador da Venda

  // Variáveis de Estado
  String _statusSelecionado = 'Ativo';
  String _sexoSelecionado = 'Macho';
  File? _imagemSelecionada;
  DateTime _dataNascimento = DateTime.now(); // Variável da Data (GTA)

  @override
  void initState() {
    super.initState();
    _brincoController = TextEditingController();
    _nomeController = TextEditingController();
    _racaController = TextEditingController();
    _pesoController = TextEditingController();

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

      // Carrega a Data de Nascimento salva
      try {
        if (a.dataNascimento.isNotEmpty) {
          _dataNascimento = DateTime.parse(a.dataNascimento);
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _brincoController.dispose();
    _nomeController.dispose();
    _racaController.dispose();
    _pesoController.dispose();
    _valorVendaController.dispose();
    super.dispose();
  }

  // --- FUNÇÃO DE FOTO ---
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
                onTap: () {
                  Navigator.pop(context);
                  _pegarImagem(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _pegarImagem(ImageSource.gallery);
                },
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

      setState(() {
        _imagemSelecionada = savedImage;
      });
    }
  }

  // --- FUNÇÃO DE DATA (GTA) ---
  Future<void> _selecionarData() async {
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataNascimento,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );

    if (dataEscolhida != null && dataEscolhida != _dataNascimento) {
      setState(() {
        _dataNascimento = dataEscolhida;
      });
    }
  }

  // --- SALVAR TUDO ---
  Future<void> _salvarAnimal() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Validação da Venda
        if (_statusSelecionado == 'Vendido' && _valorVendaController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Informe o VALOR DA VENDA!"), backgroundColor: Colors.orange),
          );
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
          dataNascimento: _dataNascimento.toString(), // Salva a data do calendário
          fotoPath: _imagemSelecionada?.path,
        );

        if (widget.animalParaEditar == null) {
          await DatabaseHelper.instance.insertAnimal(animalEditado.toMap());
        } else {
          await DatabaseHelper.instance.updateAnimal(animalEditado.toMap());
        }

        // --- LÓGICA DE VENDA (FINANCEIRO) ---
        bool eraVendidoAntes = widget.animalParaEditar?.status == 'Vendido';
        
        if (_statusSelecionado == 'Vendido' && !eraVendidoAntes) {
          final valorVenda = double.parse(_valorVendaController.text.replaceAll(',', '.'));
          
          final novaVenda = Transacao(
            tipo: 'VENDA',
            descricao: "Venda Boi ${_brincoController.text} (${_racaController.text})",
            valor: valorVenda,
            data: DateTime.now().toString(),
          );

          await DatabaseHelper.instance.insertTransacao(novaVenda.toMap());
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Venda registrada no financeiro!"), backgroundColor: Colors.green));
          }
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // FOTO
              GestureDetector(
                onTap: _mostrarOpcoesFoto,
                child: Container(
                  height: 150, width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                    image: (_imagemSelecionada != null && _imagemSelecionada!.existsSync())
                      ? DecorationImage(image: FileImage(_imagemSelecionada!), fit: BoxFit.cover)
                      : null
                  ),
                  child: _imagemSelecionada == null ? const Icon(Icons.add_a_photo, size: 50, color: Colors.grey) : null,
                ),
              ),
              const SizedBox(height: 10),
              const Text("Toque para foto", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),

              // CAMPOS PRINCIPAIS
              TextFormField(
                controller: _brincoController,
                decoration: const InputDecoration(labelText: "Nº Brinco *", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? "Obrigatório" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: "Nome/Apelido", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _racaController,
                      decoration: const InputDecoration(labelText: "Raça *", border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? "Obrigatório" : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _pesoController,
                      decoration: const InputDecoration(labelText: "Peso (kg) *", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? "Obrigatório" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // DATA DE NASCIMENTO (NOVO PARA GTA)
              InkWell(
                onTap: _selecionarData,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Nascimento (Para GTA)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today, color: Colors.green),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd/MM/yyyy').format(_dataNascimento), style: const TextStyle(fontSize: 16)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
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

              // CAMPO FINANCEIRO (Venda)
              if (_statusSelecionado == 'Vendido') ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.green[50], border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      const Row(children: [Icon(Icons.attach_money, color: Colors.green), SizedBox(width: 10), Text("Valor da Venda", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _valorVendaController,
                        decoration: const InputDecoration(labelText: "Valor (R\$)", border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  onPressed: _salvarAnimal,
                  icon: const Icon(Icons.save),
                  label: Text(widget.animalParaEditar == null ? "CADASTRAR" : "SALVAR ALTERAÇÕES"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}