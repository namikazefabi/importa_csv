import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

void main() {
  runApp(const ImportaCsvApp());
}

class Boleto {
  final String nome;
  final DateTime data;
  final double valor;

  Boleto({required this.nome, required this.data, required this.valor});

  List<String> toCsvRow() {
    final valorFormatado = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(valor);
    return [nome, data.toIso8601String(), valorFormatado];
  }
}

class ImportaCsvApp extends StatelessWidget {
  const ImportaCsvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Importa CSV de Boletos',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const ImportaCsvPage(),
    );
  }
}

class ImportaCsvPage extends StatefulWidget {
  const ImportaCsvPage({super.key});

  @override
  State<ImportaCsvPage> createState() => _ImportaCsvPageState();
}

class _ImportaCsvPageState extends State<ImportaCsvPage> {
  String? nomeArquivo;
  List<Boleto> boletos = [];
  bool carregando = false;
  String? conteudoArquivo;

  Future<void> _importarCsv() async {
    setState(() => carregando = true);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final conteudo = await file.readAsString();
      final linhas = conteudo.split('\n');
      List<Boleto> lista = [];
      for (var linha in linhas.skip(1)) {
        // Pula o cabeçalho
        if (linha.trim().isEmpty) continue;
        final partes = linha.split(',');
        if (partes.length < 3) continue;
        try {
          final nome = partes[0];
          final data = DateTime.parse(partes[1]);
          final valor = double.parse(
            partes[2]
                .replaceAll('R\$', '')
                .replaceAll('.', '')
                .replaceAll(',', '.'),
          );
          lista.add(Boleto(nome: nome, data: data, valor: valor));
        } catch (_) {}
      }
      setState(() {
        nomeArquivo = result.files.single.name;
        boletos = lista;
        conteudoArquivo = conteudo;
      });
    }
    setState(() => carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar Boletos CSV'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Importar arquivo CSV'),
              onPressed: carregando ? null : _importarCsv,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 24),
            if (carregando) const Center(child: CircularProgressIndicator()),
            if (nomeArquivo != null)
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Conteúdo de $nomeArquivo'),
                      content: SingleChildScrollView(
                        child: Text(conteudoArquivo ?? ''),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Fechar'),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  'Arquivo importado: $nomeArquivo',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                    color: Colors.blue,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (boletos.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: boletos.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final b = boletos[index];
                    return ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: Text(b.nome),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(b.data)),
                      trailing: Text(
                        NumberFormat.currency(
                          locale: 'pt_BR',
                          symbol: 'R\$',
                        ).format(b.valor),
                      ),
                    );
                  },
                ),
              ),
            if (conteudoArquivo != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Conteúdo bruto do arquivo:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey.shade200,
                      child: Text(
                        conteudoArquivo ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (nomeArquivo == null && !carregando)
              const Text(
                'Nenhum arquivo importado ainda.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
