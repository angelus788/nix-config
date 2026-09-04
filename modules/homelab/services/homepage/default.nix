{
  config,
  lib,
  ...
}:
let
  service = "homepage-dashboard";
  cfg = config.homelab.services.homepage;
  homelab = config.homelab;
in
{
  options.homelab.services.homepage = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
    monitoredServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        service
      ];
    };
    misc = lib.mkOption {
      default = [ ];
      type = lib.types.listOf (
        lib.types.attrsOf (
          lib.types.submodule {
            options = {
              description = lib.mkOption {
                type = lib.types.str;
              };
              href = lib.mkOption {
                type = lib.types.str;
              };
              siteMonitor = lib.mkOption {
                type = lib.types.str;
              };
              icon = lib.mkOption {
                type = lib.types.str;
              };
              category = lib.mkOption {
                type = lib.types.str;
                default = "Misc";
                description = "Homepage group this entry is displayed under.";
              };
            };
          }
        )
      );
    };
  };
  config = lib.mkIf cfg.enable {
    services.glances.enable = true;
    services.${service} = {
      enable = true;
      environmentFiles = [
        (builtins.toFile "homepage.env" "HOMEPAGE_ALLOWED_HOSTS=root.${homelab.baseDomain},${homelab.baseDomain},100.94.78.77,odin,localhost,127.0.0.1,odin.tailcaed2.ts.net")
      ];
      customCSS = ''
        body, html {
          font-family: SF Pro Display, Helvetica, Arial, sans-serif !important;
        }
        .font-medium {
          font-weight: 700 !important;
        }
        .font-light {
          font-weight: 500 !important;
        }
        .font-thin {
          font-weight: 400 !important;
        }
        #information-widgets {
          padding-left: 1.5rem;
          padding-right: 1.5rem;
        }
        div#footer {
          display: none;
        }
        .services-group.basis-full.flex-1.px-1.-my-1 {
          padding-bottom: 3rem;
        };
      '';
      settings = {
        layout = [
          {
            Glances = {
              header = false;
              style = "row";
              columns = 4;
            };
          }
          {
            Arr = {
              header = true;
              style = "column";
            };
          }
          {
            Media = {
              header = true;
              style = "column";
            };
          }
          {
            Tools = {
              header = true;
              style = "column";
            };
          }
          {
            Services = {
              header = true;
              style = "column";
            };
          }
        ];
        headerStyle = "clean";
        statusStyle = "dot";
        hideVersion = "true";
      };
      services =
        let
          homepageCategories = [
            "Arr"
            "Media"
            "Tools"
            "Services"
            "Observability"
            "Smart Home"
          ];
          hl = config.homelab.services;
          # These service modules declare homepage.* like any other service
          # but aren't actually deployed (enable = true) on any host yet -
          # unlike hermes-agent/pocket-id below (deployed elsewhere, just
          # need a customUrls fixup), there's no reachable target anywhere
          # for these, so Homepage's httpProxy widget spams ENOTFOUND every
          # refresh. Drop them from the dashboard until one of them
          # actually gets enabled somewhere.
          unimplementedServices = [
            "homeassistant"
            "raspberrymatic"
          ];
          homepageServices =
            x:
            (lib.attrsets.filterAttrs (
              name:
              value:
              !(builtins.elem name unimplementedServices) && value ? homepage && value.homepage.category == x
            ) homelab.services);
          serviceEntry =
            x:
            let
              customUrls = {
                forgejo = "https://git.avgtechguy.com";
                couchdb = "https://couchdb.avgtechguy.com/_utils";
                # hermes-agent only runs on thor, not odin (where Homepage
                # itself runs) - the default "https://${hl.hermes-agent.url}"
                # falls back to the option's declared default
                # (thor.thorsaga.net, plain HTTP, no TLS) since odin never
                # overrides that option itself. Now routed through the
                # NetBird BYOP reverse-proxy on heimdall instead, which
                # terminates real TLS and works from anywhere, not just
                # NetBird peers with split-DNS configured.
                hermes-agent = "https://hermes.thorsaga.net";
                # Same footgun as hermes-agent above: pocket-id only runs on
                # heimdall, which overrides its url to id.avgtechguy.com for
                # the NetBird OIDC failover rehearsal. odin never sets that
                # override, so hl.pocket-id.url falls back to the module
                # default (id.internalnetwork.party), a hostname with no
                # DNS record - Homepage's httpProxy widget then fails with
                # ENOTFOUND on every refresh.
                pocket-id = "https://id.avgtechguy.com";
              };
              serviceUrl = customUrls.${x} or "https://${hl.${x}.url}";
            in
            {
              "${hl.${x}.homepage.name}" = {
                icon = hl.${x}.homepage.icon;
                description = hl.${x}.homepage.description;
                href = serviceUrl;
                siteMonitor = serviceUrl; # This will now show the green status for the custom URL
              };
            };
          categoryServiceList =
            cat:
            lib.lists.forEach (lib.attrsets.mapAttrsToList (name: _value: name) (
              homepageServices "${cat}"
            )) serviceEntry;
          miscCategory = item: (lib.head (lib.attrValues item)).category;
          stripMiscCategory = item: lib.mapAttrs (_name: value: lib.removeAttrs value [ "category" ]) item;
          miscForCategory =
            cat: map stripMiscCategory (lib.filter (item: miscCategory item == cat) cfg.misc);
          miscOther = map stripMiscCategory (
            lib.filter (item: !(lib.elem (miscCategory item) homepageCategories)) cfg.misc
          );
        in
        lib.lists.forEach homepageCategories (cat: {
          "${cat}" =
            categoryServiceList cat
            ++ lib.optional (cat == "Arr") { Downloads = categoryServiceList "Downloads"; }
            ++ miscForCategory cat;
        })
        ++ lib.optional (miscOther != [ ]) { Misc = miscOther; }
        ++ [
          {
            Glances =
              let
                port = toString config.services.glances.port;
              in
              [
                {
                  Info = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "info";
                      chart = false;
                      version = 4;
                    };
                  };
                }
                {
                  "CPU Temp" = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "sensor:Package id 0";
                      chart = false;
                      version = 4;
                    };
                  };
                }
                {
                  Processes = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "process";
                      chart = false;
                      version = 4;
                    };
                  };
                }
                {
                  Network = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "network:enp1s0";
                      chart = false;
                      version = 4;
                    };
                  };
                }
              ];
          }
        ];
    };
    services.caddy.virtualHosts."root.${homelab.baseDomain}" = {
      useACMEHost = homelab.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8082 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
        }
      '';
    };
  };
} # reverse_proxy http://127.0.0.1:${toString config.services.${service}.listenPort} {
