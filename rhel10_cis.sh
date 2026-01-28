#!/usr/bin/env bash
set -Eeuo pipefail

### =====================================================
# SAFE RUNNER for ansible-lockdown RHEL10-CIS
# - Installs dependencies
# - Runs CIS audit/remediation
# - SSH lockout protection with rollback
### =====================================================

MODE="${1:-audit}"   # audit | remediate
WORKDIR="/opt/rhel10-cis"
ROLE_REPO="https://github.com/ansible-lockdown/RHEL10-CIS.git"
LOG="/var/log/rhel10-cis-ansible.log"
BACKUP="/root/cis-ssh-backup"
ROLLBACK_SCRIPT="/root/cis_ssh_rollback.sh"
ROLLBACK_JOB=""
ANSIBLE_OUT="$WORKDIR/ansible.out"

mkdir -p "$WORKDIR" "$BACKUP"
touch "$LOG"
exec > >(tee -a "$LOG") 2>&1

log(){ echo "[INFO] $*"; }
warn(){ echo "[WARN] $*"; }
die(){ echo "[FATAL] $*"; exit 1; }

### -------------------------------
# VALIDATION
### -------------------------------
[[ $EUID -eq 0 ]] || die "Run as root"

grep -qiE 'rhel|rocky|alma' /etc/os-release || die "Unsupported OS"

[[ "$MODE" =~ ^(audit|remediate)$ ]] || die "Usage: $0 audit|remediate"

if [[ "$MODE" == "remediate" ]]; then
  who | grep -q ssh || die "No active SSH session detected — refusing remediation"
fi

log "MODE=$MODE"

### -------------------------------
# BACKUP SSH & PAM
### -------------------------------
log "Backing up SSH and PAM configs"

cp -a /etc/ssh "$BACKUP/ssh"
cp -a /etc/pam.d "$BACKUP/pam.d"
cp -a /etc/security "$BACKUP/security"

### -------------------------------
# CREATE ROLLBACK SCRIPT
### -------------------------------
cat >"$ROLLBACK_SCRIPT" <<EOF
#!/usr/bin/env bash
set -e
echo "[ROLLBACK] Restoring SSH & PAM"
cp -a $BACKUP/ssh/* /etc/ssh/
cp -a $BACKUP/pam.d/* /etc/pam.d/
cp -a $BACKUP/security/* /etc/security/
systemctl restart sshd || systemctl restart ssh
EOF
chmod +x "$ROLLBACK_SCRIPT"

### -------------------------------
# ARM ROLLBACK (10 MIN)
### -------------------------------
if command -v at >/dev/null 2>&1; then
  echo "$ROLLBACK_SCRIPT" | at now + 10 minutes
  ROLLBACK_JOB="at"
  log "Rollback armed via at"
elif command -v systemd-run >/dev/null 2>&1; then
  systemd-run --on-active=10min "$ROLLBACK_SCRIPT"
  ROLLBACK_JOB="systemd"
  log "Rollback armed via systemd-run"
else
  warn "Rollback scheduler not available"
fi

### -------------------------------
# INSTALL DEPENDENCIES
### -------------------------------
log "Installing dependencies"

dnf -y install git python3 python3-pip ansible-core || die "Package install failed"

pip3 install --upgrade pip

ansible-galaxy collection install \
  community.general \
  community.crypto \
  ansible.posix || die "Collection install failed"

### -------------------------------
# CLONE CIS ROLE
### -------------------------------
cd "$WORKDIR"
if [[ ! -d RHEL10-CIS ]]; then
  git clone "$ROLE_REPO"
fi

cd RHEL10-CIS

### -------------------------------
# CREATE VARS (SAFE DEFAULT)
### -------------------------------
cat >cis_vars.yml <<EOF
audit_only: $( [[ "$MODE" == "audit" ]] && echo true || echo false )
run_audit: true
setup_audit: true

rhel10cis_level_1: true
rhel10cis_level_2: false
rhel10cis_disruption_high: false

apply_ssh_hardening: true
EOF

### -------------------------------
# CREATE PLAYBOOK
### -------------------------------
cat >site_runner.yml <<EOF
- hosts: localhost
  connection: local
  become: true
  vars_files:
    - cis_vars.yml
  roles:
    - role: .
EOF

### -------------------------------
# RUN ANSIBLE
### -------------------------------
log "Running CIS Ansible role"

ansible-playbook site_runner.yml \
  -i localhost, \
  | tee "$ANSIBLE_OUT"

ANSIBLE_RC=${PIPESTATUS[0]}

[[ $ANSIBLE_RC -eq 0 ]] || warn "Ansible exited with code $ANSIBLE_RC"

### -------------------------------
# SSH VALIDATION (CRITICAL)
### -------------------------------
log "Validating SSH"

sshd -t || {
  warn "sshd config invalid — triggering rollback"
  bash "$ROLLBACK_SCRIPT"
  exit 1
}

systemctl reload sshd || systemctl restart ssh || {
  warn "SSH reload failed — triggering rollback"
  bash "$ROLLBACK_SCRIPT"
  exit 1
}

ssh -o BatchMode=yes -o ConnectTimeout=5 localhost "echo SSH_OK" || {
  warn "SSH self-test failed — triggering rollback"
  bash "$ROLLBACK_SCRIPT"
  exit 1
}

log "SSH validation successful"

### -------------------------------
# DISARM ROLLBACK
### -------------------------------
if [[ "$ROLLBACK_JOB" == "at" ]]; then
  atrm \$(atq | awk '{print \$1}') || true
elif [[ "$ROLLBACK_JOB" == "systemd" ]]; then
  systemctl list-timers --all | grep cis_ssh_rollback | awk '{print \$1}' | xargs -r systemctl stop
fi

log "Rollback disarmed"

### -------------------------------
# FINISH
### -------------------------------
log "CIS Ansible run completed successfully"
log "Log: $LOG"
log "Ansible output: $ANSIBLE_OUT"







sed -i 's/\r$//' rhel10cis.sh
chmod +x rhel10cis.sh
