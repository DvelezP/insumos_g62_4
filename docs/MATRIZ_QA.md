# Matriz QA · G62-4

**Versión final probada: 1.1.1+4** (`pubspec.yaml`).

- Dispositivo de prueba: emulador Android `Medium_Phone` (`sdk_gphone16k_x86_64`, Android 17).
- Proyecto Firebase: `insumosg62`.
- Cuentas de prueba: `empleado`, `supervisor` y `bodega`. Las credenciales se comparten solo por el canal privado del docente.
- Verificación automatizada del 2026-11-09: `flutter test`, **19 pruebas aprobadas**; `flutter analyze lib`, sin problemas.
- Los casos manuales se ejecutaron el 2026-11-09 en una compilación debug de 1.1.1+4. QA-28 se ejecutó sobre el APK release.
- Las capturas están en [`docs/evidencias/`](evidencias/).
- En las capturas, las fechas del emulador aparecen en UTC (10/11/2026).

## Casos automatizados ejecutados

Cuenta/rol N/A indica que el caso usa modelos, un servicio simulado o la base de datos local; no afirma una prueba remota de Firebase.

| ID | Precondición | Cuenta/rol | Pasos | Esperado | Obtenido | Estado | Versión | Evidencia |
|---|---|---|---|---|---|---|---|---|
| QA-01 | Prueba unitaria; modelo disponible | N/A | Crear línea con cantidades 1 y 20 | Acepta ambos límites | Ambos objetos se crean | Aprobado | 1.1.1+4 | `test/domain_model_test.dart` |
| QA-02 | Prueba unitaria; modelo disponible | N/A | Crear líneas con 0 y 21 unidades | Rechaza cantidades fuera de rango | Lanza `ArgumentError` en ambas | Aprobado | 1.1.1+4 | `test/domain_model_test.dart` |
| QA-03 | Prueba unitaria; línea solicitada por 4 | N/A | Crear línea con 5 entregadas | Rechaza entrega superior a lo solicitado | Lanza `ArgumentError` | Aprobado | 1.1.1+4 | `test/domain_model_test.dart` |
| QA-04 | Prueba unitaria; cinco IDs distintos | N/A | Construir solicitud de cinco líneas | Acepta hasta cinco insumos | Solicitud contiene cinco líneas | Aprobado | 1.1.1+4 | `test/domain_model_test.dart` |
| QA-05 | Prueba unitaria; datos de líneas controlados | N/A | Probar solicitud vacía, seis líneas y un ID repetido | Rechaza cada solicitud inválida | Las tres entradas lanzan `ArgumentError` | Aprobado | 1.1.1+4 | `test/domain_model_test.dart` |
| QA-06 | Solicitud válida creada en memoria | N/A | Serializar y reconstruir una solicitud con área y aprobación | Conserva datos y estado | ID, estado, área, aprobador, fecha y líneas coinciden | Aprobado | 1.1.1+4 | `test/domain_model_test.dart` |
| QA-07 | Cliente HTTP simulado con respuesta 200 | N/A | Devolver objeto JSON válido y cargarlo | Mapea campos INVIMA al modelo | ID, nombre y unidad esperados | Aprobado | 1.1.1+4 | `test/insumo_http_service_test.dart` |
| QA-08 | Cliente HTTP simulado con respuesta 500 | N/A | Solicitar catálogo | Devuelve error controlado | Lanza `InsumoServiceException` | Aprobado | 1.1.1+4 | `test/insumo_http_service_test.dart` |
| QA-09 | Cliente HTTP simulado con JSON inválido | N/A | Responder HTTP 200 con JSON malformado | Informa error de contenido | Lanza `InsumoServiceException` | Aprobado | 1.1.1+4 | `test/insumo_http_service_test.dart` |
| QA-10 | Servicio configurado con timeout de 1 ms | N/A | Demorar respuesta simulada y consultar | Informa timeout controlado | Lanza `InsumoServiceException` | Aprobado | 1.1.1+4 | `test/insumo_http_service_test.dart` |
| QA-11 | Cliente simulado arroja `SocketException` | N/A | Consultar catálogo sin red | Informa falta de conexión | Lanza `InsumoServiceException` | Aprobado | 1.1.1+4 | `test/insumo_http_service_test.dart` |
| QA-12 | SQLite en memoria y remoto simulado disponible | Empleado simulado | Guardar una solicitud | Persiste y marca sincronizada tras respuesta remota | Retorna sincronizada y queda sin pendiente | Aprobado | 1.1.1+4 | `test/solicitud_repository_test.dart` |
| QA-13 | SQLite en memoria y remoto simulado con fallo | Empleado simulado | Guardar una solicitud | Conserva local y pendiente | Solicitud sigue consultable con `pendienteSync` | Aprobado | 1.1.1+4 | `test/solicitud_repository_test.dart` |
| QA-14 | Repositorio local sin remoto | Empleado simulado | Guardar una solicitud | Conserva local y pendiente | Retorna no sincronizada y aparece pendiente | Aprobado | 1.1.1+4 | `test/solicitud_repository_test.dart` |
| QA-15 | Dos solicitudes pendientes del mismo empleado; remoto recuperado | Empleado simulado | Ejecutar sincronización de pendientes | Envía ambas y las marca sincronizadas | Dos sincronizadas, cero pendientes | Aprobado | 1.1.1+4 | `test/solicitud_repository_test.dart` |
| QA-16 | Solicitud ya sincronizada | Empleado simulado | Ejecutar reintento | No reenvía la solicitud | Cero reenvíos y una sola llamada remota original | Aprobado | 1.1.1+4 | `test/solicitud_repository_test.dart` |
| QA-17 | Pendientes de dos empleados en SQLite | Dos empleados simulados | Sincronizar solo con UID del empleado activo | No envía datos de otra cuenta | Solo se envía el UID activo; la otra sigue pendiente | Aprobado | 1.1.1+4 | `test/solicitud_repository_test.dart` |
| QA-18 | Solicitud local pendiente; remoto continúa fallando | Empleado simulado | Reintentar sincronización | Mantiene pendiente ante fallo temporal | Cero sincronizadas; una pendiente | Aprobado | 1.1.1+4 | `test/solicitud_repository_test.dart` |
| QA-19 | Widget de app con repositorios de prueba | N/A | Montar app y revisar inicio/navegación | Muestra inicio y destinos | Textos esperados y `NavigationBar` presentes | Aprobado | 1.1.1+4 | `test/widget_test.dart` |

