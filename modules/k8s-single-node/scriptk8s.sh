#!/bin/bash

# Update package list and install general dependencies
echo "Updating package list and installing general dependencies..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg socat

# Install containerd
echo "Downloading and configuring containerd..."
curl -fsSLo containerd-config.toml \
    https://gist.githubusercontent.com/oradwell/31ef858de3ca43addef68ff971f459c2/raw/5099df007eb717a11825c3890a0517892fa12dbf/containerd-config.toml
sudo mkdir -p /etc/containerd
sudo mv containerd-config.toml /etc/containerd/config.toml

# Download and extract containerd binaries
echo "Downloading and extracting containerd binaries..."
curl -fLo containerd-1.6.14-linux-amd64.tar.gz \
    https://github.com/containerd/containerd/releases/download/v1.6.14/containerd-1.6.14-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-1.6.14-linux-amd64.tar.gz

# Install containerd as a service
echo "Installing and starting containerd as a service..."
sudo curl -fsSLo /etc/systemd/system/containerd.service \
    https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

# Install runc
echo "Downloading and installing runc..."
curl -fsSLo runc.amd64 \
    https://github.com/opencontainers/runc/releases/download/v1.1.3/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc

# Install CNI network plugins
echo "Downloading and installing CNI network plugins..."
curl -fLo cni-plugins-linux-amd64-v1.1.1.tgz \
    https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz

# Enable necessary kernel modules
echo "Enabling kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe -a overlay br_netfilter

# Configure sysctl parameters
echo "Configuring sysctl parameters..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

# Apply sysctl parameters without rebooting
echo "Applying sysctl parameters..."
sudo sysctl --system

# Add Kubernetes APT repository
echo "Adding Kubernetes APT repository..."
# Uncomment the following line if /etc/apt/keyrings directory does not exist
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

# Install Kubernetes components
echo "Installing Kubernetes components..."
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Check if swap is enabled
echo "Checking if swap is enabled..."
swapon --show

# Disable swap
echo "Disabling swap..."
sudo swapoff -a

# Permanently disable swap
echo "Disabling swap permanently..."
sudo sed -i -e '/swap/d' /etc/fstab

# Initialize Kubernetes cluster
echo "Initializing Kubernetes cluster..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Configure kubectl
echo "Configuring kubectl..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Un-taint the node to allow Pods
echo "Un-tainting nodes to allow Pods..."
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule-

# Install Flannel network plugin
echo "Installing Flannel network plugin..."
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Install metrics-server
echo "Installing metrics-server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Install Helm
echo "Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Install OpenEBS CSI driver
echo "Installing OpenEBS CSI driver..."
# Add OpenEBS repository to Helm
helm repo add openebs https://openebs.github.io/charts
# Create namespace for OpenEBS
kubectl create namespace openebs
# Install OpenEBS
helm --namespace=openebs install openebs openebs/openebs
# Set OpenEBS as default storage class
echo "Setting OpenEBS as default storage class..."
kubectl patch storageclass openebs-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Test installation with WordPress
echo "Testing installation with WordPress..."
# Add Bitnami repository to Helm
helm repo add bitnami https://charts.bitnami.com/bitnami
# Install WordPress using OpenEBS storage class
helm install wordpress bitnami/wordpress --set=global.storageClass=openebs-hostpath

echo "Installation completed successfully!"