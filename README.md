# G62-4 · Solicitudes de insumos

Aplicación Android desarrollada con Flutter y Dart para solicitar insumos internos, aprobar solicitudes, reservar existencias y registrar entregas parciales. El flujo requiere una cuenta autenticada y usa Firebase para compartir cambios entre los roles.

## Estado actual

- **Empleado:** consulta el catálogo remoto, busca y filtra insumos, crea solicitudes de 1 a 5 insumos (1–20 unidades por línea), las consulta y cancela las que siguen solicitadas.
- **Supervisor:** consulta solicitudes de su área, aprueba o rechaza las solicitudes de otras personas. La aprobación reserva todas las líneas en una transacción Firestore.
- **Bodega:** crea el stock inicial, registra ajustes con motivo y actor, y hace entregas parciales. Una entrega actualiza el inventario reservado y físico en una transacción.
- **Autenticación:** registro e inicio de sesión con correo y contraseña. El registro crea un perfil de empleado. Los roles privilegiados se asignan desde Firebase Console.
- **Modo local:** las solicitudes se guardan primero en SQLite. Si no se confirma el envío remoto quedan pendientes; los reintentos solo consideran la cuenta activa. El catálogo conserva una copia local para consultas posteriores sin conexión.
- **Preferencias:** el filtro de categoría seleccionado se guarda en SharedPreferences y se restaura al volver a abrir el catálogo.
- **Diagnóstico:** Crashlytics captura excepciones no controladas. En modo debug aparece una opción para enviar un evento no fatal de prueba; no aparece en release.

El catálogo configurado es el conjunto público de medicamentos vigentes de INVIMA (`datos.gov.co`, 10 registros), usado como fuente HTTP de referencia. Si el equipo necesita otro tipo de insumos, debe cambiar la URL y el mapeo descritos abajo.

## Requisitos

- Flutter y Dart instalados, Android Studio con Android SDK y un emulador o teléfono Android.
- Proyecto Firebase `insumosg62` con **Authentication (correo/contraseña)**, **Cloud Firestore** y **Crashlytics** habilitados.
- Reglas de Firestore de este repositorio publicadas en ese proyecto.

## Configuración de Firebase

### CLI necesarias en Windows

`flutter pub add firebase_core firebase_auth cloud_firestore` instala paquetes de Dart; no instala los comandos `firebase` ni `flutterfire`.

