import 'package:flutter_test/flutter_test.dart';
import 'package:insumos_g62_4/models/linea_solicitud.dart';
import 'package:insumos_g62_4/models/solicitud.dart';

void main() {
  group('Líneas de solicitud', () {
    test('acepta las cantidades límite 1 y 20', () {
      expect(
        LineaSolicitud(insumoId: 'a', cantidadSolicitada: 1).cantidadSolicitada,
        1,
      );
      expect(
        LineaSolicitud(
          insumoId: 'b',
          cantidadSolicitada: 20,
        ).cantidadSolicitada,
        20,
      );
    });

    test('rechaza cantidades fuera del rango permitido', () {
      expect(
        () => LineaSolicitud(insumoId: 'a', cantidadSolicitada: 0),
        throwsArgumentError,
      );
      expect(
        () => LineaSolicitud(insumoId: 'a', cantidadSolicitada: 21),
        throwsArgumentError,
      );
    });

    test('no permite entregar más de lo aprobado', () {
      expect(
        () => LineaSolicitud(
          insumoId: 'a',
          cantidadSolicitada: 4,
          cantidadEntregada: 5,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Solicitudes', () {
    test('acepta de una a cinco líneas de insumos distintos', () {
      final solicitud = crearSolicitud(List.generate(5, (i) => 'item-$i'));
      expect(solicitud.lineas, hasLength(5));
    });

    test(
      'rechaza solicitudes vacías, con más de cinco líneas o insumos repetidos',
      () {
        expect(() => crearSolicitud([]), throwsArgumentError);
        expect(
          () => crearSolicitud(List.generate(6, (i) => 'item-$i')),
          throwsArgumentError,
        );
        expect(() => crearSolicitud(['item-1', 'item-1']), throwsArgumentError);
      },
    );

    test('conserva datos, estado y área al convertir a JSON y regresar', () {
      final original = crearSolicitud(['guantes', 'alcohol']).copyWith(
        area: 'Enfermería',
        estado: EstadoSolicitud.PARCIAL,
        aprobadorId: 'supervisor-1',
        fechaDecision: DateTime.utc(2026, 11, 7),
      );
      final copia = Solicitud.fromJson(original.toJson());
      expect(copia.id, original.id);
      expect(copia.estado, EstadoSolicitud.PARCIAL);
      expect(copia.area, 'Enfermería');
      expect(copia.aprobadorId, 'supervisor-1');
      expect(copia.fechaDecision, original.fechaDecision);
      expect(copia.lineas.first.cantidadSolicitada, 2);
    });
  });
}

Solicitud crearSolicitud(List<String> ids) => Solicitud(
  id: 'solicitud-prueba',
  empleadoId: 'empleado-prueba',
  fechaCreacion: DateTime.utc(2026, 11, 7),
  estado: EstadoSolicitud.SOLICITADA,
  area: 'General',
  lineas: ids
      .map((id) => LineaSolicitud(insumoId: id, cantidadSolicitada: 2))
      .toList(),
);
