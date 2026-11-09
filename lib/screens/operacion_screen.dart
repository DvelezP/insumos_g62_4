import 'package:flutter/material.dart';

import '../models/insumo.dart';
import '../models/perfil_usuario.dart';
import '../remote/solicitud_remote_data_source.dart';
import '../repositories/insumo_repository.dart';

class OperacionScreen extends StatefulWidget {
  const OperacionScreen({
    super.key,
    required this.perfil,
    required this.remote,
    required this.insumoRepository,
  });
  final PerfilUsuario perfil;
  final SolicitudRemoteDataSource? remote;
  final InsumoRepository insumoRepository;

  @override
  State<OperacionScreen> createState() => _OperacionScreenState();
}

class _OperacionScreenState extends State<OperacionScreen> {
  bool _cargando = false;

  Future<void> _decidir(Map<String, dynamic> solicitud, bool aprobar) async {
    final motivo = await _pedirMotivo(
      aprobar ? 'Aprobar solicitud' : 'Rechazar solicitud',
      requerido: !aprobar,
    );
    if (motivo == null || !mounted) return;
    await _operar(
      () => widget.remote!.decidir(
        solicitudId: solicitud['id'] as String,
        supervisorId: widget.perfil.uid,
        aprobar: aprobar,
        motivo: motivo,
      ),
    );
  }

