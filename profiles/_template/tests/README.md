# Profile tests

Add tests for the profile's own scripts, especially the guard checks. A guard that is not
tested is a guard that can silently stop blocking.

```bash
python3 -m unittest discover -s tests -v
```

The core validator also checks the contract:

```bash
python3 /path/to/dev-agent-kit/scripts/validate-profile.py .
```
