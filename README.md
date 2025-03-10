# nvidia-driver-on-clear-linux

A **how-to** NVIDIA proprietary driver installation on Clear Linux OS.

## Quick Start with Make

This repository now includes a Makefile for one-command installation:

```bash
# For GNOME desktop (default):
make install-all    # One command to install everything

# For KDE desktop (prevents black screen):
make install-all-kde

# If you experience any issues after installation:
make fix-issues     # Automatically fix common problems
```

Or step-by-step if you prefer more control:

```bash
# Update configuration files
make prepare-update

# Switch to text mode
make prepare

# Install the driver (select one)
make install-550    # NVIDIA driver version 550
make install-560    # NVIDIA driver version 560 (recommended for CUDA)
make install-565    # NVIDIA driver version 565
make install-570    # NVIDIA driver version 570
make install        # Latest NVIDIA driver

# Install KDE (if desired, prevents black screen)
make install-kde

# Install CUDA toolkit (optional)
make install-cuda

# Build hardware acceleration (optional)
make hw-accel

# Check all commands
make help
```

## Preparation

**Starting fresh?** Obtain the current image from the Clear Linux [Downloads](https://www.clearlinux.org/downloads.html) page.

## Clear Linux OS installation and updates

Depending on the CL release, the open-source nouveau driver may not work with recent NVIDIA graphics (3000 series or newer). The solution is to install the OS in text mode. Press the letter `e` on the boot screen and prepend `nomodeset 3` with a space to the list of kernel arguments. The OS will boot into multi-user mode and prevent the nouveau driver from loading. Press enter to boot the OS. Instructions are provided on the screen for running the installer.

During setup, remember to enter `[A]` Advanced options. Select "Kernel Command Line" and enter `nomodeset 3` to "Add Extra Arguments". Optionally, go back to the prior screen and choose the `lts` (recommended) or `native` kernel under "Kernel Selection". Also disable automatic OS updates if desired.

## NVIDIA driver installation

```bash
git clone https://github.com/marioroy/nvidia-driver-on-clear-linux
cd nvidia-driver-on-clear-linux
```

First, run the pre-installer script. The `update` argument is needed on prior Clear Linux installations or to refresh the configuration files under `/etc/`. Run the pre-installer script subsequently, without an argument, to switch the target from graphical to multi-user (text-mode).

```bash
$ bash ./pre-install-driver help
Usage: pre-install-driver [ update ]

$ git pull
$ bash ./pre-install-driver update
$ bash ./pre-install-driver
```

Next, run the driver installer script. Specifying [latest](https://download.nvidia.com/XFree86/Linux-x86_64/latest.txt) installs the latest production release. Check first before installation. Or specify the desired version or path to the installer file.

| Driver | Version                          | Description                      |
|--------|----------------------------------|----------------------------------|
| latest | [latest.txt](https://download.nvidia.com/XFree86/Linux-x86_64/latest.txt) | Latest official release |
| 550    | 550.135 | Recommended Long-Term Support    |
| 560    | 560.35.05 | CUDA 12.6 Optimized Driver     |
| 565    | 565.77 | New Feature Branch               |
| 570    | 570.53.14 | Latest Series                  |
| vulkan | 550.40.81 | Vulkan Beta Driver            |

```bash
$ bash ./install-driver help
Usage: install-driver latest|550|560|565|570|vulkan|<pathname>

$ bash ./install-driver 560  # CUDA optimized driver
$ sudo reboot
```

## NVIDIA CUDA Toolkit installation

Installing the CUDA Toolkit is optional. The "auto" argument is preferred and will install the version suitable for the display driver. If the display driver is not in the table, then the script will fetch the latest CUDA run-file. If unsure, install the CUDA version matching the display driver or a lower version supported by the application (e.g. Blender).

| Driver | CUDA Toolkit | Command              |
|--------|--------------|----------------------|
|  570   |    12.6.3    | `make install-cuda-126` |
|  560   |    12.6.3    | `make install-cuda-126` |
|  565   |    12.4.1    | `make install-cuda-124` |
|  550   |    12.4.1    | `make install-cuda-124` |
|  535   |    12.2.2    | `make install-cuda-122` |
|  520   |    11.8.0    | `make install-cuda-118` |

```bash
# Using Makefile (recommended)
$ make install-cuda           # auto-detect appropriate version
$ make install-cuda-126       # install CUDA 12.6.x

# Or using scripts directly
$ bash ./install-cuda help
Usage: install-cuda auto|latest|12.6|12.4|12.2|11.8|<pathname>

$ bash ./install-cuda auto    # or path to run file
$ bash ./install-cuda ~/Downloads/cuda_12.6.3_560.35.05_linux.run
```

Update `~/.bashrc` so that it can find the `nvcc` command.

```bash
export CUDA_HOME=/opt/cuda
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
```

Or if you prefer, use `module` to prepend the CUDA path.
First time? This may require logging out and back in,
or open a new terminal window.

```bash
$ module load cuda
$ nvcc --version
$ module unload cuda
```

**Q)** Why specify the auto argument to `install-cuda` or lower version than the display driver?

**A)** Using a later CUDA Toolkit release than the display driver may cause some CUDA programs to emit an error, "the provided PTX was compiled with an unsupported toolchain".

**Q)** What are my options if the `install-cuda` script is no longer current?

