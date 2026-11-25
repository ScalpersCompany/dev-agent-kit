#!/usr/bin/env python3
import argparse
import io
import re
import subprocess
import sys
import tokenize
from pathlib import Path

SKIP_DIRS = {".git", "node_modules", ".venv", "venv", "__pycache__", "dist", "build", ".mypy_cache"}
PY_EXT = {".py", ".pyw"}
XML_EXT = {".xml", ".html", ".htm", ".xslt"}
JS_EXT = {".js", ".jsx", ".ts", ".tsx", ".css", ".scss"}
PHP_EXT = {".php"}
SH_EXT = {".sh", ".bash"}
SQL_EXT = {".sql"}
YAML_EXT = {".yml", ".yaml"}
DIRECTIVE = re.compile(
    r"^(?:!|.*-\*-.*coding|©|copyright|license|spdx|noqa\b|type:\s*ignore|pylint:\s*disable|pragma:\s*no\s*cover|"
    r"fmt:\s*(?:off|skip)|isort:\s*skip|nosec\b|coverage:\s*ignore|shellcheck\b|"
    r"eslint-disable|@ts-ignore|@ts-expect-error|istanbul ignore|prettier-ignore)",
    re.IGNORECASE,
)


def added_lines(root):
    cmd = [
        "git",
        "-C",
        str(root),
        "diff",
        "--cached",
        "--unified=0",
        "--no-color",
        "--diff-filter=ACMR",
        "--",
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise SystemExit(proc.stderr.strip() or "git diff failed")
    files = {}
    current = None
    new_line = None
    for line in proc.stdout.splitlines():
        if line.startswith("+++ b/"):
            current = line[6:]
            files.setdefault(current, set())
            new_line = None
            continue
        if line.startswith("--- "):
            current = None
            continue
        if line.startswith("@@") and current:
            match = re.search(r"\+(\d+)(?:,(\d+))?", line)
            new_line = int(match.group(1)) if match else None
            continue
        if current is None or new_line is None:
            continue
        if line.startswith("+"):
            files[current].add(new_line)
            new_line += 1
        elif line.startswith("-"):
            continue
        else:
            new_line += 1
    return files


def directive(comment):
    body = comment.strip()
    for prefix in ("#", "//", "/*", "<!--", "--"):
        if body.startswith(prefix):
            body = body[len(prefix):].strip()
            break
    return bool(DIRECTIVE.match(body))


def python_comments(text):
    found = []
    try:
        tokens = tokenize.generate_tokens(io.StringIO(text).readline)
        for token in tokens:
            if token.type == tokenize.COMMENT:
                found.append((token.start[0], token.string))
    except (tokenize.TokenError, IndentationError):
        pass
    return found


def xml_comments(text):
    found = []
    for number, line in enumerate(text.splitlines(), 1):
        index = line.find("<!--")
        if index >= 0:
            found.append((number, line[index:]))
    return found


def js_comments(text):
    found = []
    index = 0
    line = 1
    state = None
    quote = None
    start_line = 0
    buffer = []
    while index < len(text):
        char = text[index]
        following = text[index + 1] if index + 1 < len(text) else ""
        if state == "string":
            if char == "\\":
                index += 2
                continue
            if char == quote:
                state = None
            if char == "\n":
                line += 1
            index += 1
            continue
        if state == "template":
            if char == "\\":
                index += 2
                continue
            if char == "`":
                state = None
            if char == "\n":
                line += 1
            index += 1
            continue
        if state == "line":
            if char == "\n":
                found.append((start_line, "".join(buffer)))
                state = None
                line += 1
                buffer = []
            else:
                buffer.append(char)
            index += 1
            continue
        if state == "block":
            if char == "*" and following == "/":
                found.append((start_line, "".join(buffer)))
                state = None
                index += 2
                continue
            if char == "\n":
                line += 1
            buffer.append(char)
            index += 1
            continue
        if char in "\"'":
            state = "string"
            quote = char
            index += 1
            continue
        if char == "`":
            state = "template"
            index += 1
            continue
        if char == "/" and following == "/":
            state = "line"
            start_line = line
            buffer = []
            index += 2
            continue
        if char == "/" and following == "*":
            state = "block"
            start_line = line
            buffer = []
            index += 2
            continue
        if char == "\n":
            line += 1
        index += 1
    if state in ("line", "block"):
        found.append((start_line, "".join(buffer)))
    return found


def hash_comments(text):
    found = []
    for number, line in enumerate(text.splitlines(), 1):
        quote = None
        escaped = False
        for index, char in enumerate(line):
            if quote:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == quote:
                    quote = None
                continue
            if char in "'\"":
                quote = char
                continue
            if char == "#":
                found.append((number, line[index:]))
                break
    return found


def sql_comments(text):
    found = []
    index = 0
    line = 1
    state = None
    start_line = 0
    buffer = []
    quote = False
    while index < len(text):
        char = text[index]
        following = text[index + 1] if index + 1 < len(text) else ""
        if quote:
            if char == "'":
                quote = False
            if char == "\n":
                line += 1
            index += 1
            continue
        if state == "line":
            if char == "\n":
                found.append((start_line, "".join(buffer)))
                state = None
                line += 1
                buffer = []
            else:
                buffer.append(char)
            index += 1
            continue
        if state == "block":
            if char == "*" and following == "/":
                found.append((start_line, "".join(buffer)))
                state = None
                index += 2
                continue
            if char == "\n":
                line += 1
            buffer.append(char)
            index += 1
            continue
        if char == "'":
            quote = True
            index += 1
            continue
        if char == "-" and following == "-":
            state = "line"
            start_line = line
            buffer = []
            index += 2
            continue
        if char == "/" and following == "*":
            state = "block"
            start_line = line
            buffer = []
            index += 2
            continue
        if char == "\n":
            line += 1
        index += 1
    if state in ("line", "block"):
        found.append((start_line, "".join(buffer)))
    return found


def php_comments(text):
    found = []
    index = 0
    line = 1
    state = None
    start_line = 0
    buffer = []
    quote = None
    while index < len(text):
        char = text[index]
        following = text[index + 1] if index + 1 < len(text) else ""
        if state == "string":
            if char == "\\":
                index += 2
                continue
            if char == quote:
                state = None
            if char == "\n":
                line += 1
            index += 1
            continue
        if state == "line":
            if char == "\n":
                found.append((start_line, "".join(buffer)))
                state = None
                line += 1
                buffer = []
            else:
                buffer.append(char)
            index += 1
            continue
        if state == "block":
            if char == "*" and following == "/":
                if not "".join(buffer).startswith("*"):
                    found.append((start_line, "".join(buffer)))
                state = None
                index += 2
                continue
            if char == "\n":
                line += 1
            buffer.append(char)
            index += 1
            continue
        if char in "'\"":
            state = "string"
            quote = char
            index += 1
            continue
        if char == "/" and following == "/":
            state = "line"
            start_line = line
            buffer = []
            index += 2
            continue
        if char == "#" and following != "[":
            state = "line"
            start_line = line
            buffer = []
            index += 1
            continue
        if char == "/" and following == "*":
            state = "block"
            start_line = line
            buffer = []
            index += 2
            continue
        if char == "\n":
            line += 1
        index += 1
    if state in ("line", "block"):
        if state == "line" or not "".join(buffer).startswith("*"):
            found.append((start_line, "".join(buffer)))
    return found


def comments_for(path, text):
    suffix = path.suffix.lower()
    if suffix in PY_EXT:
        return python_comments(text)
    if suffix in XML_EXT:
        return xml_comments(text)
    if suffix in JS_EXT:
        return js_comments(text)
    if suffix in PHP_EXT:
        return php_comments(text)
    if suffix in SH_EXT or suffix in YAML_EXT:
        return hash_comments(text)
    if suffix in SQL_EXT:
        return sql_comments(text)
    return []


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--staged", action="store_true")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    if not args.staged:
        print("comment_lint: only staged additions are enforced")
        return 0
    files = added_lines(root)
    findings = []
    for relative, lines in sorted(files.items()):
        path = (root / relative).resolve()
        if not path.is_file():
            continue
        try:
            parts = path.relative_to(root).parts
        except ValueError:
            continue
        if any(part in SKIP_DIRS for part in parts):
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        for number, comment in comments_for(path, text):
            if number in lines and not directive(comment):
                findings.append((relative, number, comment.strip()))
    for relative, number, comment in findings:
        print("%s:%s: COMMENT %s" % (relative, number, comment))
    if findings:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
