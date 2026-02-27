{ pkgs, config, ... }:

{
  # Ensure the background binaries are available
  home.packages = with pkgs; [
    nixd
    nixpkgs-fmt
  ];

  programs.zed-editor = {
    enable = true;
    extensions = [ "nix" "toml" "elixir" "make" ];

    userSettings = {
      assistant = {
        enabled = true;
        version = "2";
        default_model = {
          provider = "zed.dev";
          model = "claude-3-5-sonnet-latest";
        };
      };

      hour_format = "hour12";
      auto_update = false;

      terminal = {
        alternate_scroll = "off";
        blinking = "off";
        copy_on_select = false;
        dock = "bottom";
        env = { TERM = "ghostty"; };
        font_family = "FiraCode Nerd Font";
        line_height = "comfortable";
        option_as_meta = false;
        button = false;
        shell = "system";
        toolbar = { title = true; };
        working_directory = "current_project_directory";
      };

      lsp = {
        rust-analyzer = {
          binary = { path_lookup = true; };
        };
        # Configuration for nixd
        nixd = {
          binary = { path = "${pkgs.nixd}/bin/nixd"; };
          settings = {
            nixpkgs = { expr = "import <nixpkgs> { }"; };
            formatting = { command = [ "nixpkgs-fmt" ]; };
            options = {
              nixos = {
                # Update 'mjolnir' to your hostname if different
                expr =
                  let
                    host =
                      let h = builtins.getEnv "HOSTNAME";
                      in if h != "" then h else builtins.getEnv "HOST";
                  in
                  "(builtins.getFlake \"/etc/nixos\").nixosConfigurations.${host}.options";
              };
            };
          };
        };
        elixir-ls = {
          binary = { path_lookup = true; };
          settings = { dialyzerEnabled = true; };
        };
      };

      languages = {
        "Nix" = {
          language_servers = [ "nixd" "!nil" ];
          format_on_save = {
            external = {
              command = "nixpkgs-fmt";
              arguments = [ ];
            };
          };
        };
        "Elixir" = {
          language_servers = [ "!lexical" "elixir-ls" "!next-ls" ];
          format_on_save = {
            external = {
              command = "mix";
              arguments = [ "format" "--stdin-filename" "{buffer_path}" "-" ];
            };
          };
        };
        "HEEX" = {
          language_servers = [ "!lexical" "elixir-ls" "!next-ls" ];
          format_on_save = {
            external = {
              command = "mix";
              arguments = [ "format" "--stdin-filename" "{buffer_path}" "-" ];
            };
          };
        };
      };

      vim_mode = false;
      load_direnv = "shell_hook";
      base_keymap = "VSCode";

      theme = {
        mode = "system";
        light = "One Light";
        dark = "One Dark";
      };

      show_whitespaces = "all";
      ui_font_size = 16;
      buffer_font_size = 16;
    };
  };
}
