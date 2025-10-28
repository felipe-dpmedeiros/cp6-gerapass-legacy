import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> with SingleTickerProviderStateMixin {
  double _length = 12;
  bool _includeLower = true;
  bool _includeUpper = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;

  String? _generatedPassword;
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
  }


  /// public PasswordWolf API: https://passwordwolf.com/
  Future<void> _generatePassword() async {
    setState(() => _isLoading = true);
    try {
      final params = {
        'length': _length.toInt().toString(),
        'lower': _includeLower ? 'on' : 'off',
        'upper': _includeUpper ? 'on' : 'off',
        'numbers': _includeNumbers ? 'on' : 'off',
        'special': _includeSymbols ? 'on' : 'off',
      };
      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final rawUrl = 'https://passwordwolf.com/api/?$query';

      Uri uri;
      if (kIsWeb) {
        final proxy = 'https://api.allorigins.win/raw?url=';
        uri = Uri.parse('$proxy${Uri.encodeComponent(rawUrl)}');
      } else {
        uri = Uri.parse(rawUrl);
      }

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        String pwd;
        if (decoded is List && decoded.isNotEmpty) {
          pwd = decoded[0]['password']?.toString() ?? '';
        } else if (decoded is Map && decoded.containsKey('password')) {
          pwd = decoded['password'].toString();
        } else {
          pwd = response.body.toString();
        }

        if (pwd.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('API retornou senha vazia')),
          );
        } else {
          setState(() => _generatedPassword = pwd.trim());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Senha gerada com sucesso')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar senha: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('API indisponível: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePassword() async {
    if (_generatedPassword == null || _generatedPassword!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gere uma senha antes de salvar')),
      );
      return;
    }

    final labelController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Salvar senha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Digite um rótulo para esta senha:'),
              const SizedBox(height: 8),
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Email pessoal',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final label = labelController.text.isEmpty
        ? 'Sem rótulo (${DateTime.now().toIso8601String()})'
        : labelController.text;

    try {
      await FirebaseFirestore.instance.collection('passwords').add({
        'label': label,
        'password': _generatedPassword,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha salva no Cloud Firestore')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Falha ao salvar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF039BE5);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: azul,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 22),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.lock_rounded, size: 22),
            SizedBox(width: 8),
            Text("Gerador de Senhas"),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Informações do app',
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'Gerador de Senhas',
              applicationVersion: '1.0.0',
              children: const [
                Text('Gera senhas via PasswordWolf API e salva no Firestore'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: azul,
        foregroundColor: Colors.white,
        onPressed: _savePassword,
        tooltip: 'Salvar senha gerada',
        child: const Icon(Icons.save),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: PasswordResultWidget(
                password: _generatedPassword ?? 'Senha não informada',
                onCopy: () async {
                  if (_generatedPassword == null ||
                      _generatedPassword!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nada para copiar')),
                    );
                    return;
                  }
                  final pwd = _generatedPassword!;
                  await Clipboard.setData(ClipboardData(text: pwd));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Senha copiada para a área de transferência',
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tamanho da senha:'),
                          Text('${_length.toInt()}'),
                        ],
                      ),
                      Slider(
                        min: 4,
                        max: 32,
                        divisions: 28,
                        value: _length,
                        activeColor: azul,
                        thumbColor: azul,
                        onChanged: (v) => setState(() => _length = v),
                      ),

                      // switches
                      SwitchListTile(
                        title: const Text('Incluir letras minúsculas'),
                        value: _includeLower,
                        activeTrackColor: azul,
                        onChanged: (v) => setState(() => _includeLower = v),
                      ),
                      SwitchListTile(
                        title: const Text('Incluir letras maiúsculas'),
                        value: _includeUpper,
                        activeTrackColor: azul,
                        onChanged: (v) => setState(() => _includeUpper = v),
                      ),
                      SwitchListTile(
                        title: const Text('Incluir números'),
                        value: _includeNumbers,
                        activeTrackColor: azul,
                        onChanged: (v) => setState(() => _includeNumbers = v),
                      ),
                      SwitchListTile(
                        title: const Text('Incluir símbolos'),
                        value: _includeSymbols,
                        activeTrackColor: azul,
                        onChanged: (v) => setState(() => _includeSymbols = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Generate button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generatePassword,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Gerar Senha',
                          style: TextStyle(color: azul),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class PasswordResultWidget extends StatelessWidget {
  final String password;
  final Future<void> Function()? onCopy;

  const PasswordResultWidget({super.key, required this.password, this.onCopy});

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF039BE5);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              password,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            onPressed: onCopy,
            color: azul,
            tooltip: 'Copiar',
          ),
        ],
      ),
    );
  }
}