**A)** Notifying the author is one option. The other option is to visit the CUDA archive URL, provided at the bottom of the page. Determine the display driver version from the filename. Then visit the driver archive and scroll to the bottom of the page. Click on the latest matching the base version.  Install the driver and CUDA Toolkit by providing the path to `install-driver` and `install-cuda` respectively.

## Enable hardware acceleration

Hardware video acceleration requires the NVDEC back-end VA-API driver. See the [HWAccel](HWAccel) folder. It provides instructions for building the VA driver and configuration file for Firefox.

## Updating the NVIDIA driver

First, ensure you have the latest by running `git pull` followed by `pre-install-driver` with the `update` argument. You may stop here if all you want to do is refresh the NVIDIA-related configuration files from any upstream updates.

```bash
$ git pull
$ bash ./pre-install-driver update
```

The output will be much smaller for `pre-install-driver` without an argument since it will skip completed sections. Run the pre-installer script regardless to switch the boot target to text mode.

Run `install-driver latest` or acquire the run-file from NVIDIA and save it locally.

```bash
$ bash ./pre-install-driver

$ bash ./install-driver latest    # or path to run file
$ bash ./install-driver ~/Downloads/NVIDIA-Linux-x86_64-550.135.run
$ sudo reboot
```

Update the CUDA Toolkit, if installed, to install the version suitable for the display driver and supported by the application.

```bash
[ -d /opt/cuda ] && bash ./install-cuda auto
```

## Uninstallation

The NVIDIA software can be uninstalled and nouveau driver restored. Reinstall the NVIDIA driver if the nouveau driver is failing for your graphics (e.g. NVIDIA 3000+ series).

```bash
$ bash ./uninstall-cuda
$ bash ./uninstall-driver
$ sudo reboot
```

## Troubleshooting

**Installing a kernel manually?** The `check-kernel-dkms` script installs missing dkms bundles and runs `dkms autoinstall` per each kernel on the system.

```bash
bash ./check-kernel-dkms
```

**Running Wayland and x11 apps are crashing?** See [issue](https://gitlab.freedesktop.org/mesa/mesa/-/issues/10624). Try setting a system-wide variable and reboot.

```text
__EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json
```

**Running a NVIDIA Optimus laptop?** See `CONFIGURATION STEPS` or search for `dbus` in `/usr/share/doc/NVIDIA_GLX-1.0/README.txt`. Undo the steps if `nvidia-powerd` reports no matching GPU found. Refer to: [Failure with the nvidia-powerd service](https://www.reddit.com/r/Fedora/comments/sobsgb/anyone_experiencing_failure_with_nvidiapowerd/) and [Video decode does not work after exiting sleep](https://github.com/elFarto/nvidia-vaapi-driver/issues/42).

See also: [Integrated GPU is not (fully) used / Responsiveness issue](https://community.clearlinux.org/t/integrated-gpu-is-not-fully-used-responsiveness-issue/8608).

**Experiencing stutter or tearing when moving windows?** Lanuch NVIDIA Settings and enable "Force Full Composition Pipeline". See also, [Difference between Force Full Composition Pipeline and Force Composition Pipeline](https://forums.developer.nvidia.com/t/can-someone-really-explain-the-difference-between-force-full-composition-pipeline-and-force-composition-pipeline/49170).

Note: Skip this section on Optimus-based laptops. Instead, see the prior URL.

```bash
1. sudo chown $USER /etc/X11  # this is done by the install-driver script
2. Go to NVIDIA Settings > X Server Display Configuration > Advanced...
3. Enable "Force Full Composition Pipeline" per each monitor
4. Click "Apply"
5. Click "Save to X Configuration File" to persist the change
```

Add the `UseNvKmsCompositionPipeline` option to the `Screen` section in `/etc/X11/xorg.conf`; to minimize power-consumption on idle when enabling `CompositionPipeline`.

```text
Option "UseNvKmsCompositionPipeline" "Off"
```

**Using a HiDPI display?** In GNOME, run `gnome-tweaks` and adjust "Scaling Factor" on the Fonts pane. For Wayland, restore `text-scaling-factor` back to 1.0 and enable an experimental feature `scale-monitor-framebuffer`. Log out for the settings to take effect. Go to GNOME settings > Displays and set the scale accordingly, for the display to 100%, 125%, 150%, ... 400%.

```bash
gsettings set org.gnome.desktop.interface text-scaling-factor 1.0
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
```

**Installing KDE?** Important, remove the `desktop-autostart` bundle to not autostart GDM resulting in black screen.

```bash
# Use the built-in command (handles everything):
make install-kde

# Or manually:
sudo swupd bundle-remove desktop-autostart
sudo swupd bundle-add desktop-kde
sudo swupd bundle-add desktop-kde-apps
```

## See also

* [Announcement; tips and solutions](https://community.clearlinux.org/t/the-nvidia-driver-automation-transitions-to-wayland-era/8499)

* [Download Driver Archive](https://download.nvidia.com/XFree86/Linux-x86_64/),
  [Unix Driver Archive](https://www.nvidia.com/en-us/drivers/unix/),
  [Vulkan Driver Support](https://developer.nvidia.com/vulkan-driver)

* [CUDA Toolkit Archive](https://developer.nvidia.com/cuda-toolkit-archive),
  [Documentation](https://docs.nvidia.com/cuda/),
  [Samples](https://github.com/NVIDIA/cuda-samples)

* [CUDA Redistributable Driver Archive](https://developer.download.nvidia.com/compute/cuda/redist/nvidia_driver/linux-x86_64/)

