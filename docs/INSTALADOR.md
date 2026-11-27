# Instalador DevAgentKit

Un comando y un menú. El instalador centraliza toda la instalación y la configuración: kit,
perfil, skills, guardarraíles, CodeGraph, Engram, referencia a tech-doc, E2E de Playwright,
GGA y la configuración local de verify. No deja pasos manuales sueltos; si algo necesita red
o un dato de tu entorno, lo pregunta antes de ejecutarlo.

## Una línea

```bash
git clone https://github.com/ScalpersCompany/dev-agent-kit.git "$HOME/.dev-agent-kit" \
  && "$HOME/.dev-agent-kit/install.sh"
```

Si ya tienes el kit: `./install.sh`.

El kit y el wrapper se instalan una vez en el home; los hooks, el perfil activo, el harness
E2E y su configuración se escriben en el repo de desarrollo porque son locales a ese repo.
El instalador pregunta antes de instalar dependencias que necesitan red y respalda como
`.bak-<fecha>` los ficheros que reemplaza.

## Qué pregunta

1. Repo de desarrollo (detecta el directorio actual).
2. Perfil o perfiles: `odoo11`, `php`, los que existan o todos.
3. Perfil activo, si instalas varios.
4. Agentes: Claude Code, OpenCode, Codex, pi, Hermes o todos.
5. Toolchain: Engram, GGA, gentle-ai, Claude si falta, dependencias de Claude y MCP de Engram; después ejecuta el smoke.
6. Herramientas de guard: ruff, black, mypy, eslint, tsc y gitleaks; son opt-in y no crean configuración por su cuenta.
7. CodeGraph y Engram, si están instalados.
8. Tech-doc: sí/no; HTML solo si se pide.
9. E2E: dependencias npm y Chromium; comando, URL base y health path. Escribe la
   configuración en `verify/config.env` y en `.dev-agent/verify.env`.
10. GGA: reglas del perfil, proveedor opcional y pre-push opcional.
11. Ejecutar `verify` ahora, si hay comandos configurados.

## Qué instala

- kit, perfiles y perfil activo en `.dev-agent/`;
- Engram, GGA, gentle-ai y Claude si faltan; jq para el plugin de Claude;
- herramientas de guard: ruff, black, mypy, eslint, tsc y gitleaks;
- MCP de Engram configurado en los agentes elegidos;
- skills del kit y del perfil copiadas al directorio global de cada agente;
- pre-commit, pre-push, guard, verify, comment_lint y `.dev-agent/verify.env`;
- índice CodeGraph y `.engram/config.json` si están disponibles;
- harness E2E, dependencias npm y Chromium si se aceptan;
- reglas GGA del núcleo y del perfil, y `.dev-agent/gga.env` si se pide pre-push;
- configuración E2E y de verify en los dos ficheros que leen `verify` y el hook;
- `docs/TECHDOC.md` y enlace local `docs/techdoc.html` si se pide;
- `bin/dev-agent` y, si se puede, `~/.local/bin/dev-agent`;
- smoke de instalación: binarios, versiones, MCP de Engram, skills y `engram doctor`.

No copia el HTML privado de tech-doc, no toca producción, no guarda secretos y no hace
push. Los backups se quedan como `*.bak-<fecha>`; los artefactos generados se excluyen en
`.git/info/exclude` para que el repo no quede sucio.

## Después de instalar

```bash
dev-agent doctor
dev-agent guard
dev-agent verify
```

Si `~/.local/bin` no está en PATH, usa `$HOME/.dev-agent-kit/bin/dev-agent` o añade la
ruta. La guía diaria es `docs/USO-RAPIDO.md`; el paso a paso para enseñar a un compañero,
`docs/formacion/guia-paso-a-paso.html`; las URL y versiones de las tecnologías,
`docs/REFERENCIAS-TECNOLOGIAS.md`; la mejora de skills, `docs/MEJORAR-SKILLS.md`.

## Actualizar core y Perfiles

El kit y los perfiles no se actualizan con `git pull` a ciegas. Desde el wrapper:

```bash
dev-agent update --check
dev-agent update --yes
dev-agent update --profiles --target /ruta/al/repo --yes
```

`update` lee el remoto y la rama del propio repo, exige el árbol limpio en tracked, hace
`fetch`, y solo avanza con `merge --ff-only`. Si hay divergencia, cambios locales o el
remoto no responde, se para y no toca nada. Antes de avanzar deja un tag local
`dev-agent-update-backup-<fecha>-<core|profiles>`. Con `--target` sincroniza las copias de
`.dev-agent/profiles/<nombre>` y las respalda como `.bak-<fecha>`; no sobrescribe
`verify/config.env`.

El perfiles repo es la fuente; el repo de desarrollo solo tiene copias instaladas. Actualiza
primero el core, después los perfiles y, si hace falta, vuelve a ejecutar `doctor` y
`guard` en el repo de desarrollo.

## Si algo falla

- **No hay acceso a tech-doc**: el kit sigue instalado; repite con `--techdoc-path` o pide
  acceso. La referencia queda pendiente, no se declara verde.
- **No hay CodeGraph/Engram**: se omiten con aviso; el doctor lo muestra.
- **No hay Docker para el HTML**: se deja la referencia y el comando de build.
- **El perfil no existe**: el instalador para antes de tocar el repo.
- **Un hook falla**: no se salta con `--no-verify`; se corrige la causa. El CI sigue siendo
  la garantía dura.
- **E2E sin red**: el instalador pregunta antes de ejecutar `npm install` y Chromium; si no
  hay red, deja el harness y la configuración, y lo dice.

## Modo automatizado

```bash
./install.sh --target /ruta/al/repo --profiles all --active odoo11 \
  --agents all --with-toolchain --with-dev-deps --with-codegraph --with-engram --with-techdoc \
  --with-gga --with-e2e-deps --with-e2e-config \
  --e2e-cmd "npm --prefix e2e test" \
  --e2e-base-url "http://127.0.0.1:8000" --e2e-health-path / \
  --verify-now --yes
```
