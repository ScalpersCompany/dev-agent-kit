# Crear un perfil nuevo

Un perfil es un adaptador de entorno. El núcleo `dev-agent-kit` pone la puerta, los hooks,
el harness de eval y las cinco skills genéricas; el perfil pone lo que solo sabe ese
lenguaje: checks, comandos, skills de dominio, casos y reglas.

El perfil **no** es un segundo kit, **no** duplica los hooks y **no** sustituye a `guard` ni
a `verify`.

## Contrato

Cada perfil es un directorio con:

```text
profile.json                 nombre, versión, API, lenguaje, rutas
profile.env                  valores que lee el núcleo
profile.schema.json          esquema del contrato
AGENTS.fragment.md           reglas del lenguaje
guard/                       checks ejecutables
verify/config.env.example    arranque, salud, smoke, tests
skills/                      skills de dominio
evals/cases/                 casos de evaluación
tests/                       tests del perfil
docs/                        documentación del perfil
CHANGELOG.md
```

`profile.json` es el contrato machine-readable:

```json
{
  "name": "php",
  "version": "1.0.0",
  "api": 1,
  "language": "php",
  "description": "PHP 8, PHPStan, PHPCS and PHPUnit",
  "guard": ["guard/php.sh"],
  "verify": "verify/config.env.example",
  "skills": "skills",
  "evals": "evals/cases",
  "agents": "AGENTS.fragment.md"
}
```

`api` es 1. El núcleo rechaza una API distinta, una ruta absoluta o una ruta que se salga
del perfil. `guard` es una lista de scripts; puede estar vacía en el esqueleto, pero un
perfil real necesita al menos un check.

`profile.env` usa rutas relativas al perfil:

```text
PROFILE_NAME=php
PROFILE_LANGUAGE=php
PROFILE_GUARD_CHECKS=guard
PROFILE_VERIFY_CONFIG=verify/config.env
PROFILE_SKILLS=skills
PROFILE_EVALS=evals/cases
PROFILE_AGENTS=AGENTS.fragment.md
```

## Plantilla y generador

La plantilla está en `profiles/_template`. No la edites para un perfil real.

```bash
bash scripts/new-profile.sh php-nuevo \
  --language php \
  --repo /home/scalpers/dev-agent-profiles \
  --description "PHP 8 con PHPStan, PHPCS y PHPUnit"
```

El generador copia la plantilla, respalda un perfil existente como `.bak-<fecha>`, sustituye
el nombre y el lenguaje en `profile.json`, `profile.env` y el README. Después:

```bash
python3 scripts/validate-profile.py /home/scalpers/dev-agent-profiles/profiles/php-nuevo
```

El validador comprueba el contrato, las rutas, `profile.env` y que los ficheros existan. Si
falla, no sigas: el perfil no está instalable.

También se puede copiar a mano:

```bash
cp -a profiles/_template /ruta/dev-agent-profiles/profiles/php-nuevo
```

## 1. Rellenar el contrato

- `name`: minúsculas, dígitos y guiones; empieza por letra.
- `version`: `MAJOR.MINOR.PATCH`; súbela en cada cambio del perfil.
- `language` y `description`: lenguaje y alcance.
- `guard`: lista de scripts existentes.
- `verify`, `skills`, `evals`, `agents`: rutas relativas existentes.

## 2. Reglas del lenguaje

`AGENTS.fragment.md` se añade al `AGENTS.md` del repo de destino. Debe responder a:

- versión del lenguaje y del framework;
- comando de build;
- comando de tests;
- lint y análisis estático;
- reglas de dominio que el núcleo no conoce;
- puertas de un solo sentido (producción, credenciales, datos);
- qué se considera una prueba suficiente.

No repitas las reglas genéricas: evidencia, sin secretos, sin producción, sin comentarios,
un cambio un commit. Ya están en el núcleo.

## 3. Guard

Un `.sh` ejecutable por check. Contrato:

- lee `GUARD_ROOT` para el repo de destino;
- acepta `--staged` y mira solo lo staged;
- sale 0 si no hay hallazgos, 1 con un mensaje corto si hay defecto;
- no muta el repo, no usa red, no imprime secretos;
- sin comentarios de prosa; cabecera legal y directivas de herramienta sí.

Esqueleto:

```bash
#!/usr/bin/env bash
set -uo pipefail
ROOT="${GUARD_ROOT:-$(pwd)}"
if [ "${1:-}" = "--staged" ]; then
  mapfile -d '' FILES < <(git -C "$ROOT" diff --cached --name-only -z --diff-filter=ACMR -- '*.php')
  [ ${#FILES[@]} -eq 0 ] && exit 0
fi
vendor/bin/phpstan analyse --no-progress "$ROOT" || exit 1
```

Un check que siempre sale 0 no es un check. Un check que solo mira el árbol completo y no
acepta `--staged` bloquea el pre-commit con hallazgos antiguos.

## 4. Verify

Rellena `verify/config.env.example`:

