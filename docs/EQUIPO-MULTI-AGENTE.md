# Equipo multiagente sobre el flujo `team`

El flujo `team` (`ScalpersCompany/dev-agent-profiles`) declara los roles de un equipo de
desarrollo en `roles.json`, y el runner (`guard/team_lint.py`) lee ese fichero. No es un perfil
activable: corre sobre el perfil de lenguaje activo. Nadie tiene que usar el mismo agente: la
puerta son comandos, y cada rol corre en el agente que tenga su dueño.

## La puerta no depende de ningún agente

`guard/` y `verify/` son bash y Python 3.8+ y git hooks. No llaman ni conocen ningún agente
concreto; el contrato de roles también es JSON puro. La única pieza que nombra agentes es
`evals/agent_runner.py`, que acepta OpenCode, Claude Code, Codex, pi y Hermes, y trata a los
cinco igual.

## Un agente por rol, generado desde el contrato

```bash
dev-agent roles claude   [--roles <roles.json>] [--out <dir>] [--model-map <json>] [--check]
dev-agent roles opencode [--roles <roles.json>] [--out <dir>] [--model-map <json>] [--check]
```

`scripts/render-roles.py` lee `roles.json` del flujo y escribe un fichero Markdown por rol, con la
superficie de escritura, las lecturas, el comando de cierre y lo prohibido tomados del
contrato. El contrato sigue siendo la fuente de verdad: cada fichero generado lo dice y
`--check` falla si el fichero quedó atrás.

| Destino | Ruta por defecto | Formato |
|---|---|---|
| `claude` | `.claude/agents/<rol>.md` | frontmatter `name`, `description`, `tools`, `disallowedTools`, `model` |
| `opencode` | `.opencode/agents/<rol>.md` | frontmatter `description`, `mode: subagent`, `permissions` |

En Claude Code los roles de solo lectura (`review`, `verify`, `judge`) reciben
`disallowedTools: Write, Edit, NotebookEdit`; en OpenCode v2 reciben una regla `edit` en
`deny`. Los dos pueden ejecutar `bash`, porque su comando de cierre es un comando; la garantía
fuerte de que el árbol no cambió es la del contrato: hash antes y después
(`team_lint.py --tree-snapshot` y `--tree-unchanged`), no la confianza en el agente.

Los modelos son cosa de cada agente. `claude` trae un mapa por defecto (`plan`, `dev` y
`verify` en `sonnet`; `review` y `judge` en `opus`), porque el contrato exige que quien revisa
y quien puntúa no sea el modelo que implementó. Se cambia con `--model-map` (JSON `rol →
modelo`) y en `opencode` no se pone modelo salvo que se pase el mapa, para no fijar un
proveedor ajeno.

## Verificación

```bash
claude plugin validate .claude/agents     # Claude Code acepta los cinco
opencode debug agents                     # OpenCode v2 lista los cinco como subagente
dev-agent roles claude --check            # nada quedó atrás respecto al contrato
```

`opencode` v2 lee `.opencode/agents/`; las versiones 1 leían `.opencode/agent/`. Los ficheros
de `scripts/install-agent-adapters.sh` usan la ruta antigua y el formato viejo de frontmatter,
así que para un equipo de roles se usa `dev-agent roles`.
