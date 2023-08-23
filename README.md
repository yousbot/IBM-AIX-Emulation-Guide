<h1 align="center">
Running IBM AIX on Intel Systems
</h1>

> IBM AIX (Advanced Interactive eXecutive) is a series of proprietary Unix operating systems developed by IBM for several of its computer platforms.
> This guide aims to bridge the gap between IBM's proprietary hardware systems and common Intel-based systems, enabling developers, researchers, and enthusiasts to experience AIX without the need for specialized IBM hardware.
> With the rapid advancement of virtualization technologies and the capabilities of QEMU, it is now possible to emulate environments that were previously restricted to specific hardware setups.
> This guide is a step-by-step walkthrough on setting up, running, and managing AIX on QEMU, making it accessible to a broader audience.

## Goals of this Project
- Demystify AIX Emulation: Break down the process into easy-to-follow steps.
- Increase Accessibility: Allow users without IBM hardware to explore AIX.
- Provide a Robust Resource: Serve as a go-to guide for all things related to AIX emulation.
## Who is this Guide For?
- Researchers: Who wish to study AIX without investing in dedicated hardware.
- Developers: Interested in cross-platform development or exploring AIX-specific software.
- Tech Enthusiasts: Curious about running different operating systems and understanding their nuances.

## Requirements 
***Hardware***
⚡️   Intel-based system with virtualization capabilities (VT-x/VT-d) enabled.
🔍  RAM: A minimum of 8GB (16GB recommended).
💾  At least 250GB of free disk space.

***Software***
🖥️  A host operating system that supports QEMU (e.g., Linux, Windows, or macOS) -- This guide was tested on Windows 10.
🔧  QEMU software installed and configured on the host system.
💿  IBM AIX installation ISO USB Version. Specifically, the version mentioned in the guide, *AIX_v7.2_Base_Install_7200-03-01-1838_USB_Flash_092018.iso*, or a compatible version.

