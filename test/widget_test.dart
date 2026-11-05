import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insumos_g62_4/main.dart';
import 'package:insumos_g62_4/repositories/insumo_repository.dart';
import 'package:insumos_g62_4/repositories/solicitud_repository.dart';
import 'package:insumos_g62_4/services/insumo_http_service.dart';

void main() {
  testWidgets('muestra la pantalla inicial y la navegación', (
    WidgetTester tester,
  ) async {
    final insumoRepository = InsumoRepository(
      service: InsumoHttpService(
        url: Uri.parse('https://www.datos.gov.co/resource/i7cb-raxc.json'),
      ),
    );

    await tester.pumpWidget(
      InsumosApp(
        repository: insumoRepository,
        solicitudRepository: SolicitudRepository(),
      ),
    );

    expect(find.text('Gestión de insumos'), findsOneWidget);
    expect(find.text('Explorar insumos'), findsOneWidget);
    expect(find.text('Insumos'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
