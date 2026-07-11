"""Colored terminal logging, matching the style of the old scripts/utils.sh."""

import os
import sys

_USE_COLOR = os.environ.get("NO_COLOR") is None and sys.stdout.isatty()

_BLUE = "\033[34m" if _USE_COLOR else ""
_GREEN = "\033[32m" if _USE_COLOR else ""
_YELLOW = "\033[33m" if _USE_COLOR else ""
_RED = "\033[31m" if _USE_COLOR else ""
_RESET = "\033[0m" if _USE_COLOR else ""


def info(msg: str) -> None:
    print(f"{_BLUE}==> {msg}{_RESET}")


def success(msg: str) -> None:
    print(f"{_GREEN}==> {msg}{_RESET}")


def warning(msg: str) -> None:
    print(f"{_YELLOW}==> {msg}{_RESET}")


def error(msg: str) -> None:
    print(f"{_RED}==> {msg}{_RESET}", file=sys.stderr)


def heading(msg: str) -> None:
    print()
    info("====================")
    info(msg)
    info("====================")
