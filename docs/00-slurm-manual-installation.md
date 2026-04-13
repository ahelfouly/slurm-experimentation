Manual Slurm installation on Rocky Linux 9
------------------------------------------

Prerequisites
-------------

cgroupv2 should be enabled on the system

```
[root@ctrl01 ~]# stat -fc %T /sys/fs/cgroup/
cgroup2fs
```

Building slurm packages requires some developement packages so for Fedora/RHEL based systems like Rocky, CRB repo should be enabled.

```
error: Failed build dependencies:
	mariadb-devel >= 5.0.0 is needed by slurm-25.11.3-1.el9.x86_64
	pam-devel is needed by slurm-25.11.3-1.el9.x86_64
	perl(ExtUtils::MakeMaker) is needed by slurm-25.11.3-1.el9.x86_64
	perl-devel is needed by slurm-25.11.3-1.el9.x86_64
	readline-devel is needed by slurm-25.11.3-1.el9.x86_64
```

Since we'll be building from source, you'll need to install `rpmdevtools`, `rpm-build"`, and `bzip2-devel`.

## Installation

Following [Quick Start Administrator Guide](https://slurm.schedmd.com/quickstart_admin.html)

### Installing munge

First step is to setup munge.

Download the tarball of your selected release from [Munge Releases](https://github.com/dun/munge/releases). In my case I chose the latest version at the time of the test _0.5.18_

`wget https://github.com/dun/munge/releases/download/munge-0.5.18/munge-0.5.18.tar.xz`

Following [Munge Installation Guide](https://github.com/dun/munge/wiki/Installation-Guide), you'll notice some dependencies that will be triggered at the time of the installation one of them is OpenSSL which OpenSSH uses. You'll want to update OpenSSH preemptively otherwise if you try to establish new SSH sessions you'll run into the error `kex_exchange_identification: read: Connection reset by peer`

Build the munge RPM packages `rpmbuild -tb --without=check ~/munge-0.5.18.tar.xz`

You'll find all the RPM packages under `~/rpmbuild/RPMS/<arch>/`

```
munge-0.5.18-1.el9.x86_64.rpm
munge-debuginfo-0.5.18-1.el9.x86_64.rpm
munge-debugsource-0.5.18-1.el9.x86_64.rpm
munge-devel-0.5.18-1.el9.x86_64.rpm
munge-libs-0.5.18-1.el9.x86_64.rpm
munge-libs-debuginfo-0.5.18-1.el9.x86_64.rpm
```

Install the built RPM packages using `dnf install /home/vagrant/rpmbuild/RPMS/x86_64/munge-0.5.18-1.el9.x86_64.rpm /home/vagrant/rpmbuild/RPMS/x86_64/munge-libs-0.5.18-1.el9.x86_64.rpm`

Make sure to install `munge-devel` as it would be required for the build of slurm packages `dnf install /home/vagrant/rpmbuild/RPMS/x86_64/munge-devel-0.5.18-1.el9.x86_64.rpm`

Generally the installation of munge will also configure munge user with UID and GID 990, you should make sure that it's conformant across the installed nodes.

Make sure to enable & start the service `systemctl enable --now munge.service`

### Preparing for installation

Make sure to create slurm user on all nodes.

```
groupadd -g 1500 slurm
useradd -m -c "SLURM workload manager" -d /var/lib/slurm -u 1500 -g 1500 -s /bin/false slurm
```

Create directories `/var/log/slurm` & `/etc/slurm` on all nodes and set the owner user and group as slurm.
Create directory `/var/spool/slurmctld` on controllers and set the owner user and group as slurm.
Create directory `/var/spool/slurmd` on compute nodes and set the owner user and group as slurm.

### Building the RPM packages

Make sure to install dependency packages `dnf install mariadb-devel pam-devel perl-devel readline-devel dbus-devel`

The `dbus-devel` package is important otherwise the cgroupv2 plugin will not be compiled.

```
[root@node01 ~]# ls /usr/lib64/slurm/cgroup*
/usr/lib64/slurm/cgroup_v1.so  /usr/lib64/slurm/cgroup_v2.so
```

### Installing Slurm packages

On all nodes install slurm plugins `dnf install /home/vagrant/rpmbuild/RPMS/x86_64/slurm-25.11.3-1.el9.x86_64.rpm`

On controller nodes `dnf install /home/vagrant/rpmbuild/RPMS/x86_64/slurm-slurmctld-25.11.3-1.el9.x86_64.rpm /home/vagrant/rpmbuild/RPMS/x86_64/slurm-perlapi-25.11.3-1.el9.x86_64.rpm`

On compute nodes `dnf install /home/vagrant/rpmbuild/RPMS/x86_64/slurm-slurmd-25.11.3-1.el9.x86_64.rpm /home/vagrant/rpmbuild/RPMS/x86_64/slurm-slurmd-25.11.3-1.el9.x86_64.rpm`


### Populating configuration file 

Enable slurmd on compute nodes `systemctl enable slurmd` then use `slurmd -C` to get the detected hardware to add it to the configuration files.

```
[root@node01 ~]# slurmd -C
NodeName=node01 CPUs=2 Boards=1 SocketsPerBoard=2 CoresPerSocket=1 ThreadsPerCore=1 RealMemory=1955
UpTime=0-02:44:40
[root@node01 ~]# 
```

You'll need to create configuration file `cgroup.conf`

```
echo "CgroupPlugin=autodetect" >> /etc/slurm/cgroup.conf
chown slurm:slurm /etc/slurm/cgroup.conf
```

Example config file [slurm.conf](./slurm.conf) generated with help of [Slurm Configuration Tool](https://slurm.schedmd.com/configurator.html) which needs to be on all nodes.


### Firewall configuration

If you firewall enabled at all times, enable slurmctld port 6817/tcp and slurmd port 6818/tcp and your srun port range which can be set to your liking for example 60001-63000/tcp

## Start Slurm services

Start `slurmctld` on controllers and `slurmd` on compute nodes

After starting make sure of the node state is idle

```
[root@ctrl01 ~]# sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
debug*       up   infinite      2   idle node[01-02]
```

Test simple job with `srun`

```
[root@ctrl01 ~]# srun -N 2 hostname
node02
node01
```
