# Instalador DevAgentKit

Un comando y un menú. El instalador deja el kit, el perfil, las skills, los guardarraíles,
CodeGraph, Engram y la referencia a tech-doc en el repo de desarrollo.

## Una línea

```bash
git clone https://github.com/ScalpersCompany/dev-agent-kit.git "$HOME/.dev-agent-kit" \
  && "$HOME/.dev-agent-kit/install.sh"
```

Si ya tienes el kit: `./install.sh`.

## Qué pregunta

1. Repo de desarrollo (detecta el directorio actual).
2. Perfil o perfiles: `odoo11`, `php`, los que existan o todos.
3. Perfil activo, si instalas varios.
4. Agentes: Claude Code, OpenCode, Codex, pi, Hermes o todos.
5. CodeGraph y Engram, si están instalados.
6. Tech-doc: sí/no; HTML solo si se pide.

## Qué instala

- kit, perfiles y perfil activo en `.dev-agent/`;
- todas las skills del core y de los perfiles elegidos;
- comandos y adaptadores para los agentes elegidos;
- pre-commit, pre-push, guard, verify, comment_lint y `.dev-agent/verify.env`;
- índice CodeGraph y `.engram/config.json` si están disponibles;
- `docs/TECHDOC.md` y enlace local `docs/techdoc.html` si se pide;
- `bin/dev-agent` y, si se puede, `~/.local/bin/dev-agent`.

No copia el HTML privado de tech-doc, no toca producción, no guarda secretos y no hace
push.

## Después de instalar

```bash
dev-agent doctor
dev-agent guard
dev-agent verify
```

Si `~/.local/bin` no está en PATH, usa `$HOME/.dev-agent-kit/bin/dev-agent` o añade la
ruta. La guía diaria es `docs/USO-RAPIDO.md`; la mejora de skills, `docs/MEJORAR-SKILLS.md`.

## Si algo falla

- **No hay acceso a tech-doc**: el kit sigue instalado; repite con `--techdoc-path` o pide
  acceso. La referencia queda pendiente, no se declara verde.
- **No hay CodeGraph/Engram**: se omiten con aviso; el doctor lo muestra.
- **No hay Docker para el HTML**: se deja la referencia y el comando de build.
- **El perfil no existe**: el instalador para antes de tocar el repo.
- **Un hook falla**: no se salta con `--no-verify`; se corrige la causa. El CI sigue siendo
  la garantía dura.

## Modo automatizado

```bash
./install.sh --target /ruta/al/repo --profiles all --active odoo11 \
  --agents all --with-codegraph --with-engram --with-techdoc --yes
```
