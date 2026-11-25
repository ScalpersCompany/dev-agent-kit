# Mejorar una skill

Una skill no se mejora con más prosa. Se mejora cuando cambia el mecanismo que demuestra
que el agente hizo lo correcto.

## El ciclo

1. **Detectar**: la misma corrección aparece dos veces en una revisión, un ticket o una
   sesión.
2. **Clasificar**: naming, capas, manejo de errores, acceso a Odoo, tests, copy o commits.
3. **Elegir el mecanismo más fuerte**: API/arquitectura, tipos, lint, CI, test; la
   documentación va al final.
4. **Editar `SKILL.md`**: disparador en la descripción, pasos observables, salida y
   criterio de fallo.
5. **Añadir un caso**: `evals/cases/<skill>/...` con un repositorio de prueba y una
   rúbrica de criterios observables.
6. **Validar en seco**: `dev-agent eval --dry-run`.
7. **Medir**: K=3 con un modelo aprobado y un juez distinto. Mira media, mínimo y
   dispersión; una corrida baja invalida una media alta.
8. **Cerrar**: actualiza `docs/SKILL-EVAL-COVERAGE.md`, el `CHANGELOG` y la formación si
   cambió el flujo.

## Reglas

- La skill es un procedimiento, no una lista de deseos.
- La descripción es el disparador; si no cabe en una frase, no está lista.
- No metas una skill en la puerta obligatoria hasta que tenga un caso y una medición.
- No nombres modelos internos en documentación, tickets ni capturas: usa
  `<modelo-aprobado>` y `<modelo-aprobado-distinto>`.
- Si una corrección se puede convertir en lint, test o CI, no la dejes en prosa.
- No cambies una skill y su rúbrica en el mismo commit sin una razón; no sabrás qué mejoró.

## Comandos

```bash
dev-agent eval --dry-run \
  --case-dir evals/cases/mi-skill/01-caso \
  --rubric evals/rubric.mi-skill.json

dev-agent eval \
  --case-dir evals/cases/mi-skill/01-caso \
  --rubric evals/rubric.mi-skill.json \
  --agent build \
  --model <modelo-aprobado> \
  --judge-model <modelo-aprobado-distinto> \
  --k 3
```

La mejora termina con una skill, un caso y evidencia; no con una opinión.
