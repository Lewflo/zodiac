SHELL := /usr/bin/env bash

.PHONY: setup env-check inventory reachability backup baseline routing verify save monitoring-up monitoring-ps monitoring-verify

setup:
	bash scripts/setup-control-node.sh

env-check:
	. scripts/use-project-ansible.sh && ansible --version && ansible-inventory --graph

inventory:
	. scripts/use-project-ansible.sh && ansible-inventory --list

reachability:
	. scripts/use-project-ansible.sh && ansible-playbook playbooks/01_check_reachability.yml

backup:
	. scripts/use-project-ansible.sh && ansible-playbook playbooks/02_backup_config.yml

baseline:
	. scripts/use-project-ansible.sh && ansible-playbook playbooks/03_baseline_config.yml

routing:
	. scripts/use-project-ansible.sh && ansible-playbook playbooks/04_routing_config.yml

verify:
	. scripts/use-project-ansible.sh && ansible-playbook playbooks/05_verify.yml

save:
	. scripts/use-project-ansible.sh && ansible-playbook playbooks/06_save_config.yml

monitoring-up:
	bash scripts/start-monitoring.sh

monitoring-ps:
	cd monitoring && (docker compose ps || sudo docker compose ps)

monitoring-verify:
	bash scripts/verify-monitoring.sh