1. Instala Firebase CLI. En Windows puedes usar el [ejecutable oficial independiente](https://firebase.google.com/docs/cli) y no necesitas instalar Node.js.
2. Abre PowerShell en la raíz del proyecto y autoriza tu cuenta:

   ```powershell
   firebase login
   firebase projects:list
   ```

   Confirma que aparezca `insumosg62` y que sea el proyecto al que tienes acceso.

3. Instala FlutterFire CLI una sola vez y agrega sus ejecutables al `PATH` del usuario:

   ```powershell
   dart pub global activate flutterfire_cli
   $env:Path += ";$env:LOCALAPPDATA\Pub\Cache\bin"
   flutterfire --version
   ```

   Después de agregar el `PATH` de forma permanente, cierra y vuelve a abrir PowerShell.

4. Desde la carpeta del proyecto, configura solo Android en el proyecto existente:

   ```powershell
   flutterfire configure --project=insumosg62 --platforms=android
   ```

   El paquete Android registrado debe ser `co.edu.udem.insumos_g62_4`. El proyecto ya contiene `.firebaserc`, `firebase.json`, `lib/firebase_options.dart` y `android/app/google-services.json` para `insumosg62`.

### Servicios en Firebase Console

1. En Firebase Console, habilita el proveedor **Correo electrónico/contraseña** en Authentication.
2. Comprueba que `android/app/google-services.json` y `lib/firebase_options.dart` correspondan al mismo proyecto Firebase y al identificador Android `co.edu.udem.insumos_g62_4`.
3. Publica `firestore.rules` desde la consola o con Firebase CLI (`firebase deploy --only firestore:rules`). No uses reglas abiertas de lectura/escritura.
4. Las cuentas que se registran desde la aplicación crean su perfil en `usuarios/{uid}` con rol `empleado` y área `General`. Para supervisores y bodega, crea o edita desde Firebase Console el documento con el UID de Authentication como ID. Ejemplo:

   ```json
   {
     "uid": "UID_DE_AUTHENTICATION",
     "correo": "persona@ejemplo.com",
     "rol": "supervisor",
     "area": "General"
   }
   ```

   El valor de `rol` solo puede ser `empleado`, `supervisor` o `bodega`. Usa la misma área para empleados y supervisores que deban compartir solicitudes.

5. La persona de bodega configura existencias desde la pestaña **Inventario**. Cada documento se guarda en `inventario/{insumoId}`; su ID debe coincidir exactamente con el ID del catálogo HTTP. La aplicación crea el primer stock y registra ajustes en `movimientos_inventario`.
6. Las reservas y entregas confirmadas deben hacerse con conexión. Crear una solicitud sí puede hacerse sin conexión después de iniciar sesión y cargar los datos necesarios.

No guardes contraseñas, claves privadas, cuentas de servicio ni contraseñas de firma dentro del repositorio. Las cuentas de prueba se comparten solo por el canal privado indicado por el docente.

## Ejecutar en Android

Desde la raíz del proyecto:

```powershell
flutter pub get
flutter emulators
flutter devices
flutter run -d <ID_DEL_DISPOSITIVO>
```

El ID se obtiene con `flutter devices` (por ejemplo `emulator-5554`). También puedes iniciar el emulador desde Android Studio > Device Manager.

## Catálogo HTTP

La URL está en `lib/config/api_config.dart`. El servicio `lib/services/insumo_http_service.dart` implementa timeout, falta de conexión, códigos HTTP no exitosos y JSON inválido; `InsumoRepository` coordina HTTP y copia local.

Mapeo principal del endpoint INVIMA:

- `producto` → nombre.
- `descripcioncomercial` → descripción.
- `unidadreferencia` (con campos alternativos) → unidad.
- `descripcionatc` (con campos alternativos) → categoría.
- `expedientecum` y `consecutivocum` → identificador.

Si el endpoint cambia, verifica también que los IDs sean estables, ya que Firestore los usa como IDs de documentos de inventario.

## Reglas del proceso

- Cada solicitud contiene de 1 a 5 insumos distintos; cada línea solicita de 1 a 20 unidades enteras.
- Una persona supervisora no aprueba solicitudes propias. Se conserva su UID y la fecha de decisión.
- La aprobación verifica disponibilidad y reserva todas las líneas en una transacción; no deja reservas parciales ni stock negativo.
- Cada entrega es positiva y no supera el saldo aprobado. El estado pasa a `ENTREGADA` solo cuando se completa todo; de lo contrario permanece `PARCIAL`.
- Un ajuste de inventario no puede reducir existencias por debajo de lo reservado y registra actor, fecha y motivo.
- Los roles, propiedad y acciones están protegidos por `firestore.rules`; ocultar botones en la interfaz no sustituye esas reglas.

## Pruebas y QA

```powershell
flutter analyze lib test
flutter test
```

La matriz y el estado de ejecución de casos están en [`docs/MATRIZ_QA.md`](docs/MATRIZ_QA.md). Las pruebas automatizadas cubren modelos, validación HTTP, persistencia local y reintentos. La verificación con tres cuentas Firebase, concurrencia real y consola Crashlytics debe completarse con la configuración Firebase del equipo.

## Crashlytics

Crashlytics se activa al iniciar Firebase. En una compilación debug, abre **Inicio** y toca **Probar evento de Crashlytics**. Confirma que aparece un evento no fatal en Firebase Console > Crashlytics desde el dispositivo/emulador de prueba. Esta opción está excluida de la compilación release. La aplicación no envía contraseñas ni tokens como información de diagnóstico.

## APK release

La versión del artefacto está en `pubspec.yaml`. Para generar e instalar el APK académico:

```powershell
flutter build apk --release
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

El APK se compila con la firma de desarrollo configurada en Gradle. Para la entrega académica no se necesita una clave de producción ni publicar en una tienda. Después de cada nueva compilación de entrega, aumenta el número `+build` y actualiza la versión que figure en la matriz QA.

## Estructura

```text
lib/
├── config/          endpoint del catálogo
├── database/        SQLite para catálogo y solicitudes pendientes
├── local/           copia local del catálogo
├── models/          insumos, líneas, solicitudes y perfiles
├── remote/          operaciones y transacciones Firestore
├── repositories/    coordinación de datos locales y remotos
├── screens/         autenticación, catálogo, creación y operación por rol
└── services/        HTTP y autenticación
```
