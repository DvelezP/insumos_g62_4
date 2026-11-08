import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/insumo.dart';
import '../models/linea_solicitud.dart';
import '../models/solicitud.dart';
import '../repositories/solicitud_repository.dart';

const String empleadoDemoId = 'empleado-demo-001';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({
    super.key,
    required this.insumos,
    required this.repository,
    this.empleadoId = empleadoDemoId,
    this.area = 'General',
  });

  final List<Insumo> insumos;
  final SolicitudRepository repository;
  final String empleadoId;
  final String area;

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, int> _quantities = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final insumo in widget.insumos) {
      _quantities[insumo.id] = 1;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final solicitud = Solicitud(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        empleadoId: widget.empleadoId,
        fechaCreacion: DateTime.now(),
        estado: EstadoSolicitud.SOLICITADA,
        area: widget.area,
        lineas: widget.insumos
            .map(
              (insumo) => LineaSolicitud(
                insumoId: insumo.id,
                cantidadSolicitada: _quantities[insumo.id]!,
              ),
            )
            .toList(),
      );
      final sincronizada = await widget.repository.guardar(solicitud);
      if (mounted) Navigator.of(context).pop(sincronizada);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar la solicitud. Inténtalo de nuevo.'),
        ),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva solicitud')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Elige una cantidad para cada insumo. Puedes solicitar entre 1 y 20 unidades por línea.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ...widget.insumos.map((insumo) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insumo.nombre,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text('${insumo.categoria} · ${insumo.unidad}'),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 82,
                        child: TextFormField(
                          initialValue: '1',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Cantidad',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final quantity = int.tryParse(value ?? '');
                            if (quantity == null ||
                                quantity < 1 ||
                                quantity > 20) {
                              return 'Usa 1–20';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            final quantity = int.tryParse(value);
                            if (quantity != null) {
                              _quantities[insumo.id] = quantity;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_saving ? 'Guardando...' : 'Enviar solicitud'),
            ),
            const SizedBox(height: 8),
            const Text(
              'La solicitud se guarda en este dispositivo con estado SOLICITADA y se envía a Firestore cuando hay conexión.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
