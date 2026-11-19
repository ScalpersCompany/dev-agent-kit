# Commands

Neutral prompt templates. The gate is always the shell command; these files are
convenience wrappers for an agent that supports slash commands.

`scripts/install-agent-adapters.sh <repo> --agents opencode,claude` copies them to the
agent's project directory. The generated directories are gitignored; the source stays
here. The `agent:` frontmatter is OpenCode-specific; Claude ignores it, and the command
text still works.
