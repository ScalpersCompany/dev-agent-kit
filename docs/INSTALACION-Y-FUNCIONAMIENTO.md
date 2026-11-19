# Instalación y funcionamiento

Esta es la guía del núcleo. Explica cómo se instala, cómo se ejecuta cada puerta y qué
está implementado frente a lo que sigue siendo diseño. El kit no se despliega en
producción: filtra el código que llega a la base de desarrollo. El perfil de Odoo 11 está
en `dev-agent-profiles/profiles/odoo11`; el núcleo no contiene Odoo ni PHP.

## 1. Qué es y qué no es

`dev-agent-kit` tiene cuatro piezas:

- **guard**: comprobaciones deterministas sobre el cambio.
- **verify**: arranca el entorno, comprueba salud, ejecuta smoke y tests, y deja evidencia.
- **evals**: mide una skill o una regla de revisión con un caso, K ejecuciones y un juez
  distinto del modelo que ejecuta.
- **skills y AGENTS.md**: procedimientos y reglas que el agente lee antes de tocar código.

No es un servicio, no despliega, no toca producción y no decide el alcance de una tarea.
El agente es intercambiable; la puerta es un comando.

## 2. Requisitos

- Linux, macOS o Windows con WSL; bash.
- Python 3.8 o superior.
- git.
- Un agente: Hermes, OpenCode, Claude Code, Codex o pi.
- Opcional: Docker, Node, `gga`, `gentle-ai`.
- Un proveedor de modelo aprobado para evals y GGA. No se usa un endpoint personal ni se
  guardan claves en el repo.

## 3. Instalación del núcleo

### 3.1 Automatizada (recomendada)

Desde el kit:

```bash
bash scripts/bootstrap.sh /ruta/al/repo
bash scripts/bootstrap.sh /ruta/al/repo --with-verify
bash scripts/bootstrap.sh /ruta/al/repo --with-gga
```

Copia `AGENTS.md`, `.opencode/`, `verify/`, `guard/`, `evals/`, `scripts/` y `docs/`;
respalda lo que reemplaza como `.bak-<fecha>`; crea `verify/config.env` desde el ejemplo e
instala el `pre-commit`. `--with-verify` añade el `pre-push` y `.dev-agent/verify.env`;
`--with-gga` añade los ficheros de GGA. No toca producción, el historial de git ni un
registro de perfiles.

### 3.2 Manual (respaldo)

```bash
git clone git@github.com:nramosscalpers/dev-agent-kit.git ~/dev-agent-kit
cd /ruta/al/repo-de-desarrollo
cp -a ~/dev-agent-kit/AGENTS.md .
cp -a ~/dev-agent-kit/.opencode .
cp -a ~/dev-agent-kit/verify .
cp -a ~/dev-agent-kit/guard .
cp -a ~/dev-agent-kit/evals .
cp -a ~/dev-agent-kit/scripts .
cp -a ~/dev-agent-kit/docs .
```

No copies `verify/config.env`, `evidence/`, `guard-report.json` ni `evals/runs/`. Si el
repo ya tiene `AGENTS.md` o `.opencode`, fusiona.

### 3.3 Configurar verify

```bash
cp verify/config.env.example verify/config.env
```

Rellena `BOOT_CMD`, `HEALTH_URL`, `SMOKE_CMD`, `TEST_CMD` y `HEALTH_TIMEOUT`. Después:

```bash
bash verify/run.sh
```

`verify` deja `evidence/<run-id>/summary.json`. Sale 0 si todo pasa, 1 si falla y 2 si no
hay configuración. Un 2 no es verde.

### 3.4 Instalar hooks

```bash
bash scripts/install-hooks.sh .
```

Instala el `pre-commit`: ejecuta `guard/guard.sh --staged` sobre los ficheros del commit.
El informe queda en `.git/guard-report.json`; un hook existente se respalda.

Para el `pre-push`:

```bash
bash scripts/install-hooks.sh . --with-verify
```

Copia `.dev-agent/verify.env` y falla cerrado hasta que tenga un `TEST_CMD` real.

### 3.5 Instalar GGA (opcional)

```bash
bash scripts/install-gga.sh .
# edita .gga y elige PROVIDER=claude, opencode, codex, ollama:<modelo>...
bash scripts/review-gga.sh . --ci
```

`GGA_ADVISORY=1` informa sin bloquear. No ejecutes `gga install`: pisaría el pre-commit del
kit. Sin proveedor o sin `.gga`, no se declara verde.

### 3.6 Skills en los agentes

- Hermes: `~/.hermes/skills/`.
- OpenCode: `~/.config/opencode/skills/`.
- Claude Code: `~/.claude/skills/`.
- Codex: `~/.codex/AGENTS.md` y sus rutas.
- pi/gentle-shell: su directorio de skills.
- Base compartida: `~/.agents/skills/`.

La norma global vive en `~/.agents/AGENTS.md`; `SOUL.md`, `AGENTS.md` de OpenCode y
`CLAUDE.md` apuntan a ella. `gentle-ai sync` distribuye skills y MCP; no sustituye a
`guard` ni a `verify`.

