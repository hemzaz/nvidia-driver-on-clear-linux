# Makefile for NVIDIA driver installation on Clear Linux OS
# Provides simplified commands for driver operations

.PHONY: help prepare prepare-update install install-latest install-550 install-560 install-565 install-570 install-vulkan \
	install-cuda install-cuda-126 install-cuda-124 install-cuda-122 install-cuda-118 \
	uninstall clean check-dkms hw-accel hw-clean update install-kde install-all install-all-kde fix-issues

help:
	@echo "NVIDIA Driver on Clear Linux - Makefile"
	@echo ""
	@echo "One-Command Installation:"
	@echo "  make install-all     - Complete NVIDIA driver installation in one step"
	@echo "  make install-all-kde - Complete installation with KDE desktop environment"
	@echo "  make fix-issues      - Automatically fix common NVIDIA driver issues"
	@echo ""
	@echo "Step-by-Step Installation:"
	@echo "  make prepare         - Prepare the system for driver installation"
	@echo "  make prepare-update  - Update configuration files"
	@echo "  make install         - Install the latest NVIDIA driver"
	@echo "  make install-550     - Install NVIDIA driver version 550 (Recommended/Stable)"
	@echo "  make install-560     - Install NVIDIA driver version 560 (CUDA-optimized)"
	@echo "  make install-565     - Install NVIDIA driver version 565 (Feature Branch)"
	@echo "  make install-570     - Install NVIDIA driver version 570 (Latest Series)"
	@echo "  make install-vulkan  - Install NVIDIA Vulkan beta driver"
	@echo ""
	@echo "CUDA Installation:"
	@echo "  make install-cuda    - Install CUDA toolkit compatible with your driver"
	@echo "  make install-cuda-126 - Install CUDA toolkit 12.6.x (for driver 560+)"
	@echo "  make install-cuda-124 - Install CUDA toolkit 12.4.x (for driver 550+)"
	@echo "  make install-cuda-122 - Install CUDA toolkit 12.2.x (for driver 535+)"
	@echo "  make install-cuda-118 - Install CUDA toolkit 11.8.x (for driver 520+)"
	@echo ""
	@echo "Desktop Environment:"
	@echo "  make install-kde     - Install KDE desktop environment (prevents black screen)"
	@echo ""
	@echo "Hardware Acceleration:"
	@echo "  make hw-accel        - Build hardware acceleration components"
	@echo "  make hw-clean        - Remove hardware acceleration build artifacts"
	@echo ""
	@echo "Maintenance:"
	@echo "  make uninstall       - Remove NVIDIA driver and CUDA toolkit"
	@echo "  make clean           - Remove downloaded files"
	@echo "  make check-dkms      - Verify DKMS modules for installed kernels"
	@echo "  make update          - Update driver to latest version"
	@echo ""
	@echo "Example workflow:"
	@echo "  Single command: make install-all"
	@echo "  Or step by step:"
	@echo "    make prepare-update  - First update config files"
	@echo "    make prepare         - Switch to text mode"
	@echo "    make install-560     - Install CUDA-optimized driver version"
	@echo "    make install-cuda-126 - Install compatible CUDA toolkit"
	@echo "    make hw-accel        - Build hardware acceleration support"

prepare:
	@echo "Preparing system for driver installation (switching to text mode)..."
	bash ./pre-install-driver

prepare-update:
	@echo "Updating configuration files..."
	bash ./pre-install-driver update

install: install-latest

install-latest:
	@echo "Installing latest NVIDIA driver..."
	bash ./install-driver latest

install-550:
	@echo "Installing NVIDIA driver version 550..."
	bash ./install-driver 550

install-560:
	@echo "Installing NVIDIA driver version 560..."
	bash ./install-driver 560

install-565:
	@echo "Installing NVIDIA driver version 565..."
	bash ./install-driver 565

install-570:
	@echo "Installing NVIDIA driver version 570..."
	bash ./install-driver 570

install-vulkan:
	@echo "Installing NVIDIA Vulkan beta driver..."
	bash ./install-driver vulkan

install-cuda:
	@echo "Installing compatible CUDA toolkit..."
	bash ./install-cuda auto

install-cuda-126:
	@echo "Installing CUDA toolkit 12.6.x..."
	bash ./install-cuda 12.6

install-cuda-124:
	@echo "Installing CUDA toolkit 12.4.x..."
	bash ./install-cuda 12.4

install-cuda-122:
	@echo "Installing CUDA toolkit 12.2.x..."
	bash ./install-cuda 12.2

install-cuda-118:
	@echo "Installing CUDA toolkit 11.8.x..."
	bash ./install-cuda 11.8

uninstall:
	@echo "Uninstalling CUDA toolkit (if installed)..."
	[ -d /opt/cuda ] && bash ./uninstall-cuda || true
	@echo "Uninstalling NVIDIA driver..."
	bash ./uninstall-driver

clean:
	@echo "Cleaning up downloaded files..."
	rm -f NVIDIA-Linux-x86_64-*.run
	rm -f nvidia_driver-linux-x86_64-*-archive.tar.xz
	rm -f cuda_*_linux.run
	rm -f vulkan-*-linux

check-dkms:
	@echo "Checking DKMS modules for installed kernels..."
	bash ./check-kernel-dkms

hw-accel:
	@echo "Building hardware acceleration components..."
	cd HWAccel && bash ./build-all

hw-clean:
	@echo "Cleaning hardware acceleration build artifacts..."
	cd HWAccel && bash ./clean-all

update:
	@echo "Updating NVIDIA driver to latest version..."
	bash ./pre-install-driver update
	bash ./pre-install-driver
	bash ./install-driver latest
	[ -d /opt/cuda ] && bash ./install-cuda auto || true

install-kde:
	@echo "Installing KDE desktop environment (first removing desktop-autostart to prevent black screen)..."
	sudo swupd bundle-remove desktop-autostart
	sudo swupd bundle-add desktop-kde
	sudo swupd bundle-add desktop-kde-apps
	
install-all:
	@echo "Installing NVIDIA driver with full setup in one go..."
	bash ./pre-install-driver update
	bash ./pre-install-driver
	bash ./install-driver 560  # CUDA-optimized version
	sudo reboot

install-all-kde:
	@echo "Installing NVIDIA driver with KDE desktop in one go..."
	@echo "First removing desktop-autostart bundle to prevent black screen with KDE..."
	sudo swupd bundle-remove desktop-autostart
	bash ./pre-install-driver update
	bash ./pre-install-driver
	bash ./install-driver 560  # CUDA-optimized version
	sudo swupd bundle-add desktop-kde
	sudo swupd bundle-add desktop-kde-apps
	sudo reboot
	
fix-issues:
	@echo "Automatically fixing common NVIDIA driver issues..."
	bash ./fix-common-issues