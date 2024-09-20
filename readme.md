<h1>Installation Script for containerd, Kubernetes, and Associated Tools</h1>

<p>This script installs containerd, Kubernetes, and various associated tools on an Ubuntu system. It sets up the necessary environment, installs dependencies, and configures Kubernetes with the Calico network plugin, metrics-server, Helm, OpenEBS, and WordPress for testing. Follow the instructions below to understand the purpose of each section of the script.</p>

<h2>1. Update and Install General Dependencies</h2>
<p>This section updates the package list and installs essential packages such as <code>apt-transport-https</code>, <code>ca-certificates</code>, <code>curl</code>, <code>gpg</code>, and <code>socat</code>.</p>

<pre><code>sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y apt-transport-https ca-certificates curl gpg socat</code></pre>

<h2>2. Install and Configure containerd</h2>
<p>The following steps download and configure <code>containerd</code>:</p>
<ul>
  <li>Download a pre-configured containerd configuration file.</li>
  <li>Download the containerd binaries and install them.</li>
  <li>Configure containerd as a system service and start it.</li>
</ul>

<pre><code>curl -fsSLo containerd-config.toml https://gist.githubusercontent.com/oradwell/31ef858de3ca43addef68ff971f459c2/raw/5099df007eb717a11825c3890a0517892fa12dbf/containerd-config.toml
sudo mkdir -p /etc/containerd
sudo mv containerd-config.toml /etc/containerd/config.toml

curl -fLo containerd-1.6.14-linux-amd64.tar.gz https://github.com/containerd/containerd/releases/download/v1.6.14/containerd-1.6.14-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-1.6.14-linux-amd64.tar.gz

sudo curl -fsSLo /etc/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo systemctl daemon-reload
sudo systemctl enable --now containerd</code></pre>

<h2>3. Install runc</h2>
<p><code>runc</code> is installed, which is a CLI tool for spawning and running containers based on OCI.</p>

<pre><code>curl -fsSLo runc.amd64 https://github.com/opencontainers/runc/releases/download/v1.1.3/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc</code></pre>

<h2>4. Install CNI Network Plugins</h2>
<p>This step installs the Container Network Interface (CNI) plugins needed by Kubernetes for networking.</p>

<pre><code>curl -fLo cni-plugins-linux-amd64-v1.1.1.tgz https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz</code></pre>

## 5. Enable Kernel Modules and Configure sysctl

This section enables necessary kernel modules and configures `sysctl` parameters required by Kubernetes.

```bash
# Enable necessary kernel modules
sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

# Load the modules
sudo modprobe -a overlay br_netfilter

# Configure sysctl parameters
sudo tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

# Apply the sysctl settings
sudo sysctl --system 
```

<h2>6. Add Kubernetes APT Repository</h2>
<p>The script adds the Kubernetes APT repository and installs <code>kubelet</code>, <code>kubeadm</code>, and <code>kubectl</code> for managing the cluster.</p>

<pre><code>curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl</code></pre>

<h2>7. Disable Swap</h2>
<p>To meet Kubernetes' requirement, swap is disabled both temporarily and permanently.</p>

<pre><code>sudo swapoff -a
sudo sed -i -e '/swap/d' /etc/fstab</code></pre>

<h2>8. Initialize Kubernetes Cluster</h2>
<p>Kubernetes is initialized with the pod network CIDR set to <code>10.244.0.0/16</code> to work with the Calico network plugin.</p>

<pre><code>sudo kubeadm init --pod-network-cidr=10.244.0.0/16</code></pre>

<h2>9. Configure kubectl</h2>
<p>Once the cluster is initialized, <code>kubectl</code> is configured to interact with it.</p>

<pre><code>mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config</code></pre>

<h2>10. Un-taint Master Nodes</h2>
<p>This step removes taints from master nodes to allow Pods to be scheduled on them.</p>

<pre><code>kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes --all node-role.kubernetes.io/control-plane-</code></pre>

<h2>11. Install Calico Network Plugin</h2>
<p>The Calico network plugin is installed for networking within the cluster.</p>

<pre><code>kubectl apply -f https://docs.projectcalico.org/v3.25/manifests/calico.yaml</code></pre>

<h2>12. Install Metrics-Server</h2>
<p>The metrics-server is installed to provide resource usage data for Pods and nodes.</p>

<pre><code>kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml</code></pre>

<h2>13. Install Helm</h2>
<p>Helm is installed to manage Kubernetes packages (charts).</p>

<pre><code>curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash</code></pre>

<h2>14. Install OpenEBS CSI Driver</h2>
<p>OpenEBS is installed to provide persistent storage for the Kubernetes cluster. It is set as the default storage class.</p>

<pre><code>helm repo add openebs https://openebs.github.io/charts
kubectl create namespace openebs
helm --namespace=openebs install openebs openebs/openebs
kubectl patch storageclass openebs-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'</code></pre>

<h2>15. Test Installation with WordPress</h2>
<p>The installation is tested by deploying WordPress using Helm and the OpenEBS storage class.</p>

<pre><code>helm repo add bitnami https://charts.bitnami.com/bitnami
helm install wordpress bitnami/wordpress --set=global.storageClass=openebs-hostpath</code></pre>

<h2>16. Completion</h2>
<p>The installation is now complete.</p>

<p>All URLs and resources used in this script are directly referenced from the official sources:</p>
<ul>
  <li><a href="https://github.com/containerd/containerd">containerd on GitHub</a></li>
  <li><a href="https://github.com/opencontainers/runc">runc on GitHub</a></li>
  <li><a href="https://github.com/containernetworking/plugins">CNI Plugins on GitHub</a></li>
  <li><a href="https://docs.projectcalico.org">Calico Documentation</a></li>
  <li><a href="https://github.com/kubernetes-sigs/metrics-server">Metrics Server on GitHub</a></li>
  <li><a href="https://github.com/helm/helm">Helm on GitHub</a></li>
  <li><a href="https://openebs.io/">OpenEBS</a></li>
  <li><a href="https://bitnami.com/">Bitnami</a></li>
</ul>