#!/bin/sh
set -ex

release=$(curl https://www.debian.org/releases/ | grep -oP 'codenamed <em>\K(.*)(?=</em>)')
release="sid"
include_apps="linux-image-cloud-amd64,extlinux,initramfs-tools,busybox"
include_apps+=",systemd,systemd-resolved,systemd-sysv,dbus,bash-completion,openssh-server,ca-certificates"
include_apps+=",sudo,curl,openssl,socat,conntrack,ebtables,ipset,ipvsadm,iptables,ethtool,iproute2,systemd-cron,apparmor"
exclude_apps="unattended-upgrades"
enable_services="systemd-networkd.service systemd-resolved.service ssh.service"
disable_services="apt-daily.timer apt-daily-upgrade.timer fstrim.timer e2scrub_all.timer e2scrub_reap.service"

export DEBIAN_FRONTEND=noninteractive
apt-config dump | grep -we Recommends -e Suggests | sed 's/1/0/' | tee /etc/apt/apt.conf.d/99norecommends
apt update
apt install -y qemu-system-x86 debootstrap qemu-utils

mount_dir=/tmp/debian

qemu-img create -f raw /tmp/debian.raw 100G
loopx=$(losetup --show -f -P /tmp/debian.raw)

mkfs.ext4 -F -L debian-root -b 1024 -I 128 -O "^has_journal" $loopx

mkdir -p ${mount_dir}
mount $loopx ${mount_dir}

sed -i 's/ls -A/ls --ignore=lost+found -A/' /usr/sbin/debootstrap
/usr/sbin/debootstrap --no-check-gpg --no-check-certificate --components=main,contrib,non-free --include="$include_apps" --exclude="$exclude_apps" --variant minbase ${release} ${mount_dir}

mount -t proc none ${mount_dir}/proc
mount -o bind /sys ${mount_dir}/sys
mount -o bind /dev ${mount_dir}/dev

cat << EOF > ${mount_dir}/etc/fstab
LABEL=debian-root /        ext4  defaults,noatime                0 0
tmpfs             /run     tmpfs defaults,size=50%               0 0
tmpfs             /tmp     tmpfs mode=1777,size=90%              0 0
tmpfs             /var/log tmpfs defaults,noatime                0 0
EOF

mkdir -p ${mount_dir}/root/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDyuzRtZAyeU3VGDKsGk52rd7b/rJ/EnT8Ce2hwWOZWp" >> ${mount_dir}/root/.ssh/authorized_keys
chmod 600 ${mount_dir}/root/.ssh/authorized_keys

mkdir -p ${mount_dir}/etc/apt/apt.conf.d
cat << EOF > ${mount_dir}/etc/apt/apt.conf.d/99-freedisk
APT::Authentication "0";
APT::Get::AllowUnauthenticated "1";
Dir::Cache "/dev/shm";
Dir::State::lists "/dev/shm";
Dir::Log "/dev/shm";
DPkg::Post-Invoke {"/bin/rm -f /dev/shm/archives/*.deb || true";};
EOF

cat << EOF > ${mount_dir}/etc/apt/apt.conf.d/99norecommend
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOF

mkdir -p ${mount_dir}/etc/dpkg/dpkg.cfg.d
cat << EOF > ${mount_dir}/etc/dpkg/dpkg.cfg.d/99-nodoc
path-exclude /usr/share/doc/*
path-exclude /usr/share/man/*
path-exclude /usr/share/groff/*
path-exclude /usr/share/info/*
path-exclude /usr/share/lintian/*
path-exclude /usr/share/linda/*
path-exclude /usr/share/locale/*
path-include /usr/share/locale/en*
EOF

mkdir -p ${mount_dir}/etc/systemd/journald.conf.d
cat << EOF > ${mount_dir}/etc/systemd/journald.conf.d/storage.conf
[Journal]
Storage=volatile
EOF

cat << EOF > ${mount_dir}/etc/systemd/network/20-dhcp.network
[Match]
Name=en*

[Network]
DHCP=yes
IPv6AcceptRA=yes

[DHCPv4]
ClientIdentifier=mac
EOF

mkdir -p ${mount_dir}/etc/systemd/system-environment-generators
cat << EOF > ${mount_dir}/etc/systemd/system-environment-generators/20-python
#!/bin/sh
echo 'PYTHONDONTWRITEBYTECODE=1'
echo 'PYTHONSTARTUP=/usr/lib/pythonstartup'
EOF
chmod +x ${mount_dir}/etc/systemd/system-environment-generators/20-python

cat << EOF > ${mount_dir}/etc/profile.d/python.sh
#!/bin/sh
export PYTHONDONTWRITEBYTECODE=1 PYTHONSTARTUP=/usr/lib/pythonstartup
EOF

cat << EOF > ${mount_dir}/usr/lib/pythonstartup
import readline
import time
readline.add_history("# " + time.asctime())
readline.set_history_length(-1)
EOF

cat << EOF > ${mount_dir}/root/.bashrc
export HISTSIZE=1000 LESSHISTFILE=/dev/null HISTFILE=/dev/null PYTHONDONTWRITEBYTECODE=1 PYTHONSTARTUP=/usr/lib/pythonstartup
EOF

mkdir -p ${mount_dir}/boot/syslinux
cat << EOF > ${mount_dir}/boot/syslinux/syslinux.cfg
PROMPT 0
TIMEOUT 0
DEFAULT debian

LABEL debian
        LINUX /vmlinuz
        INITRD /initrd.img
        APPEND root=LABEL=debian-root intel_iommu=on iommu=pt console=ttyS0
EOF

chroot ${mount_dir} /bin/bash -c "
sed -i 's/root:\*:/root::/' etc/shadow
dd if=/usr/lib/EXTLINUX/mbr.bin of=$loopx
extlinux -i /boot/syslinux
busybox --install -s /bin

systemctl enable $enable_services
systemctl disable $disable_services

ln -rsf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
echo kubesphere > /etc/hostname

sed -i '/src/d' /etc/apt/sources.list
rm -rf /etc/localtime /usr/share/doc /usr/share/man /tmp/* /var/log/* /var/tmp/* /var/cache/apt/* /var/lib/apt/lists/* /usr/bin/perl*.* /usr/bin/systemd-analyze /lib/modules/5.6.0-2-cloud-amd64/kernel/drivers/net/ethernet/ /boot/System.map-*
find /usr/*/locale -mindepth 1 -maxdepth 1 ! -name 'en' -prune -exec rm -rf {} +
find /usr -type d -name __pycache__ -prune -exec rm -rf {} +
"
# cat << EOF >> ${mount_dir}/etc/containerd/config.toml
# [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
#   SystemdCgroup = true
# EOF

VERSION="$(curl -skL https://api.github.com/repos/kubesphere/kubekey/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')"
DOWNLOAD_URL="https://github.com/kubesphere/kubekey/releases/download/${VERSION}/kubekey-${VERSION}-linux-amd64.tar.gz"
curl -skL ${DOWNLOAD_URL} | tar -xz -C /tmp

/tmp/kk create config -y -f /tmp/config.yaml
KVERSION=$(awk '/version/ {print $2}' /tmp/config.yaml)

cp /tmp/kk ${mount_dir}/usr/local/bin
chmod +x ${mount_dir}/usr/local/bin/kk

ssh-keygen -q -P '' -f /root/.ssh/id_ed25519 -C '' -t ed25519
ssh-keygen -y -f /root/.ssh/id_ed25519 >> ${mount_dir}/root/.ssh/authorized_keys
cp /root/.ssh/id_ed25519 ${mount_dir}/root/.ssh/
chmod 600 ${mount_dir}/root/.ssh/id_ed25519

sync ${mount_dir}
umount ${mount_dir}/dev ${mount_dir}/proc ${mount_dir}/sys
sleep 1
killall -r provjobd || true
sleep 1
umount ${mount_dir}
sleep 1
losetup -d $loopx

sleep 2
cp /tmp/debian.raw /tmp/debian2.raw

sleep 2
systemd-run -G -q --unit qemu-kubesphere-building.service qemu-system-x86_64 -name kubesphere-building -machine q35,accel=kvm:hax:hvf:whpx:tcg -cpu kvm64 -smp "$(nproc)" -m 24G -nographic -object rng-random,filename=/dev/urandom,id=rng0 -device virtio-rng-pci,rng=rng0 -boot c -drive file=/tmp/debian.raw,if=virtio,format=raw,media=disk -netdev user,id=n0,ipv6=off,net=10.20.20.0/24,host=10.20.20.100,dhcpstart=10.20.20.10,dns=10.20.20.101,hostfwd=tcp:127.0.0.1:22222-:22 -device virtio-net,netdev=n0

sleep 60
journalctl -u qemu-kubesphere-building.service

sleep 2
#ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22222 -l root 127.0.0.1 kk create cluster --debug --yes --with-kubesphere --container-manager containerd --with-local-storage

scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -P 22222 kubesphere-config.yaml root@127.0.0.1:/root
ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22222 -l root 127.0.0.1 kk create cluster --debug --yes --with-kubesphere --with-local-storage --filename /root/kubesphere-config.yaml
# /tmp/kk create cluster --yes --with-kubesphere --with-local-storage --filename /home/runner/work/k8s/k8s/kubesphere-config.yaml

sleep 300
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22222 -l root 127.0.0.1 poweroff
sleep 300

sleep 2
systemd-run -G -q --unit qemu-kubesphere-building2.service qemu-system-x86_64 -name kubesphere-building2 -machine q35,accel=kvm:hax:hvf:whpx:tcg -cpu kvm64 -smp "$(nproc)" -m 24G -nographic -object rng-random,filename=/dev/urandom,id=rng0 -device virtio-rng-pci,rng=rng0 -boot c -drive file=/tmp/debian2.raw,if=virtio,format=raw,media=disk -netdev user,id=n0,ipv6=off,net=10.20.20.0/24,host=10.20.20.100,dhcpstart=10.20.20.10,dns=10.20.20.101,hostfwd=tcp:127.0.0.1:22222-:22 -device virtio-net,netdev=n0

sleep 60
journalctl -u qemu-kubesphere-building2.service

sleep 2
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22222 -l root 127.0.0.1 kk create cluster --debug --yes --container-manager containerd --with-local-storage

sleep 300
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22222 -l root 127.0.0.1 poweroff
sleep 300

sleep 1
sync
sleep 1

sleep 10
qemu-img convert -c -f raw -O qcow2 /tmp/debian.raw /tmp/kubesphere-${KVERSION}.img
qemu-img info /tmp/kubesphere-${KVERSION}.img
split --verbose -d -b 1500M /tmp/kubesphere-${KVERSION}.img /tmp/kubesphere-${KVERSION}.img.
rm -f /tmp/kubesphere-${KVERSION}.img
sleep 10
qemu-img convert -c -f raw -O qcow2 /tmp/debian2.raw /tmp/kubesphere-k8s-${KVERSION}.img
qemu-img info /tmp/kubesphere-k8s-${KVERSION}.img
