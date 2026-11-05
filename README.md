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

## Organización principal

```text
lib/
├── config/          URL del catálogo
├── database/        inicialización y tablas SQLite
├── local/           acceso local al catálogo
├── models/          Insumo, LineaSolicitud y Solicitud
├── repositories/    coordinación de datos
├── screens/         inicio, catálogo y creación de solicitudes
└── services/        consulta HTTP
```

## Comprobaciones

```powershell
flutter analyze lib
flutter test
```

La prueba de widget actual comprueba la pantalla inicial. No se deben considerar estas comprobaciones como evidencia de que el APK release esté instalado y recorrido.

## Alcance todavía pendiente

Este estado del proyecto usa el identificador fijo `empleado-demo-001`. Aún no están implementados Firebase Authentication, los tres roles, Firestore, reglas de seguridad, aprobación o rechazo, reservas de stock, entregas parciales, ajustes de inventario ni la sincronización de pendientes. Tampoco se ha entregado un APK release, una matriz QA o evidencia de Crashlytics.
