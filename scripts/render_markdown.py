#!/usr/bin/env python3
"""Render TechFlow's small Markdown subset as readable terminal output."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import textwrap
from pathlib import Path


RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"
CYAN = "\033[36m"
BRIGHT_CYAN = "\033[96m"
YELLOW = "\033[33m"
GREEN = "\033[32m"

ORDERED_RE = re.compile(r"^(\d+)\.\s+(.*)$")
BULLET_RE = re.compile(r"^[-*]\s+(.*)$")
HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)$")
LINK_RE = re.compile(r"\[([^]]+)]\(([^)]+)\)")
CODE_RE = re.compile(r"`([^`]+)`")
BOLD_RE = re.compile(r"\*\*([^*]+)\*\*")


def paint(value: str, *styles: str, color: bool) -> str:
    if not color or not value:
        return value
    return "".join(styles) + value + RESET


def render_inline(value: str, *, color: bool) -> str:
    value = LINK_RE.sub(lambda match: f"{match.group(1)} ({match.group(2)})", value)
    value = CODE_RE.sub(
        lambda match: paint(match.group(1), BOLD, GREEN, color=color), value
    )
    value = BOLD_RE.sub(
        lambda match: paint(match.group(1), BOLD, color=color), value
    )
    return value


def is_block_start(line: str) -> bool:
    return bool(
        not line.strip()
        or line.startswith("```")
        or HEADING_RE.match(line)
        or ORDERED_RE.match(line)
        or BULLET_RE.match(line)
    )


def wrap(value: str, width: int) -> list[str]:
    value = LINK_RE.sub(lambda match: f"{match.group(1)} ({match.group(2)})", value)
    value = CODE_RE.sub(
        lambda match: f"`{match.group(1).replace(' ', chr(0x00A0))}`", value
    )
    value = BOLD_RE.sub(
        lambda match: f"**{match.group(1).replace(' ', chr(0x00A0))}**", value
    )
    lines = textwrap.wrap(
        value,
        width=max(width, 20),
        break_long_words=False,
        break_on_hyphens=False,
    ) or [""]
    return [line.replace(chr(0x00A0), " ") for line in lines]


def render_banner(title: str, width: int, *, color: bool) -> list[str]:
    label = " TECHFLOW TRAINING "
    top = "╭─" + label + "─" * max(width - len(label) - 3, 1) + "╮"
    bottom = "╰" + "─" * (width - 2) + "╯"
    title_text = title.upper()
    title_lines = wrap(title_text, width - 6)
    result = [paint(top, BRIGHT_CYAN, color=color)]
    for line in title_lines:
        padding = " " * max(width - len(line) - 5, 0)
        body = f"│  {line}{padding} │"
        result.append(paint(body, BOLD, color=color))
    result.append(paint(bottom, BRIGHT_CYAN, color=color))
    return result


def render_document(
    source: str,
    *,
    width: int = 88,
    color: bool = False,
    title: str | None = None,
) -> str:
    width = max(40, min(width, 100))
    lines = source.splitlines()

    if lines and lines[0].startswith("# "):
        document_title = lines.pop(0)[2:].strip()
    else:
        document_title = title or "TechFlow"
    if title:
        document_title = title

    output = render_banner(document_title, width, color=color)
    output.append("")
    index = 0

    while index < len(lines):
        line = lines[index].rstrip()
        if not line:
            if output and output[-1] != "":
                output.append("")
            index += 1
            continue

        if line.startswith("```"):
            index += 1
            code_lines: list[str] = []
            while index < len(lines) and not lines[index].startswith("```"):
                code_lines.append(lines[index].rstrip())
                index += 1
            index += index < len(lines)
            output.append(paint("  COMMAND", BOLD, YELLOW, color=color))
            for code_line in code_lines:
                output.append(
                    "  "
                    + paint("│", DIM, color=color)
                    + " "
                    + paint(code_line, BOLD, GREEN, color=color)
                )
            continue

        heading = HEADING_RE.match(line)
        if heading:
            heading_text = heading.group(2).strip()
            output.append(
                paint(f"── {heading_text} ", BOLD, BRIGHT_CYAN, color=color)
                + paint("─" * max(width - len(heading_text) - 5, 1), DIM, color=color)
            )
            index += 1
            continue

        ordered = ORDERED_RE.match(line)
        if ordered:
            number, content = ordered.groups()
            index += 1
            continuation: list[str] = []
            while index < len(lines):
                candidate = lines[index]
                if is_block_start(candidate.lstrip() if candidate.startswith("   ") else candidate):
                    if candidate.startswith("   ") and candidate.strip():
                        continuation.append(candidate.strip())
                        index += 1
                        continue
                    break
                continuation.append(candidate.strip())
                index += 1
            item = " ".join([content, *continuation]).strip()
            item_lines = wrap(item, width - 9)
            label = paint(f"[{number}]", BOLD, YELLOW, color=color)
            output.append(f"  {label} {render_inline(item_lines[0], color=color)}")
            for item_line in item_lines[1:]:
                output.append(f"      {render_inline(item_line, color=color)}")
            continue

        bullet = BULLET_RE.match(line)
        if bullet:
            item_lines = wrap(bullet.group(1), width - 8)
            marker = paint("•", BOLD, YELLOW, color=color)
            output.append(f"  {marker} {render_inline(item_lines[0], color=color)}")
            for item_line in item_lines[1:]:
                output.append(f"    {render_inline(item_line, color=color)}")
            index += 1
            continue

        paragraph = [line.strip()]
        index += 1
        while index < len(lines) and not is_block_start(lines[index]):
            paragraph.append(lines[index].strip())
            index += 1
        for paragraph_line in wrap(" ".join(paragraph), width - 4):
            output.append("  " + render_inline(paragraph_line, color=color))

    while output and output[-1] == "":
        output.pop()
    return "\n".join(output) + "\n"


def should_use_color() -> bool:
    return bool(
        sys.stdout.isatty()
        and "NO_COLOR" not in os.environ
        and os.environ.get("TERM", "") != "dumb"
    )


def display(output: str, *, pager: bool) -> None:
    terminal_lines = shutil.get_terminal_size((88, 24)).lines
    use_pager = bool(
        pager
        and sys.stdout.isatty()
        and os.environ.get("TECHFLOW_PAGER", "auto") != "never"
        and output.count("\n") >= terminal_lines - 2
        and shutil.which("less")
    )
    if use_pager:
        subprocess.run(["less", "-R", "-F", "-X"], input=output, text=True, check=False)
    else:
        sys.stdout.write(output)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", type=Path)
    parser.add_argument("--title")
    parser.add_argument("--no-pager", action="store_true")
    parser.add_argument("--width", type=int)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    width = args.width or shutil.get_terminal_size((88, 24)).columns
    output = render_document(
        args.path.read_text(encoding="utf-8"),
        width=width,
        color=should_use_color(),
        title=args.title,
    )
    display(output, pager=not args.no_pager)


if __name__ == "__main__":
    main()
