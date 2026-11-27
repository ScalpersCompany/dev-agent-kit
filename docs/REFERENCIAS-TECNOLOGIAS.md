# Referencias de tecnologías

> Documento de referencia para el equipo. No es la lista de dependencias transitivas de
> Python: son las herramientas, agentes y servicios que instalamos o usamos directamente.
> Versiones locales de la máquina de formación (`dev-nicolas`, 2026-11-27). Las versiones
> cambian: el comando de comprobación y la URL oficial son la referencia.

## Cómo leer esta tabla

- **Tecnología**: nombre que aparece en el kit, la guía o el instalador.
- **Para qué la usamos**: papel en el flujo, no una descripción de marketing.
- **URL oficial**: fuente para instalar, actualizar o consultar.
- **Versión local**: la que había el 2026-11-27; no es una promesa de versión fija.
- **Instalación**: lo que hace el instalador principal o el comando de respaldo.

## Núcleo del kit y agentes

| Tecnología | Para qué la usamos | URL oficial | Versión local | Instalación |
|---|---|---|---|---|
| **Engram** | Memoria persistente de decisiones, bugs y contexto; MCP para los agentes. | https://github.com/Gentleman-Programming/engram | 3.7.2 | `install-toolchain.sh`; descarga el release oficial |
| **GGA** (Gentleman Guardian Angel) | Segunda revisión del diff, bloqueante; reglas del núcleo y del perfil. | https://github.com/Gentleman-Programming/gentleman-guardian-angel | v2.10.1 | `install-toolchain.sh`; instalador oficial |
| **gentle-ai** | Instala y sincroniza skills, agentes y MCP entre herramientas. | https://github.com/Gentleman-Programming/gentle-ai | 4.5.0 | `install-toolchain.sh`; instalador oficial |
| **gentle-shell** | Workspace de terminal para el agente pi; no es la puerta del kit. | https://github.com/Gentleman-Programming/gentle-shell | 4.7.0 | Instalación opcional; no la instala el kit |
| **CodeGraph** | Índice local de estructura, símbolos y llamadas; contexto antes de editar. | https://github.com/colbymchenry/codegraph | 1.6.2 | `install.sh` lo indexa si está; instalación por npm/curl |
| **Model Context Protocol (MCP)** | Protocolo que conecta Engram con Claude, OpenCode, Codex, pi y Hermes. | https://modelcontextprotocol.io/ | — | Lo configura `engram setup` o el fallback de `install-toolchain.sh` |

## Agentes y CLIs

| Tecnología | Para qué la usamos | URL oficial | Versión local | Instalación |
|---|---|---|---|---|
| **Claude Code** | Agente de Anthropic; lee skills globales y el MCP de Engram. | https://www.anthropic.com/claude-code | 2.1.325 | `install-toolchain.sh`; `npm install -g @anthropic-ai/claude-code` |
| **OpenCode** | Agente de terminal open source; adaptadores `.opencode/`. | https://opencode.ai/ · https://github.com/anomalyco/opencode | v2.3.0 | Instalación del agente; el kit genera adaptadores |
| **Codex** | CLI de OpenAI; skills globales y MCP. | https://github.com/openai/codex | 0.167.0 | Instalación del agente; el kit copia skills |
| **pi** | Agent harness extensible; workspace Gentle Shell. | https://github.com/earendil-works/pi | 1.5.0 | Instalación del agente; el kit copia skills |
| **Hermes Agent** | Agente de Nous Research; MCP y skills. | https://hermes-agent.nousresearch.com/docs | 0.23.3 | Instalación del agente; el kit copia skills |
| **Claude Code CLI** | Ver Claude Code; el binario se llama `claude`. | https://docs.anthropic.com/en/docs/claude-code/overview | 2.1.325 | Ver arriba |

## Calidad, pruebas y utilidades del repo

| Tecnología | Para qué la usamos | URL oficial | Versión local | Instalación |
|---|---|---|---|---|
| **Playwright** | Suite E2E de flujos de usuario; deja informe, JUnit/JSON y trazas. | https://playwright.dev/ | 1.49.1 (baseline) | `install.sh` pregunta; `npm install` + `npx playwright install chromium` |
| **ruff** | Lint y formato Python opcional en guard. | https://docs.astral.sh/ruff/ | 0.17.6 | `install-dev-deps.sh` |
| **black** | Formato Python opcional; `--check` en guard. | https://black.readthedocs.io/ | 26.10.1 | `install-dev-deps.sh` |
| **mypy** | Tipos estáticos Python opcional. | https://mypy-lang.org/ | 2.4.1 | `install-dev-deps.sh` |
| **ESLint** | Lint JavaScript/TypeScript en repos que tengan `package.json`. | https://eslint.org/ | 10.15.0 | `install-dev-deps.sh` |
| **TypeScript / tsc** | Comprobación de tipos TypeScript. | https://www.typescriptlang.org/ | 7.0.2 | `install-dev-deps.sh` |
| **gitleaks** | Detección de secretos en staged. | https://github.com/gitleaks/gitleaks | 8.30.1 | `install-dev-deps.sh`; release oficial |
| **jq** | Requisito del plugin de Claude Code de Engram. | https://jqlang.github.io/jq/ | 1.6 | `install-toolchain.sh`; gestor de paquetes |
| **pipx** | Aísla las herramientas Python instaladas por el kit. | https://pipx.pypa.io/ | — | Requisito/instalación del sistema |

