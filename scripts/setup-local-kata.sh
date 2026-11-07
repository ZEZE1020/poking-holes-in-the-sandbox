#!/bin/bash
set -euo pipefail

# Based on the guide from https://github.com/can1357/oh-my-pi/blob/main/infra/docs/02-kata-runtime.md

KATA_VER=3.3.0
KATA_URL="https://github.com/kata-containers/kata-containers/releases/download/${KATA_VER}/kata-static-${KATA_VER}-amd64.tar.xz"
KATA_DEST="/opt/kata"
KATA_SHIM="${KATA_DEST}/runtime-rs/bin/containerd-shim-kata-v2"
KATA_CONFIG="${KATA_DEST}/share/defaults/kata-containers/runtime-rs/configuration-qemu.toml"

echo "Installing Kata Containers version ${KATA_VER}..."

if ! command -v k3d >/dev/null 2>&1 || ! command -v kubectl >/dev/null 2>&1; then
    echo "k3d and kubectl must be installed before running local setup." >&2
    exit 1
fi

# Check for virtualization support
if ! grep -q -E '^(vmx|svm)' /proc/cpuinfo; then
    echo "Hardware virtualization (VT-x or AMD-V) is not enabled." >&2
    echo "Please enable it in your BIOS and try again." >&2
    exit 1
fi

if [ -r /dev/kvm ] && [ ! -w /dev/kvm ]; then
    echo "The current user cannot access /dev/kvm. Add the user to the kvm group and retry." >&2
    exit 1
fi

# Use passwordless sudo when available. Preinstalled Kata files can be reused
# without sudo; downloading or installing them still requires elevated access.
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if sudo -n true 2>/dev/null; then
        SUDO="sudo"
    elif [ ! -x "${KATA_SHIM}" ] || [ ! -f "${KATA_CONFIG}" ]; then
        echo "Kata is not installed and passwordless sudo is unavailable." >&2
        echo "Install Kata Containers or configure sudo, then retry." >&2
        exit 1
    fi
fi

# Download and extract Kata Containers
if [ ! -x "${KATA_SHIM}" ] || [ ! -f "${KATA_CONFIG}" ]; then
    echo "--- Starting Kata Containers download at $(date) ---"
    echo "Downloading Kata Containers from ${KATA_URL}..."
    curl --fail --location --retry 3 --progress-bar -o /tmp/kata-static.tar.xz "${KATA_URL}"
    echo "--- Finished Kata Containers download at $(date) ---"

    echo "--- Starting Kata Containers extraction at $(date) ---"
    echo "Extracting to ${KATA_DEST}..."
    ${SUDO} mkdir -p "${KATA_DEST}"
    ${SUDO} tar -xf /tmp/kata-static.tar.xz -C /
    rm /tmp/kata-static.tar.xz
    echo "--- Finished Kata Containers extraction at $(date) ---"
else
    echo "Kata Containers already found in ${KATA_DEST}. Skipping download."
fi

# Create symlinks
echo "Creating symlinks..."
if [ -n "${SUDO}" ] || [ "$(id -u)" -eq 0 ]; then
    ${SUDO} ln -sf "${KATA_DEST}/bin/containerd-shim-kata-v2" /usr/local/bin/containerd-shim-kata-v2
    ${SUDO} ln -sf "${KATA_DEST}/bin/kata-runtime" /usr/local/bin/kata-runtime
fi

# Create k3d cluster with containerd config template
echo "--- Starting k3d cluster creation at $(date) ---"
echo "Creating k3d cluster..."
cat <<EOF > /tmp/k3s-config.toml.tmpl
{{ template "base" . }}

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata]
  runtime_type = "io.containerd.kata.v2"
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata.options]
    ConfigPath = "${KATA_CONFIG}"
EOF

timeout 180s k3d cluster create local-workshop \
  --volume /tmp/k3s-config.toml.tmpl:/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl@server:0 \
  --volume "${KATA_DEST}:${KATA_DEST}@server:0" \
  --volume "${KATA_SHIM}:/usr/local/bin/containerd-shim-kata-v2@server:0" \
  --volume /dev/kvm:/dev/kvm@server:0
echo "--- Finished k3d cluster creation at $(date) ---"

# Create RuntimeClass
echo "Creating RuntimeClass..."
cat <<EOF | kubectl apply -f -
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: kata
handler: kata
EOF

echo "Local setup complete!"
echo "You can now run 'kubectl get runtimeclass' to verify the setup."