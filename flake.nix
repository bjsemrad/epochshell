{
  description = "EpochShell: a Quickshell-based shell with a nix flake + HM module";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, quickshell, home-manager, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        inherit system;
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      # -----------------------
      # Packages
      # -----------------------
      packages = forAllSystems ({ system, pkgs }: let
        qs =
          quickshell.packages.${system}.default;

        epochshell = pkgs.writeShellScriptBin "epochshell" ''
          exec ${qs}/bin/quickshell "$@"
        '';
      in {
        quickshell = qs;
        epochshell = epochshell;
        default = epochshell;
      });

      apps = forAllSystems ({ system, ... }: {
        default = {
          type = "app";
          program = "${self.packages.${system}.epochshell}/bin/epochshell";
        };
      });

      # -----------------------
      # Home Manager module
      # -----------------------
      homeManagerModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.epochshell;
          epochPkg = self.packages.${pkgs.system}.epochshell;
          qsPkg = self.packages.${pkgs.system}.quickshell;
        in
        {
          options.programs.epochshell = {
            enable = lib.mkEnableOption "EpochShell (runs Quickshell)";

            # Where your config is installed under ~/.config/
            configDir = lib.mkOption {
              type = lib.types.str;
              default = "epochshell";
              description = "Directory under XDG config home containing the EpochShell config.";
            };

            autostart = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Start EpochShell (quickshell) via systemd --user.";
            };
          };

          config = lib.mkIf cfg.enable {
            # Install both:
            # - quickshell runtime (useful for debugging / direct calls)
            # - epochshell wrapper (the command you want to run)
            home.packages = [ qsPkg epochPkg ];

            # Put your repo's ./config into ~/.config/epochshell
            xdg.configFile."${cfg.configDir}".source = ./config;

            # Autostart service runs `epochshell` (which runs `quickshell`)
            systemd.user.services.epochshell = lib.mkIf cfg.autostart {
              Unit = {
                Description = "EpochShell (Quickshell)";
                After = [ "graphical-session.target" ];
              };
              Service = {
                ExecStart = "${epochPkg}/bin/epochshell";
                Restart = "on-failure";
              };
              Install = {
                WantedBy = [ "graphical-session.target" ];
              };
            };
          };
        };

      # Optional: a simple dev shell
      devShells = forAllSystems ({ pkgs, system }: {
        default = pkgs.mkShell {
          packages = [
            self.packages.${system}.epochshell
            self.packages.${system}.quickshell
            pkgs.git
          ];
        };
      });
    };
}