```text
BOOT_CMD="php -S 127.0.0.1:8000 -t public"
HEALTH_URL="http://127.0.0.1:8000/health"
SMOKE_CMD="curl -fsS http://127.0.0.1:8000/health"
TEST_CMD="vendor/bin/phpunit"
HEALTH_TIMEOUT="60"
```

`TEST_CMD` debe ejercitar el cambio, no un smoke ajeno. Una base compartida o de producción
no es un destino válido. Si no hay configuración, `verify` sale 2; no es verde.

## 5. Skills

- Las cinco genéricas (`dev-verify`, `repro-first`, `review-diff`, `correct`,
  `query-readonly`) son del núcleo; no las copies.
- En `skills/` solo las de dominio: por ejemplo `odoo-safe-change`,
  `odoo-11-code-review` o una skill PHP propia.
- SDD es `spec-driven-development`, una skill global; se declara, no se copia.
- ODD es texto siempre activo en `AGENTS.md`/`SOUL.md`; no es una skill.
- RDD es el binario `gentle-ai review`; no es una skill.
- rsc-harness es opcional: sus skills viven en `.rsc/skills` del repo y no se copian.
- `gentle-ai` instala y sincroniza agentes, skills y MCP; no sustituye a rsc-harness.

## 6. Evals

Un caso por skill o regla que cambie. Cada caso necesita `TASK.md`, `context.json`, el
fixture y una rúbrica. El harness es el del núcleo:

```bash
python3 /ruta/dev-agent-kit/evals/harness.py \
  --case-dir evals/cases/<caso> \
  --rubric evals/rubric.<perfil>.json \
  --agent build \
  --model <modelo-aprobado> \
  --judge-model <modelo-aprobado-distinto> \
  --k 3
```

K=3, umbral 8,5, juez distinto del ejecutor. `--dry-run` valida el caso sin gastar modelo.
Un caso sin rúbrica o sin `context.json` no es una eval real. El harness y `evals/loop.sh`
todavía ejecutan OpenCode; el runner neutral es una deuda conocida, no un gate neutral.

## 7. Tests y CI

- Tests para los checks del perfil; un guard sin test puede dejar de bloquear en silencio.
- `python3 scripts/validate-profile.py <perfil>` en local y en CI.
- CI del perfil: unit tests, sintaxis, linter y, si el runner lo permite, el `verify`
  completo. No se toca el CI de Scalpers.
- El perfil Odoo tiene su propio CI; el núcleo no ejecuta Odoo.

## 8. Instalar en un repo

Mientras `dev-agent init` no exista:

```bash
mkdir -p /ruta/repo/.dev-agent/profiles
cp -a /ruta/dev-agent-profiles/profiles/php-nuevo /ruta/repo/.dev-agent/profiles/php-nuevo
printf 'DEV_AGENT_PROFILE=php-nuevo\n' > /ruta/repo/.dev-agent/config
cd /ruta/repo
cp verify/config.env.example verify/config.env
bash guard/guard.sh
```

El `guard.sh` del núcleo lee `.dev-agent/config`, encuentra
`.dev-agent/profiles/php-nuevo/guard/*.sh`, exporta `GUARD_ROOT` y ejecuta los checks. Los
hooks son los mismos para todos los perfiles.

## 9. Checklist

- [ ] `profile.json` válido y `validate-profile.py` en verde.
- [ ] `profile.env` con el nombre correcto y rutas relativas.
- [ ] `AGENTS.fragment.md` con versión, build, tests, lint y reglas de dominio.
- [ ] Al menos un guard ejecutable, con `--staged` y probado.
- [ ] `verify/config.env.example` con tests reales y base desechable.
- [ ] Skills de dominio, sin duplicar las genéricas.
- [ ] Caso y rúbrica si cambia una skill o regla.
- [ ] Tests del perfil y CI.
- [ ] `CHANGELOG.md` con la versión del perfil.
- [ ] Documentación del perfil en `docs/`.
- [ ] Sin secretos, sin producción, sin datos de cliente.

## 10. Anti-patrones

- Copiar los hooks del núcleo al perfil: se duplican y se desincronizan.
- Meter Odoo o PHP en el núcleo: el núcleo deja de ser agnóstico.
- Declarar ODD o RDD como skills: el agente no las encuentra al cargar por nombre.
- Copiar las cinco skills genéricas en cada perfil: tres copias y ninguna dueña.
- Un guard que solo corre en local y no está en el hook o en CI: no es una puerta.
- Un `TEST_CMD` que prueba otro módulo o una base compartida: evidencia falsa.
- Añadir un perfil sin `CHANGELOG` o sin versión: no se puede reproducir.

## 11. Estado actual

- Plantilla: `profiles/_template`.
- Generador: `scripts/new-profile.sh`.
- Validador: `scripts/validate-profile.py`.
- Odoo 11: `dev-agent-profiles/profiles/odoo11`, local; remoto pendiente.
- PHP: `dev-agent-profiles/profiles/php`, esqueleto.
- Instalador `dev-agent init`: pendiente.
- Mapa visual: `docs/DIAGRAMA-SISTEMA.md` y `docs/diagrams/sistema.html`.
