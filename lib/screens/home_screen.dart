import 'package:flutter/material.dart';

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
          'Las solicitudes se guardan en este dispositivo y quedan pendientes de sincronización.',
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
  late Future _requestsFuture;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    _requestsFuture = widget.repository.listarPorEmpleado(empleadoDemoId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
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

        final solicitudes = snapshot.data ?? [];
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

        return ListView.builder(
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
                subtitle: Text(
                  '$fechaTexto · ${solicitud.lineas.length} insumo(s) · $cantidadTotal unidad(es)',
                ),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(label: Text(solicitud.estado.name)),
                    const Text(
                      'Pendiente sync',
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
