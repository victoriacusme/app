# 0002. Bloc para el estado, frente a Riverpod

**Estado:** aceptada

**En pocas palabras:** uso Bloc para manejar el estado de las pantallas
porque deja cada paso de un flujo escrito de forma explícita, y eso es lo
que necesito en el login y en las transferencias.

## Contexto
Los flujos más delicados de la app, como el login y la transferencia, son
una secuencia de pasos con errores bien definidos. Quería que cualquiera
pudiera leer esos pasos en el código, revisarlos y probarlos sin esfuerzo.

## Decisión
Uso `flutter_bloc`:

- **Bloc** cuando llegan eventos y necesito controlar qué pasa si se
  repiten. Por ejemplo, con `droppable` un doble toque en "Confirmar" no
  envía dos transferencias, y con `restartable` un refresco nuevo cancela
  el anterior.
- **Cubit** (la versión simple de Bloc) para estados sencillos, como los
  ajustes o la conectividad.
- **`bloc_test`** para probar cada transición de estado.

## Alternativas
- **Riverpod:** menos código y muy buena composición, pero los flujos con
  eventos y control de concurrencia quedan menos visibles.
- **`setState` o `ChangeNotifier`:** se quedan cortos para flujos de
  dinero.

## Consecuencias
- Escribo más código (eventos y estados), pero a cambio las transiciones
  se leen como una especificación:
  `Editing → Confirming → Submitting → Success | Rejected | Unknown`.
- Cada sección del home tiene su propio Bloc, así que si falla el servicio
  de una sección, solo esa sección se degrada.