## 4. Uso diario

1. Rama `feat/`, `fix/` o `hotfix/`; nunca en la rama por defecto.
2. Leer `AGENTS.md`, la issue y el `AGENTS.fragment.md` del perfil activo.
3. Reproducir el bug con un test que falle primero.
4. Implementar: cambio, tests y documentación en el mismo commit.
5. Guard: `bash guard/guard.sh` o el hook.
6. Verify: `bash verify/run.sh`; adjunta `summary.json`.
7. Eval: solo si cambia una skill, prompt, regla o rúbrica.
8. Revisión humana y política del repo.

## 5. Guard

`guard/guard.sh` ejecuta ruff, black, mypy, eslint, tsc, gitleaks, `comment_lint` y, si hay
perfil activo, los `guard/*.sh` del perfil. En `--staged` solo mira lo que entra en el
commit. Un `skipped` no es un `pass`; se dice por qué.

El perfil Odoo añade `sudo()`, `cr.commit()`, SQL crudo y `print()`; sus reglas están en
`dev-agent-profiles/profiles/odoo11`.

## 6. Evals

```bash
python3 evals/harness.py \
  --case-dir evals/cases/dev-verify/01-fix-failing-test \
  --rubric evals/rubric.dev-verify.json \
  --agent build \
  --model <modelo-aprobado> \
  --judge-model <modelo-aprobado-distinto> \
  --k 3
```

Cada ejecución va en un worktree o copia desechable. El juez recibe los artefactos y el
`context.json`. El umbral es 8,5; `--dry-run` valida el caso sin gastar modelo. `score.json`
incluye scores, media, mínimo, máximo, desviación, tokens, coste, aislamiento y `passed`.

La línea base del núcleo está en `docs/EVAL-BASELINE.md`; la del perfil Odoo, en
`dev-agent-profiles/profiles/odoo11/docs/EVAL-BASELINE.md`.

## 7. Perfil Odoo 11

El perfil vive en `dev-agent-profiles/profiles/odoo11`:

- `guard/odoo.sh` y `guard/odoo_lint.py`;
- `verify/config.env.example` con base desechable;
- skills `odoo-safe-change`, `odoo-11-code-review`, `factorlibre-mr-preflight`;
- casos y rúbricas de Odoo y FactorLibre;
- `AGENTS.fragment.md` con las reglas de Odoo 11.

Para usarlo, copia el perfil a `.dev-agent/profiles/odoo11` (o `profiles/odoo11`) y escribe
`.dev-agent/config` con `DEV_AGENT_PROFILE=odoo11`. El `guard.sh` del núcleo ejecutará
`guard/odoo.sh`. El instalador `dev-agent init` que hará esto automáticamente está
diseñado, no implementado.

## 8. Qué está implementado y qué es diseño

Implementado:

- guard genérico, `comment_lint`, verify, evals y hooks;
- cinco skills core;
- GGA opcional;
- perfil Odoo extraído localmente con sus tests y casos;
- `guard.sh` con carga de perfil.

Diseño o migración pendiente:

- repo remoto privado de perfiles y `dev-agent init/use/profiles/doctor`;
- lock de perfiles;
- PHP como perfil real (hoy esqueleto);
- `comment_lint` para `.php`;
- cableado de `gentle-ai sync`, `rsc-harness`, `rsc-brain` y `engram` en el flujo diario;
- instalación automática del perfil desde el bootstrap.

## 9. Seguridad

- Producción no se toca; nada destructivo sin autorización.
- Sin secretos, tokens ni datos de cliente en código, tests, logs, commits o documentación.
- Verify usa base desechable; nunca la base `scalpers`.
- Los hooks se pueden saltar con `--no-verify`; el CI es la garantía dura. El CI de Scalpers
  no se toca.

## 10. Problemas frecuentes

- **`verify` sale 2**: falta `SMOKE_CMD` o `TEST_CMD`; no es verde.
- **`guard` sale con `skipped`**: falta herramienta o configuración; se dice.
- **El pre-push falla cerrado**: falta `.dev-agent/verify.env` o `TEST_CMD`.
- **El perfil no se ejecuta**: `.dev-agent/config` no define `DEV_AGENT_PROFILE` o el
  directorio del perfil no está en `.dev-agent/profiles/<nombre>` ni `profiles/<nombre>`.
- **GGA no revisa**: falta `PROVIDER`, `.gga` o autenticación del CLI.
- **`comment_lint` marca una cabecera**: solo se permiten cabeceras legales; si no, es un
  comentario y se quita.

## 11. Documentos relacionados

- `docs/ARQUITECTURA-ENTORNOS.md`: capas y límites.
- `docs/PERFILES-EN-REPOS.md`: perfiles, registro, instalador y lock.
- `docs/OPERATIONS.md`: flujo, hooks, GGA y skills.
- `docs/DEV-BASE.md`: qué cubre el núcleo.
- `docs/EVAL-BASELINE.md`: línea base core.
- `docs/SKILL-EVAL-COVERAGE.md`: skills core.
- `CHANGELOG.md`.
