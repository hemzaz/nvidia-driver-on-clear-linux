# nvidia-driver-on-clear-linux

An automation **how-to** for installing the NVIDIA proprietary driver on Clear Linux OS.

## Clear Linux OS installation

*Starting fresh? Obtain a recent Clear Linux image from the [release archive](https://cdn.download.clearlinux.org/releases/) (>= 36740, 37230, 37860 or later; but not [37810-37850](https://github.com/clearlinux/distribution/issues/2791)). Currently running CL 37810-37850? First update the OS to 37860 (or later) before installing the display driver.*

Depending on the CL release, the open-source nouveau driver may not work with recent NVIDIA graphics (3000 series or later). The solution is to install the OS in text mode. Press the letter `e` on the boot screen and add `modprobe.blacklist=nouveau` to the list of kernel arguments. That will prevent the nouveau driver from loading. Press enter to boot the OS. Instructions are provided on the screen for running the installer.

During setup, remember to enter `[A]` Advanced options. Select "Kernel Command Line" and add `modprobe.blacklist=nouveau` to "Add Extra Arguments". Optionally, go back to the prior screen and choose the `lts` or `native` kernel under "Kernel Selection". Also disable automatic OS updates if desired.

## NVIDIA driver installation

```bash
git clone https://github.com/marioroy/nvidia-driver-on-clear-linux
cd nvidia-driver-on-clear-linux
```

First, run the pre-installer script and reboot the OS. The `update` argument is needed on prior Clear Linux installations to refresh the associated configuration files under `/etc/`. Run the pre-installer script subsequently, without an argument, to switch the boot target to text mode.

```bash
$ bash ./pre-install-driver help
Usage: pre-install-driver [ update ]

$ git pull
$ bash ./pre-install-driver update
$ bash ./pre-install-driver
$ reboot
```

Next, run the driver installer script. Running the LTS kernel? Choose any driver in the list. Running the Native kernel or GeForce RTX 4000 series? Specify `520` or later. Or provide the location of the `NVIDIA-Linux-x86_64-*` run-file.

If you have an NVIDIA Optimus laptop, choose 520. The 525 display driver is [problematic](https://github.com/elFarto/nvidia-vaapi-driver/issues/141).

Which one to choose regardless? The 520 series driver worked best for my RTX 3070 graphics. I also enabled "Force Full Composition Pipeline"; see instructions at the end of this document.

| Driver |  Version    |
|--------|-------------|
| latest | 525.60.11   |
|  525   | 525.60.13   |
|  520   | 520.61.05   |
|  515   | 515.86.01   |
|  510   | 510.108.03  |
|  470   | 470.161.03  |

```bash
$ bash ./install-driver help
Usage: install-driver latest |525|520|515|510|470| <valid_pathname>

$ bash ./install-driver 520
$ reboot
```

## NVIDIA CUDA Toolkit installation

Installing the CUDA Toolkit is optional. The "auto" argument is preferred and will install the version suitable for the display driver. If the display driver is not in the table then will fetch the latest CUDA run-file.

| Driver | CUDA Toolkit |
|--------|--------------|
|  525   |    12.0.0    |
|  520   |    11.8.0    |
|  515   |    11.7.1    |
|  510   |    11.6.2    |
|  470   |    11.4.4    |

```bash
$ bash ./install-cuda help
Usage: install-cuda latest | auto | <valid_pathname>

$ bash ./install-cuda auto    # or path to run file
$ bash ./install-cuda ~/Downloads/cuda_11.8.0_520.61.05_linux.run
```

**Q)** Why specify the auto argument to `install-cuda`?

**A)** This is the preferred choice. Otherwise, using a mismatched CUDA Toolkit installation not suited for the display driver may cause some CUDA programs to emit an error, "the provided PTX was compiled with an unsupported toolchain".

**Q)** What are my options if the `install-cuda` script is no longer current?

**A)** Notifying the author is one option. The other option is to visit the CUDA archive URL, provided at the bottom of the page. Determine the display driver version from the filename. Then visit the driver archive and scroll to the bottom of the page. Click on the latest matching the base version.  Install the driver and CUDA Toolkit by providing the path to `install-driver` and `install-cuda` respectively.

## Enable hardware acceleration

