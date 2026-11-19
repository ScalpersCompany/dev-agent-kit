# Arquitectura agnóstica de entorno

## Decisión

El kit deja de ser «el kit de Odoo» y pasa a ser un **núcleo agnóstico con perfiles de
entorno**. El núcleo no importa Odoo, PHP ni Node: ejecuta contratos. Cada equipo añade un
perfil delgado con sus comandos, sus reglas y sus casos de evaluación. Un compañero de PHP
usa el mismo flujo sin aprender Odoo; el equipo de Odoo conserva su perfil y sus skills.

La regla de diseño es: **el agente es intercambiable; la puerta es un comando**. Hermes,
OpenCode y Claude Code ejecutan los mismos scripts y los mismos hooks; ninguno es dueño
del flujo.

## Capas

| Capa | Herramienta | Responsabilidad | No es |
| ------ | ----------- | --------------- | ----- |
| Proceso | `rsc-harness` | Spec, criterios de aceptación, tareas y estado por repo | No ejecuta los tests ni bloquea el commit |
| Puerta | `dev-agent-kit` | `guard`, `verify`, `evals`, hooks y skills de ejecución | No decide el alcance ni el diseño |
| Instalación | `gentle-ai` | Instala y sincroniza skills, `AGENTS.md` y MCP en cada agente | No es un gate ni un servidor de conocimiento |
| Conocimiento | `rsc-brain` | Wiki curada del proyecto/equipo, decisiones y arquitectura, con fuentes | No es memoria de sesión ni un diario |
| Memoria | `engram` | Decisiones, bugs y contexto de trabajo por proyecto, entre sesiones y agentes | No es documentación aprobada ni un gate |
| Norma | `~/.agents/AGENTS.md` | Reglas globales de la empresa | No contiene comandos de un repo concreto |

La precedencia es: norma global `~/.agents/AGENTS.md` → `AGENTS.md` del repo → fragmento del
perfil → spec de `rsc-harness`. Si dos capas se contradicen, gana la más específica y se
documenta la decisión.

## Estructura objetivo

```text
dev-agent-kit/
  core/
    AGENTS.md
    verify/run.sh                  # BOOT_CMD, HEALTH_URL, SMOKE_CMD, TEST_CMD
    guard/guard.sh                # ejecuta checks core + perfil
    guard/checks/comment_lint.py  # genérico: Python, JS/TS, XML, shell, SQL, YAML (PHP pendiente)
    guard/checks/secrets.sh
    evals/harness.py              # k runs, artifacts, judge, score.json
    hooks/                        # pre-commit y pre-push
    scripts/init-profile.sh
    scripts/install-hooks.sh
    skills/core/                  # dev-verify, repro-first, review-diff, correct, query-readonly
  profiles/
    _template/
    odoo11/
      profile.env
      AGENTS.fragment.md
      guard/odoo_lint.py
      verify/config.env.example
      skills/                     # odoo-safe-change, odoo-11-*, factorlibre-mr-preflight
      evals/cases/
      docs/
    php/
      profile.env
      AGENTS.fragment.md
      guard/                      # phpstan, phpcs, phpunit
      verify/config.env.example
      skills/                     # php-safe-change y los genéricos que apliquen
      evals/cases/
  docs/
  CHANGELOG.md
  README.md
```

El repo actual se migra sin cambiar el comportamiento: los ficheros de Odoo se han movido
a `dev-agent-profiles/profiles/odoo11`; el núcleo se queda con lo que ya es genérico
(`verify/run.sh`, `guard/guard.sh`, `guard/comment_lint.py`, el harness de eval y los
hooks). El perfil Odoo conserva su linter, allowlist, verify, skills, casos y tests.

## Contrato de perfil

`profile.env` es la única interfaz entre el núcleo y el entorno:

```sh
PROFILE_NAME=odoo11
PROFILE_LANGUAGE=python
PROFILE_GUARD_CHECKS=guard/odoo.sh
PROFILE_VERIFY_CONFIG=verify/config.env
PROFILE_SKILLS=profiles/odoo11/skills
PROFILE_EVALS=profiles/odoo11/evals/cases
PROFILE_AGENTS=profiles/odoo11/AGENTS.fragment.md
```

