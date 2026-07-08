{pkgs, ... }: 
{
environment.systemPackages =  [ pkgs.packet ];
networking.firewall = {
  allowedTCPPorts = [ 9300 ];
  allowedUDPPorts = [ 9300 ];
};

}