# Escenarios manuales de QA · G62-4

Este guion prepara seis operaciones del proceso para ejecutarlas desde la app con los tres perfiles. Las operaciones deben hacerse con insumos y solicitudes de prueba identificables. No usar inventario de trabajo real.

## Datos de prueba

- La API configurada en `lib/config/api_config.dart` devolvió **10 registros** el 2026-11-08; cumple el mínimo de ocho.
- Selecciona un insumo del catálogo y registra su ID exacto. Bodega debe crear existencias para ese ID antes de probar reservas y entregas.
- Usa tres cuentas de prueba ya configuradas: empleado, supervisor y bodega. El supervisor debe compartir área con el empleado.
- Para la prueba de concurrencia, prepara dos solicitudes distintas y existencias suficientes para que, juntas, compitan por el último saldo disponible.

## Seis operaciones del negocio

| N.º | Actor y acción | Preparación / pasos | Resultado esperado |
|---|---|---|---|
| 1 | Empleado crea solicitud | En catálogo, elige 1–5 insumos distintos y cantidades entre 1 y 20; envía una solicitud. | Aparece en sus solicitudes como `SOLICITADA`; si no hay red, queda local pendiente y no se muestra como aprobada remotamente. |
| 2 | Supervisor aprueba solicitud de otra persona | Inicia sesión como supervisor del área y aprueba la solicitud 1. | Estado `APROBADA`; quedan registrados aprobador y fecha. Se reserva todo el stock en una sola transacción. |
| 3 | Supervisor rechaza solicitud | El empleado crea una segunda solicitud; el supervisor la rechaza e ingresa el motivo requerido. | Estado `RECHAZADA`, con aprobador, fecha y motivo; no se reserva inventario. |
| 4 | Bodega entrega parcialmente | Para una solicitud aprobada, bodega entrega una cantidad positiva menor al saldo pendiente de una línea. | Estado `PARCIAL`; cantidades entregadas y saldo reservado se actualizan correctamente. |
| 5 | Bodega completa entrega y reintenta | Entrega el saldo restante. Repite el envío usando el mismo ID de operación si se está probando un reintento por error de red. | Estado `ENTREGADA`; el reintento no duplica movimientos ni cantidades. |
| 6 | Bodega intenta ajuste inválido | Con una cantidad reservada, intenta reducir existencias por debajo de esa reserva y proporciona un motivo. | El ajuste se rechaza; existencias y reserva conservan sus valores anteriores. |

## Concurrencia de reservas

Es un escenario adicional de aceptación, separado de las seis operaciones anteriores:

1. Bodega configura un saldo conocido para un insumo de prueba.
2. Dos solicitudes de empleados distintos compiten por ese saldo, de modo que solo una puede aprobarse por completo.
3. Dos supervisores intentan aprobarlas casi simultáneamente.
4. Comprueba en Firestore que solo una reserva fue confirmada y que `reservado` nunca supera `existencias`. La otra solicitud debe quedar sin aprobación de reserva y mostrar un resultado claro.

## Evidencia que se debe guardar

Para cada ejecución, anota fecha, versión de app, rol/cuenta de prueba (sin contraseña), ID de solicitud/insumo, pasos, resultado esperado, resultado obtenido y estado. Adjunta capturas de las pantallas y, para las operaciones remotas, de los documentos de Firestore pertinentes. Si algo falla, registra el defecto y vuelve a ejecutar el caso después de corregirlo; no lo marques aprobado antes.