`scripts/new-profile.sh <perfil> <repo>` copia la plantilla, escribe
`.dev-agent/config` con `DEV_AGENT_PROFILE=<perfil>` y no toca el código. `guard.sh` carga
el perfil y ejecuta, en este orden:

1. checks del núcleo, siempre;
2. `profiles/<perfil>/guard/*.sh`, solo los del perfil;
3. `comment_lint`, genérico, sobre las líneas añadidas.

`verify/run.sh` ya es genérico: recibe `BOOT_CMD`, `HEALTH_URL`, `SMOKE_CMD` y `TEST_CMD`.
No necesita saber si detrás hay Odoo, PHP o Node. El perfil solo aporta el fichero de
configuración. `evals/harness.py` recibe el caso y la rúbrica; el perfil aporta los casos.

`scripts/install-hooks.sh <repo> --profile <perfil>` instala los hooks y escribe el perfil
en `.dev-agent/config`; los hooks exportan `DEV_AGENT_PROFILE` antes de llamar a
`guard/guard.sh` o `verify/run.sh`. El hook sigue siendo de git: vale para cualquier agente.

## Perfil PHP

El perfil PHP no necesita nada del núcleo de Odoo:

```sh
PROFILE_NAME=php
PROFILE_LANGUAGE=php
PROFILE_GUARD_CHECKS=phpstan,phpcs,phpunit
PROFILE_VERIFY_CONFIG=verify/config.env
PROFILE_SKILLS=skills
PROFILE_EVALS=evals/cases
PROFILE_AGENTS=AGENTS.fragment.md
```

Comandos de ejemplo:

```sh
composer install --no-interaction --prefer-dist
vendor/bin/phpstan analyse
vendor/bin/phpcs
vendor/bin/phpunit
```

El `verify` del perfil arranca el servidor de desarrollo y ejecuta el test de integración:

```sh
BOOT_CMD="php -S 127.0.0.1:8000 -t public"
HEALTH_URL="http://127.0.0.1:8000/health"
SMOKE_CMD="curl -fsS http://127.0.0.1:8000/health"
TEST_CMD="vendor/bin/phpunit"
```

`comment_lint.py` añade `.php` con `//`, `#` y `/* */`, respetando strings y las mismas
directivas que ya admite para Python y JS. Las skills genéricas (`dev-verify`,
`repro-first`, `review-diff`, `correct`, `query-readonly`) sirven tal cual; el perfil PHP
solo añade la suya de dominio (`php-safe-change`).

## Perfil Odoo 11

Es el perfil actual, movido sin cambios de comportamiento:

- `guard/odoo_lint.py` con `sudo`, `cr.commit`, SQL, `print`, `--files` y `--allowlist`;
- `verify/config.env` con base desechable y `-i`/`-u --test-enable`;
- skills `odoo-safe-change`, `odoo-11-code-review`, `factorlibre-mr-preflight` y las
  específicas de Odoo;
- casos de eval de Odoo y el preflight de FactorLibre.

El núcleo no importa nada de Odoo; si un repo no tiene perfil Odoo, `odoo_lint` no se
ejecuta.

## rsc-harness

`rsc-harness` define el **qué** y el **porqué**: spec, criterios de aceptación, tareas y
estado. Se instala por repo con `npx @ericrisco/rsc@4.1.8 onboard ...`; crea `02-DOCS/`,
`01-TOOLS/`, `AGENTS.md` y el estado. Sus targets son OpenCode, Claude, Codex, pi y otros;
Hermes no es target, pero recibe el contenido por `02-DOCS/`, el bloque de `AGENTS.md` y el
MCP del brain.

Reglas de convivencia:

- El harness escribe un bloque entre `<!-- rsc-suggest:start -->` y
  `<!-- rsc-suggest:end -->`; no se toca lo de fuera.
