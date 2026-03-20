{ lib, ...}:
if (builtins.lessThan 2 (builtins.length cfg.bootDevices)) then
  # ... mirrored logic ...
else
  { device = "nodev"; }
{
  
boot.loader.grub = {
  enable = true;
  zfsSupport = true;
  efiSupport = true;
  # CRITICAL: This stops GRUB from trying to install the i386-pc (Legacy) version
  device = lib.mkForce "nodev"; 
  efiInstallAsRemovable = true;
};
  
}