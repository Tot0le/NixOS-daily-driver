# Main desktop. Anything specific to this machine lives here; what every
# machine shares is in configuration.nix and modules/.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./users.nix
  ];

  # GRUB on UEFI, with os-prober so that the Windows entry shows up (dual boot)
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.useOSProber = true;

  environment.etc."systemd/system-sleep/xhci-fix" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      # Works around a known AMD A520 chipset XHCI resume bug: after S3
      # suspend, the controller comes back in an error state (USBSTS 0x401)
      # unless it's fully unbound before sleep and rebound after wake.
      # Confirmed fix — resume errors disappeared in testing after this.
      case "$1" in
        pre)
          echo 0000:04:00.0 > /sys/bus/pci/drivers/xhci_hcd/unbind
          ;;
        post)
          echo 0000:04:00.0 > /sys/bus/pci/drivers/xhci_hcd/bind
          ;;
      esac
    '';
  };

  # Release this machine was first installed with: never change it
  system.stateVersion = "25.11";
}
