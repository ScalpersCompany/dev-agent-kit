#!/usr/bin/env python3
"""Validate a dev-agent-kit profile contract."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REQUIRED = ["name", "version", "api", "language", "description", "guard", "verify", "skills", "evals", "agents"]
PATH_KEYS = ["verify", "skills", "evals", "agents"]
ENV_KEYS = ["PROFILE_NAME", "PROFILE_LANGUAGE", "PROFILE_GUARD_CHECKS", "PROFILE_VERIFY_CONFIG", "PROFILE_SKILLS", "PROFILE_EVALS", "PROFILE_AGENTS"]
NAME_RE = re.compile(r"^[a-z][a-z0-9-]*$")
VERSION_RE = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")


def safe_path(root: Path, value: str) -> Path:
    path = Path(value)
    if path.is_absolute() or ".." in path.parts:
        raise ValueError(f"path escapes the profile: {value}")
    return root / path


def validate(profile_dir: Path) -> list[str]:
    errors: list[str] = []
    contract_path = profile_dir / "profile.json"
    if not contract_path.is_file():
        return [f"missing profile.json in {profile_dir}"]
    try:
        data = json.loads(contract_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return [f"invalid profile.json: {exc}"]
    if not isinstance(data, dict):
        return ["profile.json must be a JSON object"]
    for key in REQUIRED:
        if key not in data:
            errors.append(f"profile.json missing key: {key}")
    if data.get("name") != "_template" and not NAME_RE.match(str(data.get("name", ""))):
        errors.append("name must match ^[a-z][a-z0-9-]*$")
    if not VERSION_RE.match(str(data.get("version", ""))):
        errors.append("version must be MAJOR.MINOR.PATCH")
    if data.get("api") != 1:
        errors.append("api must be 1")
    if not isinstance(data.get("guard"), list):
        errors.append("guard must be a list")
    else:
        for guard in data["guard"]:
            try:
                path = safe_path(profile_dir, guard)
            except ValueError as exc:
                errors.append(str(exc))
                continue
            if not path.is_file():
                errors.append(f"guard file not found: {guard}")
    for key in PATH_KEYS:
        value = data.get(key)
        if not isinstance(value, str) or not value:
            errors.append(f"{key} must be a non-empty string")
            continue
        try:
            path = safe_path(profile_dir, value)
        except ValueError as exc:
            errors.append(str(exc))
            continue
        if not path.exists():
            errors.append(f"{key} path not found: {value}")
    gga_path = profile_dir / "gga" / "REVIEW-RULES.md"
    if not gga_path.is_file():
        errors.append("missing gga/REVIEW-RULES.md")
    env_path = profile_dir / "profile.env"
    if not env_path.is_file():
        errors.append("missing profile.env")
    else:
        env = {}
        for line in env_path.read_text(encoding="utf-8").splitlines():
            if not line or line.lstrip().startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            env[key.strip()] = value.strip()
        for key in ENV_KEYS:
            if key not in env:
                errors.append(f"profile.env missing key: {key}")
        if env.get("PROFILE_NAME") != data.get("name"):
            errors.append("PROFILE_NAME does not match profile.json name")
        for key in ["PROFILE_VERIFY_CONFIG", "PROFILE_SKILLS", "PROFILE_EVALS", "PROFILE_AGENTS"]:
            value = env.get(key, "")
            try:
                safe_path(profile_dir, value)
            except ValueError as exc:
                errors.append(f"{key}: {exc}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate a dev-agent-kit profile")
    parser.add_argument("profile", nargs="?", default=".", help="profile directory")
    args = parser.parse_args()
    profile_dir = Path(args.profile).resolve()
    if not profile_dir.is_dir():
        print(f"error: not a directory: {profile_dir}", file=sys.stderr)
        return 2
    errors = validate(profile_dir)
    if errors:
        for error in errors:
            print(f"error: {error}", file=sys.stderr)
        return 1
    print(f"ok: {profile_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
