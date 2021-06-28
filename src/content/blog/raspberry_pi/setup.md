---
title: "Setting Up A Headless Raspberry Pi"
date: "2021-06-28T19:20:00-04:00"

toc: True
draft: False
---


## Objective

The goal of this post is to setup a bare-bones headless [Raspberry Pi 4 Model B](https://www.raspberrypi.org/products/raspberry-pi-4-model-b/)
with (1) a running SSH service, (2) 64-bit enabled, and (3) a secured default
user. In future posts, this host will serve as a foundation to experiment with
configuration management, security hardening, containerization, observability
and much more.


## Requirements

The following are required to follow the steps in this post and produce a
functional host:

 - UNIX computer
 - Internet connection
 - microSD card (or equivalent [boot medium](https://www.raspberrypi.org/documentation/hardware/raspberrypi/bootmodes/msd.md))
 - Raspberry Pi 4 Model B
 - Raspberry Pi power supply
 - Ethernet cable
 - Wired local area network


## Steps

### Acquire Minimal OS Image

The first task is to obtain the latest minimal OS image offered by the Raspberry
Pi Foundation.

1. Navigate to the [Raspberry Pi website](https://www.raspberrypi.org/).
2. Click the "Software" header in the navigation bar.
3. Within the "Software" dropdown menu, click the ["Raspberry Pi OS" link](https://www.raspberrypi.org/software/operating-systems/#raspberry-pi-os-32-bit).
4. Locate the "Raspberry Pi OS Lite" image and copy the link's location.

As of the time of this post's writing, the latest image was built on May 7th
2021 with the following details provided:

```
Release date: May 7th 2021
Kernel version: 5.10
Size: 444MB
```

If you're interested in reviewing any changes to the image, [release notes](https://downloads.raspberrypi.org/raspios_lite_armhf/release_notes.txt)
may be found on the Raspberry Pi website.

5. Download the OS image - we will be using [`wget(1)`](https://linux.die.net/man/1/wget):

```
$ wget https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-05-28/2021-05-07-raspios-buster-armhf-lite.zip
```

6. The integrity of the downloaded image can be verified against the checksum
   published on the Raspberry Pi website (click "Show SHA256 file integrity
   hash"). For this release of the lite image, the known checksum is
   `c5dad159a2775c687e9281b1a0e586f7471690ae28f2f2282c90e7d59f64273c` and we can
   run the command below to verify that the downloaded ZIP archive isn't
   corrupt:

```
$ sha256sum 2021-05-07-raspios-buster-armhf-lite.zip | grep c5dad159a2775c687e9281b1a0e586f7471690ae28f2f2282c90e7d59f64273c
c5dad159a2775c687e9281b1a0e586f7471690ae28f2f2282c90e7d59f64273c  2021-05-07-raspios-buster-armhf-lite.zip
```

If the entire SHA-256 digest outputted by [`sha256sum(1)`](https://linux.die.net/man/1/sha256sum)
is highlighted, then the downloaded image matches the expected checksum. If the
any part of the SHA-256 digest does not match, than the downloaded OS image is
corrupted and should not be used. 

7. The ZIP archive containing the OS image can be extracted using
   [`unzip(1)`](https://linux.die.net/man/1/unzip) - note that extracting the OS
   image from the archive may take a few seconds:

```
$ unzip 2021-05-07-raspios-buster-armhf-lite.zip
Archive:  2021-05-07-raspios-buster-armhf-lite.zip
  inflating: 2021-05-07-raspios-buster-armhf-lite.img
```

If we [`ls(1)`](https://linux.die.net/man/1/ls) the current working directory,
we can observe the original ZIP archive occupying 445MB of disk space and the 
extracted and uncompressed OS image (`.img`) occupying 1.8GB of disk space.

```
$ ls -lh
total 2.2G
-rw-r--r-- 1 patrick patrick 1.8G May  7 11:00 2021-05-07-raspios-buster-armhf-lite.img
-rw-r--r-- 1 patrick patrick 445M May  7 11:02 2021-05-07-raspios-buster-armhf-lite.zip
```

From here, we can begin provisioning the boot medium. 


### Provision Boot Medium

1. Prior to connecting the boot medium to the machine, we will use [`lsblk(8)`](https://linux.die.net/man/8/lsblk)
   to list IO block devices that are currently attached to the machine.

```
$ lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
nvme0n1                   259:0    0  477G  0 disk
├─nvme0n1p1               259:1    0  512M  0 part  /boot/efi
├─nvme0n1p2               259:2    0  488M  0 part  /boot
└─nvme0n1p3               259:3    0  476G  0 part
  └─nvme0n1p3_crypt       254:0    0  476G  0 crypt
    ├─thinkpad--vg-root   254:1    0  475G  0 lvm   /
    └─thinkpad--vg-swap_1 254:2    0  976M  0 lvm   [SWAP]
```

Note that only one block device (the machine's boot drive), `nvme0n1`, is
present on the computer. We can now attach the Raspberry Pi's boot medium to the
computer and re-run `lsblk(8)` to identify the name of the new block device.

2. Attach the Raspberry Pi's boot medium to the computer.
3. Re-run `lsblk(8)` and review the output:

```
$ lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
sdb                         8:16   1 29.8G  0 disk  
└─sdb1                      8:17   1 29.8G  0 part  
nvme0n1                   259:0    0  477G  0 disk  
├─nvme0n1p1               259:1    0  512M  0 part  /boot/efi
├─nvme0n1p2               259:2    0  488M  0 part  /boot
└─nvme0n1p3               259:3    0  476G  0 part  
  └─nvme0n1p3_crypt       254:0    0  476G  0 crypt 
    ├─thinkpad--vg-root   254:1    0  475G  0 lvm   /
    └─thinkpad--vg-swap_1 254:2    0  976M  0 lvm   [SWAP]
```

4. Identify the Raspberry Pi boot medium. A new block device, `sdb` can now be
   observed attached to the computer.
5. Next, the Raspberry Pi OS Lite image will be burned to the boot medium
   (`/dev/sdb`) using the [`dd(1)`](https://linux.die.net/man/1/dd) command;
   optionally, [`pv(1)`](https://linux.die.net/man/1/pv) may be used to monitor
   the progress of writing the image to the device:

Using only `dd(1)`:

```
$ sudo dd if=2021-05-07-raspios-buster-armhf-lite.img of=/dev/sdb
```

Piping the image into `dd(1)` via `pv(1)` and monitoring the progress:

```
$ pv 2021-05-07-raspios-buster-armhf-lite.img | sudo dd of=/dev/sdb
203MiB 0:00:20 [10.2MiB/s] [===>                        ] 11% ETA 0:02:35
```

Once the OS image has been burned to the boot medium, the newly created
Raspberry Pi OS disk partitions can be observed.

6. Verify Raspberry Pi OS disk partitions on the boot medium by using `lsblk(8)`:

```
$ lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
sdb                         8:16   1 29.8G  0 disk
├─sdb1                      8:17   1  256M  0 part
└─sdb2                      8:18   1  1.5G  0 part
nvme0n1                   259:0    0  477G  0 disk
├─nvme0n1p1               259:1    0  512M  0 part  /boot/efi
├─nvme0n1p2               259:2    0  488M  0 part  /boot
└─nvme0n1p3               259:3    0  476G  0 part
  └─nvme0n1p3_crypt       254:0    0  476G  0 crypt
    ├─thinkpad--vg-root   254:1    0  475G  0 lvm   /
    └─thinkpad--vg-swap_1 254:2    0  976M  0 lvm   [SWAP]
```

Two new partitions `sdb1` and `sdb2` can be observed on the `sdb` device. At
this point, the boot medium is viable and can be plugged into the Raspberry Pi
and booted from; however, this post will continue to both (1) enable the SSH
service to allow for remote access to the host; and (2) change the default
user's (`pi`) password - as a security best practice.


### Enabling The SSH Service

By default, Raspberry Pi OS uses the OpenBSD Secure Shell (SSH) server,
[`sshd(8)`](https://linux.die.net/man/8/sshd), to permit remote access to the
host. Due to the security implications of permitting remote access to a host,
this functionality is disabled by default and requires the opt-in via a minor
configuration change.

1. Mount the Raspberry Pi's boot partition, `/dev/sdb1` (the 256MB partition):

```
$ sudo mkdir /mnt/boot
$ sudo mount /dev/sdb1 /mnt/boot
```

2. Verify that the boot partition has been mounted properly by listing its
   contents:

```
$ cd /mnt/boot
$ ls -la
total 48178
drwxr-xr-x 3 root root    3584 Dec 31  1969 .
drwxr-xr-x 3 root root    4096 Jun 24 18:46 ..
-rwxr-xr-x 1 root root   25607 Mar  3 08:40 bcm2708-rpi-b.dtb
-rwxr-xr-x 1 root root   25870 Mar  3 08:40 bcm2708-rpi-b-plus.dtb
-rwxr-xr-x 1 root root   25218 Mar  3 08:40 bcm2708-rpi-b-rev1.dtb
-rwxr-xr-x 1 root root   25529 Mar  3 08:40 bcm2708-rpi-cm.dtb
-rwxr-xr-x 1 root root   25352 Mar  3 08:40 bcm2708-rpi-zero.dtb
-rwxr-xr-x 1 root root   26545 Mar  3 08:40 bcm2708-rpi-zero-w.dtb
-rwxr-xr-x 1 root root   26745 Mar  3 08:40 bcm2709-rpi-2-b.dtb
-rwxr-xr-x 1 root root   26894 Mar  3 08:40 bcm2710-rpi-2-b.dtb
-rwxr-xr-x 1 root root   28392 Mar  3 08:40 bcm2710-rpi-3-b.dtb
-rwxr-xr-x 1 root root   29011 Mar  3 08:40 bcm2710-rpi-3-b-plus.dtb
-rwxr-xr-x 1 root root   26890 Mar  3 08:40 bcm2710-rpi-cm3.dtb
-rwxr-xr-x 1 root root   48810 Apr 30 10:01 bcm2711-rpi-400.dtb
-rwxr-xr-x 1 root root   49090 Mar  3 08:40 bcm2711-rpi-4-b.dtb
-rwxr-xr-x 1 root root   49202 Mar  3 08:40 bcm2711-rpi-cm4.dtb
-rwxr-xr-x 1 root root   52456 Jan  5 02:30 bootcode.bin
-rwxr-xr-x 1 root root     169 May  7 11:00 cmdline.txt
-rwxr-xr-x 1 root root    1784 May  7 10:43 config.txt
-rwxr-xr-x 1 root root   18693 Jan  5 02:30 COPYING.linux
-rwxr-xr-x 1 root root    3191 Apr 30 10:01 fixup4cd.dat
-rwxr-xr-x 1 root root    5446 Apr 30 10:01 fixup4.dat
-rwxr-xr-x 1 root root    8454 Apr 30 10:01 fixup4db.dat
-rwxr-xr-x 1 root root    8452 Apr 30 10:01 fixup4x.dat
-rwxr-xr-x 1 root root    3191 Apr 30 10:01 fixup_cd.dat
-rwxr-xr-x 1 root root    7314 Apr 30 10:01 fixup.dat
-rwxr-xr-x 1 root root   10298 Apr 30 10:01 fixup_db.dat
-rwxr-xr-x 1 root root   10298 Apr 30 10:01 fixup_x.dat
-rwxr-xr-x 1 root root     145 May  7 11:00 issue.txt
-rwxr-xr-x 1 root root 6320888 Apr 30 10:01 kernel7.img
-rwxr-xr-x 1 root root 6694528 Apr 30 10:01 kernel7l.img
-rwxr-xr-x 1 root root 7758283 Apr 30 10:01 kernel8.img
-rwxr-xr-x 1 root root 5981944 Apr 30 10:01 kernel.img
-rwxr-xr-x 1 root root    1594 Jan  5 02:30 LICENCE.broadcom
drwxr-xr-x 2 root root   18432 May  7 10:42 overlays
-rwxr-xr-x 1 root root  793084 Apr 30 10:01 start4cd.elf
-rwxr-xr-x 1 root root 3722504 Apr 30 10:01 start4db.elf
-rwxr-xr-x 1 root root 2228768 Apr 30 10:01 start4.elf
-rwxr-xr-x 1 root root 2981160 Apr 30 10:01 start4x.elf
-rwxr-xr-x 1 root root  793084 Apr 30 10:01 start_cd.elf
-rwxr-xr-x 1 root root 4794472 Apr 30 10:01 start_db.elf
-rwxr-xr-x 1 root root 2952928 Apr 30 10:01 start.elf
-rwxr-xr-x 1 root root 3704712 Apr 30 10:01 start_x.elf
```

4. Enable the SSH service by creating an empty file named `ssh` in the
   `/mnt/boot` directory:

```
$ sudo touch /mnt/boot/ssh
```

The SSH service will now start when the Raspberry Pi is first booted up. Next,
64-bit mode will be enabled on the Raspberry Pi.


### Enable 64-bit Support

By default, the Raspberry Pi 4 Model B runs in 32-bit mode on the `armv7l`
architecture. Both the Raspberry Pi 3 and 4 support both 32-bit and 64-bit mode;
however, to take full advantage of the Raspberry Pi 4 models with 4GB and 8GB of
memory - the 64-bit mode is preferable. In order to enable 64-bit mode:

1. Edit `config.txt` in the boot partition `/mnt/boot/config.txt`:

```
$ sudo vim /mnt/boot/config.txt
```

2. Locate the INI configuration section entitled `pi4`:

```
[pi4]
# Enable DRM VC4 V3D driver on top of the dispmanx display stack
dtoverlay=vc4-fkms-v3d
max_framebuffers=2
```

3. Add the line `arm_64bit=1` to the section to enable 64-bit support:

```
[pi4]
# Enable DRM VC4 V3D driver on top of the dispmanx display stack
dtoverlay=vc4-fkms-v3d
max_framebuffers=2
arm_64bit=1
```

4. Save the changes.

5. Unmount the boot partition:

```
$ sudo umount /mnt/boot
$ sudo rmdir /mnt/boot
```

Upon first boot, the Raspberry Pi should boot straight into 64-bit mode. From
here, the default user's credentials can now be changed to a secure password.


### Change Default User Credentials

By default, Raspberry Pi OS comes with a single user, `pi`, with a default
password, `raspberry`. The `pi` user can escalate it's privileges to that of the
`root` super-user; as such, in order to protect the host's security, the `pi`
user's credentials must be strengthened.

Similar to the previous section, we must mount a partition from the boot medium.
This time around, the root partition, `sdb2`, will be mounted to allow for
some configuration changes.

1. Mount the root partition, `/dev/sdb2`:

```
$ sudo mkdir /mnt/pi
$ sudo mount /dev/sdb2 /mnt/pi
```

2. Change current working directory:

```
$ cd /mnt/pi
```

3. Review `/etc/shadow`. Note that there should be a line for the `pi` user.

```
$ sudo cat /mnt/pi/etc/shadow
root:*:18754:0:99999:7:::
daemon:*:18754:0:99999:7:::
bin:*:18754:0:99999:7:::
sys:*:18754:0:99999:7:::
sync:*:18754:0:99999:7:::
games:*:18754:0:99999:7:::
man:*:18754:0:99999:7:::
lp:*:18754:0:99999:7:::
mail:*:18754:0:99999:7:::
news:*:18754:0:99999:7:::
uucp:*:18754:0:99999:7:::
proxy:*:18754:0:99999:7:::
www-data:*:18754:0:99999:7:::
backup:*:18754:0:99999:7:::
list:*:18754:0:99999:7:::
irc:*:18754:0:99999:7:::
gnats:*:18754:0:99999:7:::
nobody:*:18754:0:99999:7:::
systemd-timesync:*:18754:0:99999:7:::
systemd-network:*:18754:0:99999:7:::
systemd-resolve:*:18754:0:99999:7:::
_apt:*:18754:0:99999:7:::
pi:$6$KUf.pHy0JZ2A8C.G$1ybG8vZLdxRFmSh0NqZ9v3zTEX3LQlCuSDZLYrseM1lys364EB59Pq89g92bRSxpur3ca.gmOyKHXQndxLKwP0:18754:0:99999:7:::
messagebus:*:18754:0:99999:7:::
_rpc:*:18754:0:99999:7:::
statd:*:18754:0:99999:7:::
sshd:*:18754:0:99999:7:::
avahi:*:18754:0:99999:7:::
```


#### Deep Dive Into Shadow Files

As noted in the [`shadow(5)` manual page](https://linux.die.net/man/5/shadow),
the `/etc/shadow` file contains password information for system accounts
including various parameters separated by a `:`. For the default `pi` user
account, those values are the following:

 - login name: `pi`
 - encrypted password: `$6$KUf.pHy0JZ2A8C.G$1ybG8vZLdxRFmSh0NqZ9v3zTEX3LQlCuSDZLYrseM1lys364EB59Pq89g92bRSxpur3ca.gmOyKHXQndxLKwP0`
 - date of last password change: `18754`
   - Measured as the number of days since Jan 1, 1970. `18754` corresponds to
     Friday May 7, 2021 - the date the OS image was released.
 - minimum password age: `0`
 - maximum password age: `99999`
   - On or after Monday Oct. 16, 2243, Raspberry Pi users who still use the
     default password will be prompted to change their password.
     This is interesting yet has no importance with respect to changing the 
     password.
 - password warning period: `7`
   - The user will be warned of the upcoming password change requirement 7 days
     before Oct. 16, 2243.
 - password inactivity period: None
 - account expiration date: None
 - reserved field: None

In order to change the user's password, the encrypted password field will need 
to be updated. From the [`shadow(5)` manual](https://linux.die.net/man/5/shadow),
the encrypted password field is generated using [`crypt(3)`](https://linux.die.net/man/3/crypt):

```
encrypted password
    Refer to crypt(3) for details on how this string is interpreted.

    If the password field contains some string that is not a valid result of
    crypt(3), for instance ! or *, the user will not be able to use a unix
    password to log in (but the user may log in the system by other means).

    This field may be empty, in which case no passwords are required to
    authenticate as the specified login name. However, some applications
    which read the /etc/shadow file may decide not to permit any access at
    all if the password field is empty.

    A password field which starts with an exclamation mark means that the
    password is locked. The remaining characters on the line represent the
    password field before the password was locked.
```

Thankfully, there are [Python binding](https://docs.python.org/3/library/crypt.html)
to the underlying C [`crypt(3)` library](https://linux.die.net/man/3/crypt) - so
there is no need to write and compile any C code. We can use the `shadow_gen.py`
source code below to input the new default user credentials and generate an
encrypted `crypt(3)` digest for `/etc/shadow`:

```python3
#! /usr/bin/env python3

import getpass
import cryptimport hmac

passphrase = getpass.getpass()
digest = crypt.crypt(passphrase)

if hmac.compare_digest(digest, crypt.crypt(passphrase, digest)):
    print(digest)
else:
    raise ValueError("Unable to validate integrity of crypt(3) passphrase digest")
```

4. Create a new password for the `pi` user - preferably managed by a password
   manager.
5. Generate the `crypt(3)` digest for the new password:

```
$ python3 shadow_gen.py 
Password: 
$6$f559SmWj.Fc4SQFY$LbUtc1NqFDWGeVY5bdA14NEODStFsFTnxaOcI9Q3CZM3QQ0b68dfc0HR40cw4BT8RjngmiRTQjtqvp1HC.7vV1
```

Note that the `crypt(3)` library is based on the cryptographically weak [Data Encryption Standard (DES)](https://csrc.nist.gov/csrc/media/publications/fips/46/3/archive/1999-10-25/documents/fips46-3.pdf),
as such, the encrypted hash digest should be treated as sensitive and not
published.

6. Substitute the original salted digest for the `pi` user in
   `/mnt/pi/etc/shadow` with the newly generated `crypt(3)` digest:

```
$ sudo vim /mnt/pi/etc/shadow
```

7. Unmount the system partition:

```
$ sudo umount /mnt/pi
$ sudo rmdir /mnt/pi
```

The boot medium is now complete and ready for its first boot.


### Boot Raspberry Pi

1. Disconnect the boot medium from the computer.
2. Insert the boot medium into the Raspberry Pi.
3. Connect the Raspberry Pi to the local area network via an Ethernet cable.
4. Connect the Raspberry Pi to power and wait a minute or two for the host to
   boot. During the first boot, the Raspberry Pi will re-size the root partition
   of the boot medium to take advantage of any unused space - this may make the
   first boot take a few minutes longer than the typical boot time.
5. Determine the local IP address of the Raspberry Pi. This may be accomplished
   by logging into your router's administration interface.
6. SSH into the Raspberry Pi:

```
$ ssh pi@192.168.86.81
The authenticity of host '192.168.86.81 (192.168.86.81)' can't be established.
ECDSA key fingerprint is SHA256:2yOgTd58jerUTa6PPvh5agUf+9/KP9I0TQ8LXgBsMSY.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '192.168.86.81' (ECDSA) to the list of known hosts.
pi@192.168.86.81's password:
Linux raspberrypi 5.10.17-v8+ #1414 SMP PREEMPT Fri Apr 30 13:23:25 BST 2021 aarch64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Sun Jun 27 16:46:19 2021 from 192.168.86.63

Wi-Fi is currently blocked by rfkill.
Use raspi-config to set the country before use.

pi@raspberrypi:~$
```

7. Enjoy tinkering!

The SSH prompt outputs various system information, including the  architecture -
without running any additional commands 64-bit mode can be confirmed by
observing `aarch64`.

The host is now ready to begin experimentation. While the remainder of this post
is optional, it will review various system metrics (including resource usage) to
establish a baseline for future reference.


## Initial Resource Usage


### CPU

The [`lscpu(1)`](https://linux.die.net/man/1/lscpu) and [`uptime(1)`](https://linux.die.net/man/1/uptime)
commands can be used to display metadata about the host's CPU architecture and
view both the host's uptime and CPU load. The `uptime(1)` command outputs CPU
load averages over three periods - 1, 5, and 15 minutes.

```
pi@raspberrypi:~$ lscpi u
Architecture:        aarch64
Byte Order:          Little Endian
CPU(s):              4
On-line CPU(s) list: 0-3
Thread(s) per core:  1
Core(s) per socket:  4
Socket(s):           1
Vendor ID:           ARM
Model:               3
Model name:          Cortex-A72
Stepping:            r0p3
CPU max MHz:         1500.0000
CPU min MHz:         600.0000
BogoMIPS:            108.00
Flags:               fp asimd evtstrm crc32 cpuid
```

From the output of `lscpu(1)` it can be observed that the Raspberry Pi 4 Model B
ships with a 4 core Cortex-A72 CPU using the `aarch64` architecture. If the
architecture on your host is `armv7l`, the Raspberry Pi is running in 32-bit
mode - 64-bit mode has not been properly enabled and `/boot/config.txt` should
be double checked. The Cortex-A72 features a maximum clock speed of 1.5GHz and a
minimum clock speed of 600MHz (i.e. when idle to preserve power or when [thermal throttling](https://www.raspberrypi.org/blog/thermal-testing-raspberry-pi-4/)).

```
pi@raspberrypi:~$ uptime
 23:57:04 up 1 day,  7:13,  1 user,  load average: 0.00, 0.00, 0.00
```

From the output of `uptime(1)` it can be observed that the host has been running
for just over 2 days. Due to the host being idle and running no other software
during that period, all CPU loads are `0.00` - indicating little-to-no usage.
Since the host has 4 cores, CPU load can range from `0.00` (0% usage) to `4.00`
(100% usage).


### Memory

Memory usage can be observed using [`free(1)`](https://linux.die.net/man/1/free).

```
pi@raspberrypi:~$ free -h
              total        used        free      shared  buff/cache   available
Mem:          7.7Gi        48Mi       7.4Gi        16Mi       275Mi       7.4Gi
Swap:          99Mi          0B        99Mi
```

An idle host with only one active SSH session uses only 48Mi of active memory
space and 275Mi of buffer/cache memory - leaving 7.4Gi of memory available for
experimentation and other processes.


### Disk Usage

Similarly, disk usage can be observed using [`lsblk(8)`](https://linux.die.net/man/8/lsblk)
and [`df(1)`](https://linux.die.net/man/1/df).

```
pi@raspberrypi:~$ lsblk
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
mmcblk0     179:0    0  29.8G  0 disk
├─mmcblk0p1 179:1    0   256M  0 part /boot
└─mmcblk0p2 179:2    0  29.6G  0 part /
```

From the initial 32GB microSD card boot medium, 29.8GB of disk space is usable;
of that space, 256MB is allocated to the boot sector and the remaining 29.6GB
is allocated to the root partition.

Actual disk usage can be observed using `df(1)` as shown below:

```
pi@raspberrypi:~$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        30G  1.3G   27G   5% /
devtmpfs        3.8G     0  3.8G   0% /dev
tmpfs           3.9G     0  3.9G   0% /dev/shm
tmpfs           3.9G   17M  3.9G   1% /run
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
tmpfs           3.9G     0  3.9G   0% /sys/fs/cgroup
/dev/mmcblk0p1  253M   48M  205M  19% /boot
tmpfs           788M     0  788M   0% /run/user/1000
```

The most important partition displayed in the output above is `/dev/root` which
is the host's root partition - 1.3GB of disk space is used with 27GB remaining.


### Temperature

The [`vcgencmd`](https://www.raspberrypi.org/documentation/raspbian/applications/vcgencmd.md)
command may be used to obtain the Raspberry Pi's [system-on-a-chip](https://en.wikipedia.org/wiki/System_on_a_chip)
temperature.

When the Raspberry Pi exceeds a temperature of 85 C, [the system will thermal
throttle](https://www.raspberrypi.org/documentation/hardware/raspberrypi/frequency-management.md)
and reduce the CPU's frequency in an attempt to control the system's
temperature. Under some circumstances, voltages within the system will be
decreased - potentially disconnecting peripherals.

```
pi@raspberrypi:~$ vcgencmd measure_temp
temp=37.9'C
```

The Raspberry Pi used in this post is equipped with a [Flirc case](https://flirc.tv/more/raspberry-pi-4-case)
which passively cools the system.


### Installed Packages

The `apt(8)` command is responsible for managing the system's software packages.
A complete list of software installed on the base Raspberry Pi OS Lite image may
be obtained by running `apt list --installed`. From the results, it can be
observed that the base system has 483 packages installed - a complete list of
[packages may be found here](/files/raspberry_pi/lite_base_packages.txt).

```
pi@raspberrypi:~$ apt list --installed | wc -l

WARNING: apt does not have a stable CLI interface. Use with caution in scripts.

484
```

Note that `apt list --installed` includes an extra newline containing
`Listing... Done` which must be removed from the final count.


## Next Steps

Now that the Raspberry Pi has been configured, it will serve as a foundation for
future posts surrounding configuration management, security hardening,
observability, Docker, and much more!
