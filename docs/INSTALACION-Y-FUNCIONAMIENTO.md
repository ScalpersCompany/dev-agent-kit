# Instalación y funcionamiento

Esta es la guía de entrada del kit. Explica qué hay, cómo se instala en un repo de
desarrollo, cómo se ejecuta cada puerta y qué está implementado hoy frente a lo que sigue
siendo diseño. El kit no se despliega en producción: filtra el código que llega a la base
de desarrollo.

## 1. Qué es y qué no es

`dev-agent-kit` es un conjunto de comandos y reglas para que un agente no entregue código
sin prueba. Tiene cuatro piezas:

- **guard**: comprobaciones deterministas sobre el cambio (lint, secretos, comentarios,
  reglas de Odoo cuando el perfil las aporta).
- **verify**: arranca el entorno, comprueba salud, ejecuta smoke y tests, y deja evidencia.
- **evals**: mide una skill o una regla de revisión con un caso, K ejecuciones y un juez
  distinto del modelo que ejecuta.
- **skills y AGENTS.md**: procedimientos y reglas que el agente lee antes de tocar código.

No es un servicio en segundo plano, no despliega, no toca producción y no decide el
alcance de una tarea. El agente es intercambiable; la puerta es un comando.

## 2. Requisitos

- Linux, macOS o Windows con WSL; bash.
- Python 3.8 o superior (`python3`).
- git.
- Un agente: Hermes, OpenCode, Claude Code, Codex o pi. Los gates no dependen del agente.
- Opcional: Docker para el `verify` de Odoo; Node para eslint/tsc; `gga` para la revisión
  con IA; `gentle-ai` para distribuir skills y MCP.
- Un proveedor de modelo aprobado para los evals y para GGA. No se usa un endpoint
  personal ni se guardan claves en el repo.

## 3. Instalación del kit en un repo

### 3.1 Estado actual: copia de directorios

El kit todavía se instala copiando su estructura en el repo de desarrollo. El instalador
`dev-agent init` con perfiles separados está diseñado en `docs/PERFILES-EN-REPOS.md`, pero
no está implementado; no se debe presentar como si lo estuviera.

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

No copies `verify/config.env`, `evidence/`, `guard-report.json` ni `evals/runs/`: son
salidas locales. Si el repo ya tiene `AGENTS.md` o `.opencode`, fusiona; no sobrescribas
reglas existentes.

### 3.2 Configurar verify

```bash
cp verify/config.env.example verify/config.env
```

Rellena:

- `BOOT_CMD`: comando que levanta la app; vacío si no hace falta.
- `HEALTH_URL`: URL que devuelve 200/204 cuando está sana; vacío si no aplica.
- `SMOKE_CMD`: comprobación corta de que la app responde.
- `TEST_CMD`: la suite real del repo.
- `HEALTH_TIMEOUT`: segundos de espera.

Después:

```bash
bash verify/run.sh
```

`verify` deja `evidence/<run-id>/summary.json` con `status`, `tests` y los logs. Sale 0 si
todo pasa, 1 si falla y 2 si no hay configuración. Un 2 no es verde.

El `verify/config.env` que viene en el kit es un ejemplo de Odoo 11 con base desechable;
prueba `scalpers_partner_vat_unique` y sirve para comprobar el runner, no para dar por
probado otro módulo. Para un cambio real, `TEST_CMD` debe ejecutar los tests de ese cambio.

### 3.3 Instalar hooks

```bash
bash scripts/install-hooks.sh .
```

Instala el `pre-commit`: ejecuta `guard/guard.sh --staged` sobre los ficheros del commit.
El informe queda en `.git/guard-report.json`. Si ya había un hook, lo respalda como
`.bak-<fecha>`; no lo borra.

Para el `pre-push`:

```bash
bash scripts/install-hooks.sh . --with-verify
```

Copia `verify/config.env.example` a `.dev-agent/verify.env` y el hook falla cerrado hasta
que ese fichero tenga un `TEST_CMD` real. La evidencia va a
`.git/dev-agent-evidence/`. El hook no sustituye al CI; se puede saltar con
`--no-verify`, por decisión humana.

Los hooks son de git: funcionan con Hermes, OpenCode, Claude Code y cualquier editor.

