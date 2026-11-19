# Perfiles en repositorios separados

## Decisión

Los perfiles viven en **repositorios propios**, no dentro del núcleo. El núcleo
`dev-agent-kit` mantiene el contrato, el registro y el instalador; cada perfil mantiene su
lenguaje, sus comandos y sus skills. Esto evita que el compañero de PHP tenga que clonar el
árbol de Odoo y que el equipo de Odoo cargue dependencias de PHP.

Se usa **registro + clonado**, no submódulos:

- el núcleo queda pequeño y sin `.gitmodules`;
- cada perfil se versiona, revisa y etiqueta por separado;
- el repo de destino fija la versión exacta en `.dev-agent/profiles.lock.json`;
- se puede instalar un perfil, otro o todos;
- se puede trabajar sin red con `--source <ruta>`.

## Repositorios

```text
nramosscalpers/dev-agent-kit         # núcleo, contrato, instalador, documentación
nramosscalpers/dev-agent-profiles    # perfiles: odoo11/, php/ (un solo repo privado)
```

Un solo repo de perfiles es suficiente y se recomienda para un equipo pequeño: una sola
credencial, un solo `CHANGELOG` por perfil, `CODEOWNERS` por directorio y una matriz de CI.
Cada perfil conserva su `version` y su `profile.json`; el lock fija el commit del repo y el
subdirectorio. Si en el futuro un perfil necesita otro ciclo de acceso, se puede separar sin
cambiar el contrato.

El perfil Odoo se extrae del kit actual en la fase 1; el perfil PHP nace del esqueleto
`profiles/php`. El núcleo conserva `profiles/_template` como plantilla, no como perfil
instalable.

## Contrato de un perfil

Cada perfil es un subdirectorio del repo `dev-agent-profiles`:

```text
profile.json                 # nombre, versión, API, lenguaje, checks, rutas
profile.env                  # variables que lee el núcleo
AGENTS.fragment.md           # reglas del lenguaje, se añaden al AGENTS del repo
guard/                       # checks ejecutables del perfil
verify/config.env.example    # BOOT_CMD, HEALTH_URL, SMOKE_CMD, TEST_CMD
skills/                      # solo skills de dominio; las genéricas son del núcleo
evals/cases/                 # casos de evaluación del perfil
docs/                        # documentación del perfil
tests/                       # tests del propio perfil
CHANGELOG.md
```

`profile.json` es el contrato machine-readable:

```json
{
  "name": "php",
  "version": "0.1.0",
  "api": 1,
  "language": "php",
  "description": "PHP 8, PHPStan, PHPCS and PHPUnit",
  "guard": ["guard/phpstan.sh", "guard/phpcs.sh"],
  "verify": "verify/config.env.example",
  "skills": "skills",
  "evals": "evals/cases",
  "agents": "AGENTS.fragment.md"
}
```

El núcleo rechaza un perfil con `api` distinta de la suya, sin `profile.json`, sin
`profile.env` o con rutas que se salgan del repo. La API empieza en 1 y solo cambia con una
migración documentada.

## Hooks y perfiles

El hook es **uno y del núcleo**. No se duplica un `pre-commit` por lenguaje: el mismo
`hooks/pre-commit` lee `.dev-agent/config` y llama a `guard/guard.sh`; el mismo
`hooks/pre-push` llama a `verify/run.sh`. Lo que cambia por perfil es lo que el hook
ejecuta:

- `guard/` del perfil: checks propios (Odoo, PHPStan, PHPCS...);
- `verify/config.env`: los comandos de arranque y test;
- `skills/`: las skills de dominio;
- `evals/cases/`: los casos del perfil;
- `AGENTS.fragment.md`: las reglas del lenguaje.

Las skills genéricas y el checker de comentarios viven en el núcleo. Un perfil que
necesite un hook extra lo declara en su `profile.json`; el núcleo lo ejecuta después de los
suyos, sin reemplazarlos.

## Instalador

El comando del núcleo se llama `dev-agent`:

```bash
./dev-agent init --repo /ruta/al/repo --profile php
./dev-agent init --repo /ruta/al/repo --profile odoo11
./dev-agent init --repo /ruta/al/repo --all --select php
./dev-agent use php
./dev-agent profiles list
./dev-agent profiles update
./dev-agent doctor
```

- `init` copia el núcleo al repo, resuelve el perfil desde `profiles.index.json`, lo clona
  en `.dev-agent/profiles/<nombre>` y escribe `.dev-agent/config`.
- `--profile` instala solo ese perfil; `--all` instala todos los disponibles y deja activo
  el de `--select`; sin `--select`, el primero del índice.
- `--source <ruta>` instala desde un directorio local; sirve para el perfil que todavía no
  está publicado y para un equipo sin acceso al remoto.
- `use` cambia el perfil activo sin reinstalar ni copiar skills.
- `profiles update` actualiza las versiones fijadas; `doctor` valida contrato, comandos,
  fichero de verify y hooks.