Hardware acceleration requires installing NVDEC/VDPAU back-end VA-API drivers. See the [HWAccel](HWAccel) folder. It provides instructions for building the VA drivers, a configuration file for Firefox, and launch-desktop files for Brave, Chromium-Freeworld, Google Chrome, Microsoft Edge, and Vivaldi.

## Updating the NVIDIA driver

First, ensure you have the latest by running `git pull` followed by `pre-install-driver` with the `update` argument. You may stop here if all you want to do is refresh the NVIDIA-related configuration files from any upstream updates.

```bash
$ git pull
$ bash ./pre-install-driver update
```

The output will be much smaller for `pre-install-driver` without an argument since it will skip completed sections. Run the pre-installer script regardless to switch the boot target to text mode.

Run `install-driver latest` or acquire the run-file from NVIDIA and save it locally. Note: choosing [latest](https://download.nvidia.com/XFree86/Linux-x86_64/latest.txt) may not be the latest release. See table above.

```bash
$ bash ./pre-install-driver
$ reboot

$ bash ./install-driver latest    # or path to run file
$ bash ./install-driver ~/Downloads/NVIDIA-Linux-x86_64-525.60.13.run
$ reboot
```

Update the CUDA Toolkit, if installed, to install the version suitable for the display driver.

```bash
[ -d /opt/cuda ] && bash ./install-cuda auto
```

## Epilogue

Using a HiDPI monitor? Consider running Xorg versus Wayland. The reason is that device scale-factor does not work in Chrome on Wayland. In GNOME, run `gnome-tweaks` and adjust "Scaling Factor" on the Fonts pane.

Experiencing stutter or tearing when moving windows? Lanuch NVIDIA Settings and enable "Force Full Composition Pipeline". See also, [Difference between Force Full Composition Pipeline and Force Composition Pipeline](https://forums.developer.nvidia.com/t/can-someone-really-explain-the-difference-between-force-full-composition-pipeline-and-force-composition-pipeline/49170).

```bash
1. sudo chown $USER /etc/X11  # this is done by the install-driver script
2. Go to NVIDIA Settings > X Server Display Configuration > Advanced...
3. Enable "Force Full Composition Pipeline" per each monitor
4. Click "Apply"
5. Click "Save to X Configuration File" to persist the change
```

NVIDIA may not boot on systems running Linux 5.18 (or later) with Intel CPUs. A workaround is to disable [Indirect Branch Tracking](https://edc.intel.com/content/www/us/en/design/ipla/software-development-platforms/client/platforms/alder-lake-desktop/12th-generation-intel-core-processors-datasheet-volume-1-of-2/007/indirect-branch-tracking/) until this is fixed, deemed safe temporarily. Refer to [NVIDIA - ArchWiki](https://wiki.archlinux.org/title/NVIDIA).

```bash
sudo mkdir -p /etc/kernel/cmdline.d
sudo tee /etc/kernel/cmdline.d/disable-ibt.conf >/dev/null <<'EOF'
ibt=off
EOF
sudo clr-boot-manager update
```

Installing a kernel manually or the display driver stops working after an OS update? The `check-kernel-dkms` script installs missing dkms bundles and runs `dkms autoinstall` per each kernel on the system.

```bash
bash ./check-kernel-dkms
ls -ltr /usr/lib/modules/*/kernel/drivers/video
reboot
```

If the issue persists, then reinstall the NVIDIA driver described above.

Running a NVIDIA Optimus laptop? See `CONFIGURATION STEPS` or search for `dbus` in `/usr/share/doc/NVIDIA_GLX-1.0/README.txt`. Undo the steps if `nvidia-powerd` reports no matching GPU found. See also, [failure with the nvidia-powerd service](https://www.reddit.com/r/Fedora/comments/sobsgb/anyone_experiencing_failure_with_nvidiapowerd/) and [video decode does not work after exiting sleep](https://github.com/elFarto/nvidia-vaapi-driver/issues/42).

## See also

* [Clear Fraction - third-party repository for Clear Linux](https://clearfraction.cf)
* [CUDA Redistributable Driver Archive](https://developer.download.nvidia.com/compute/cuda/redist/nvidia_driver/linux-x86_64/)
* [CUDA Toolkit Archive](https://developer.nvidia.com/cuda-toolkit-archive)
* [NVIDIA Driver Archive](https://download.nvidia.com/XFree86/Linux-x86_64/)

