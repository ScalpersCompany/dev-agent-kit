# Formación DevAgentKit

Guía para dar de alta a un compañero que empieza de cero, en tres sesiones de 90 minutos.
El objetivo no es que memorize comandos: es que pueda instalar la puerta, configurar un
perfil y entregar un cambio con evidencia.

## Resultado de la formación

Al terminar, el compañero debe poder:

1. clonar el kit, los perfiles y su repo de desarrollo;
2. instalar el kit en la raíz de su repo y activar un perfil;
3. ejecutar `guard` y `verify`, y explicar qué significa un `skipped` o un `exit 2`;
4. usar las cinco skills del núcleo y una skill de su perfil;
5. elegir un modelo aprobado y un juez distinto para las evals;
6. entregar un cambio sin secretos, sin producción y con evidencia;
7. reconocer las deudas conocidas: el eval todavía usa OpenCode y el instalador de perfiles
   automático no está cableado.

La presentación para proyectar está en `docs/formacion/dev-agent-kit-formacion.html`.
Esta guía es el manual del formador y la referencia escrita del alumno.

## Antes de la primera sesión

Enviar al compañero esta lista y pedirle que la confirme antes del lunes:

- git instalado y una cuenta con acceso a los repositorios que vaya a usar;
- bash, Python 3.8 o superior y `rsync`;
- `curl` si el verify va a usar `HEALTH_URL`;
- un agente instalado: Claude Code, OpenCode, Codex, pi o Hermes;
- acceso a un repo de desarrollo, nunca a producción;
- acceso al proveedor de modelo aprobado por la empresa;
- si va a usar Odoo 11: Docker y una base desechable, nunca la base compartida;
- si va a usar tech-doc: acceso al repo privado de documentación.

No se empieza si falta el acceso al repo de desarrollo o al proveedor aprobado. El kit no
inventa credenciales ni crea entornos.

## Los cuatro repos

| Repo | Papel | Qué se hace con él |
|---|---|---|
| `ScalpersCompany/dev-agent-kit` | Puerta, hooks, skills, evals | Se clona; es el núcleo |
| `ScalpersCompany/dev-agent-profiles` | Perfiles Odoo 11 y PHP | Se clona aparte; se copia el perfil activo |
| `ScalpersCompany/scalpers-tech-doc` | Norma y documentación de empresa | Se enlaza su `AGENTS.md`; no se copia ni se fusiona |
| El repo donde se desarrolla | Código de producto, Odoo, PHP o cualquier stack | Se instala el kit y el perfil en su raíz |

Son repos separados, no submódulos. El repo de producto no es uno fijo: es el repo en el
que se está trabajando. El kit no despliega ni toca producción.

## Mapa de las tres sesiones

| Sesión | Día | Qué se enseña | Laboratorio |
|---|---|---|---|
| 1 | Lunes | Qué es el kit, repos, descarga, instalación, perfil, guard y verify | Instalar en un repo desechable, activar un perfil y ver la primera evidencia |
| 2 | Martes | Skills, adaptadores, modelos y flujo diario | Reproducir un bug, verificar y revisar un diff |
| 3 | Jueves | Perfil Odoo/PHP en profundidad, evals, tech-doc, GGA y diagnóstico | Profundizar el perfil, ejecutar una eval en seco y cerrar el checklist |

Cada sesión: 10 minutos de repaso, 30 de explicación, 35 de laboratorio y 15 de dudas.
El orden importa: no se enseña una eval antes de que `verify` haya producido evidencia.

## Sesión 1. La puerta

### 1.1 Por qué existe

El agente propone y ejecuta; la puerta decide. `guard` mira el cambio, `verify` ejecuta el
comportamiento real y deja evidencia, y las skills explican al agente cómo trabajar. El kit
no es un modelo, no es un CI y no decide el alcance.

Enseñar la diferencia entre:

- **hecho**: el agente lo dice;
- **verificado**: hay salida de comando, test, HTTP o artefacto;
- **aprobado**: una persona revisó y decidió.

### 1.2 Descarga

