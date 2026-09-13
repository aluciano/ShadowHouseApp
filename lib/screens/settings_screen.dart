import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../repositories/local_app_settings_store.dart';
import '../widgets/shadow_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final settingsStore = createLocalAppSettingsStore();
  final playerNameController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  @override
  void dispose() {
    playerNameController.dispose();
    super.dispose();
  }

  Future<void> loadSettings() async {
    final settings = await settingsStore.load();

    if (!mounted) {
      return;
    }

    playerNameController.text = settings.playerName;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveSettings() async {
    final playerName = playerNameController.text.trim();

    if (playerName.isEmpty) {
      showMessage('Informe um nome para salvar.');
      return;
    }

    setState(() {
      isSaving = true;
    });

    await settingsStore.save(AppSettings(playerName: playerName));

    if (!mounted) {
      return;
    }

    setState(() {
      isSaving = false;
    });

    showMessage('Configurações salvas.');
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            children: [
              const Text(
                'Configurações',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Preferências salvas neste aparelho.',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              Card(
                color: const Color(0xFF221229),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Jogador',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE7C76F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: playerNameController,
                        enabled: !isLoading && !isSaving,
                        textCapitalization: TextCapitalization.words,
                        keyboardType: TextInputType.name,
                        decoration: const InputDecoration(
                          labelText: 'Nome padrão',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: isLoading || isSaving ? null : saveSettings,
                        icon: isSaving
                            ? const SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Salvar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
