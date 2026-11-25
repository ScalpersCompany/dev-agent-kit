# Uso rápido

Comandos de cada día. El wrapper funciona desde la raíz del repo de desarrollo.

| Comando | Uso |
|---|---|
| `dev-agent doctor` | Ver qué está instalado, qué es opcional y qué falta. |
| `dev-agent guard` | Pasar las comprobaciones antes del commit. |
| `dev-agent verify` | Ejecutar comportamiento real, tests y E2E, y dejar evidencia. |
| `dev-agent review` | Ver el diff y el prompt de la skill review-diff. |
| `dev-agent review-gga` | Revisión GGA bloqueante; `--advisory` solo informa. |
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
`.dev-agent/verify.env`; si no hay `TEST_CMD` ni `E2E_CMD`, falla cerrado. El E2E de
Playwright se ejecuta con `E2E_CMD="npm --prefix e2e test"` y deja el informe y las trazas
en `evidence/<run-id>/e2e/`.

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

## Revisión GGA

```bash
dev-agent review-gga
dev-agent review-gga --advisory
```

La revisión es bloqueante por defecto: exige `STATUS: PASSED` y salida 0. Las reglas del
núcleo son agnósticas de lenguaje; el perfil activo añade su `gga/REVIEW-RULES.md` (Odoo 11,
PHP 8 o hexagonal), y la norma de empresa sigue ganando. Si no hay `gga` o `.gga`, falla
cerrada. Para instalarlo:

```bash
bash scripts/install-gga.sh . --profile "$HOME/dev-agent-profiles/profiles/odoo11"
bash scripts/install-gga.sh . --profile "$HOME/dev-agent-profiles/profiles/odoo11" --with-pre-push
```

`--with-pre-push` ejecuta GGA después de verify; el hook sigue siendo local y `--no-verify`
no sustituye al CI.

## Evals

```bash
dev-agent eval \
  --case-dir evals/cases/dev-verify/01-fix-failing-test \
  --rubric evals/rubric.dev-verify.json \
  --agent claude \
  --judge-agent opencode \
  --model <modelo-aprobado> \
  --judge-model <modelo-aprobado-distinto> \
  --k 3
```

`--agent` acepta `opencode`, `claude`, `codex`, `pi` o `hermes`. `--agent build` sigue
funcionando como alias de OpenCode con el perfil `build`. Empieza con `--dry-run`.

## Documentación

- `docs/INSTALADOR.md`: instalación.
- `docs/FORMACION-DEV-AGENT-KIT.md`: formación de tres sesiones.
- `docs/MEJORAR-SKILLS.md`: cómo mejorar una skill sin romper el flujo.
- `docs/PERFILES-EN-REPOS.md`: contrato de perfiles.
