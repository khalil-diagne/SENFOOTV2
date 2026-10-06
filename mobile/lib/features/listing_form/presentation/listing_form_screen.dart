import 'package:efoot_market/features/auth/application/auth_controller.dart';
import 'package:efoot_market/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ListingFormScreen extends ConsumerStatefulWidget {
  const ListingFormScreen({super.key});

  @override
  ConsumerState<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends ConsumerState<ListingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _powerController = TextEditingController();
  final _levelController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _platform = 'mobile';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _powerController.dispose();
    _levelController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = ref.read(authControllerProvider);
    if (auth.user == null || !auth.user!.isSeller) {
      setState(() => _error = 'Seuls les comptes vendeur peuvent publier une annonce.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final imageUrl = _imageUrlController.text.trim();
      final listing = await ref.read(listingsRepositoryProvider).createListing(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            priceXof: int.parse(_priceController.text.trim()),
            platform: _platform,
            teamStrength: int.tryParse(_powerController.text.trim()),
            accountLevel: int.tryParse(_levelController.text.trim()),
            imageUrls: imageUrl.isEmpty ? const [] : [imageUrl],
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annonce publiée')),
      );
      context.go('/listings/${listing.id}');
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vendre un compte')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (auth.user != null && !auth.user!.isSeller) ...[
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Votre compte est en rôle acheteur. Passez en rôle vendeur '
                          '(réinscription ou support) pour publier des annonces.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre',
                      hintText: 'Ex. Compte puissance 3200 PS4',
                    ),
                    validator: (v) => (v == null || v.trim().length < 3) ? 'Titre trop court' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Joueurs épics, puissance, plateforme, mode de transfert...',
                    ),
                    validator: (v) => (v == null || v.trim().length < 10)
                        ? 'Description trop courte (min. 10)'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Prix (FCFA)',
                      hintText: 'Ex. 28000',
                    ),
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null || n <= 0) return 'Prix entier positif requis';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _platform,
                    decoration: const InputDecoration(labelText: 'Plateforme'),
                    items: const [
                      DropdownMenuItem(value: 'ps4', child: Text('PS4')),
                      DropdownMenuItem(value: 'ps5', child: Text('PS5')),
                      DropdownMenuItem(value: 'xbox', child: Text('Xbox')),
                      DropdownMenuItem(value: 'mobile', child: Text('Mobile')),
                      DropdownMenuItem(value: 'pc', child: Text('PC')),
                    ],
                    onChanged: (value) => setState(() => _platform = value ?? 'mobile'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _powerController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Puissance'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _levelController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Niveau compte'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL image (optionnel)',
                      hintText: 'https://...',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Publier l\'annonce'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
