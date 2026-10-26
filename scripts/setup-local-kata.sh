#!/bin/bash
set -euo pipefail

# Based on the guide from https://github.com/can1357/oh-my-pi/blob/main/infra/docs/02-kata-runtime.md

KATA_VER=3.3.0
KATA_URL="https://github.com/kata-containers/kata-containers/releases/download/${KATA_VER}/kata-static-${KATA_VER}-amd64.tar.xz"
KATA_DEST="/opt/kata"

echo "Installing Kata Containers version ${KATA_VER}..."

# Check for virtualization support
if ! grep -q -E '^(vmx|svm)' /proc/cpuinfo; then
    echo "Hardware virtualization (VT-x or AMD-V) is not enabled." >&2
    echo "Please enable it in your BIOS and try again." >&2
    exit 1
fi

# Download and extract Kata Containers
if [ ! -d "${KATA_DEST}" ]; then
    echo "Downloading Kata Containers from ${KATA_URL}..."
    curl -fsSL -o /tmp/kata-static.tar.xz "${KATA_URL}"
    echo "Extracting to ${KATA_DEST}..."
    sudo mkdir -p "${KATA_DEST}"
    sudo tar -xf /tmp/kata-static.tar.xz -C /
    rm /tmp/kata-static.tar.xz
else
    echo "Kata Containers already found in ${KATA_DEST}. Skipping download."
fi

# Create symlinks
echo "Creating symlinks..."
sudo ln -sf "${KATA_DEST}/bin/containerd-shim-kata-v2" /usr/local/bin/containerd-shim-kata-v2
sudo ln -sf "${KATA_DEST}/bin/kata-runtime" /usr/local/bin/kata-runtime

# Create k3d cluster with containerd config template
echo "Creating k3d cluster..."
cat <<EOF > /tmp/k3s-config.toml.tmpl
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata-qemu]
  runtime_type = "io.containerd.kata.v2"
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata-qemu.options]
    ConfigPath = "/opt/kata/share/defaults/kata-containers/configuration-qemu.toml"
EOF

k3d cluster create local-workshop \
  --k3s-arg "--containerd-config-path=/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl@server:0" \
  --volume /tmp/k3s-config.toml.tmpl:/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl

# Create RuntimeClass
echo "Creating RuntimeClass..."
cat <<EOF | kubectl apply -f -
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: kata-qemu
handler: kata-qemu
EOF

echo "Local setup complete!"
echo "You can now run 'kubectl get runtimeclass' to verify the setup."