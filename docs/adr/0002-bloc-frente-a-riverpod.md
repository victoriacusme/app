# 0002. Bloc para el estado, frente a Riverpod

**Estado:** aceptada

## Contexto
Los flujos críticos (login, transferencia) son máquinas de estados con
pasos y errores bien definidos, y deben ser auditables y fáciles de probar.

## Decisión
`flutter_bloc`: Bloc cuando hay eventos con concurrencia que controlar
(p. ej. `droppable` para que un doble toque en "Confirmar" no envíe dos
transferencias, `restartable` para refrescos) y Cubit para estados simples.
`bloc_test` para probar transiciones.

## Alternativas
- **Riverpod**: menos código y muy buena composición, pero los flujos con
  eventos y transformadores de concurrencia quedan menos explícitos.
- **setState / ChangeNotifier**: insuficiente para flujos de dinero.

## Consecuencias
- Más código repetitivo (eventos, estados), a cambio de transiciones
  explícitas que se leen como una especificación
  (`Editing → Confirming → Submitting → Success | Rejected | Unknown`).
- Cada sección del home tiene su propio Bloc, lo que permite que se degrade
  sola cuando falla su servicio.