## Casos manuales en Android con Firebase

| ID | Precondición | Cuenta/rol | Pasos | Esperado | Obtenido | Estado | Versión | Evidencia |
|---|---|---|---|---|---|---|---|---|
| QA-20 | App instalada, sin sesión | Bodega / empleado | 1. Iniciar sesión con contraseña incorrecta. 2. Iniciar con la correcta. 3. Cerrar la app por completo y abrirla. | Mensaje comprensible ante credenciales inválidas; la sesión se restaura al reabrir | "Correo o contraseña incorrectos."; al reabrir entra directo al inicio | Aprobado | 1.1.1+4 | [20a](evidencias/QA-20a_login.png), [20b](evidencias/QA-20b_error_credenciales.png) (contraseña tapada), [20c](evidencias/QA-20c_sesion_restaurada.png) |
| QA-21 | Tres cuentas con perfil en `usuarios/{uid}` | Empleado, supervisor y bodega | Iniciar sesión con cada rol y revisar navegación y acciones | Cada rol ve solo sus pantallas y acciones | Empleado: Inicio, Insumos y Solicitudes. Supervisor: bandeja con Aprobar/Rechazar. Bodega: Entregas e Inventario | Aprobado (tras corregir D-02) | 1.1.1+4 | [21a](evidencias/QA-21a_inicio_empleado.png), [21b](evidencias/QA-21b_inicio_supervisor.png), [21c](evidencias/QA-21c_bandeja_supervision.png), [21d](evidencias/QA-21d_inicio_bodega.png), [21e](evidencias/QA-21e_bodega_entregas.png) |
| QA-22 | Reglas publicadas | Empleado | Intentar leer solicitudes de otro UID o cambiar el propio `rol` | Firestore lo rechaza (`permission-denied`) | No ejecutado desde la app: la interfaz no ofrece esas acciones. Las reglas tienen `allow update: if false` sobre `usuarios` y filtran la lectura por `empleadoId` | Pendiente: ejecutar en el simulador de reglas de Firebase Console | — | — |
| QA-23 | CARDIK (`20048021-41`) con stock conocido | Supervisor | 1. Aprobar 4 unidades con 3 existencias. 2. Llevar el stock a 4 y aprobar 4. 3. Aprobar otra solicitud de 1 unidad. | Solo se aprueba lo que cabe en el disponible; nunca queda stock negativo | 1. "No hay existencias suficientes…". 2. Aprobada, 4/4 reservadas. 3. "No hay existencias suficientes…". También se valida "Falta configurar el stock…" | Aprobado (secuencial) | 1.1.1+4 | [23a](evidencias/QA-23a_sin_existencias_bloquea_aprobacion.png), [24b](evidencias/QA-24b_aprobada_reserva_stock.png), [23c](evidencias/QA-23c_ultimas_unidades_no_se_exceden.png), [23b](evidencias/QA-23b_falta_stock_configurado.png) |
| QA-24 | Solicitud 1794273215789876 de 4 CARDIK | Supervisor y bodega | 1. Aprobar. 2. Entregar 2. | APROBADA reserva 4; la entrega parcial deja PARCIAL 2/4 e inventario 2/2 | Coincide con lo esperado | Aprobado | 1.1.1+4 | [24a](evidencias/QA-24a_aprobar_dialogo.png), [24b](evidencias/QA-24b_aprobada_reserva_stock.png), [24c](evidencias/QA-24c_inventario_reservado.png), [24d](evidencias/QA-24d_entrega_parcial_dialogo.png), [24e](evidencias/QA-24e_entrega_parcial_confirmada.png), [24f](evidencias/QA-24f_inventario_tras_entrega_parcial.png) |
| QA-25 | Misma solicitud en PARCIAL 2/4 | Bodega y empleado | 1. Entregar las 2 restantes. 2. Revisar inventario y la vista del empleado. | ENTREGADA 4/4; inventario 0/0 sin descontar dos veces | ENTREGADA; inventario 0 existencias / 0 reservadas; el empleado ve 4/4 | Aprobado | 1.1.1+4 | [25a](evidencias/QA-25a_entrega_completa.png), [25b](evidencias/QA-25b_bandeja_bodega_tras_entrega.png), [25c](evidencias/QA-25c_inventario_tras_entrega_final.png), [25d](evidencias/QA-25d_empleado_ve_entregada.png) |
| QA-26 | CARDIK con 2 existencias y 2 reservadas | Bodega | Ajustar −1 con motivo | Se rechaza; el inventario no cambia | "El ajuste dejaría existencias por debajo del stock reservado."; sigue 2/2 | Aprobado | 1.1.1+4 | [26a](evidencias/QA-26a_ajuste_invade_reservado_dialogo.png), [26b](evidencias/QA-26b_ajuste_invade_reservado_rechazado.png) |
| QA-27 | Compilación debug | Empleado | Tocar "Probar evento de Crashlytics" y reiniciar la app | Evento no fatal visible en Firebase Console | Mensaje "Evento de prueba enviado a Crashlytics." en la app | Parcial: falta la captura de la consola. Pendiente: guardar `evidencias/QA-27b_consola_crashlytics.png` desde Firebase Console > `insumosg62` > Crashlytics (no fatales), mostrando versión 1.1.1 (4) y dispositivo `sdk_gphone16k_x86_64` | 1.1.1+4 debug | [27a](evidencias/QA-27a_evento_crashlytics_enviado.png) |
| QA-28 | APK release instalado (`versionName 1.1.1`, `versionCode 4`) | Supervisor, bodega y empleado | 1. Supervisor rechaza con motivo. 2. Bodega revisa el inventario y entrega 1 unidad. 3. Empleado carga el catálogo HTTP y crea una solicitud. | Ningún rol ve opciones de desarrollo; HTTP, Authentication, base local, Firestore y sincronización funcionan desde el release | Sin botón de prueba en ningún rol. Rechazo y entrega confirmados por Firestore. Catálogo HTTP cargado. Solicitud 1794281089108363 guardada y "Sincronizada" | Aprobado | 1.1.1+4 release | [28a](evidencias/QA-28a_release_inicio_supervisor.png), [28b](evidencias/QA-28b_release_supervisor_rechaza.png), [28c](evidencias/QA-28c_release_inicio_bodega.png), [28d](evidencias/QA-28d_release_inventario_bodega.png), [28e](evidencias/QA-28e_release_bodega_entrega.png), [28f](evidencias/QA-28f_release_inicio_empleado.png), [28g](evidencias/QA-28g_release_catalogo_http.png), [28h](evidencias/QA-28h_release_solicitud_sincronizada.png), [28i](evidencias/QA-28i_release_mis_solicitudes.png) |
| QA-29 | Catálogo cargado | Empleado | Elegir una categoría, cerrar la app por completo y volver a abrirla | El filtro se restaura (SharedPreferences) | Se restaura la misma categoría | Aprobado | 1.1.1+4 | [29a](evidencias/QA-29a_filtro_categoria.png), [29b](evidencias/QA-29b_filtro_restaurado.png) |
| QA-30 | Cargar `firestore.rules` en el emulador local | — | Compilar reglas | Sin errores | Sin errores | Aprobado (2026-11-08) | 1.1.0+3 | — |
| QA-31 | Instalar y abrir APK release | — | Abrir app | Firebase Core y Crashlytics inicializan | Inicializan | Aprobado (2026-11-08) | 1.1.0+3 | — |
| QA-32 | Publicar `firestore.rules` en `insumosg62` | — | `firebase deploy --only firestore:rules` | Reglas liberadas | `Deploy complete` | Aprobado (2026-11-08) | 1.1.0+3 | — |
| QA-33 | Endpoint HTTP configurado | Empleado | Abrir catálogo | Se reciben al menos ocho registros | 10 registros visibles | Aprobado | 1.1.1+4 | [33](evidencias/QA-33_catalogo_http.png) |
| QA-34 | Solicitud propia en SOLICITADA | Empleado | Cancelar | Pasa a CANCELADA con resultado claro | "Solicitud cancelada."; estado CANCELADA. Ver D-03 | Aprobado | 1.1.1+4 | [34](evidencias/QA-34_cancelacion_empleado.png) |
| QA-35 | Solicitud de otro empleado en SOLICITADA | Supervisor | 1. Rechazar sin motivo. 2. Rechazar con motivo. | El motivo es obligatorio; luego queda RECHAZADA | "Este campo es obligatorio."; luego "Operación confirmada por Firestore." | Aprobado | 1.1.1+4 | [35a](evidencias/QA-35a_rechazo_exige_motivo.png), [35b](evidencias/QA-35b_rechazo_con_motivo.png), [35c](evidencias/QA-35c_rechazo_confirmado.png) |
| QA-36 | Inventario visible | Bodega | 1. Ajuste +1 con motivo. 2. Crear stock inicial de ALUNBRIG (10) | Ambos quedan registrados con motivo y actor | CARDIK 3→4; ALUNBRIG 10 | Aprobado | 1.1.1+4 | [36a](evidencias/QA-36a_inventario_bodega.png), [36b](evidencias/QA-36b_ajuste_positivo_con_motivo.png), [36c](evidencias/QA-36c_crear_stock_inicial.png), [24c](evidencias/QA-24c_inventario_reservado.png) |
| QA-37 | Solicitud APROBADA con saldo 4 | Bodega | Entregar 5 | Se rechaza | "La cantidad entregada supera el saldo aprobado."; sin cambios | Aprobado | 1.1.1+4 | [37](evidencias/QA-37_entrega_supera_saldo.png) |
| QA-38 | Catálogo cargado | Empleado | Seleccionar dos insumos y enviar | Solicitud SOLICITADA y sincronizada | Aparece en Mis solicitudes con su estado | Aprobado | 1.1.1+4 | [38a](evidencias/QA-38a_seleccion_insumos.png), [38b](evidencias/QA-38b_mis_solicitudes_estados.png) |
| QA-39 | Formulario de nueva solicitud | Empleado | Escribir 25 unidades y enviar | Validación 1–20 | "Usa 1–20"; no se envía | Aprobado | 1.1.1+4 | [39](evidencias/QA-39_cantidad_fuera_rango.png) |
| QA-40 | Sesión iniciada; red del emulador apagada | Empleado | 1. Crear una solicitud de 4 unidades. 2. Cerrar la app por completo y abrirla sin red. | Se guarda local como "Pendiente de sincronizar" y sigue después del reinicio | Pendiente con el mensaje "Firebase no respondió…"; persiste tras el reinicio | Aprobado (tras corregir D-01) | 1.1.1+4 | [40a](evidencias/QA-40a_guardando_sin_conexion.png), [40b](evidencias/QA-40b_pendiente_sincronizar.png), [40c](evidencias/QA-40c_persiste_tras_reinicio.png) |
| QA-41 | Solicitud pendiente de QA-40; red restaurada | Empleado | Tocar "Sincronizar" y recargar | Queda sincronizada una sola vez | "Sincronizada"; el ID aparece una vez | Aprobado | 1.1.1+4 | [41a](evidencias/QA-41a_sincronizar_pendiente.png), [41b](evidencias/QA-41b_sincronizada_sin_duplicado.png) |
| QA-42 | Catálogo sin respuesta HTTP | Empleado | Abrir el catálogo sin red | Error controlado con copia local y opción de reintento | "Sin conexión: se muestra la última copia guardada del catálogo." con botón Reintentar | Aprobado | 1.1.1+4 | [42](evidencias/QA-42_http_sin_conexion_reintentar.png) |

