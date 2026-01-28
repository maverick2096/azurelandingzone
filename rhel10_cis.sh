#!/usr/bin/env bash
set -Eeuo pipefail

# =========================================================
# SAFE RUNNER for ansible-lockdown RHEL10-CIS (AS-IS)
# - Does NOT change repo structure
# - Uses site_runner.yml (official)
# - SSH rollback protection
# =========================================================

MODE="${1:-audit}"          # audit | remediate
BASE_DIR="/opt/rhel10-cis"
REPO_DIR="$BASE_DIR/RHEL10-CIS"
REPO_URL="https://github.com/ansible-lockdown/RHEL10-CIS.git"

LOG="/var/log/rhel10-cis-ansible.log"
BACKUP_DIR="/root/cis-ssh-backup"
ROLLBACK_SCRIPT="/root/cis_ssh_rollback.sh"
ANSIBLE_OUT="$BASE_DIR/ansible.out"

mkdir -p "$BASE_DIR" "$BACKUP_DIR"
touch "$LOG"
exec > >(tee -a "$LOG") 2>&1

log(){ echo "[INFO] $*"; }
warn(){ echo "[WARN] $*"; }
die(){ echo "[FATAL] $*"; exit 1; }

# ---------------------------------------------------------
# VALIDATION
# ---------------------------------------------------------
[[ $EUID -eq 0 ]] || die "Run as root"

grep -qiE 'rhel|rocky|alma' /etc/os-release || die "Unsupported OS"

[[ "$MODE" =~ ^(audit|remediate)$ ]] || die "Usage: $0 audit|remediate"

if [[ "$MODE" == "remediate" ]]; then
  who | grep -q ssh || die "No active SSH session detected — refusing remediation"
fi

log "MODE=$MODE"

# ---------------------------------------------------------
# BACKUP SSH / PAM
# ---------------------------------------------------------
log "Backing up SSH & PAM"

cp -a /etc/ssh "$BACKUP_DIR/ssh"
cp -a /etc/pam.d "$BACKUP_DIR/pam.d"
cp -a /etc/security "$BACKUP_DIR/security"

# ---------------------------------------------------------
# CREATE ROLLBACK SCRIPT
# ---------------------------------------------------------
cat >"$ROLLBACK_SCRIPT" <<EOF
#!/usr/bin/env bash
set -e
echo "[ROLLBACK] Restoring SSH & PAM"
cp -a $BACKUP_DIR/ssh/* /etc/ssh/
cp -a $BACKUP_DIR/pam.d/* /etc/pam.d/
cp -a $BACKUP_DIR/security/* /etc/security/
systemctl restart sshd || systemctl restart ssh
EOF
chmod +x "$ROLLBACK_SCRIPT"

# ---------------------------------------------------------
# ARM ROLLBACK (10 MIN)
# ---------------------------------------------------------
if command -v at >/dev/null 2>&1; then
  echo "$ROLLBACK_SCRIPT" | at now + 10 minutes
  log "Rollback armed via at"
elif command -v systemd-run >/dev/null 2>&1; then
  systemd-run --on-active=10min "$ROLLBACK_SCRIPT"
  log "Rollback armed via systemd-run"
else
  warn "No rollback scheduler available"
fi

# ---------------------------------------------------------
# INSTALL DEPENDENCIES
# ---------------------------------------------------------
log "Installing dependencies"

dnf -y install git python3 python3-pip ansible-core || die "Package install failed"
pip3 install --upgrade pip

ansible-galaxy collection install \
  ansible.posix \
  community.general \
  community.crypto || die "Collection install failed"

# ---------------------------------------------------------
# CLONE / UPDATE REPO (AS-IS)
# ---------------------------------------------------------
cd "$BASE_DIR"
if [[ ! -d "$REPO_DIR" ]]; then
  git clone "$REPO_URL"
else
  cd "$REPO_DIR"
  git pull
fi

cd "$REPO_DIR"

# ---------------------------------------------------------
# CONFIGURE cis_vars.yml (SAFE DEFAULTS)
# ---------------------------------------------------------
log "Configuring cis_vars.yml"

cat >cis_vars.yml <<EOF
audit_only: $( [[ "$MODE" == "audit" ]] && echo true || echo false )
run_audit: true
setup_audit: true

rhel10cis_level_1: true
rhel10cis_level_2: false
rhel10cis_disruption_high: false
EOF

# ---------------------------------------------------------
# RUN CIS (OFFICIAL ENTRYPOINT)
# ---------------------------------------------------------
log "Running CIS via site_runner.yml"

ansible-playbook site_runner.yml \
  -i localhost, \
  -c local \
  -b \
  | tee "$ANSIBLE_OUT"

ANSIBLE_RC=${PIPESTATUS[0]}
[[ $ANSIBLE_RC -eq 0 ]] || warn "Ansible exited with code $ANSIBLE_RC"

# ---------------------------------------------------------
# SSH VALIDATION (FIXED – NO HOST KEY FALSE NEGATIVE)
# ---------------------------------------------------------
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

ssh \
  -o BatchMode=yes \
  -o ConnectTimeout=5 \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  localhost "echo SSH_OK" || {
    warn "SSH self-test failed — triggering rollback"
    bash "$ROLLBACK_SCRIPT"
    exit 1
}

log "SSH validation successful"

# ---------------------------------------------------------
# DISARM ROLLBACK
# ---------------------------------------------------------
if command -v at >/dev/null 2>&1; then
  atq | awk '{print $1}' | xargs -r atrm
elif command -v systemd-run >/dev/null 2>&1; then
  systemctl list-timers --all | grep cis_ssh_rollback | awk '{print $1}' | xargs -r systemctl stop
fi

log "Rollback disarmed"

# ---------------------------------------------------------
# FINISH
# ---------------------------------------------------------
log "CIS run completed"
log "Ansible output: $ANSIBLE_OUT"
log "Log file: $LOG"




# --- Disable /tmp hardening (cloud-safe) ---
rhel10cis_rule_1_1_2: false   # Ensure /tmp is configured
rhel10cis_rule_1_1_3: false   # nodev on /tmp
rhel10cis_rule_1_1_4: false   # nosuid on /tmp
rhel10cis_rule_1_1_5: false   # noexec on /tmp