  Future<void> _registrarEntrega(Map<String, dynamic> solicitud) async {
    final lineas = (solicitud['lineas'] as List)
        .map((linea) => Map<String, dynamic>.from(linea as Map))
        .toList();
    final cantidades = <String, int>{};
    final campos = <_DialogTextInput>[];
    for (final linea in lineas) {
      final id = linea['insumoId'] as String;
      final saldo =
          (linea['cantidadSolicitada'] as int) -
          ((linea['cantidadEntregada'] as int?) ?? 0);
      campos.add(
        _DialogTextInput(
          label: '$id · pendiente $saldo',
          keyboardType: TextInputType.number,
          initialValue: '0',
        ),
      );
    }
    campos.add(
      const _DialogTextInput(label: 'Observación', required: false),
    );
    final valores = await showDialog<List<String>>(
      context: context,
      builder: (context) => _TextInputsDialog(
        title: 'Registrar entrega parcial',
        fields: campos,
        submitLabel: 'Registrar',
      ),
    );
    if (valores == null || !mounted) return;

    var valido = true;
    for (var i = 0; i < lineas.length; i++) {
      final id = lineas[i]['insumoId'] as String;
      final cantidad = int.tryParse(valores[i]);
      if (cantidad == null || cantidad < 0) valido = false;
      cantidades[id] = cantidad ?? 0;
    }
    if (!valido || cantidades.values.every((value) => value == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ingresa cantidades enteras válidas y registra al menos una unidad.',
          ),
        ),
      );
    } else {
      await _operar(
        () => widget.remote!.registrarEntrega(
          solicitudId: solicitud['id'] as String,
          encargadoId: widget.perfil.uid,
          cantidades: cantidades,
          motivo: valores.last.trim(),
          operationId: SolicitudRemoteDataSource.idOperacionEntrega(
            solicitudId: solicitud['id'] as String,
            lineas: lineas,
            cantidades: cantidades,
          ),
        ),
      );
    }
  }

  Future<String?> _pedirMotivo(String titulo, {required bool requerido}) async {
    final valores = await showDialog<List<String>>(
      context: context,
      builder: (context) => _TextInputsDialog(
        title: titulo,
        fields: [
          _DialogTextInput(
            label: requerido ? 'Motivo obligatorio' : 'Observación opcional',
            maxLines: 3,
            required: requerido,
          ),
        ],
        submitLabel: 'Continuar',
      ),
    );
    return valores?.first.trim();
  }

  Future<void> _operar(Future<void> Function() action) async {
    setState(() => _cargando = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operación confirmada por Firestore.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_mensaje(error))));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _mensaje(Object error) {
    final texto = error.toString();
    return texto.startsWith('Bad state: ')
        ? texto.substring(11)
        : texto.startsWith('Invalid argument(s): ')
        ? texto.substring(21)
        : 'No se pudo completar la operación. Revisa la conexión e inténtalo de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    final remote = widget.remote;
    if (remote == null) {
      return const Center(
        child: Text(
          'Firebase no está disponible. No se pueden confirmar cambios compartidos.',
        ),
      );
    }
    if (widget.perfil.rol == RolUsuario.supervisor) {
      return _solicitudes(
        remote.solicitudesDelArea(widget.perfil.area),
        aprobaciones: true,
      );
    }
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Entregas'),
              Tab(text: 'Inventario'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _solicitudes(
                  remote.solicitudesParaEntrega(),
                  aprobaciones: false,
                ),
                _InventarioPanel(
                  remote: remote,
                  repository: widget.insumoRepository,
                  actorId: widget.perfil.uid,
                  onAjustar: (id, delta, motivo) => _operar(
                    () => remote.ajustarInventario(
                      insumoId: id,
                      cambio: delta,
                      actorId: widget.perfil.uid,
                      motivo: motivo,
                    ),
                  ),
                  onInicializar: (id, cantidad, motivo) => _operar(
                    () => remote.inicializarInventario(
                      insumoId: id,
                      cantidad: cantidad,
                      actorId: widget.perfil.uid,
                      motivo: motivo,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_cargando) const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Widget _solicitudes(
    Stream<List<Map<String, dynamic>>> stream, {
    required bool aprobaciones,
  }) => StreamBuilder<List<Map<String, dynamic>>>(
    stream: stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Center(
          child: Text(
            'No se pudieron cargar las solicitudes compartidas. Revisa el acceso y la conexión.',
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final solicitudes = snapshot.data!;
      if (solicitudes.isEmpty) {
        return Center(
          child: Text(
            aprobaciones
                ? 'No hay solicitudes pendientes de aprobación.'
                : 'No hay entregas pendientes.',
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: solicitudes.length,
        itemBuilder: (context, index) {
          final solicitud = solicitudes[index];
          final lineas = (solicitud['lineas'] as List)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solicitud ${solicitud['id']}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Empleado: ${solicitud['empleadoId']} · ${solicitud['estado']}',
                  ),
                  ...lineas.map(
                    (linea) => Text(
                      '${linea['insumoId']}: ${linea['cantidadSolicitada']} solicitadas, ${linea['cantidadEntregada'] ?? 0} entregadas',
                    ),
                  ),
                  if (aprobaciones && solicitud['estado'] == 'SOLICITADA')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _cargando
                              ? null
                              : () => _decidir(solicitud, false),
                          child: const Text('Rechazar'),
                        ),
                        FilledButton(
                          onPressed: _cargando
                              ? null
                              : () => _decidir(solicitud, true),
                          child: const Text('Aprobar'),
                        ),
                      ],
                    )
                  else
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _cargando
                            ? null
                            : () => _registrarEntrega(solicitud),
                        icon: const Icon(Icons.local_shipping_outlined),
                        label: const Text('Registrar entrega'),
                      ),
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

class _InventarioPanel extends StatelessWidget {
  const _InventarioPanel({
    required this.remote,
    required this.repository,
    required this.actorId,
    required this.onAjustar,
    required this.onInicializar,
  });
  final SolicitudRemoteDataSource remote;
  final InsumoRepository repository;
  final String actorId;
  final Future<void> Function(String id, int delta, String motivo) onAjustar;
  final Future<void> Function(String id, int cantidad, String motivo)
  onInicializar;

  Future<void> _mostrarInicializacion(
    BuildContext context,
    Insumo insumo,
  ) async {
    final valores = await showDialog<List<String>>(
      context: context,
      builder: (context) => _TextInputsDialog(
        title: 'Crear stock de ${insumo.nombre}',
        fields: const [
          _DialogTextInput(
            label: 'Existencias iniciales',
            keyboardType: TextInputType.number,
            required: true,
          ),
          _DialogTextInput(label: 'Motivo', required: true),
        ],
        submitLabel: 'Crear',
      ),
    );
    if (valores == null || !context.mounted) return;
    final value = int.tryParse(valores[0]);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Indica una cantidad positiva y el motivo del registro inicial.',
          ),
        ),
      );
    } else {
      await onInicializar(insumo.id, value, valores[1].trim());
    }
  }

  Future<void> _mostrarAjuste(BuildContext context, Insumo insumo) async {
    final valores = await showDialog<List<String>>(
      context: context,
      builder: (context) => _TextInputsDialog(
        title: 'Ajustar ${insumo.nombre}',
        fields: const [
          _DialogTextInput(
            label: 'Cambio (+/- unidades)',
            keyboardType: TextInputType.numberWithOptions(signed: true),
            required: true,
          ),
          _DialogTextInput(label: 'Motivo', required: true),
        ],
        submitLabel: 'Guardar',
      ),
    );
    if (valores == null || !context.mounted) return;
    final value = int.tryParse(valores[0]);
    if (value == null || value == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Indica un cambio entero distinto de cero y su motivo.',
          ),
        ),
      );
    } else {
      await onAjustar(insumo.id, value, valores[1].trim());
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<List<Map<String, dynamic>>>(
    stream: remote.inventarioActual(),
    builder: (context, stocks) {
      if (stocks.hasError) {
        return const Center(child: Text('No se pudo consultar el inventario.'));
      }
      if (!stocks.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final stockPorId = {
        for (final row in stocks.data!) row['id'] as String: row,
      };
      return FutureBuilder<List<Insumo>>(
        future: repository.obtenerInsumos(),
        builder: (context, catalog) {
          if (!catalog.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = catalog.data!;
          if (items.isEmpty) {
            return const Center(child: Text('No hay insumos para mostrar.'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final stock = stockPorId[item.id];
              return ListTile(
                title: Text(item.nombre),
                subtitle: Text(
                  stock == null
                      ? 'Sin stock configurado en Firestore'
                      : 'Existencias: ${stock['existencias']} · Reservado: ${stock['reservado'] ?? 0}',
                ),
                trailing: IconButton(
                  tooltip: stock == null
                      ? 'Crear stock inicial'
                      : 'Ajustar stock',
                  icon: Icon(
                    stock == null ? Icons.add_box_outlined : Icons.tune,
                  ),
                  onPressed: () => stock == null
                      ? _mostrarInicializacion(context, item)
                      : _mostrarAjuste(context, item),
                ),
              );
            },
          );
        },
      );
    },
  );
}

class _DialogTextInput {
  const _DialogTextInput({
    required this.label,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.required = false,
    this.initialValue = '',
  });

  final String label;
  final TextInputType keyboardType;
  final int maxLines;
  final bool required;
  final String initialValue;
}

class _TextInputsDialog extends StatefulWidget {
  const _TextInputsDialog({
    required this.title,
    required this.fields,
    required this.submitLabel,
  });

  final String title;
  final List<_DialogTextInput> fields;
  final String submitLabel;

  @override
  State<_TextInputsDialog> createState() => _TextInputsDialogState();
}

class _TextInputsDialogState extends State<_TextInputsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers = widget.fields
      .map((field) => TextEditingController(text: field.initialValue))
      .toList();

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.fields.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              TextFormField(
                controller: _controllers[i],
                keyboardType: widget.fields[i].keyboardType,
                maxLines: widget.fields[i].maxLines,
                decoration: InputDecoration(
                  labelText: widget.fields[i].label,
                  border: const OutlineInputBorder(),
                ),
                validator: widget.fields[i].required
                    ? (value) => value == null || value.trim().isEmpty
                          ? 'Este campo es obligatorio.'
                          : null
                    : null,
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            _controllers.map((controller) => controller.text).toList(),
          );
        },
        child: Text(widget.submitLabel),
      ),
    ],
  );
}