### Getting started
--- 
This section describes how to set up the IBM AIX system on a virtual machine.
```bash
# Create a new disk image for the AIX installation
qemu-img create -f qcow2 "C:\Users\Youssef Sbai Idrissi\Downloads\AIX\AIX1.qcow2" 100G

# Launch the AIX installation on the QEMU virtual machine
qemu-system-ppc64 -cpu POWER9 -machine pseries -m 2048 -serial mon:stdio \
-cdrom "C:\Users\Youssef Sbai Idrissi\DownloadDirector\AIX_v7.2_Base_Install_7200-03-01-1838_USB_Flash_092018.iso" \
-hda "C:\Users\Youssef Sbai Idrissi\Downloads\AIX\AIX1.qcow2" \
-prom-env "input-device=/vdevice/vty@71000000" \
-prom-env "output-device=/device/vty@71000000" \
-prom-env boot-command='boot cdrom:'
```
#### Post-Reboot Steps
After the initial setup, follow the steps below:
```
# Create a secondary disk image for AIX
qemu-img create -f qcow2 "C:\Users\Youssef Sbai Idrissi\Downloads\AIX\AIX2.qcow2" 100G

# Run the QEMU virtual machine with the secondary disk image
qemu-system-ppc64 -cpu POWER9 -machine pseries -m 2048 -serial mon:stdio \
-cdrom "C:\Users\Youssef Sbai Idrissi\DownloadDirector\AIX_v7.2_Base_Install_7200-03-01-1838_USB_Flash_092018.iso" \
-hda "C:\Users\Youssef Sbai Idrissi\Downloads\AIX\AIX1.qcow2" \
-drive file="C:\Users\Youssef Sbai Idrissi\Downloads\AIX\AIX2.qcow2",if=none,id=drive-virtio-disk0 \
-device virtio-scsi-pci,id=scsi -device scsi-hd,drive=drive-virtio-disk0 \
-prom-env "input-device=/vdevice/vty@71000000" \
-prom-env "output-device=/vdevice/vty@71000000" \
-prom-env boot-command='boot cdrom:'
```
#### Maintenance Mode Commands
Once you enter maintenance mode, execute the following commands:
```bash
# Display physical volumes
lspv
# List all available disk devices
lsdev -Cc disk
# Attempt to run the 'cdgmgr' command (will fail since it doesn't exist)
cdgmgr
# Configure devices
cfgmgr
# Display physical volumes again to see changes
lspv
# List all available disk devices again to see changes
lsdev -Cc disk
# Save the current base configuration
savebase -v
# Build a boot image
bosboot -ad /dev/hdisk0
# Change directory to the jfs2 helpers directory
cd /sbin/helpers/jfs2
# List the contents of the directory
ls
# Synchronize cached writes to disk
sync
# Repeat the sync command for safety
sync
# Repeat the sync command a third time for assurance
sync
# Halt the system quickly
halt -q
```
#### Local Script Creation
Locally, create the following scripts to set up networking and other configurations:
```bash
# Create a bridge interface and configure it
ifconfig bridge1 create
ifconfig bridge1 192.168.100.1/24 up
sysctl -w net.inet.ip.forwarding=1
sysctl -w net.link.ether.inet.proxyall=1
pfctl -F all
pfctl -f "C:\Users\Youssef Sbai Idrissi\Downloads\AIX\aix_nat_config"
```
#### Booting AIX Machine
Run the AIX machine using the following command:
```bash
qemu-system-ppc64 -cpu POWER9 -machine pseries -m 2048 -serial mon:stdio \
-drive file="C:\Users\Youssef Sbai Idrissi\Downloads\AIX\AIX1.qcow2",if=none,id=drive-virtio-disk0 \
-device virtio-scsi-pci,id=scsi -device scsi-hd,drive=drive-virtio-disk0 \
-prom-env boot-command='boot disk:' \
-net nic -net tap \
-display vnc=:1
```
#### Startup Script
This script sets up the network and then starts the AIX VM:
```bash
# Network setup
brctl addbr br0
ip addr flush dev enp0s3
brctl addif br0 enp03
brctl addif br0 enp0s3
tunctl -t tap0 -u `whoami`
brctl addif br0 tap0
ifconfig tap0 up
ifconfig br0 up
dhclient -v br0

# Start the AIX VM with the specified configurations
qemu-system-ppc64 -cpu POWER9 \
-machine pseries -m 2048 \
-serial mon:stdio -cdrom /opt/AIX/ressources/AIX_v7.2_Base_Install_7200-03-01-1838_USB_Flash_092018.iso \
-drive file=/opt/AIX/ressources/AIX1.qcow2,if=none,id=drive-virtio-disk0 \
-device virtio-scsi-pci,id=scsi -device scsi-hd,drive=drive-virtio-disk0 \
-netdev tap,id=n1,ifname=tap0,script=no,downscript=no \
-device virtio-net,netdev=n1 -prom-env "input-device=/vdevice/vty@71000000" \
-prom-env "output-device=/vdevice/vty@71000000" \
-prom-env boot-command='boot disk:'
```
#### Network Device Setup on AIX
Set up a network device on AIX using the following commands:
```bash
# List available devices
lsdev
# Display attributes of en0
lsattr -El en0
# Change the IP address and netmask of en0
chdev -l en0 -a netaddr=192.168.1.9 -a netmask=255.255.255.0
# Bring up en0
chdev -l en0 -a state=up
# Start the QEMU system with the specified configurations
qemu-system-ppc64 -cpu POWER9 \
-machine pseries -m 2048 \
-serial mon:stdio -cdrom /opt/AIX/ressources/AIX_v7.2_Base_Install_7200-03-01-1838_USB_Flash_092018.iso \
-drive file=/opt/AIX/ressources/AIX1.qcow2,if=none,id=drive-virtio-disk0 \
-device virtio-scsi-pci,id=scsi -device scsi-hd,drive=drive-virtio-disk0 \
-netdev tap,id=tap0,script=none,downscript=none \
-device virtio-net,netdev=tap0 -prom-env "input-device=/vdevice/vty@71000000" \
-prom-env "output-device=/vdevice/vty@71000000" \
-prom-env boot-command='boot disk:'
```
*Author : Youssef Sbai Idrissi*