```bash
mkdir -p "$HOME/dev"
git clone https://github.com/ScalpersCompany/dev-agent-kit.git "$HOME/dev-agent-kit"
git clone https://github.com/ScalpersCompany/dev-agent-profiles.git "$HOME/dev-agent-profiles"
```

El repo de desarrollo se clona aparte, con la URL y la credencial que correspondan. No se
pega ningún token en un fichero del repo.

Exportar el kit para que los hooks lo encuentren:

```bash
export DEV_AGENT_KIT="$HOME/dev-agent-kit"
```

Añadirlo al perfil del shell si el compañero no clona en esa ruta. Los hooks
`hooks/pre-commit` y `hooks/pre-push` tienen `/home/scalpers/dev-agent-kit` como ruta por
defecto. Si el compañero clona en otra ruta u otro HOME, tiene que exportar
`DEV_AGENT_KIT` en el entorno en el que git ejecuta el hook; los clientes GUI no leen el
perfil del shell. Comprobarlo antes de seguir:

```bash
test -x "$DEV_AGENT_KIT/guard/guard.sh" && echo "kit OK"
```

### 1.3 Instalación en el repo de desarrollo

```bash
cd /ruta/a/tu/repo
bash "$HOME/dev-agent-kit/scripts/bootstrap.sh" . --with-verify
```

Qué hace y qué no:

- copia `AGENTS.md`, `skills/`, `commands/`, `agents/`, `verify/`, `guard/`, `evals/`,
  `scripts/`, `docs/` y `profiles/`;
- respalda lo que ya exista como `.bak-<fecha>`;
- crea `verify/config.env` desde el ejemplo;
- instala el pre-commit;
- con `--with-verify`, instala el pre-push y crea `.dev-agent/verify.env`;
- **no** instala un perfil de Odoo o PHP: eso se hace a mano en el paso siguiente.

El bootstrap **sobrescribe** `AGENTS.md` y hace merge de los directorios copiados; los
backups `.bak-<fecha>` son la red. Si el repo ya tenía reglas propias en `AGENTS.md`, hay
que fusionarlas desde el backup. Los `.bak` quedan como ficheros sin seguimiento.

Para que el repo no se llene de artefactos locales, añade las exclusiones antes de trabajar:

```bash
printf '%s\n' '.dev-agent/' 'evidence/' 'guard-report.json' 'verify/config.env' \
  '.opencode/' '.claude/skills/' '.claude/commands/' '.claude/agents/' '__pycache__/' \
  >> .git/info/exclude
```

El bootstrap no copia un `.gitignore` al repo destino: estas reglas son locales a tu clon.
Si quieres compartir alguna, conviértela en una entrada deliberada de `.gitignore`, no en un
efecto colateral.

El instalador automático de perfiles (`dev-agent init`) está diseñado, no cableado. No se
promete en la formación.

### 1.4 Activar un perfil

Para Odoo 11:

```bash
mkdir -p .dev-agent/profiles
rsync -a --exclude='verify/config.env' \
  "$HOME/dev-agent-profiles/profiles/odoo11/" .dev-agent/profiles/odoo11/
printf 'DEV_AGENT_PROFILE=odoo11\n' > .dev-agent/config
```

Para PHP, el perfil todavía es un esqueleto: se puede copiar y validar, pero no se promete
un runtime PHP completo.

`guard/guard.sh` busca el perfil en `.dev-agent/profiles/<nombre>` o `profiles/<nombre>`.
Si no lo encuentra, la línea `profile` sale `skipped`; un `skipped` no es un `pass`.

`.dev-agent/` queda excluido por `--with-verify` y no se versiona. Si quieres que el perfil
lo vea CI o el equipo, copia el perfil a `profiles/odoo11` (la otra ruta que acepta
`guard.sh`) y decide si lo commiteas; `.dev-agent/config` puede quedar local.

### 1.5 Configurar verify

Hay dos ficheros y no son lo mismo:

- `verify/config.env`: lo usa `bash verify/run.sh` a mano;
- `.dev-agent/verify.env`: lo usa el hook pre-push.

