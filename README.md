# Cisco IOS XE CSR1000v Ansible Automation and Monitoring

This project provisions three Cisco IOS XE CSR1000v routers and deploys a Docker Compose monitoring stack with SNMP Exporter, Prometheus, and Grafana.

## Project Tree

```text
ztp-cisco-telemetry/
├── README.md
├── Makefile
├── ansible.cfg
├── backups/
├── group_vars/
│   └── ios_routers.yml
├── host_vars/
│   ├── rtr-binus-alsut.yml
│   ├── rtr-binus-anggrek.yml
│   └── rtr-binus-inter.yml
├── inventory/
│   └── hosts.yml
├── monitoring/
│   ├── docker-compose.yml
│   ├── grafana/
│   │   ├── dashboards/
│   │   │   └── cisco-ios-snmp.json
│   │   └── provisioning/
│   │       ├── dashboards/
│   │       │   └── cisco-ios.yml
│   │       └── datasources/
│   │           └── prometheus.yml
│   ├── prometheus.yml
│   └── snmp.yml
├── playbooks/
│   ├── 01_check_reachability.yml
│   ├── 02_backup_config.yml
│   ├── 03_baseline_config.yml
│   ├── 04_routing_config.yml
│   ├── 05_verify.yml
│   └── 06_save_config.yml
├── requirements.txt
├── requirements.yml
├── scripts/
│   ├── start-monitoring.sh
│   ├── setup-control-node.sh
│   ├── use-project-ansible.sh
│   └── verify-monitoring.sh
└── templates/
    └── baseline.j2
```

## Lab IP Plan

| Device | Role | IP |
| --- | --- | --- |
| srv-binus | Ansible and monitoring host | 192.168.10.100 |
| rtr-binus-anggrek | CSR1000v router 1 | 192.168.10.10 |
| rtr-binus-alsut | CSR1000v router 2 | 192.168.10.20 |
| rtr-binus-inter | CSR1000v router 3 | 192.168.10.30 |

## Quick Start

Run this once on `srv-binus` from the project root:

```bash
cd ~/ztp-cisco-telemetry
bash scripts/setup-control-node.sh
```

Activate the project Ansible environment:

```bash
source scripts/use-project-ansible.sh
```

After activation, `ansible-playbook` resolves to `~/ztp-cisco-telemetry/.venv-libssh/bin/ansible-playbook`, which includes `ansible-pylibssh` for IOS XE `network_cli`.

Validate:

```bash
which ansible-playbook
ansible --version
ansible-inventory --graph
ansible-playbook playbooks/01_check_reachability.yml
```

The same workflow is also available through `make`:

```bash
make setup
make reachability
```

The setup script also installs Docker Engine and Docker Compose plugin. If Docker was just installed or the user was just added to the `docker` group, open a new shell or use `sudo docker ...` for the current shell.

## Prerequisites

