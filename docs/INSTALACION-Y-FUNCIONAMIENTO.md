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

### 2.1 Repos que se usan juntos

| Repo | Papel | Cómo se usa |
|---|---|---|
| `ScalpersCompany/dev-agent-kit` | Puerta, hooks, skills, evals | Se clona; es el núcleo |
| `ScalpersCompany/dev-agent-profiles` | Perfiles Odoo 11 y PHP | Se clona aparte; se instala el perfil activo |
| `ScalpersCompany/scalpers-tech-doc` | Norma y documentación de empresa | Se clona aparte; su `AGENTS.md` se enlaza en `~/.agents/AGENTS.md` |
| El repo donde se desarrolla | Código de producto (Odoo, PHP, cualquier stack) | Se instala el kit y el perfil activo en su raíz; no se clona desde el kit |

No se usa un submódulo. Antes de instalar un perfil o dar una norma por buena, comprueba
tech-doc:

```bash
bash scripts/check-techdoc.sh \
  --path ~/odoo-doodba-template/scalpers-tech-doc \
  --branch main --require-link
```

Si el check falla por árbol sucio, la norma no es reproducible: se cierra el cambio en el
repo de empresa. `--allow-dirty` solo sirve para una revisión local. La integración
completa está en `docs/INTEGRACION-TECHDOC.md`.

## 3. Instalación del núcleo

### 3.1 Instalador único (recomendada)

El instalador pregunta el repo, el perfil o perfiles, el perfil activo, los agentes y los
extras. Instala el kit, el perfil, todas las skills, los hooks, guard/verify, CodeGraph,
Engram y la referencia a tech-doc.

```bash
git clone https://github.com/ScalpersCompany/dev-agent-kit.git "$HOME/.dev-agent-kit" \
  && "$HOME/.dev-agent-kit/install.sh"
```

La guía corta está en `docs/INSTALADOR.md`; el uso diario, en `docs/USO-RAPIDO.md`.

### 3.1.1 Bootstrap (nivel inferior)

El bootstrap sigue disponible para automatizar una parte sin el menú:

```bash
bash scripts/bootstrap.sh /ruta/a/tu/repo \
  --profile odoo11 \
  --with-verify \
  --with-techdoc \
  --build-techdoc-html
```

- `--profile odoo11` copia el perfil desde `dev-agent-profiles` a
  `.dev-agent/profiles/odoo11` y escribe `.dev-agent/config`. El `verify/config.env` real
  del perfil no se copia.
- `--with-techdoc` clona `ScalpersCompany/scalpers-tech-doc` si no existe, enlaza
  `~/.agents/AGENTS.md` y crea `docs/TECHDOC.md` con la referencia.
- `--build-techdoc-html` ejecuta `make single-html` en el libro de metodología. Requiere
  Docker; si falla, deja la referencia y el comando.
- El enlace `docs/techdoc.html` es local y está en `.git/info/exclude`; el HTML no se
  versiona.

Si no hay acceso al repo privado de tech-doc, el kit sigue instalado y el bootstrap avisa.
Se puede pasar `--techdoc-path` con un clon existente.

### 3.1.2 Sin tech-doc

```bash
bash scripts/bootstrap.sh /ruta/a/tu/repo --profile odoo11 --with-verify
```

La puerta y el perfil funcionan sin tech-doc; la norma canónica de empresa no estará
enlazada hasta que se clone.

La versión mínima, sin perfil ni tech-doc, sigue siendo:

```bash
bash scripts/bootstrap.sh /ruta/a/tu/repo --with-verify
```

Copia `AGENTS.md`, `skills/`, `commands/`, `agents/`, `verify/`, `guard/`, `evals/`,
`scripts/`, `docs/` y `profiles/` (plantilla); respalda lo que reemplaza como
`.bak-<fecha>`; crea `verify/config.env` desde el ejemplo e instala el `pre-commit`.
`--with-verify` añade el `pre-push` y `.dev-agent/verify.env`; `--with-gga` añade los
ficheros de GGA; `--profile` instala el perfil activo. No toca producción, el historial de
git ni un registro de perfiles.

### 3.2 Manual (respaldo)

```bash
git clone git@github.com:ScalpersCompany/dev-agent-kit.git ~/dev-agent-kit
cd /ruta/al/repo-de-desarrollo
cp -a ~/dev-agent-kit/AGENTS.md .
cp -a ~/dev-agent-kit/skills .
cp -a ~/dev-agent-kit/commands .
cp -a ~/dev-agent-kit/agents .
cp -a ~/dev-agent-kit/verify .
cp -a ~/dev-agent-kit/guard .
cp -a ~/dev-agent-kit/evals .
cp -a ~/dev-agent-kit/scripts .
cp -a ~/dev-agent-kit/docs .
```

No copies `verify/config.env`, `evidence/`, `guard-report.json` ni `evals/runs/`. Si el
repo ya tiene `AGENTS.md`, fusiónalo. Los adaptadores `.opencode/` o `.claude/` se generan
con `bash scripts/install-agent-adapters.sh . --agents opencode,claude --profile /ruta/dev-agent-profiles/profiles/odoo11`; en el kit están ignorados, pero el repo destino no recibe un `.gitignore` del script: añádelos a `.git/info/exclude` o commitéalos a propósito.

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
El harness y `evals/loop.sh` todavía invocan OpenCode; el runner neutral está pendiente.

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
`guard/odoo.sh`. `scripts/bootstrap.sh --profile odoo11` ya copia el perfil y escribe
`.dev-agent/config`; `install.sh` es el instalador completo actual; `dev-agent init` y el
lock siguen pendientes.

Para crear otro perfil: `profiles/_template`, `scripts/new-profile.sh <nombre> --language
<lenguaje> --repo <repo-de-perfiles>` y `scripts/validate-profile.py <perfil>`; la guía
completa está en `docs/CREAR-PERFIL.md`. El mapa visual del sistema está en
`docs/diagrams/sistema.html` y `docs/DIAGRAMA-SISTEMA.md`.

## 8. Qué está implementado y qué es diseño

Implementado:

- guard genérico, `comment_lint`, verify, evals y hooks;
- cinco skills core;
- GGA opcional;
- perfil Odoo extraído localmente con sus tests y casos;
- `guard.sh` con carga de perfil.

Diseño o migración pendiente:

- repo de perfiles y `dev-agent init/use/profiles/doctor`;
- lock de perfiles;
- PHP como perfil real (hoy esqueleto);
- `comment_lint` para `.php`;
- cableado de `gentle-ai sync`, `rsc-harness` y `engram` en el flujo diario; `engram` en local hasta que exista la infraestructura AWS;
- instalación automática del perfil desde el bootstrap.

## 9. Formación

La guía paso a paso para un compañero que empieza de cero está en
`docs/FORMACION-DEV-AGENT-KIT.md`; la presentación navegable está en
`docs/formacion/dev-agent-kit-formacion.html`. Cubre descarga, instalación, perfiles,
skills, modelos, laboratorios, evaluación y los límites conocidos.

## 10. Seguridad

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