### 3.4 Instalar GGA (opcional)

GGA es un revisor con IA, no un gate. Requiere un proveedor y un fichero de reglas.

```bash
bash scripts/install-gga.sh .
# edita .gga y elige PROVIDER=claude, opencode, codex, ollama:<modelo>...
bash scripts/review-gga.sh . --ci
```

`scripts/review-gga.sh .` revisa lo staged; `GGA_ADVISORY=1` informa sin bloquear. No
ejecutes `gga install`: instalaría su propio pre-commit y pisaría el del kit. Si no hay
proveedor o no hay `.gga`, el script lo dice; no se declara verde.

### 3.5 Skills en los agentes

Los gates viven en el repo; las skills se instalan en el agente:

- Hermes: `~/.hermes/skills/`.
- OpenCode: `~/.config/opencode/skills/`.
- Claude Code: `~/.claude/skills/`.
- Codex: `~/.codex/AGENTS.md` y las rutas que este fichero indique.
- pi/gentle-shell: su directorio de skills.
- Base compartida: `~/.agents/skills/`.

La norma global vive en `~/.agents/AGENTS.md`; `SOUL.md` de Hermes, `AGENTS.md` de
OpenCode y `CLAUDE.md` de Claude apuntan a ella. `gentle-ai sync` distribuye skills y
MCP; `scripts/install-to-editors.sh` de una skill concreta hace la copia idempotente. No
dupliques el contenido de una skill en tres sitios sin dueño.

## 4. Uso diario

1. **Rama**: `feat/`, `fix/` o `hotfix/`; nunca trabajar en la rama por defecto.
2. **Leer**: `AGENTS.md`, `docs/FEATURE_MAP.md` si existe, el perfil y la issue.
3. **Reproducir**: para un bug, un test que falle primero; conserva la salida.
4. **Implementar**: un cambio, tests y documentación en el mismo commit.
5. **Guard**: `bash guard/guard.sh` o el hook de pre-commit. Un check `skipped` no es un
   check verde; se dice por qué.
6. **Verify**: `bash verify/run.sh`; adjunta `summary.json` y los logs relevantes.
7. **Eval**: solo si cambia una skill, un prompt, una regla de revisión o una rúbrica.
8. **Revisión**: una persona lee el diff; el informe del agente no es la revisión.
9. **Entrega**: el repo de Scalpers recibe el cambio cuando guard, verify y el eval
   aplicable están verdes. El push y el CI remoto son decisiones humanas; el CI de
   Scalpers no se toca desde el kit.

## 5. Guard en detalle

`guard/guard.sh` ejecuta:

- `ruff`, `black`, `mypy` si están instalados y configurados;
- `eslint`, `tsc` si hay `package.json`/`tsconfig.json` y los binarios locales;
- `gitleaks` si está instalado;
- `odoo_lint` sobre módulos Odoo;
- `comment_lint` sobre las líneas añadidas: bloquea comentarios de prosa en Python, PHP,
  JS/TS, XML, shell, SQL y YAML. Las cabeceras legales, las directivas de herramienta
  (`noqa`, `type: ignore`, `pylint`, `eslint-disable`, `shellcheck`) y los docstrings no
  cuentan.

En `--staged` solo mira lo que entra en el commit. En modo completo, `comment_lint` se
omite con motivo para no bloquear por comentarios antiguos. El informe
`guard-report.json` es una línea JSON por check; un `skipped` no es un `pass`.

## 6. Evals en detalle

```bash
python3 evals/harness.py \
  --case-dir evals/cases/odoo-11-code-review/01-seeded \
  --rubric evals/rubric.odoo-11-code-review.json \
  --agent build \
  --model <modelo-aprobado> \
  --judge-model <modelo-aprobado-distinto> \
  --k 3
```

- Cada ejecución va en un worktree o copia desechable, nunca en el árbol de trabajo.
- El juez recibe los artefactos y el `context.json` del caso.
- El harness calcula la media ponderada; el juez no hace aritmética.
- El umbral de referencia es 8,5; una media por debajo no es un aprobado.
- `--dry-run` valida el caso sin gastar modelo.
- Las rúbricas no llevan nombres de modelo; usan `REPLACE_WITH_APPROVED_MODEL`.
- El resultado `score.json` incluye scores, media, mínimo, máximo, desviación, tokens,
  coste, aislamiento y `passed`.