### Escenarios de aceptación del caso G62-4

| Escenario | Casos |
|---|---|
| 1. Dos aprobaciones buscan las últimas unidades y no exceden el disponible | QA-23 y QA-24 |
| 2. Una entrega parcial deja el saldo correcto; repetir el envío no duplica el movimiento | QA-24 y QA-25 (ver L-02) |
| 3. Un ajuste que invade lo reservado se rechaza | QA-26 |

## Registro de defectos

| ID | Defecto | Severidad | Corrección | Estado |
|---|---|---|---|---|
| D-00 | `main` no compilaba: un merge dejó un `ListView` duplicado y una llave sin cerrar en `lib/screens/home_screen.dart` | Bloqueante | Se eliminó el bloque duplicado y se conservó la versión más reciente de la tarjeta | Corregido |
| D-01 | Una solicitud creada sin conexión se mostraba "Sincronizada". La recarga leía la caché offline de Firestore, que incluye escrituras sin confirmar, y la guardaba como confirmada | Alta | `cargarSolicitudesDeEmpleado` usa `GetOptions(source: Source.server)`; sin servidor se conserva el estado local (`lib/remote/solicitud_remote_data_source.dart`) | Corregido; verificado en QA-40 |
| D-02 | El supervisor veía "Registrar entrega" (acción de bodega) en solicitudes RECHAZADA, ENTREGADA y CANCELADA | Media | El botón solo se muestra en la bandeja de bodega (`lib/screens/operacion_screen.dart`) | Corregido; verificado en QA-21 |
| D-03 | Cancelar una solicitud no pide confirmación (un toque) | Baja | Sin cambio: muestra un resultado claro, que los lineamientos aceptan | Abierto |
| D-04 | La bandeja del supervisor y la de bodega muestran el UID del empleado en vez de su correo | Baja | Sin cambio | Abierto |

