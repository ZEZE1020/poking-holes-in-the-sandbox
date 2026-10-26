#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

readonly WORKSHOP_USER="workshop"
readonly TTYD_VERSION="${TTYD_VERSION:-1.7.7}"
readonly TTYD_URL="https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.x86_64"
readonly TTYD_PATH="/usr/local/bin/ttyd"
readonly K3S_INSTALL_URL="https://get.k3s.io"
readonly KATA_MANAGER_URL="https://raw.githubusercontent.com/kata-containers/kata-containers/main/utils/kata-manager.sh"

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl kmod openssl \
  jq linux-modules-extra-"$(uname -r)" stress-ng

modprobe kvm
modprobe kvm_intel

if ! id --user "$WORKSHOP_USER" >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash "$WORKSHOP_USER"
fi
install -d -m 0750 -o "$WORKSHOP_USER" -g "$WORKSHOP_USER" "/home/$WORKSHOP_USER/.kube"

curl --fail --location --retry 5 --output "$TTYD_PATH" "$TTYD_URL"
chmod 0755 "$TTYD_PATH"

if [ ! -x /usr/local/bin/containerd-shim-kata-v2 ]; then
  set +e
  curl --fail --location --retry 5 "$KATA_MANAGER_URL" | bash -s -- -o -t
  kata_install_status=${PIPESTATUS[1]}
  set -e
  if [ "$kata_install_status" -ne 0 ] && [ ! -x /opt/kata/runtime-rs/bin/containerd-shim-kata-v2 ]; then
    echo "Kata Containers installation failed" >&2
    exit "$kata_install_status"
  fi
  install -m 0755 /opt/kata/runtime-rs/bin/containerd-shim-kata-v2 \
    /usr/local/bin/containerd-shim-kata-v2
fi

if ! systemctl is-active --quiet k3s; then
  if ! command -v k3s >/dev/null 2>&1; then
    curl --fail --location --retry 5 "$K3S_INSTALL_URL" | \
      INSTALL_K3S_EXEC="server --disable=traefik --write-kubeconfig-mode=0600" sh -
  else
    systemctl start k3s
  fi
fi

readonly CONTAINERD_TEMPLATE="/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl"
install -d "$(dirname "$CONTAINERD_TEMPLATE")"
if ! grep --quiet 'io.containerd.kata.v2' "$CONTAINERD_TEMPLATE" 2>/dev/null; then
  cat >>"$CONTAINERD_TEMPLATE" <<'EOF'

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata]
  runtime_type = "io.containerd.kata.v2"
EOF
  systemctl restart k3s
fi

chmod 0600 /etc/rancher/k3s/k3s.yaml
chown root:root /etc/rancher/k3s/k3s.yaml

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl wait --for=condition=Ready node --all --timeout=180s

install -d -m 0750 -o "$WORKSHOP_USER" -g "$WORKSHOP_USER" "/home/$WORKSHOP_USER/.kube"
cp /etc/rancher/k3s/k3s.yaml "/home/$WORKSHOP_USER/.kube/config"
chown -R "$WORKSHOP_USER:$WORKSHOP_USER" "/home/$WORKSHOP_USER/.kube"
chmod 0600 "/home/$WORKSHOP_USER/.kube/config"

install -d -m 0750 -o root -g "$WORKSHOP_USER" /etc/ttyd
if [ ! -s /etc/ttyd/server.key ] || [ ! -s /etc/ttyd/server.crt ]; then
  openssl req -x509 -newkey rsa:2048 -nodes -days 30 \
    -keyout /etc/ttyd/server.key \
    -out /etc/ttyd/server.crt \
    -subj "/CN=workshop-node"
fi
chown root:"$WORKSHOP_USER" /etc/ttyd/server.key /etc/ttyd/server.crt
chmod 0640 /etc/ttyd/server.key
chmod 0644 /etc/ttyd/server.crt

cat >/etc/systemd/system/ttyd.service <<'EOF'
[Unit]
Description=Workshop browser terminal
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=workshop
WorkingDirectory=/home/workshop
Environment=TERM=xterm-256color
ExecStart=/usr/local/bin/ttyd --ssl --ssl-cert /etc/ttyd/server.crt --ssl-key /etc/ttyd/server.key -W -p 7681 /bin/bash
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now ttyd.service

kubectl apply -f - <<'EOF'
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: kata
handler: kata
EOF
