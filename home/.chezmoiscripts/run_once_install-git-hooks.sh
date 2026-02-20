#!/bin/bash
# Installs the chezmoi re-add pre-commit hook into the dotfiles repo.
# Runs once (re-runs if this script content changes).

DOTFILES_DIR="${HOME}/dev/personal/dotfiles"
HOOKS_DIR="${DOTFILES_DIR}/.git/hooks"

ln -f "${DOTFILES_DIR}/git/hooks/pre-commit" "${HOOKS_DIR}/pre-commit"
chmod +x "${HOOKS_DIR}/pre-commit"
echo "Installed pre-commit hook at ${HOOKS_DIR}/pre-commit"
