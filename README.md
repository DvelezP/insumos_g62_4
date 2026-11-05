# G62-4: Solicitudes de insumos

Aplicación móvil desarrollada con Flutter y Dart para consultar un catálogo y crear solicitudes internas de insumos. El proyecto está preparado para ejecutarse en Android.

## Requisitos

- Flutter y Dart instalados.
- Android Studio con Android SDK y al menos un emulador Android configurado, o un teléfono Android con depuración USB habilitada.
- Visual Studio Code o Android Studio para editar el proyecto.

## Ejecutar en Android

Desde la carpeta del proyecto:

```powershell
flutter doctor
flutter pub get
flutter emulators
```

Si aparece el emulador `Pixel_8`, se puede iniciar así:

```powershell
flutter emulators --launch Pixel_8
flutter devices
```

Cuando el emulador aparezca en la lista de dispositivos, ejecuta la app usando su identificador. Por ejemplo:

```powershell
flutter run -d emulator-5554
```

El identificador puede variar. Usa el que muestre `flutter devices`. También puedes seleccionar el emulador desde **Device Manager** de Android Studio. Para un teléfono, activa las opciones de desarrollador y la depuración USB, conéctalo al computador y confirma que aparezca con `flutter devices`.

El proyecto actual no tiene configurados los destinos Web ni Windows. Para probarlo, usa un emulador o dispositivo Android.

## Funciones implementadas

- Pantalla inicial con navegación a Inicio, Insumos y Solicitudes.
- Catálogo remoto de medicamentos vigentes publicado por INVIMA, con búsqueda y filtro por categoría.
- Búsqueda HTTP con tiempo límite y mensajes para falta de conexión, errores del servidor y JSON inválido.
- Copia local del catálogo en SQLite. Si falla una consulta posterior, la app intenta mostrar la última copia guardada.
- Creación local de solicitudes desde el catálogo. Cada solicitud puede tener de 1 a 5 insumos distintos y cada línea permite solicitar de 1 a 20 unidades.
- Guardado de solicitudes en SQLite, estado inicial `SOLICITADA` y estado de sincronización `PENDIENTE`.
- Vista de las solicitudes guardadas para el usuario de demostración.
- Sincronización de solicitudes con Cloud Firestore. Cada solicitud se guarda primero en SQLite y luego se envía a la colección `solicitudes`; si Firestore no responde, queda `PENDIENTE` y se puede reintentar desde **Mis solicitudes**.

La API de INVIMA es un catálogo de medicamentos. Si el caso del equipo requiere otra clase de insumos, se debe acordar y configurar un endpoint que corresponda al dominio del proyecto.

## Configuración del catálogo HTTP

La URL está definida en `lib/config/api_config.dart`:

```dart
const String kInsumosUrl =
    'https://www.datos.gov.co/resource/i7cb-raxc.json?%24limit=10';
```

El servicio está en `lib/services/insumo_http_service.dart`. Mapea los campos de INVIMA al modelo `Insumo`:

- `producto` → nombre.
- `descripcioncomercial` → descripción.
- `unidadreferencia` (o campos alternativos) → unidad.
- `descripcionatc` (o campos alternativos) → categoría.
- `expedientecum` y `consecutivocum` → identificador cuando están disponibles.

El repositorio `lib/repositories/insumo_repository.dart` coordina la consulta HTTP y la copia local. Si se cambia la URL, revisa también el mapeo de campos del servicio para que coincida con la respuesta JSON.

## Sincronización con Firestore

Firebase se inicializa en `main.dart` dentro de un `try/catch`. Si no inicia, la app sigue funcionando con los datos locales y las solicitudes quedan pendientes.

El flujo de `SolicitudRepository` es:

1. Guarda la solicitud en SQLite con `syncState = PENDIENTE`.
2. Intenta escribirla en Firestore con `SolicitudRemoteDataSource` (tiempo límite de 8 segundos).
3. Si Firestore confirma, cambia `syncState` a `SINCRONIZADA`. Si falla, la deja `PENDIENTE` y guarda el motivo en `lastError`, sin mostrar un error al usuario.
4. `sincronizarPendientes()` reintenta solo las solicitudes pendientes y devuelve cuántas se enviaron y cuántas siguen pendientes.

El id de la solicitud se usa como id del documento y la escritura usa `SetOptions(merge: true)`, así que reenviar una solicitud actualiza el mismo documento en lugar de duplicarlo.

Las reglas de Firestore están en `firestore.rules`. Son temporales: permiten leer y escribir solo la colección `solicitudes` hasta el 15 de diciembre de 2026, mientras se implementa Firebase Authentication.

## Organización principal

```text
lib/
├── config/          URL del catálogo
├── database/        inicialización y tablas SQLite
├── local/           acceso local al catálogo
├── models/          Insumo, LineaSolicitud y Solicitud
├── remote/          escritura de solicitudes en Firestore
├── repositories/    coordinación de datos
├── screens/         inicio, catálogo y creación de solicitudes
└── services/        consulta HTTP
```

## Comprobaciones

```powershell
flutter analyze lib
flutter test
```

La prueba de widget comprueba la pantalla inicial. `test/solicitud_repository_test.dart` comprueba la sincronización con una base SQLite en memoria y un Firestore simulado: solicitud sincronizada, solicitud pendiente cuando Firestore falla o no está configurado, reintento de pendientes y que las solicitudes ya sincronizadas no se reenvían. No se deben considerar estas comprobaciones como evidencia de que el APK release esté instalado y recorrido.

## Alcance todavía pendiente

Este estado del proyecto usa el identificador fijo `empleado-demo-001`. Aún no están implementados Firebase Authentication, los tres roles, reglas de seguridad por usuario, aprobación o rechazo, reservas de stock, entregas parciales ni ajustes de inventario. Firestore por ahora solo recibe las solicitudes creadas. Tampoco se ha entregado un APK release, una matriz QA o evidencia de Crashlytics.
