import 'package:flutter/material.dart';

import '../models/insumo.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  static const List<Insumo> _insumos = [
    Insumo(
      id: 'INS-001',
      nombre: 'Papel tamaño carta',
      unidad: 'resma',
      categoria: 'Papelería',
      descripcion: 'Papel blanco para impresión y fotocopiado.',
    ),
    Insumo(
      id: 'INS-002',
      nombre: 'Bolígrafo azul',
      unidad: 'unidad',
      categoria: 'Papelería',
      descripcion: 'Bolígrafo de tinta azul.',
    ),
    Insumo(
      id: 'INS-003',
      nombre: 'Jabón líquido',
      unidad: 'litro',
      categoria: 'Aseo',
      descripcion: 'Jabón líquido para limpieza general.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de insumos')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _insumos.length,
        itemBuilder: (context, index) {
          final insumo = _insumos[index];

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
            ),
          );
        },
      ),
    );
  }
}
