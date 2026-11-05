import '../local/insumo_local_data_source.dart';
import '../models/insumo.dart';
import '../services/insumo_http_service.dart';

class InsumoRepository {
  InsumoRepository({
    required this.service,
    InsumoLocalDataSource? localDataSource,
  }) : _localDataSource = localDataSource ?? InsumoLocalDataSource();

  final InsumoHttpService service;
  final InsumoLocalDataSource _localDataSource;
  bool usandoCatalogoLocal = false;

  Future<List<Insumo>> obtenerInsumos() async {
    late final List<Insumo> insumos;
    try {
      insumos = await service.fetchInsumos();
    } catch (_) {
      final insumosGuardados = await _localDataSource.obtenerTodos();
      if (insumosGuardados.isEmpty) rethrow;
      usandoCatalogoLocal = true;
      return insumosGuardados;
    }

    usandoCatalogoLocal = false;
    try {
      await _localDataSource.guardarTodos(insumos);
    } catch (_) {
      // El catálogo remoto sigue disponible aunque falle la copia local.
    }
    return insumos;
  }
}
