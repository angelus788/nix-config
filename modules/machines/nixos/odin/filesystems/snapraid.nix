{ ... }:
{
  services.snapraid = {
    enable = true;
    parityFiles = [
      "/Parity1/snapraid.parity"
    ];
    contentFiles = [
      "/var/lib/snapraid.content"
      "/Data1/snapraid.content"
      "/Data2/snapraid.content"
      "/Data3/snapraid.content"
      "/Data4/snapraid.content"
    ];
    dataDisks = {
      d1 = "/Data1";
      d2 = "/Data2";
      d3 = "/Data3";
      d4 = "/Data4";
    };
  };
}
 