Rellenar el segundo para el hook y, si se quiere una sola fuente, usar el mismo contenido:

```bash
cp .dev-agent/profiles/odoo11/verify/config.env.example verify/config.env
cp verify/config.env .dev-agent/verify.env
```

Ejemplo mínimo para un repo Python sin Odoo:

```bash
SMOKE_CMD='python3 -c "import mi_paquete"'
TEST_CMD='python3 -m unittest discover -v'
```

Para Odoo 11, el `TEST_CMD` depende de la base y del módulo. El `.example` del perfil es
la misma plantilla vacía; el `config.env` real de esta máquina tiene un comando local que
no se copia. Escribe el tuyo contra una base desechable y un módulo concreto; nunca la base
compartida, nunca producción, nunca datos de cliente.

`verify` sale 2 cuando no hay `SMOKE_CMD` ni `TEST_CMD`: no es verde, es una configuración
incompleta.

### 1.6 Primera puerta

```bash
bash guard/guard.sh
bash verify/run.sh
```

Leer la salida:

- `guard: passed` con checks `skipped` significa que no había herramienta o ficheros; hay
  que decir por qué se omitió, no convertirlo en un falso verde;
- `verify` deja `evidence/<run-id>/summary.json` cuando se ejecuta a mano;
- el pre-push deja la evidencia en `.git/dev-agent-evidence/<run-id>/`, fuera del árbol;
- `guard` sin `--staged` omite `comments`; para probar `comment_lint` hay que stagear un
  comentario de prosa y ejecutar `bash guard/guard.sh --staged`;
- el pre-commit ejecuta `guard --staged`; el pre-push ejecuta `verify` con
  `.dev-agent/verify.env`;
- `git --no-verify` salta el hook local; el CI del repo es la garantía dura, y el CI de
  Scalpers no se toca;
- no se commitean `evidence/`, `guard-report.json` ni `.dev-agent/`.

Prueba de humo de los hooks, sin crear un commit:

```bash
bash .git/hooks/pre-commit
```

Si el hook no existe o no encuentra el kit, falla aquí y no en el primer commit real.
`git hook run pre-commit` solo existe desde git 2.36; esta guía usa la ruta directa para no
depender de la versión.

### 1.7 Laboratorio 1

Crear un repo desechable, no el repo real:

```bash
mkdir -p "$HOME/devkit-lab" && cd "$HOME/devkit-lab"
git init
printf 'def suma(a, b):\n    return a + b\n' > calc.py
printf 'import unittest\nfrom calc import suma\n\nclass TestCalc(unittest.TestCase):\n    def test_suma(self):\n        self.assertEqual(suma(2, 3), 5)\n\nif __name__ == "__main__":\n    unittest.main()\n' > test_calc.py
git add . && git -c user.name='Formacion' -c user.email='formacion@example.com' commit -m 'lab inicial'
bash "$HOME/dev-agent-kit/scripts/bootstrap.sh" . --with-verify
```

Rellenar `verify/config.env` y `.dev-agent/verify.env` con:

```bash
SMOKE_CMD='python3 -c "import calc"'
TEST_CMD='python3 -m unittest discover -v'
```

Ejecutar `bash verify/run.sh` y `bash guard/guard.sh`. Criterio de salida: el alumno explica
qué comprobó cada comando y dónde está la evidencia.

Probar `comment_lint` en modo staged, porque `guard` sin `--staged` lo omite:

```bash
printf '\n# comentario de prosa\n' >> calc.py
git add calc.py
bash guard/guard.sh --staged   # debe fallar
git restore --staged calc.py
git checkout -- calc.py
```

## Sesión 2. Skills, agentes y modelos

### 2.1 Una sola fuente

El repo guarda la fuente neutral:

```text
skills/       las cinco skills del núcleo
commands/     plantillas de /verify, /guard, /repro, /correct, /eval
agents/       el juez de las evals
```

Los directorios `.opencode/` y `.claude/` son adaptadores generados, no la fuente. No se
editan a mano: se regeneran.

