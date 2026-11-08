# Matriz QA · G62-4

Versión de código: **1.1.0+3**. Ejecución automatizada en entorno local con `flutter test --reporter expanded`: **19 pruebas aprobadas**. El análisis `flutter analyze lib test` no reportó problemas. `firestore.rules` también se compiló sin errores en el emulador local de Firestore.

## Casos automatizados ejecutados

| ID | Caso | Resultado esperado | Estado |
|---|---|---|---|
| QA-01 | Solicitar 1 unidad y el máximo de 20 | Ambas cantidades son aceptadas | Aprobado |
| QA-02 | Solicitar 0 o 21 unidades | El modelo rechaza la línea | Aprobado |
| QA-03 | Entregar más de lo solicitado | El modelo rechaza la cantidad | Aprobado |
| QA-04 | Solicitud con cinco insumos distintos | Se acepta la solicitud | Aprobado |
| QA-05 | Solicitud vacía, con seis líneas o insumo repetido | El modelo rechaza la solicitud | Aprobado |
| QA-06 | Convertir solicitud a JSON y reconstruirla | Estado, área, aprobador y líneas se conservan | Aprobado |
| QA-07 | HTTP 200 con JSON INVIMA válido | Los campos se mapean al modelo `Insumo` | Aprobado |
| QA-08 | HTTP 500 | Se devuelve un error legible del servicio | Aprobado |
| QA-09 | HTTP 200 con JSON malformado | Se devuelve un error controlado | Aprobado |
| QA-10 | Petición HTTP excede el tiempo límite | Se informa timeout controlado | Aprobado |
| QA-11 | Cliente HTTP sin conexión | Se informa falta de red | Aprobado |
| QA-12 | Guardar solicitud con remoto disponible | Se conserva localmente y queda sincronizada | Aprobado |
| QA-13 | Firestore falla al guardar | La solicitud queda local y pendiente | Aprobado |
| QA-14 | Repositorio sin Firestore | La solicitud permanece pendiente | Aprobado |
| QA-15 | Reintentar solicitudes pendientes | Se sincronizan y se actualiza su estado | Aprobado |
| QA-16 | Reintentar solicitudes ya sincronizadas | No se reenvían | Aprobado |
| QA-17 | Sincronizar con otra cuenta activa | No se envían pendientes de otras cuentas | Aprobado |
| QA-18 | Firestore continúa fallando en el reintento | Se mantienen pendientes | Aprobado |
| QA-19 | Abrir app y navegar por pantalla inicial | Inicio y destinos principales aparecen | Aprobado |

## Casos que requieren Firebase o Android configurado

| ID | Caso manual | Evidencia a guardar | Estado |
|---|---|---|---|
| QA-20 | Registrar empleado, cerrar sesión, iniciar sesión y restaurar la sesión | Capturas de registro e inicio de sesión | Pendiente |
| QA-21 | Iniciar sesión con empleado, supervisor y bodega; confirmar acciones por rol | Captura de cada rol y su pantalla | Pendiente |
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

Los casos pendientes no se marcan como aprobados porque requieren cuentas, existencias y servicios reales del proyecto Firebase, además de un dispositivo Android. El evento no fatal y las pruebas de transacciones se deben ejecutar antes de presentar la evidencia final.
