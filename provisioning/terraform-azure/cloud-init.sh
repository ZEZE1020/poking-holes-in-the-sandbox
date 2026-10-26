#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

readonly TTYD_VERSION="${ttyd_version}"
readonly TTYD_URL="https://github.com/tsl0922/ttyd/releases/download/v${ttyd_version}/ttyd.x86_64"
readonly TTYD_PATH="/usr/local/bin/ttyd"
readonly KATA_MANAGER_URL="https://raw.githubusercontent.com/kata-containers/kata-containers/main/utils/kata-manager.sh"
readonly K3S_INSTALL_URL="https://get.k3s.io"

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl kmod openssl jq \
  linux-modules-extra-"$(uname -r)"

modprobe kvm
modprobe kvm_intel || true

curl --fail --location --retry 5 --output "$TTYD_PATH" "$TTYD_URL"
chmod 0755 "$TTYD_PATH"

if [ ! -x /usr/local/bin/containerd-shim-kata-v2 ]; then
  set +e
  curl --fail --location --retry 5 "$KATA_MANAGER_URL" | bash -s -- -o -t
  kata_install_status="$${PIPESTATUS[1]}"
  set -e
  if [ "$kata_install_status" -ne 0 ] && \
    [ ! -x /opt/kata/runtime-rs/bin/containerd-shim-kata-v2 ]; then
    echo "Kata Containers installation failed" >&2
    exit "$kata_install_status"
  fi
  install -m 0755 /opt/kata/runtime-rs/bin/containerd-shim-kata-v2 \
    /usr/local/bin/containerd-shim-kata-v2
fi

if ! command -v k3s >/dev/null 2>&1; then
  curl --fail --location --retry 5 "$K3S_INSTALL_URL" | \
    INSTALL_K3S_EXEC="server --disable=traefik --write-kubeconfig-mode=0600" sh -
fi
systemctl enable --now k3s

readonly CONTAINERD_TEMPLATE="/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl"
install -d "$(dirname "$CONTAINERD_TEMPLATE")"
if ! grep --quiet 'io.containerd.kata.v2' "$CONTAINERD_TEMPLATE" 2>/dev/null; then
  cat >>"$CONTAINERD_TEMPLATE" <<'CONTAINERD'

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata]
  runtime_type = "io.containerd.kata.v2"
CONTAINERD
  systemctl restart k3s
fi

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl wait --for=condition=Ready node --all --timeout=180s
kubectl apply -f - <<'RUNTIMECLASS'
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: kata
handler: kata
RUNTIMECLASS

install -d -m 0750 /etc/ttyd
openssl req -x509 -newkey rsa:2048 -nodes -days 30 \
  -keyout /etc/ttyd/server.key \
  -out /etc/ttyd/server.crt \
  -subj "/CN=workshop-host"
chmod 0600 /etc/ttyd/server.key
chmod 0644 /etc/ttyd/server.crt

%{ for index, port in terminal_ports ~}
user="$$(printf 'participant%02d' ${index + 1})"
if ! id --user "$user" >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash "$user"
fi
install -d -m 0700 -o "$user" -g "$user" "/home/$user"
cat >"/etc/systemd/system/ttyd-$${user}.service" <<SERVICE
[Unit]
Description=Workshop browser terminal for $${user}
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$${user}
WorkingDirectory=/home/$${user}
Environment=TERM=xterm-256color
ExecStart=/usr/local/bin/ttyd --ssl --ssl-cert /etc/ttyd/server.crt --ssl-key /etc/ttyd/server.key --writable -p ${port} /bin/bash --login
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
SERVICE
%{ endfor ~}

systemctl daemon-reload
%{ for index, port in terminal_ports ~}
systemctl enable --now "ttyd-participant$(printf '%02d' ${index + 1}).service"
%{ endfor ~}