- El bloque de la norma compartida `~/.agents/AGENTS.md` va **fuera** de esos marcadores,
  porque `rsc repair` reescribe el suyo.
- `gitPermissions: false`: el arnés no commitea ni empuja; la puerta y el push siguen siendo
  decisiones nuestras.
- Cada tarea de rsc se cierra con `guard` y `verify` verdes; el kit no duplica el spec, y
  rsc no duplica los tests.

## rsc-brain

`rsc-brain` es la **wiki curada** del proyecto y del equipo: arquitectura, perfiles,
decisiones y trampas verificadas. Escucha en `127.0.0.1:8090`, con web, API `/v1` y MCP
`/mcp`.

- Un brain por proyecto o por equipo; el repo se vincula por su remoto.
- Cada página cita sus fuentes (`url` o `entryId`), como pide la API.
- No se duplica el README ni el `docs/` del repo: la página resume y enlaza.
- El token de escritura vive en `~/.config/rsc-brain/token` (600) y no se imprime.
- Para el equipo, se publica por túnel SSH; abrir el puerto a la red es otra decisión.
- Publicar es una escritura: se hace con autorización y se verifica con un GET.

## engram

`engram` es la **memoria de trabajo**: decisiones, bugs, descubrimientos no obvios y
convenciones por proyecto. Vive como MCP en cada agente; el repo lleva su
`.engram/config.json` con el `project_name`.

- `mem_context` al empezar; `mem_save` al cerrar una decisión o un bug.
- No guarda secretos, datos de cliente ni revisiones que no se puedan citar.
- No sustituye al brain: el brain es conocimiento curado y compartido; engram es memoria de
  sesión y de proyecto.
- No es un gate: si engram no está, el desarrollo sigue; se pierde contexto, no la puerta.

## gentle-ai

`gentle-ai` es el **instalador y la paridad entre agentes**: skills, `AGENTS.md`, MCP
(codegraph, engram, rsc-brain) y persona. No es un gate.

- La fuente de skills es una sola: `skills/` y `profiles/<perfil>/skills`;
  `gentle-ai sync` las lleva a OpenCode, Claude, Codex, pi y Hermes.
- `gentle-ai sync --dry-run` antes de escribir; no se cambian cinco configuraciones a
  ciegas.
- `~/.agents/skills` es el canónico de nombres; se compara por nombre, no por conteo.
- El kit sigue instalando los hooks del repo; gentle-ai no instala hooks de git.
- La norma global se queda en `~/.agents/AGENTS.md`; gentle-ai no la duplica.

## GGA (revisión opcional)

`gga` (Gentleman Guardian Angel) es un revisor de código con IA, instalado por
`gentle-ai`. No sustituye a `guard` ni a `verify`: es un segundo par de ojos, no
determinista, que necesita un proveedor y tarda. Se añade como paso opcional, nunca
como puerta dura.

- `scripts/install-gga.sh <repo>` copia `.gga` y `.gga-rules.md`, con backup si ya
  existen. **No** ejecuta `gga install`: ese comando instalaría su propio pre-commit y
  pisaría el del kit.
- `scripts/review-gga.sh <repo>` ejecuta `gga run` sobre lo staged. Con
  `GGA_ADVISORY=1` informa y no bloquea; sin esa variable devuelve el código de GGA.
  Para revisar un commit: `scripts/review-gga.sh <repo> --ci`.
- El `.gga` de ejemplo usa `PROVIDER=claude`; se puede cambiar a `opencode`, `codex`,
  `ollama:<modelo>`, `gemini` o el proveedor aprobado. Hermes y OpenCode lanzan el
  script como un comando; no hay API de agente.
- `.gga-rules.md` es el contrato de revisión: sin comentarios de prosa, tests de
  comportamiento, UdM correcta, retry terminal, `depends` directo, sin secretos. El
  perfil puede añadir patrones de fichero, pero no duplicar las reglas del núcleo.
- Si no hay proveedor o no hay `.gga`, el script lo dice y no se declara verde. El
  `guard` determinista sigue siendo la garantía; GGA es consejo.