## Stack de producto y entorno

| Tecnología | Para qué la usamos | URL oficial | Versión local | Nota |
|---|---|---|---|---|
| **Odoo 11** | Producto principal de Scalpers; perfiles, módulos, XML y ORM v11. | https://www.odoo.com/documentation/11.0/ | 11.0 | No se usa Odoo 12+ ni OWL |
| **PostgreSQL** | Base de datos de Odoo; las pruebas usan una base desechable. | https://www.postgresql.org/ | Según el entorno | Nunca la base compartida en pruebas |
| **Docker / Compose** | Entorno Doodba de desarrollo y ejecución de Odoo/Postgres. | https://www.docker.com/ | 26.1.4 | No se toca producción |
| **Git** | Ramas, hooks, diffs y evidencia de commits. | https://git-scm.com/ | 2.34.1 | Los hooks son locales |
| **Python** | Lenguaje del núcleo, perfiles y herramientas. | https://www.python.org/ | 3.14.9 local | El kit declara compatibilidad desde 3.8; el perfil Odoo usa Python 3.5/3.10 según imagen |
| **Node.js** | Runtime de Playwright, CodeGraph, agentes y herramientas JS. | https://nodejs.org/ | 22.23.4 | Necesario para E2E y varios agentes |
| **npm** | Instalación de agentes, Playwright, ESLint y TypeScript. | https://www.npmjs.com/ | 10.9.9 | Prefijo local del usuario |

## Repositorios internos y material de empresa

| Repositorio | Para qué | URL |
|---|---|---|
| **dev-agent-kit** | Núcleo, instalador, guard, verify, skills, evals, E2E, GGA. | https://github.com/ScalpersCompany/dev-agent-kit |
| **dev-agent-profiles** | Perfiles por lenguaje y contrato de equipo. | https://github.com/ScalpersCompany/dev-agent-profiles |
| **scalpers-tech-doc** | Norma de empresa y documentación canónica. | https://github.com/ScalpersCompany/scalpers-tech-doc |
| **scalpers-v11** | Código de producto Odoo 11 (FactorLibre). | https://git.factorlibre.com/odoo-11/scalpers-v11 |
| **Guía paso a paso** | Instalación, CodeGraph, primera prueba y cómo enseñarlo. | `docs/formacion/guia-paso-a-paso.html` |
| **Guía del equipo** | Conceptos: skills, perfiles, juez y agentes. | `docs/formacion/guia-equipo.html` |
| **Presentación** | Deck para proyectar en la formación. | `docs/formacion/plan-formacion-equipo.html` |

## Opcionales que pueden aparecer en la instalación

| Tecnología | Para qué | URL | Estado |
|---|---|---|---|
| **rsc-harness** | Harness de especificación, tareas y verificación; no es la puerta del kit. | https://github.com/ericrisco/rsc-harness | Opcional; instalación por repo |
| **rsc-brain** | Memoria/wiki autoalojada con MCP; no sustituye a Engram. | https://github.com/ericrisco/rsc-brain | Opcional; contenedores |
| **Homebrew** | Gestor de paquetes en macOS/Linux para algunas herramientas. | https://brew.sh/ | Opcional |
| **GitHub CLI (`gh`)** | Revisión de PRs y estado de repositorios. | https://cli.github.com/ | Opcional |

## Comprobación rápida de versiones

```bash
engram --version
gga --version
gentle-ai --version
gentle-shell --version
codegraph --version
claude --version
opencode --version
codex --version
pi --version
hermes --version
node --version
npm --version
python3 --version
playwright --version 2>/dev/null || true
ruff --version
black --version
mypy --version
eslint --version
tsc --version
gitleaks version
jq --version
```

## Lo que no se debe deducir de esta tabla

- Una herramienta instalada no es una herramienta configurada: Engram necesita su MCP,
  GGA necesita proveedor y reglas, y las skills necesitan estar en la ruta global del agente.
- Una herramienta instalada no es una puerta: guard y verify son los comandos que deciden;
  GGA es la segunda revisión; el CI y la persona siguen siendo la garantía final.
- Las versiones son una foto de esta máquina. Antes de formar, comprueba las URLs y ejecuta
  `dev-agent doctor`; si una versión cambia, actualiza esta tabla y el CHANGELOG.
- No se incluyen tokens, claves, rutas de credenciales ni datos de cliente. Las URLs son
  públicas o internas de Scalpers, no secretos.