La línea base está en `docs/EVAL-BASELINE.md`; la cobertura de skills y prioridades en
`docs/SKILL-EVAL-COVERAGE.md`.

## 7. Qué está implementado y qué es diseño

Implementado:

- guard con Odoo, comentarios, secretos y checks de toolchain;
- verify genérico con evidencia;
- evals con K, artifacts, juez distinto y score;
- hooks locales, backups y fail-closed para verify;
- skills globales en Hermes, OpenCode, Claude y otros;
- GGA opcional con reglas y wrapper, sin pisar el pre-commit;
- norma global 4.1 y checker de comentarios.

Diseño o migración pendiente:

- `core` + `profiles` separados; hoy Odoo sigue en la raíz y `profiles/php` es un
  esqueleto;
- repositorios privados de perfil y el instalador `dev-agent init/use/profiles/doctor`;
- `profiles.lock.json` y actualización reproducible;
- wire de `gentle-ai sync` con el perfil activo;
- integración de `rsc-harness`, `rsc-brain` y `engram` en el flujo diario, más allá de la
  documentación de límites;
- `comment_lint` para PHP en el núcleo (hoy la regla está en el perfil PHP y el checker
  genérico aún no tiene la extensión). Hasta que se añada, el checker no cubre `.php`.

No se debe presentar ninguna de estas pendientes como terminada.

## 8. Seguridad

- Producción no se toca: ni despliegue, ni reinicio, ni configuración, ni UPDATE/DELETE
  sin autorización explícita para esa acción y ese momento.
- Nada destructivo sin permiso; antes de borrar, renombrar a `.bak-<fecha>`.
- Sin secretos, tokens, credenciales ni datos de cliente en código, tests, logs, commits o
  documentación.
- `verify` de Odoo usa una base desechable y única por ejecución; no la base `scalpers`.
- Los hooks se pueden saltar con `--no-verify`; el CI es la garantía dura. El CI de
  Scalpers no se toca; el del kit y el de cada repo se configuran aparte.
- Las revisiones y los datos de revisión son locales; no se publican ni se citan en
  tickets, documentos o commits.

## 9. Problemas frecuentes

- **`verify` sale 2**: no hay `SMOKE_CMD` ni `TEST_CMD` en el config; no es verde.
- **`guard` sale con `skipped`**: falta la herramienta o la configuración; se dice, no se
  borra el check para ponerlo verde.
- **El pre-push falla cerrado**: falta `.dev-agent/verify.env` o el `TEST_CMD`; edítalo.
- **Odoo falla en `-i --test-enable` por un test de base**: instala primero sin tests y
  ejecuta después `-u <módulo> --test-enable`, en base desechable.
- **El contenedor Odoo no arranca**: el entrypoint doodba aborta si hay enlaces colgados en
  `odoo/auto/addons`; se limpian y se revisa el `addons_path`.
- **GGA no revisa**: no hay `PROVIDER`, no hay `.gga` o el CLI del proveedor no está
  autenticado; el script lo dice; no es un aprobado.
- **`comment_lint` marca una cabecera**: las cabeceras legales están permitidas; si no es
  legal, es un comentario y se quita.
- **El perfil PHP no está activo**: `profiles/php` es un esqueleto; la instalación por
  perfiles es fase 1; no se comporta como un runtime todavía.

## 10. Documentos relacionados

- `docs/ARQUITECTURA-ENTORNOS.md`: capas y límites con rsc-harness, rsc-brain, engram y
  gentle-ai.
- `docs/PERFILES-EN-REPOS.md`: perfiles en repos privados, registro, instalador y lock.
- `docs/OPERATIONS.md`: flujo, hooks, GGA y skills globales.
- `docs/DEV-BASE.md`: qué cubre el kit en la base de desarrollo.
- `docs/EVAL-BASELINE.md`: línea base de evals.
- `docs/SKILL-EVAL-COVERAGE.md`: skills, prioridad y estado de evaluación.
- `docs/agent-quality/ENVIRONMENT.md`: entorno real, comandos y credenciales.
- `CHANGELOG.md`: cambios por versión.
