# Diagrama del sistema

El mapa visual está en `docs/diagrams/sistema.html`; se puede abrir en el navegador o
previsualizar desde el chat. Este documento deja la versión Mermaid para el repositorio.

## Flujo

```mermaid
flowchart TB
  subgraph Entrada
    A[Jira SIS / ticket / bug / idea]
    A2[Decisión humana de alcance]
  end

  subgraph Agentes
    B[Hermes]
    B2[OpenCode]
    B3[Claude Code]
    B4[Codex / pi]
    C[AGENTS.md + skills + perfil]
  end

  subgraph Proceso
    D[SDD: spec-driven-development]
    D2[ODD: texto siempre activo]
    D3[RDD: gentle-ai review]
    D4[rsc-harness: ASDD opcional]
  end

  subgraph Perfil
    E[profiles/odoo11]
    E2[guard/odoo.sh + verify + skills + casos]
    E3[profiles/php: esqueleto]
  end

  subgraph Puerta
    F[pre-commit: guard genérico + perfil]
    G[pre-push: verify + base desechable]
    H[eval K=3 si cambia skill o regla]
    I[evidence/summary.json]
  end

  subgraph Salida
    J[Revisión humana + GGA opcional]
    K[Rama / MR / CI]
    L[Producción: autorización humana]
  end

  subgraph Capas
    M[gentle-ai: instala y sincroniza]
    N[engram: memoria local]
    P[scalpers-tech-doc: norma de empresa]
  end

  A --> A2 --> B
  B2 --> C
  B3 --> C
  B4 --> C
  B --> C
  C --> D
  D2 --> E
  D3 --> E
  D4 --> E
  E --> E2
  E2 --> F --> G --> H --> I --> J
  J --> K --> L
  M -.-> C
  N -.-> C
  P -.-> C
```

## Flujo detallado

El mapa visual con los bucles y las decisiones está en
`docs/diagrams/flujo-detallado.html`. Esta es la versión Mermaid:

```mermaid
flowchart TD
  N0[skills/ + commands/ + agents/] --> N1[adapters .opencode/.claude]
  N0 --> N2[gentle-ai global]
  N3[scalpers-tech-doc/AGENTS.md] --> A[Entrada: Jira SIS / ticket / bug / idea]
  N1 --> A
  N2 --> A

  A --> B{¿Bug reproducible?}
  B -->|sí| C[repro-first: test rojo]
  B -->|no| D[SDD: spec y criterios]
  C --> E[rama + perfil activo + verify config]
  D --> E
  E --> F[implementar + tests + docs]

  F --> G[pre-commit: guard genérico + perfil]
  G --> H{¿guard pasa?}
  H -->|no| F
  H -->|sí| I[pre-push: verify + evidencia]
  I --> J{¿verify pasa?}
  J -->|no| F
  J -->|sí| K{¿cambia skill, prompt, regla o rúbrica?}

  K -->|no| L[revisión humana del diff]
  K -->|sí| M[eval: TASK + context + K=3 + juez distinto]
  M --> N{¿score >= 8.5?}
  N -->|no| O[mejorar skill o rúbrica] --> M
  N -->|sí| L

  L --> P[rama / MR / CI]
  P --> Q{¿CI verde?}
  Q -->|no| F
  Q -->|sí| R[merge humano]
  R --> S[producción: autorización humana]

  F -.-> T[engram / CHANGELOG]
  G -.-> U[guard-report.json]
  I -.-> V[evidence/summary.json]
  M -.-> W[score.json]
```

La deuda conocida está marcada en el mapa: `docs/CREAR-PERFIL.md` y el README
explican que el **harness de eval** y `evals/loop.sh` todavía ejecutan OpenCode; la
fuente de skills, comandos y juez ya es neutral, pero el runner de eval no. El flujo
neutral de guard/verify no depende de OpenCode.

## Cómo leerlo

- **Entrada**: la persona decide qué se hace y con qué prioridad.
- **Agentes**: Hermes, OpenCode, Claude, Codex y pi ejecutan el mismo flujo; lo que cambia
  es el cliente, no la puerta.
- **Proceso**: SDD es una skill; ODD es texto siempre activo; RDD es un binario; rsc-harness
  es la capa de spec/ASDD y es opcional. `gentle-ai` no sustituye a rsc-harness.
- **Perfil**: el núcleo no sabe Odoo ni PHP. Odoo 11 aporta su linter, verify, skills y
  casos; PHP es un esqueleto.
- **Puerta**: pre-commit y pre-push son los mismos hooks para todos los perfiles. La
  evaluación se ejecuta cuando cambia una skill, un prompt, una regla o una rúbrica. El
  harness de eval todavía ejecuta OpenCode; el runner neutral está pendiente.
- **Salida**: la revisión, el merge y el despliegue son humanos. El kit no toca producción.
- **Capas**: `gentle-ai` distribuye; `engram` recuerda en local hasta que exista la
  infraestructura AWS.

## Estado

| Pieza | Estado |
|---|---|
| core `guard`, `verify`, evals, hooks | implementado y probado |
| perfil Odoo 11 | extraído; repo público `ScalpersCompany/dev-agent-profiles` |
| perfil PHP | esqueleto |
| `dev-agent init` y lock | pendiente |
| plantilla y generador | implementados |
| GGA | opcional, no es puerta |
| rsc-harness | opcional; no lo sustituye gentle-ai |
| producción | humano |

## Ficheros

- `docs/diagrams/sistema.html`: mapa visual con el flujo y las capas.
- `docs/CREAR-PERFIL.md`: cómo montar un perfil nuevo.
- `docs/PERFILES-EN-REPOS.md`: contrato, registro e instalación.
- `profiles/_template`: plantilla base.