```bash
bash "$HOME/dev-agent-kit/scripts/install-agent-adapters.sh" . \
  --agents claude,opencode \
  --profile "$HOME/dev-agent-profiles/profiles/odoo11"
```

El script no escribe `.gitignore`: en un repo nuevo, `.opencode/`, `.claude/skills/` y
`.claude/commands/` aparecen sin seguimiento. Añadirlos a `.git/info/exclude` si son
locales, o commitearlos a propósito; no usar `git add .` sin mirar.

### 2.2 Claude Code

1. Instalar y autenticar Claude Code una vez:
   `claude` y seguir el flujo de login.
2. En el repo, generar el adaptador:

   ```bash
   bash "$HOME/dev-agent-kit/scripts/install-agent-adapters.sh" . \
     --agents claude \
     --profile "$HOME/dev-agent-profiles/profiles/odoo11"
   ```

3. Claude Code lee `CLAUDE.md`, no `AGENTS.md`. Si no existe `CLAUDE.md`:

   ```bash
   ln -s AGENTS.md CLAUDE.md
   ```

   Si ya existe, añadir una línea que remita a `AGENTS.md`; no se pisa.
4. Abrir Claude Code en la raíz del repo. Elegir el modelo aprobado con `/model` y el
   esfuerzo con `/effort`. No usar `--dangerously-skip-permissions` en la formación.
5. Comprobar que las skills aparecen en `.claude/skills/` y que los comandos están en
   `.claude/commands/`.

Claude Code no es el único agente: es el ejemplo principal. El kit es agnóstico.

### 2.3 OpenCode

```bash
bash "$HOME/dev-agent-kit/scripts/install-agent-adapters.sh" . \
  --agents opencode \
  --profile "$HOME/dev-agent-profiles/profiles/odoo11"
```

OpenCode lee `AGENTS.md` y `.opencode/skills`; reiniciar la sesión después de generar el
adaptador. El proveedor y la clave se configuran fuera del repo.

### 2.4 Codex, pi y Hermes

`install-agent-adapters.sh` solo acepta `opencode` y `claude`; cualquier otro agente sale
con `unknown agent`. Para los demás, copia la fuente neutral a mano. El `cp -a` sobrescribe
skills homónimas: haz backup del directorio destino antes. El backup va antes del `mkdir`;
si el directorio no existe, no hay nada que respaldar.

```bash
# Codex
[ -d "$HOME/.codex/skills" ] && cp -a "$HOME/.codex/skills" "$HOME/.codex/skills.bak-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$HOME/.codex/skills"
cp -a "$HOME/dev-agent-kit/skills/." "$HOME/.codex/skills/"
cp -a "$HOME/dev-agent-profiles/profiles/odoo11/skills/." "$HOME/.codex/skills/"

# pi / gentle-shell
[ -d "$HOME/.pi/agent/skills" ] && cp -a "$HOME/.pi/agent/skills" "$HOME/.pi/agent/skills.bak-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$HOME/.pi/agent/skills"
cp -a "$HOME/dev-agent-kit/skills/." "$HOME/.pi/agent/skills/"
cp -a "$HOME/dev-agent-profiles/profiles/odoo11/skills/." "$HOME/.pi/agent/skills/"

# Hermes
[ -d "$HOME/.hermes/skills" ] && cp -a "$HOME/.hermes/skills" "$HOME/.hermes/skills.bak-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$HOME/.hermes/skills"
cp -a "$HOME/dev-agent-kit/skills/." "$HOME/.hermes/skills/"
cp -a "$HOME/dev-agent-profiles/profiles/odoo11/skills/." "$HOME/.hermes/skills/"
```

Codex lee su `AGENTS.md` global; los demás leen el `AGENTS.md` del repo o su norma global.
No copies los comandos `/verify` etc. a agentes que no los soportan; los comandos son una
comodidad, la puerta es el script. Si `gentle-ai` está instalado, `gentle-ai sync` puede
distribuir la fuente global; si no, se copia o se enlaza la skill concreta y se reinicia el
agente. No se duplica la fuente dentro del kit.

