import 'package:flutter/material.dart';

import '../models/solicitud.dart';
import '../repositories/insumo_repository.dart';
import '../repositories/solicitud_repository.dart';
import 'catalog_screen.dart';
import 'create_request_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.solicitudRepository,
  });

  final InsumoRepository repository;
  final SolicitudRepository solicitudRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<String> _titles = [
    'Inicio',
    'Catálogo de insumos',
    'Mis solicitudes',
  ];

  void _openTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardScreen(onOpenCatalog: () => _openTab(1)),
      CatalogScreen(
        repository: widget.repository,
        solicitudRepository: widget.solicitudRepository,
      ),
      _RequestsScreen(repository: widget.solicitudRepository),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _openTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Insumos',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Solicitudes',
          ),
        ],
      ),
    );
  }
}

class _DashboardScreen extends StatelessWidget {
  const _DashboardScreen({required this.onOpenCatalog});

  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 40,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(height: 16),
              Text(
                'Gestión de insumos',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Consulta los insumos disponibles y lleva el seguimiento de tus solicitudes.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onOpenCatalog,
                icon: const Icon(Icons.search),
                label: const Text('Explorar insumos'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Accesos rápidos', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Catálogo'),
            subtitle: const Text('Consulta y selecciona insumos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenCatalog,
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.assignment_outlined),
            title: Text('Solicitudes'),
            subtitle: Text('Crea solicitudes y consulta su estado'),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Las solicitudes se guardan primero en este dispositivo y se sincronizan con Firestore cuando hay conexión.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _RequestsScreen extends StatefulWidget {
  const _RequestsScreen({required this.repository});

  final SolicitudRepository repository;

  @override
  State<_RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<_RequestsScreen> {
  late Future<List<Solicitud>> _requestsFuture;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    _requestsFuture = widget.repository.listarPorEmpleado(empleadoDemoId);
  }

  Future<void> _syncPending() async {
    setState(() => _syncing = true);
    try {
      final resultado = await widget.repository.sincronizarPendientes();
      if (!mounted) return;
      final message = resultado.pendientes == 0
          ? 'Se sincronizaron ${resultado.sincronizadas} solicitud(es).'
          : '${resultado.pendientes} solicitud(es) siguen pendientes. Revisa tu conexión e inténtalo de nuevo.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo sincronizar. Inténtalo de nuevo.'),
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _syncing = false;
      _loadRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Solicitud>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No se pudieron cargar las solicitudes.'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(_loadRequests),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final solicitudes = snapshot.data ?? const <Solicitud>[];
        if (solicitudes.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64),
                  SizedBox(height: 16),
                  Text('Aún no tienes solicitudes'),
                  SizedBox(height: 8),
                  Text(
                    'Ve al catálogo, selecciona de 1 a 5 insumos y crea tu primera solicitud.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final pendientes = solicitudes
            .where((solicitud) => solicitud.pendienteSync)
            .length;

        return Column(
          children: [
            if (pendientes > 0)
              _PendingSyncBanner(
                pendientes: pendientes,
                syncing: _syncing,
                onSync: _syncPending,
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: solicitudes.length,
                itemBuilder: (context, index) {
                  final solicitud = solicitudes[index];
                  final fecha = solicitud.fechaCreacion.toLocal();
                  final fechaTexto =
                      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
                  final cantidadTotal = solicitud.lineas.fold<int>(
                    0,
                    (total, linea) => total + linea.cantidadSolicitada,
                  );
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.assignment_outlined),
                      ),
                      title: Text('Solicitud ${solicitud.id}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$fechaTexto · ${solicitud.lineas.length} insumo(s) · $cantidadTotal unidad(es)',
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Chip(
                                label: Text(solicitud.estado.name),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              _SyncStatusLabel(
                                pendiente: solicitud.pendienteSync,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PendingSyncBanner extends StatelessWidget {
  const _PendingSyncBanner({
    required this.pendientes,
    required this.syncing,
    required this.onSync,
  });

  final int pendientes;
  final bool syncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_upload_outlined, color: colors.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$pendientes solicitud(es) pendiente(s) de sincronizar',
              style: TextStyle(color: colors.onTertiaryContainer),
            ),
          ),
          TextButton(
            onPressed: syncing ? null : onSync,
            child: Text(syncing ? 'Enviando...' : 'Sincronizar'),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusLabel extends StatelessWidget {
  const _SyncStatusLabel({required this.pendiente});

  final bool pendiente;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          pendiente ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
          size: 12,
          color: pendiente ? colors.error : colors.primary,
        ),
        const SizedBox(width: 4),
        Text(
          pendiente ? 'Pendiente' : 'Sincronizada',
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}
