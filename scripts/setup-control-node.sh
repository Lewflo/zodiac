#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="${PROJECT_DIR}/.venv-libssh"

cd "${PROJECT_DIR}"

echo "[1/5] Installing Ubuntu packages"
sudo apt update
sudo apt install -y python3 python3-pip python3-venv sshpass docker.io docker-compose-plugin
sudo systemctl enable --now docker || true
sudo usermod -aG docker "${USER}" || true

echo "[2/5] Creating Python virtual environment"
python3 -m venv "${VENV_DIR}"

echo "[3/5] Installing Ansible Python dependencies"
"${VENV_DIR}/bin/python" -m pip install --upgrade pip
"${VENV_DIR}/bin/python" -m pip install -r requirements.txt

echo "[4/5] Installing Ansible collections"
"${VENV_DIR}/bin/ansible-galaxy" collection install -r requirements.yml

echo "[5/5] Validating project Ansible environment"
"${VENV_DIR}/bin/ansible" --version
"${VENV_DIR}/bin/ansible-inventory" --graph

cat <<'EOF'

Setup complete.

Activate this project environment before running playbooks:

  source scripts/use-project-ansible.sh

Then run playbooks normally:

  ansible-playbook playbooks/01_check_reachability.yml

EOF