### 2.5 Las cinco skills del núcleo

| Skill | Cuándo se usa | Qué produce |
|---|---|---|
| `dev-verify` | después de cualquier cambio | evidencia y veredicto |
| `repro-first` | al arreglar un bug | test que falla antes y pasa después |
| `review-diff` | antes de pedir revisión | veredicto con hallazgos |
| `correct` | cuando se repite una corrección | lint, test o CI, no otra regla en prosa |
| `query-readonly` | cuando la respuesta necesita datos | consulta y resultado en evidencia |

El perfil Odoo añade `odoo-safe-change`, `odoo-11-code-review` y
`factorlibre-mr-preflight`. El perfil PHP es un esqueleto.

### 2.6 Cómo se prepara una skill

1. Detectar una corrección repetida en transcripciones, revisiones o tickets.
2. Clasificarla: naming, capas, errores, acceso a Odoo, tests, copy o commits.
3. Elegir el mecanismo más fuerte que funcione: API o arquitectura, tipos, lint, CI, test
   y documentación al final.
4. Escribir `SKILL.md` con frontmatter (`name`, `description`, `version`) y pasos
   observables.
5. Añadir un caso de eval si la skill es crítica; empezar con `--dry-run`.
6. Ejecutar `guard` y `verify`; la skill no es una wish list, es un procedimiento.

La descripción de una skill es su disparador. Si no se puede explicar en una frase, no está
lista.

### 2.7 Modelos

- Usar el proveedor y el modelo aprobados por la empresa.
- No poner claves, tokens ni `.env` en el repo, en `verify/config.env` ni en una captura.
- Claude Code: `/model`, `/effort`, `/context`, `/cost`; las claves viven en el entorno o
  en el gestor del agente.
- OpenCode, Codex, pi y Hermes: su configuración habitual; el kit no la duplica.
- En las evals, `--model` y `--judge-model` deben ser modelos distintos; el que ejecuta no
  se puntúa a sí mismo. Usar `<modelo-aprobado>` en la documentación, nunca un nombre
  interno.
- Empezar con `--dry-run`; después K=3. Una media alta con una corrida baja es una skill
  inestable.

### 2.8 Laboratorio 2

En el repo de laboratorio:

1. Romper `calc.py` a propósito.
2. Pedir al agente: “Usa `repro-first`: escribe el test que falla, conserva la salida y
   corrige después.”
3. Ejecutar `bash verify/run.sh`.
4. Pedir: “Usa `review-diff` sobre el diff; no edites.”
5. Elegir una corrección repetida y pedir: “Usa `correct`; convierte la regla en un lint,
   test o CI.”
6. Criterio de salida: hay un test nuevo, una salida de verify y una regla con mecanismo.

Si el compañero no tiene modelo o autenticación, el laboratorio se hace con los comandos y
la revisión del diff a mano; no se inventa una ejecución de agente.

## Sesión 3. Perfil, eval y cierre

### 3.1 Perfil Odoo 11

El perfil añade un linter de Odoo: `sudo()`, `cr.commit()`, SQL de escritura y `print()`.
También aporta `odoo-safe-change`, `odoo-11-code-review` y `factorlibre-mr-preflight`.

Si ya lo activaste en la sesión 1, esto es la revisión y la prueba del linter. Si no, actívalo
ahora:

```bash
mkdir -p .dev-agent/profiles
rsync -a --exclude='verify/config.env' \
  "$HOME/dev-agent-profiles/profiles/odoo11/" .dev-agent/profiles/odoo11/
printf 'DEV_AGENT_PROFILE=odoo11\n' > .dev-agent/config
bash guard/guard.sh
```

Probar que un `sudo()` o un `cr.commit()` en un fichero Python staged hace fallar el guard.
El perfil no sustituye a `guard` ni a `verify`: los dos siguen siendo la puerta.

El `TEST_CMD` de Odoo necesita el proyecto docker compose (`devel.yaml`) y una base
desechable; el kit no crea ese entorno. El laboratorio de perfil solo necesita `guard`; para
`verify` con Odoo, el repo y el equipo aportan la infraestructura.

