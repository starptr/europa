{
  inputs = {
    nixpkgs-tilderef.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
    };

    sops-nix.url = "github:Mic92/sops-nix";

    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";

    cursor-server = {
      url = "github:strickczq/nixos-cursor-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };
  outputs =
    {
      self,
      nixpkgs-tilderef,
      flake-utils,
      deploy-rs,
      nixpkgs,
      devenv,
      systems,
      sops-nix,
      cursor-server,
    }@inputs:
    let
      generated-serverref-data-from-pulumi = builtins.fromJSON (builtins.readFile ./generated-serverref.json);
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      devShells = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pkgs-tilderef = nixpkgs-tilderef.legacyPackages.${system};
        in
        {
          simple-deploy-rs = pkgs-tilderef.mkShell { buildInputs = [ pkgs-tilderef.deploy-rs ]; };
          # INFO: Totally broken. Devenv somehow breaks deploy-rs in impure devshells
          #using-devenv = devenv.lib.mkShell {
          #  inherit inputs pkgs;
          #  modules = [
          #    {
          #      # https://devenv.sh/reference/options/
          #      packages = [
          #        pkgs.hello
          #        pkgs.deploy-rs
          #      ];

          #      enterShell = ''
          #        hello
          #      '';

          #      processes.hello.exec = "hello";
          #    }
          #  ];
          #};
          default = self.devShells.${system}.simple-deploy-rs;
        }
      );
      # deploy-rs
      nixosConfigurations.serverref = nixpkgs-tilderef.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ 
          cursor-server.nixosModules.default
          ./src/serverref.nix
        ];
      };
      deploy.nodes.serverref = {
        hostname = generated-serverref-data-from-pulumi.ipAddress;
        profilesOrder = [ "system" ];
        profiles.system = {
          user = "root";
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.serverref;
          remoteBuild = true;
        };
      };

      formatter = forEachSystem (
        system:
        let
          pkgs = import nixpkgs-tilderef { inherit system; };
        in
        pkgs.nixfmt-rfc-style
      );

      # This is highly advised, and will prevent many possible mistakes
      # Disabled to avoid remote builder
      #checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