## Limitaciones conocidas

- **L-01:** QA-23 se ejecutó de forma secuencial con un solo supervisor. La exclusión concurrente depende de la transacción Firestore de `decidir`; no se ejecutaron dos aprobaciones simultáneas desde dos dispositivos.
- **L-02:** desde la interfaz no se puede forzar el reenvío de la misma entrega. La entrega usa un ID de operación determinista (`operaciones_entrega/{operationId}`) dentro de una transacción. Un reintento con la misma operación no se ejecutó en el emulador.
- **L-03:** la regla "el supervisor no aprueba su propia solicitud" no se puede ejecutar desde la app, porque las reglas solo permiten crear solicitudes al rol `empleado`. El código también la valida en `decidir`.
- **L-04:** la consulta del consumo del área por parte del supervisor no está implementada.

## Checklist de release

- [x] Autenticación y tres roles comprobados (QA-20, QA-21); reglas publicadas (QA-32). Pendiente: prueba de reglas QA-22.
- [x] Flujo completo y reglas de negocio validados (QA-23 a QA-26, QA-34 a QA-39).
- [x] Persistencia local, pendientes, reintentos sin duplicados y filtrado por cuenta (QA-17, QA-40, QA-41).
- [ ] Crashlytics verificado en la consola (QA-27 parcial).
- [x] Logs y permisos revisados: el manifiesto principal declara `INTERNET`; no se piden permisos en tiempo de ejecución.
- [x] Versión actualizada a 1.1.1+4.
- [x] APK release instalado y recorrido con los tres roles (QA-28).
- [x] Código, README, datos de prueba y matriz QA listos para revisión.