El perfil PHP está en esqueleto. No se presenta como terminado.

### 3.2 Eval

La eval mide una skill o una regla, no un cambio de producto:

```bash
python3 evals/harness.py \
  --case-dir evals/cases/dev-verify/01-fix-failing-test \
  --rubric evals/rubric.dev-verify.json \
  --agent build \
  --model <modelo-aprobado> \
  --judge-model <modelo-aprobado-distinto> \
  --k 3
```

- Cada corrida va en un worktree o copia desechable.
- El juez recibe los artefactos; el harness calcula la media ponderada.
- Umbral 8,5; `--dry-run` valida el caso sin gastar modelo.
- **Deuda conocida**: `evals/harness.py` y `evals/loop.sh` todavía usan OpenCode. El runner
  neutral está pendiente. No se vende como agnóstico ni se usa como puerta obligatoria
  hasta que esa deuda se cierre.

### 3.3 Tech-doc

El repo de empresa es la norma canónica, no un submódulo:

```bash
git clone git@github.com:ScalpersCompany/scalpers-tech-doc.git \
  "$HOME/odoo-doodba-template/scalpers-tech-doc"
mkdir -p "$HOME/.agents"
ln -sfn "$HOME/odoo-doodba-template/scalpers-tech-doc/AGENTS.md" "$HOME/.agents/AGENTS.md"
bash "$HOME/dev-agent-kit/scripts/check-techdoc.sh" \
  --path "$HOME/odoo-doodba-template/scalpers-tech-doc" \
  --branch main --require-link
```

Si el check falla por un árbol sucio, la norma no es reproducible: se cierra el cambio en el
repo de empresa. `--allow-dirty` solo sirve para una revisión local. El kit no copia la
norma y no empuja tech-doc.

Si el compañero no tiene acceso a tech-doc, puede usar el `AGENTS.md` local del kit para
practicar; en un repo real de la empresa, la norma de tech-doc gana.

### 3.4 GGA y revisión

GGA es una revisión asesora opcional, no una puerta. `GGA_ADVISORY=1` informa sin bloquear;
sin proveedor o sin `.gga`, no se declara verde. No ejecutar `gga install`: pisaría el
pre-commit del kit.

```bash
bash scripts/install-gga.sh .
# editar .gga y elegir el proveedor aprobado
GGA_ADVISORY=1 bash scripts/review-gga.sh .
```

La revisión humana sigue siendo humana. El agente que escribió el cambio no es el que lo
aprueba. El merge y el despliegue no se delegan.

### 3.5 Laboratorio 3

1. Activar el perfil Odoo y comprobar que `guard` carga `profile:odoo`.
2. Meter un `sudo()` en un fichero staged y ver el fallo; retirarlo.
3. Ejecutar una eval con `--dry-run` y explicar qué validó.
4. Ejecutar `check-techdoc` y leer el estado.
5. Cerrar el checklist de salida.

## Checklist de salida

- [ ] Sabe clonar el kit, los perfiles y su repo.
- [ ] Tiene `git`, `bash`, `python3`, `rsync` y, si hay health check, `curl`.
- [ ] Sabe exportar `DEV_AGENT_KIT` en el entorno de git.
- [ ] Sabe instalar el kit en la raíz de su repo.
- [ ] Sabe copiar un perfil y escribir `.dev-agent/config`.
- [ ] Sabe que `.dev-agent/` es local o que el perfil debe ir a `profiles/` si se comparte.
- [ ] Sabe rellenar `verify/config.env` y `.dev-agent/verify.env`.
- [ ] Sabe ejecutar `guard` y `verify`, y explicar `skipped` y `exit 2`.
- [ ] Sabe dónde queda la evidencia manual y la del pre-push.
- [ ] Sabe generar los adaptadores de Claude y OpenCode.
- [ ] Sabe copiar skills a Codex, pi y Hermes, que no tienen adaptador.
- [ ] Sabe invocar `dev-verify`, `repro-first`, `review-diff`, `correct` y una skill de perfil.
- [ ] Sabe elegir un modelo aprobado y un juez distinto.
- [ ] Sabe que la eval todavía es OpenCode-only.
- [ ] Sabe que GGA es opcional y no sustituye a guard/verify.
- [ ] Sabe que no se toca producción, no se ponen secretos y no se empuja sin autorización.
- [ ] Sabe que tech-doc es la norma canónica y no se copia.

