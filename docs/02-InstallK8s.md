# Installing kubernetes

This guide covers installing kubernetes and associated tooling

## Installing Containerd [^1], [^2]

On each node

1. Edit /etc/modules-load.d/k8s.conf and add the line `overlay`
2. `sudo modprobe overlay`
3. Edit /etc/sysctl.d/k8s.conf and add the line `net.ipv4.ip_forward = 1`
4. sudo sysctl --system
5. `sudo yum install yum-utils`
6. Containerd is found in the docker-ce repo so we'll need to add that. 
   `sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo`
7. Run `yum repolist` to check the new repo is working, at current time there
   is an issue where the expansion of the repo path in
   /etc/yum.repos.d/docker-ce.repo does not match the actual path. This is due
   $releasever in RHEL7 expanding to '7Server' rather than '7'. Manually fixing
   the repo definition works for now
8. Containerd depends on container-selinux which is in the extras channel
   `sudo subscription-manager repos --enable=rhel-7-server-extras-rpms`
9. `sudo yum install container-selinux.no_arch`
10. `sudo yum install containerd`
11. `sudo mkdir -p /etc/containerd`
12. `containerd config default | sudo tee /etc/containerd/config.toml`
13. `sudo systemctl restart containerd`
14. `systemctl status containerd` and check that it has started

## Install kubeadm, kubelet & kubectl [^3]
1. Add the kubernetes repo by running the following commands. THis repo
   definition will *not* update the three packages we are about to installas
   upgrades to them *must* be done manually.
```
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
```
2. Turn off SELinux (TODO remove this step)
```
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```
3. `sudo yum install -y kublet kubeadm kubectl --disableexcludes=kubernetes`
4. `sudo systemctl enable --now kublet`

[^1]: https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd
[^2]: https://docs.docker.com/engine/install/centos/#install-using-the-repository
[^3]: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
