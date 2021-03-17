# VM Setup

This guide covers setting up the VMS which will host the Kubernetes cluster.
Since the focus of this project is the hardening of the cluster a fairly basic
approach wil be taken to setting up the hosts (i.e these would not be
production ready).

The control plane will be on linux nodes as will two of the workers therefore
we need to create 5 VMs 

- hard8-m1
- hard8-m2 
- hard8-m3
- hard8-w1
- hard8-w2
- hard8-w3

Using Hyper-V these VM's need to be created indvidually rather than cloned as I
can't work out how to ensure VM's which are exported/imported have a unique
product id (a requirement for kubernetes)

### Create Linux VMs [^1]

1. Download RHEL7 dvd iso 
2. Start Hyper-V
3. Click new in the right hand nav and select virtual machine
4. Specify name and location for VM
5. Select generation 2
6. Select 2048mb ram
7. Select Default switch  
8. 25gb hardisk
9. Select install image from bootable iso file and point it at the iso from step 1
10. In hyper-v select the newly created VM and click 'settings' in the right
    hand nav
11. Select the security tab
12. Change the template to 'Microsoft UEFI Certificate Authority'
13. Select the Processor tab and increase the number of processors to two.

### Setup RHEL7 [^1], [^2]

1. Start the VM 
2. Select 'Test this media and install redhat 7.9'
3. Select language (english - uk), then continue
4. Click on Installation destination accept the defaults, then click done
5. Select kdump and then untick the 'Enable kdump' checkbox, click done
6. Select 'network and host name', set the hostname to the name for this VM
   e.g. hard8-m1, then toggle eth0 to on and click done.
7. While the installation is in progress select a root password 
8. Create a user account for general management (kate), tick the 'Make this
   user administrator' to enable sudo for the account.
9. Eject the installation media and reboot 
10. When the system restarts logon as kate
11. Run `sudo swapon --show` to identify the swap file
12. Run `sudo swapoff <file from last step>`
13. Edit the fstab to remove the swap entry (may point to a symbolic link the
    swapfile)
14. Run `systemctl daemon-reload` to pick up your config changes
15. Remove the old swap file with `sudo rm </path/to/swap>`
12. Ping www.google.com to make sure you have internet connectivity
13. Run `sudo subscription-manager register --auto-attach` And enter your
    account details. (Make sure to use your username and not the email address 
    you registered with - unless that is your username)
14. Run `sudo yum repolist`
15. Run `sudo yum update` and then reboot.
18. Checkpoint the system

## Verify the setup [^3]

Log on to each vm and do the following

1. Check you can ping the others
2. Run ip link, confirm the mac address is different 
3. Run `sudo cat /sys/class/dmi/id/product_uuid`, each value should be unique

### Setup iptables [^3], [^4]

On each VM do the following

1. Create /etc/modules-load.d/k8s.conf with content
`br_netfilter`
2. Create /etc/sysctl.d/k8s.conf with content
```
net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-iptables=1
```
3. `modprobe br_netfilter`
4. `firewall-cmd --add-masquerade --permanent`
5. `firewall-cmd --reload`
6. `sysctl --system`

### Add control plane node specific rules [^4], [^5], [^6]

1. Open the ports needed to speak to the control plane services
`firewall-cmd --zone=public --permanent --add-port={6443,2379-2380,10250-10252}/tcp`
2. Apply the change `firewall-cmd --reload`

### Add worker node specific rules [^4], [^5], [^6]

1. Open ports to allow contact with kublet and any nodeports
`firewall-cmd --zone=public --permanent --add-port={10250,30000-32767}/tcp`
2. Apply the change `firewall-cmd --reload`

[^1]: https://developers.redhat.com/rhel8/install-rhel8-hyperv-v3
[^2]: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/storage_administration_guide/s1-swap-removing
[^3]: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
[^4]: https://upcloud.com/community/tutorials/install-kubernetes-cluster-centos-8/
[^5]: https://firewalld.org/documentation/man-pages/firewall-cmd.html
[^6]: https://www.linuxjournal.com/content/understanding-firewalld-multi-zone-configurations