## Problemas frecuentes

| Síntoma | Causa probable | Arreglo |
|---|---|---|
| `guard: profile skipped` | no hay `.dev-agent/config` o la ruta del perfil no existe | revisar `DEV_AGENT_PROFILE` y `.dev-agent/profiles/<nombre>` |
| `dev-agent-kit verify not found` | el hook no encuentra el kit | exportar `DEV_AGENT_KIT` en el entorno de git; los GUI no leen el perfil |
| `rsync: command not found` | falta `rsync` | instalarlo antes de bootstrap/adapters |
| `verify: no SMOKE_CMD or TEST_CMD` | configuración vacía | rellenar `verify/config.env`; no es un verde |
| pre-push bloquea | falta `.dev-agent/verify.env` | copiar el ejemplo y rellenar `TEST_CMD` |
| `comment_lint` bloquea | comentario de prosa nuevo | quitarlo; solo directivas y cabeceras legales |
| `CLAUDE.md` no carga | Claude lee `CLAUDE.md`, no `AGENTS.md` | crear el enlace o añadir la referencia |
| las skills no aparecen | adaptador no generado o sesión antigua | regenerar y reiniciar el agente |
| `.dev-agent` no se ve en git | el hook lo excluyó localmente | es local; si quieres compartir el perfil, copiarlo a `profiles/` |
| `check-techdoc` falla | remoto, rama o árbol sucio | cerrar el cambio en tech-doc; no forzar |
| la eval no corre con Claude | el harness sigue atado a OpenCode | usar `--dry-run` o OpenCode; deuda conocida |
| `git push` rechazado | no hay autorización o el remoto no es el correcto | parar; no forzar el push |

## Seguridad y límites

- El kit es para la base de desarrollo, no para producción.
- No se usan datos de cliente en fixtures, tests, evals ni prompts.
- No se guardan secretos, tokens, claves ni contraseñas en el repo, la config o la evidencia.
- No se ejecuta `--dangerously-skip-permissions` en la formación.
- No se toca el CI de Scalpers; cada repo configura el suyo.
- Los hooks se pueden saltar con `--no-verify`; el CI es la garantía dura.
- El merge y el despliegue son decisiones humanas.
- El kit no crea el entorno de Odoo ni la base de datos: eso lo prepara el equipo.

## Estado actual que hay que decir en voz alta

- `bootstrap.sh` no instala perfiles; se copian a mano.
- `.dev-agent/` queda local y excluido; si el perfil debe ir a CI, va en `profiles/` y se commitea.
- El `.example` del perfil Odoo es una plantilla vacía; el `config.env` real de esta máquina no se copia.
- Los hooks tienen `/home/scalpers/dev-agent-kit` como ruta por defecto; `DEV_AGENT_KIT` debe estar en el entorno de git.
- `dev-agent init` y el lock de perfiles están diseñados, no implementados.
- El perfil PHP es un esqueleto.
- `evals/harness.py` y `evals/loop.sh` todavía usan OpenCode.
- `check-techdoc.sh` falla cerrado si tech-doc está sucio; el clon de esta máquina está en
  una rama de trabajo con cambios sin commitear.
- GGA es opcional y asesor; no sustituye a `guard` ni a `verify`.

## Enlaces

- `README.md`
- `docs/INSTALACION-Y-FUNCIONAMIENTO.md`
- `docs/PERFILES-EN-REPOS.md`
- `docs/CREAR-PERFIL.md`
- `docs/INTEGRACION-TECHDOC.md`
- `docs/EVAL-BASELINE.md`
- `docs/diagrams/sistema.html`
- `docs/diagrams/flujo-detallado.html`
- `docs/formacion/dev-agent-kit-formacion.html`
