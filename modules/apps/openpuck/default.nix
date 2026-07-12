{ ... }:
#OPENPUCK settings
{
services.udev.extraRules = ''
  # OpenPuck / NRF52840 Bootloader (DFU Mode)
  SUBSYSTEMS=="usb", ATTRS{idVendor}=="239a", ATTRS{idProduct}=="0029", MODE="0666", TAG+="uaccess"
  
  # OpenPuck Steam Controller Puck Emulation Mode
  SUBSYSTEMS=="usb", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="1142", MODE="0666", TAG+="uaccess"
  
  # OpenPuck Xbox / XInput Mode Emulation
  SUBSYSTEMS=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="02d1", MODE="0666", TAG+="uaccess"

  # NRF52840 Bootloader / Pro Micro

  SUBSYSTEMS=="usb", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="005a", MODE="0666", GROUP="plugdev"

  SUBSYSTEMS=="usb", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="615e", MODE="0666", GROUP="plugdev"

    # OpenPuck Emulated Controller Modes (Xbox / DS4 / Switch)

  KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"
'';
}