## Flujo de una tarea

1. **Spec**: rsc-harness crea o actualiza la tarea y los criterios de aceptación.
2. **Contexto**: el agente lee `AGENTS.md`, el perfil, `02-DOCS`, el brain y engram.
3. **Implementación**: una rama, un cambio, tests y docs.
4. **Puerta**: `guard` en pre-commit; `verify` en pre-push o CI; `eval` si cambia una
   skill, un prompt o una regla de revisión.
5. **Cierre**: engram guarda la decisión o el bug; el brain guarda lo reutilizable; rsc
   cierra la tarea con la evidencia.
6. **Distribución**: si cambian skills o MCP, `gentle-ai sync`; si cambian hooks, el
   instalador del kit.

## CI

- `core`: unit tests, sintaxis, dry-run de eval, sin servicios.
- `dev-agent-profiles/profiles/php`: `composer install`, PHPStan, PHPCS, PHPUnit; el runner
  es barato.
- `dev-agent-profiles/profiles/odoo11`: base desechable y servicios; se ejecuta en el runner
  que ya tiene el stack o en el pre-push local, no en cada push de cualquier repo.
- Los hooks locales se pueden saltar con `--no-verify`; el CI es la garantía dura. El CI
  de Scalpers no se toca; el del kit y el de cada repo son los que se configuran.

## Compatibilidad de agentes

- Skills: `SKILL.md` estándar; Hermes, OpenCode y Claude Code los cargan; Codex recibe
  rutas y `AGENTS.md`; pi tiene su árbol.
- Scripts: bash y Python 3.8+; sin SDK de un agente.
- Norma: `~/.agents/AGENTS.md`; `SOUL.md`, `AGENTS.md` de OpenCode y `CLAUDE.md` apuntan a
  ella.
- Instalación: `gentle-ai` para skills/MCP; `install-hooks.sh` para git; no se mezclan.

## Migración

1. **Fase 0** (este documento y el esqueleto `profiles/`): decide el contrato, sin mover
   código.
2. **Fase 1 (hecha localmente)**: extraer `core/` y `dev-agent-profiles/profiles/odoo11`;
   mover `odoo_lint`, skills y casos de Odoo; el núcleo ya no contiene Odoo y el perfil
   Odoo conserva sus tests. El repo de perfiles es local; el remoto está pendiente.
3. **Fase 2 (pendiente)**: completar `dev-agent-profiles/profiles/php` con un caso real;
   `.php` en `comment_lint`; verificar `guard` y `verify` en un repo PHP de prueba.
4. **Fase 3**: integrar rsc-harness y gentle-ai; el spec y las skills se enlazan; no se
   duplican.
5. **Fase 4**: rsc-brain y engram por repo; páginas con fuentes y memoria de decisiones.

Criterio de aceptación de la migración: el núcleo no menciona Odoo ni PHP; un repo PHP
puede instalar el kit y pasar sus gates sin tocar Odoo; un repo Odoo conserva el
comportamiento actual; Hermes, OpenCode y Claude Code ejecutan los mismos hooks.

## Decisiones abiertas

- Framework PHP del compañero (Laravel, Symfony u otro) y nivel de PHPStan/PHPCS.
- Si el brain es por repo o por equipo, y quién lo aloja.
- Si rsc-harness se instala en cada repo o solo en los que llevan spec formal.
- Si engram es por repo o por equipo; el `project_name` decide.
- Quién mantiene el perfil PHP y quién el de Odoo; el núcleo lo mantiene el equipo de
  calidad.

## Lo que no se hace

- No se duplica el contenido de las skills en cada agente: una fuente y `gentle-ai sync`.
- No se mete Odoo en el núcleo ni se obliga a PHP a instalar Odoo.
- No se usa rsc-brain como diario ni engram como documentación aprobada.
- No se commitea ni se empuja desde rsc-harness; la autorización es humana.
- No se toca el CI de producción ni el de Scalpers; cada repo configura el suyo.
