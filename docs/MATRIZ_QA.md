# Matriz QA · G62-4

Versión de código: **1.1.0+3**. Verificación local ejecutada el **2026-11-08**: `flutter test --reporter expanded`, **19 pruebas aprobadas**; `flutter analyze lib test`, sin problemas. `firestore.rules` también se compiló sin errores en el emulador local de Firestore.

## Casos automatizados ejecutados

Los casos siguientes se ejecutaron el 2026-11-08 mediante `flutter test --reporter expanded`. Cuenta/rol N/A indica que el caso usa modelos, servicio simulado o base de datos local; no afirma una prueba remota de Firebase.

| ID | Precondición | Cuenta/rol | Pasos | Esperado | Obtenido | Estado | Versión | Evidencia |
|---|---|---|---|---|---|---|---|---|
| QA-01 | Prueba unitaria; modelo disponible | N/A | Crear línea con cantidades 1 y 20 | Acepta ambos límites | Ambos objetos se crean | Aprobado | 1.1.0+3 | `test/domain_model_test.dart` |
| QA-02 | Prueba unitaria; modelo disponible | N/A | Crear líneas con 0 y 21 unidades | Rechaza cantidades fuera de rango | Lanza `ArgumentError` en ambas | Aprobado | 1.1.0+3 | `test/domain_model_test.dart` |
| QA-03 | Prueba unitaria; línea solicitada por 4 | N/A | Crear línea con 5 entregadas | Rechaza entrega superior a lo solicitado | Lanza `ArgumentError` | Aprobado | 1.1.0+3 | `test/domain_model_test.dart` |
| QA-04 | Prueba unitaria; cinco IDs distintos | N/A | Construir solicitud de cinco líneas | Acepta hasta cinco insumos | Solicitud contiene cinco líneas | Aprobado | 1.1.0+3 | `test/domain_model_test.dart` |
| QA-05 | Prueba unitaria; datos de líneas controlados | N/A | Probar solicitud vacía, seis líneas y un ID repetido | Rechaza cada solicitud inválida | Las tres entradas lanzan `ArgumentError` | Aprobado | 1.1.0+3 | `test/domain_model_test.dart` |
| QA-06 | Solicitud válida creada en memoria | N/A | Serializar y reconstruir una solicitud con área y aprobación | Conserva datos y estado | ID, estado, área, aprobador, fecha y líneas coinciden | Aprobado | 1.1.0+3 | `test/domain_model_test.dart` |
| QA-07 | Cliente HTTP simulado con respuesta 200 | N/A | Devolver objeto JSON válido y cargarlo | Mapea campos INVIMA al modelo | ID, nombre y unidad esperados | Aprobado | 1.1.0+3 | `test/insumo_http_service_test.dart` |
| QA-08 | Cliente HTTP simulado con respuesta 500 | N/A | Solicitar catálogo | Devuelve error controlado | Lanza `InsumoServiceException` | Aprobado | 1.1.0+3 | `test/insumo_http_service_test.dart` |
| QA-09 | Cliente HTTP simulado con JSON inválido | N/A | Responder HTTP 200 con JSON malformado | Informa error de contenido | Lanza `InsumoServiceException` | Aprobado | 1.1.0+3 | `test/insumo_http_service_test.dart` |
| QA-10 | Servicio configurado con timeout de 1 ms | N/A | Demorar respuesta simulada y consultar | Informa timeout controlado | Lanza `InsumoServiceException` | Aprobado | 1.1.0+3 | `test/insumo_http_service_test.dart` |
| QA-11 | Cliente simulado arroja `SocketException` | N/A | Consultar catálogo sin red | Informa falta de conexión | Lanza `InsumoServiceException` | Aprobado | 1.1.0+3 | `test/insumo_http_service_test.dart` |
| QA-12 | SQLite en memoria y remoto simulado disponible | Empleado simulado | Guardar una solicitud | Persiste y marca sincronizada tras respuesta remota | Retorna sincronizada y queda sin pendiente | Aprobado | 1.1.0+3 | `test/solicitud_repository_test.dart` |
| QA-13 | SQLite en memoria y remoto simulado con fallo | Empleado simulado | Guardar una solicitud | Conserva local y pendiente | Solicitud sigue consultable con `pendienteSync` | Aprobado | 1.1.0+3 | `test/solicitud_repository_test.dart` |
| QA-14 | Repositorio local sin remoto | Empleado simulado | Guardar una solicitud | Conserva local y pendiente | Retorna no sincronizada y aparece pendiente | Aprobado | 1.1.0+3 | `test/solicitud_repository_test.dart` |
| QA-15 | Dos solicitudes pendientes del mismo empleado; remoto recuperado | Empleado simulado | Ejecutar sincronización de pendientes | Envía ambas y las marca sincronizadas | Dos sincronizadas, cero pendientes | Aprobado | 1.1.0+3 | `test/solicitud_repository_test.dart` |
| QA-16 | Solicitud ya sincronizada | Empleado simulado | Ejecutar reintento | No reenvía la solicitud | Cero reenvíos y una sola llamada remota original | Aprobado | 1.1.0+3 | `test/solicitud_repository_test.dart` |
| QA-17 | Pendientes de dos empleados en SQLite | Dos empleados simulados | Sincronizar solo con UID del empleado activo | No envía datos de otra cuenta | Solo se envía el UID activo; la otra sigue pendiente | Aprobado | 1.1.0+3 | `test/solicitud_repository_test.dart` |
| QA-18 | Solicitud local pendiente; remoto continúa fallando | Empleado simulado | Reintentar sincronización | Mantiene pendiente ante fallo temporal | Cero sincronizadas; una pendiente | Aprobado | 1.1.0+3 | `test/solicitud_repository_test.dart` |
| QA-19 | Widget de app con repositorios de prueba | N/A | Montar app y revisar inicio/navegación | Muestra inicio y destinos | Textos esperados y `NavigationBar` presentes | Aprobado | 1.1.0+3 | `test/widget_test.dart` |

