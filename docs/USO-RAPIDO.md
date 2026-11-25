# Uso rápido

Comandos de cada día. El wrapper funciona desde la raíz del repo de desarrollo.

| Comando | Uso |
|---|---|
| `dev-agent doctor` | Ver qué está instalado, qué es opcional y qué falta. |
| `dev-agent guard` | Pasar las comprobaciones antes del commit. |
| `dev-agent verify` | Ejecutar el comportamiento real y dejar evidencia. |
| `dev-agent review` | Ver el diff y el prompt de la skill review-diff. |
| `dev-agent eval --dry-run` | Validar un caso de eval sin gastar modelo. |
| `dev-agent profile list` | Ver perfiles instalados y el activo. |
| `dev-agent profile use odoo11` | Cambiar el perfil activo. |
| `dev-agent codegraph` | Sincronizar el índice con el repo. |
| `dev-agent memory save "..." "..."` | Guardar una decisión o un bug en Engram. |

## Un cambio normal

```bash
git switch -c feat/mi-cambio
# implementar; tests y docs en el mismo cambio
dev-agent guard
dev-agent verify
git add ...
git commit -m "feat: ..."
```

El pre-commit ejecuta guard sobre lo staged. El pre-push ejecuta verify con
`.dev-agent/verify.env`; si no hay `TEST_CMD`, falla cerrado.

## Perfil

```bash
dev-agent profile list
dev-agent profile use odoo11
```

El perfil activo está en `.dev-agent/config`. Si guard dice `profile: skipped`, no hay
perfil activo o falta `.dev-agent/profiles/<nombre>`.

## Revisión

```bash
dev-agent review
```

Muestra el diff y el prompt. La revisión se pide al agente con la skill `review-diff`; el
agente no edita. La aprobación y el merge siguen siendo humanos.

## CodeGraph y Engram

```bash
dev-agent codegraph
dev-agent memory save "Decisión" "Qué se decidió y por qué" --type decision
```

CodeGraph indexa el repo; Engram guarda decisiones, bugs y contexto. Ninguno es una puerta.

## Evals

```bash
dev-agent eval \
  --case-dir evals/cases/dev-verify/01-fix-failing-test \
  --rubric evals/rubric.dev-verify.json \
  --agent build \
  --model <modelo-aprobado> \
  --judge-model <modelo-aprobado-distinto> \
  --k 3
```

Empieza con `--dry-run`. El harness sigue atado a OpenCode; es una deuda conocida.

## Documentación

- `docs/INSTALADOR.md`: instalación.
- `docs/FORMACION-DEV-AGENT-KIT.md`: formación de tres sesiones.
- `docs/MEJORAR-SKILLS.md`: cómo mejorar una skill sin romper el flujo.
- `docs/PERFILES-EN-REPOS.md`: contrato de perfiles.
