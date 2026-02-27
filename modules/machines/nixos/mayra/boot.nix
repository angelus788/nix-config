{ pkgs, lib, ... }:
{
  console = {
    font = "ter-132n";
    packages = [ pkgs.terminus_font ];
    keyMap = "us";
  };

  # TTY
  fonts.packages = [ pkgs.meslo-lgs-nf ];
  services.kmscon = {
    enable = true;
    hwRender = true;
    extraConfig = ''
      font-name=MesloLGS NF
      font-size=20
    '';
  };
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    consoleLogLevel = 0;
    initrd = {
      verbose = false;
      kernelModules = [ "amd" ];
      availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "sd_mod" "usbhid" "evdev" ];
    };
    kernelParams = [
      "quiet"
      "splash"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "boot.shell_on_fail"
    ];
    loader = {
      timeout = 0;
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
    kernelModules = [ "kvm-amd" ];
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