## Casos que requieren Firebase o Android configurado

| ID | Caso manual | Evidencia a guardar | Estado |
|---|---|---|---|
| QA-20 | Registrar empleado, cerrar sesión, iniciar sesión y restaurar la sesión | Capturas de registro e inicio de sesión | Pendiente |
| QA-21 | Iniciar sesión con empleado, supervisor y bodega; confirmar acciones por rol | Captura de cada rol y su pantalla | Reportado por el equipo; evidencia pendiente |
| QA-22 | Empleado intenta consultar datos de otro UID o cambiar su rol | Resultado denegado por reglas de Firestore | Pendiente |
| QA-23 | Dos supervisores intentan reservar simultáneamente las últimas unidades | Una sola aprobación y stock no negativo | Pendiente |
| QA-24 | Aprobar una solicitud y entregar una parte | Saldo parcial e inventario reservado/físico correctos | Pendiente |
| QA-25 | Reintentar el mismo ID de operación de entrega | No duplica cantidades ni movimientos | Pendiente |
| QA-26 | Ajuste negativo que invade el stock reservado | Firestore rechaza el ajuste | Pendiente |
| QA-27 | Enviar el evento de prueba desde debug | Evento no fatal visible en Firebase Crashlytics | Pendiente |
| QA-28 | Instalar APK release y recorrer flujo con los tres roles | Versión, dispositivo y evidencia del recorrido | Pendiente |
| QA-29 | Elegir una categoría, salir y volver al catálogo | La preferencia de SharedPreferences se restaura | Pendiente |
| QA-30 | Cargar `firestore.rules` en el emulador local | El archivo compila sin errores | Aprobado |
| QA-31 | Instalar y abrir APK release con Firebase `insumosg62` | El paquete abre; Firebase Core y Crashlytics inicializan | Aprobado |
| QA-32 | Publicar `firestore.rules` en Firebase `insumosg62` | Confirmación de Firebase CLI: reglas compiladas y liberadas en `cloud.firestore` | Aprobado (2026-11-08) |
| QA-33 | Consultar el endpoint HTTP configurado en la app | Se reciben al menos ocho objetos JSON | Aprobado: 10 recibidos (2026-11-08) |

QA-32 se ejecutó el 2026-11-08 y Firebase confirmó `Deploy complete` para el proyecto `insumosg62`. QA-33 consultó el endpoint configurado en `lib/config/api_config.dart` y recibió diez registros. El equipo reporta que los tres perfiles pueden iniciar sesión y funcionan, pero falta adjuntar capturas para cerrar QA-21. Los escenarios de seis operaciones de negocio están descritos en [`ESCENARIOS_QA_MANUAL.md`](ESCENARIOS_QA_MANUAL.md); siguen pendientes de ejecución con cuentas y existencias de prueba. También falta verificar el evento en Crashlytics y el recorrido de release con evidencia.