Install Docker and Docker Compose plugin on `srv-binus`:

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
```

If a previous Docker Desktop CLI install exists but no Docker daemon is running, install the Ubuntu engine package:

```bash
sudo apt install -y docker.io docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
```

The CSR1000v routers must already have management IP, SSH, enable password, and local user access configured from console.

## Run Commands

Run all commands from the project root:

```bash
cd ~/ztp-cisco-telemetry
```

Validate inventory:

```bash
ansible-inventory --graph
ansible-inventory --list
```

Check router reachability:

```bash
ansible-playbook playbooks/01_check_reachability.yml
```

Backup running configuration:

```bash
ansible-playbook playbooks/02_backup_config.yml
ls -lah backups/
```

Apply baseline configuration:

```bash
ansible-playbook playbooks/03_baseline_config.yml
ansible-playbook playbooks/06_save_config.yml
```

Configure Loopback0 and OSPF:

```bash
ansible-playbook playbooks/04_routing_config.yml
ansible-playbook playbooks/06_save_config.yml
```

Verify configuration:

```bash
ansible-playbook playbooks/05_verify.yml
```

Force-save running configuration when needed:

```bash
ansible-playbook playbooks/06_save_config.yml
```

Start monitoring:

```bash
cd ~/ztp-cisco-telemetry
make monitoring-up
make monitoring-verify
```

## Monitoring Flow

The monitoring path is:

```text
CSR1000v SNMP agent -> SNMP Exporter :9116 -> Prometheus :9090 -> Grafana :3000
```

Service URLs:

| Service | URL |
| --- | --- |
| SNMP Exporter | http://192.168.10.100:9116 |
| Prometheus | http://192.168.10.100:9090 |
| Grafana | http://192.168.10.100:3000 |

Grafana login:

```text
username: admin
password: admin
```

Prometheus is automatically provisioned as the Grafana data source, and the `Cisco IOS XE SNMP Overview` dashboard is loaded from `monitoring/grafana/dashboards/cisco-ios-snmp.json`.

## Verification Steps

Router access:

```bash
ping -c 3 192.168.10.10
ping -c 3 192.168.10.20
ping -c 3 192.168.10.30
ansible-playbook playbooks/01_check_reachability.yml
```

Router configuration:

```bash
ansible-playbook playbooks/05_verify.yml
```

Expected router evidence:

```text
show ip interface brief
show running-config | include snmp-server
show running-config | include ntp server
show running-config interface Loopback0
show ip ospf neighbor
```

Prometheus targets:

```bash
curl http://localhost:9090/-/ready
curl "http://localhost:9116/snmp?target=192.168.10.10&module=if_mib&auth=public_v2"
curl "http://localhost:9090/api/v1/query?query=up%7Bjob%3D%22snmp-cisco-ios%22%7D"
```

Open Prometheus targets:

```text
http://192.168.10.100:9090/targets
```

Expected state: `snmp-cisco-ios` targets are `UP`.

Validated Prometheus API result should include all three router instances with value `1`:

```text
192.168.10.10
192.168.10.20
192.168.10.30
```

Grafana dashboard:

```text
http://192.168.10.100:3000/d/cisco-ios-xe-snmp/cisco-ios-xe-snmp-overview
```

Expected panels:

- Router Availability: `up{job="snmp-cisco-ios"}`
- Interface Incoming Traffic: `rate(ifHCInOctets{job="snmp-cisco-ios"}[5m]) * 8`
- Interface Outgoing Traffic: `rate(ifHCOutOctets{job="snmp-cisco-ios"}[5m]) * 8`
- Interface Operational Status: `ifOperStatus{job="snmp-cisco-ios"}`
- Router Uptime: `sysUpTime{job="snmp-cisco-ios"} / 100`

## Troubleshooting

If Ansible cannot connect, verify SSH from `srv-binus`:

```bash
ssh user@192.168.10.10
```

For a noninteractive credential test:

```bash
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no user@192.168.10.10 'show version'
```

If this returns `Permission denied`, fix the router console bootstrap first. The Ansible inventory and playbooks cannot authenticate until the router has a matching local user and VTY SSH login:

```text
configure terminal
username user privilege 15 secret P@ssw0rd
enable secret P@ssw0rd
ip domain-name binus.local
crypto key generate rsa modulus 2048
ip ssh version 2
line vty 0 4
 login local
 transport input ssh
 privilege level 15
end
write memory
```

If enable mode fails, confirm `enable secret` and `ansible_become_password` match in `group_vars/ios_routers.yml`.

If playbooks fail with missing modules, install collections:

```bash
ansible-galaxy collection install cisco.ios ansible.netcommon
```

If backup files are missing, confirm the command was run from the project root and that `backups/` exists.

If SNMP targets are down in Prometheus, verify router SNMP configuration:

```text
show running-config | include snmp-server
```

Then test SNMP Exporter directly:

```bash
curl "http://localhost:9116/snmp?target=192.168.10.10&module=if_mib&auth=public_v2"
```

If Grafana has no dashboard, restart the stack so provisioning runs again:

```bash
cd ~/ztp-cisco-telemetry/monitoring
docker compose restart grafana
```

If OSPF neighbors are empty, verify there is a routed data-plane link between CSR routers. The playbook configures Loopback0 and OSPF process state, but OSPF adjacency requires connected interfaces in the same area.