- El instalador no borra un perfil existente: lo respalda como `.bak-<fecha>` y para si el
  contrato no valida. No ejecuta `gentle-ai sync` sin `--with-agents`; las skills se
  distribuyen después.

`profiles.index.json` es la lista del núcleo:

```json
{
  "api": 1,
  "profiles": [
    {
      "name": "odoo11",
      "repo": "git@github.com:nramosscalpers/dev-agent-profiles.git",
      "path": "profiles/odoo11",
      "ref": "v1.0.0"
    },
    {
      "name": "php",
      "repo": "git@github.com:nramosscalpers/dev-agent-profiles.git",
      "path": "profiles/php",
      "ref": "v0.1.0"
    }
  ]
}
```

El lock del repo de destino fija el commit del repo de perfiles y el `path`:

```json
{
  "api": 1,
  "active": "php",
  "profiles": {
    "php": {
      "repo": "git@github.com:nramosscalpers/dev-agent-profiles.git",
      "path": "profiles/php",
      "ref": "v0.1.0",
      "commit": "<sha>"
    }
  }
}
```

El lock es reproducible; un `update` es una decisión explícita. El lock no lleva tokens ni
URLs con credenciales.

## Qué lee el núcleo

El repo de destino queda así:

```text
.dev-agent/
  config                 # DEV_AGENT_PROFILE=php
  profiles.lock.json
  profiles/
    php/
      profile.json
      profile.env
      guard/
      verify/config.env
      skills/
      evals/cases/
  verify.env             # copia editable de verify/config.env.example
```

- `guard.sh` ejecuta los checks del núcleo y después `profiles/<activo>/guard/*.sh`; no hay
  `if odoo` ni `if php` en el núcleo.
- `verify/run.sh` lee `.dev-agent/verify.env`; no sabe qué hay detrás.
- `evals/harness.py` recibe el caso del perfil activo.
- `hooks/pre-commit` y `pre-push` leen `.dev-agent/config`; cambiar de perfil no reinstala
  los hooks.
- `AGENTS.md` del repo se compone de la norma global, la sección del núcleo y el
  `AGENTS.fragment.md` del perfil. El bloque compartido `~/.agents/AGENTS.md` no se toca.
- `gentle-ai sync` distribuye `skills/core` y `profiles/<activo>/skills` a los agentes;
  `install-hooks.sh` instala los hooks. Son dos responsabilidades distintas.

## Instalar uno, otro o todos

- **Un perfil**: `--profile php`. El repo no descarga Odoo ni sus skills.
- **Varios**: `--profile php,odoo11` o `--all`. Se copian todos, solo uno activo.
- **Cambiar**: `dev-agent use odoo11`; el lock y las skills se conservan; el `verify.env`
  se regenera solo si no existe o con `--reset-verify`.
- **Actualizar**: `dev-agent profiles update --profile php` fija un commit nuevo; el
  `doctor` vuelve a validar.
- **Quitar**: no se borra en silencio; se mueve a `.dev-agent/profiles/<nombre>.bak-<fecha>`
  y se cambia el activo.

## Seguridad y compatibilidad

- Los perfiles son privados; se clonan por SSH o HTTPS con la credencial del usuario. El
  lock no guarda el token.
- El perfil no puede ejecutar `git push` ni tocar producción; solo declara comandos de
  guard y verify.
- Los scripts son bash/Python 3.8+; Hermes, OpenCode y Claude Code los ejecutan igual. Las
  skills son `SKILL.md`; `gentle-ai` las distribuye.
- GGA es opcional y se instala por repo; el perfil solo aporta patrones de fichero y reglas
  adicionales.
- rsc-harness, rsc-brain y engram no entran en el perfil: son capas del flujo, no comandos
  del lenguaje.

## Migración

1. Crear `dev-agent-profiles` y mover `guard/odoo_lint.py`, las skills de Odoo, los casos
   y el verify de Odoo a `profiles/odoo11`; el núcleo se queda con lo genérico.
2. Crear `profiles/php` desde el esqueleto; añadir PHPStan, PHPCS, PHPUnit y un caso de
   eval.
3. Implementar `dev-agent init/use/profiles/doctor` y el lock; probar con el perfil PHP en
   un repo vacío y con el perfil Odoo en `scalpers-v11`.
4. Retirar del núcleo los ficheros de Odoo que se hayan movido; el CI del núcleo no debe
   necesitar Odoo.
5. Conectar `gentle-ai sync`, rsc-harness, rsc-brain y engram en el flujo; no dentro del
   perfil.

Criterio de aceptación: un repo PHP instala `--profile php` y pasa `guard`/`verify` sin
Odoo; un repo Odoo instala `--profile odoo11` y conserva el comportamiento actual; el
núcleo no menciona ningún lenguaje; el lock es reproducible y no contiene secretos.
