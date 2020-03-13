CentOS based Konvoy cluster on bare metal

# Platform Details:

- Konvoy version : 1.2.4
- Kubectl version : 1.17.3
- Docker CE version : 19.03.7
- Containerd version : 1.2.13
- Deployer VM:1 (VM from which konvoy cluster is setup)
- Master VM : 1
- Worker VMs : 5
- Total VMs: 7

## VM configurations (same for deployer,master and worker VMs):

- Guest OS: CentOS 4/5/6/7
- Operating System: centos-release-7-7.1908.0.el7.centos.x86_64
- Number of virtual sockets: 2
- Number of cores per virtual socket: 2
- CPU: 4vCPU (virtual sockets \* cores per virtual sockets)
- Memory: 16GB
- Disk size: 100GB
- Disk provisioning: Thin provisioning

## Network configurations:

- Gateway: 10.1.1.1
- DNS server: 10.1.1.21
- Netmask: 255.0.0.0
- Hostname: VM name + mayalabs.io

## deployer machine details:

- IP: 10.43.10.10

## master1 machine details:

- IP: 10.43.10.11

## worker1 machine details:

- IP: 10.43.10.12

## worker2 machine details:

- IP: 10.43.10.13

## worker3 machine details:

- IP: 10.43.10.14

## worker4 machine details:

- IP: 10.43.10.15

## worker5 machine details:

- IP: 10.43.10.16

For information on deploying k8s on bare metal with konvoy, refer to this [blog](https://medium.com/@fromprasath/fordeploy-k8s-on-bare-metal-with-d2iq-konvoy-and-use-openebs-for-storage-af4a2551d8ca)
