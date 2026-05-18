#!/usr/bin/env bash

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="${PROJECT_DIR}/.venv-libssh"

if [ ! -x "${VENV_DIR}/bin/ansible-playbook" ]; then
  echo "Project Ansible environment is missing."
  echo "Run: bash scripts/setup-control-node.sh"
  return 1 2>/dev/null || exit 1
fi

export PATH="${VENV_DIR}/bin:${PATH}"
export ANSIBLE_CONFIG="${PROJECT_DIR}/ansible.cfg"

echo "Using project Ansible: $(command -v ansible-playbook)"
