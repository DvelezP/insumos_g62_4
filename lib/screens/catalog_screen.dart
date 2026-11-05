import 'package:flutter/material.dart';

import '../models/insumo.dart';
import '../repositories/insumo_repository.dart';
import '../repositories/solicitud_repository.dart';
import '../services/insumo_http_service.dart';
import 'create_request_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({
    super.key,
    required this.repository,
    required this.solicitudRepository,
  });

  final InsumoRepository repository;
  final SolicitudRepository solicitudRepository;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late Future<List<Insumo>> _loadFuture;
  final Map<String, Insumo> _selectedInsumos = {};
  String _searchText = '';
  String _selectedCategory = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadFuture = widget.repository.obtenerInsumos();
  }

  void _loadInsumos() {
    setState(() {
      _loadFuture = widget.repository.obtenerInsumos();
    });
  }

  void _toggleInsumo(Insumo insumo) {
    setState(() {
      if (_selectedInsumos.containsKey(insumo.id)) {
        _selectedInsumos.remove(insumo.id);
      } else if (_selectedInsumos.length < 5) {
        _selectedInsumos[insumo.id] = insumo;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Una solicitud puede tener máximo 5 insumos.'),
          ),
        );
      }
    });
  }

  Future<void> _openRequestForm() async {
    if (_selectedInsumos.isEmpty) return;

    // null: el usuario volvió sin crear la solicitud.
    final sincronizada = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CreateRequestScreen(
          insumos: _selectedInsumos.values.toList(),
          repository: widget.solicitudRepository,
        ),
      ),
    );
    if (sincronizada == null || !mounted) return;

    setState(_selectedInsumos.clear);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sincronizada
              ? 'Solicitud guardada y sincronizada con Firestore.'
              : 'Solicitud guardada en el dispositivo. Queda pendiente de sincronización.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Insumo>>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is InsumoServiceException
                ? (snapshot.error! as InsumoServiceException).message
                : 'Ocurrió un problema al cargar el catálogo.';
            return _ErrorView(message: message, onRetry: _loadInsumos);
          }

          final insumos = snapshot.data ?? const <Insumo>[];
          if (insumos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'El catálogo no tiene insumos disponibles por ahora.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final categories = [
            'Todos',
            ...{for (final item in insumos) item.categoria},
          ];
          final filteredItems = insumos.where((item) {
            final search = _searchText.toLowerCase();
            final matchesText = '${item.nombre} ${item.descripcion}'
                .toLowerCase()
                .contains(search);
            final matchesCategory =
                _selectedCategory == 'Todos' ||
                item.categoria == _selectedCategory;
            return matchesText && matchesCategory;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar insumos',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _searchText = value),
                ),
              ),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ChoiceChip(
                      label: Text(category),
                      selected: category == _selectedCategory,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    );
                  },
                ),
              ),
              Expanded(
                child: filteredItems.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay insumos que coincidan con la búsqueda.',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final insumo = filteredItems[index];
                          final selected = _selectedInsumos.containsKey(
                            insumo.id,
                          );
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.inventory_2_outlined),
                              ),
                              title: Text(insumo.nombre),
                              subtitle: Text(
                                '${insumo.categoria} · ${insumo.unidad}\n${insumo.descripcion}',
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                tooltip: selected
                                    ? 'Quitar de la solicitud'
                                    : 'Agregar a la solicitud',
                                onPressed: () => _toggleInsumo(insumo),
                                icon: Icon(
                                  selected
                                      ? Icons.check_circle
                                      : Icons.add_circle_outline,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedInsumos.isEmpty ? null : _openRequestForm,
        icon: const Icon(Icons.post_add),
        label: Text('Crear solicitud (${_selectedInsumos.length})'),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 56),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
