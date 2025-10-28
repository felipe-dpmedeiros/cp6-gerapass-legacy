import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterfirebaseapp/routes.dart';

import 'package:lottie/lottie.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    const azul = Color(0xFF039BE5);
    const Cortexto = Color.fromARGB(200, 4, 87, 117);

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
            icon: const Icon(Icons.logout),
            tooltip: "Sair",
            onPressed: _signOut,
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  const Expanded(child: SizedBox()),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 16, color: Cortexto,),
                      const SizedBox(width: 6),
                      Text(
                        user?.email ?? 'Usuário',
                        style: const TextStyle(fontSize: 14, color: Cortexto),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Image.asset("../../assets/images/getPremium.png"),
            const SizedBox(height: 8),
            Expanded(
              child: SenhasList()
            )
          ]
          
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: azul,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.pushNamed(context, Routes.password),
        child: const Icon(Icons.add),
      ),
    );
  }
}


// Lista de senhas
class SenhasList extends StatefulWidget {
  const SenhasList({super.key});

  @override
  State<SenhasList> createState() => _SenhasListState();
}

class _SenhasListState extends State<SenhasList> {
  final CollectionReference passwords = FirebaseFirestore.instance.collection(
    'passwords',
  );

  final Map<String, bool> _showMap = {};

  @override
  Widget build(BuildContext context) {
    const textColor = Color.fromARGB(200, 4, 87, 117);

    return StreamBuilder<QuerySnapshot>(
      stream: passwords.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erro ao carregar senhas: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 180,
                    child: Lottie.asset(
                      '../../../assets/lottie/password.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Nenhum registro encontrado',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Adicione uma senha para começar!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final id = doc.id;
            final label = (doc['label'] ?? '').toString();
            final password = (doc['password'] ?? '').toString();

            _showMap.putIfAbsent(id, () => false);
            final isShown = _showMap[id] == true;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                leading: IconButton(
                  icon: Icon(isShown ? Icons.visibility : Icons.visibility_off),
                  tooltip: isShown ? 'Ocultar senha' : 'Mostrar senha',
                  onPressed: () => setState(() => _showMap[id] = !isShown),
                ),
                title: Text(label.isNotEmpty ? label : 'Sem rótulo'),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          isShown ? password : _mask(password),
                          style: const TextStyle(letterSpacing: 2.0),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.redAccent,
                        ),
                        tooltip: 'Excluir senha',
                        onPressed: () => _delete(doc),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _mask(String value) {
    if (value.isEmpty) return '•••••••';
    return List.filled(value.length, '•').join();
  }

  Future<void> _delete(DocumentSnapshot doc) async {
    try {
      await passwords.doc(doc.id).delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Senha excluída')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Falha ao excluir: $e')));
    }
  }
}
