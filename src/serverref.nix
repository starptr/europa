{ config, modulesPath, lib, pkgs, ... }:
  let
    generated-serverref-data-from-pulumi = builtins.fromJSON (builtins.readFile ./../generated-serverref.json);
  in
  {
    imports = lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix ++ [
      (modulesPath + "/virtualisation/digital-ocean-config.nix")
    ];

    nix = {
      settings.experimental-features = [ "nix-command" "flakes" ];
      settings.trusted-public-keys = [
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      settings.trusted-substituters = [
        "https://devenv.cachix.org"
        "https://nix-community.cachix.org"
      ];
    };

    system.stateVersion = "23.11"; # Do not change lightly!

    # Config from the base image
    swapDevices = [
      {
        device = "/swapfile";
        size = 3072;
      }
    ];

    fileSystems."/nix" = {
      device = "/dev/disk/by-id/scsi-0DO_Volume_${generated-serverref-data-from-pulumi.nix-store-volume}";
      neededForBoot = true;
      options = [ "noatime" ];
    };

    environment.defaultPackages = [
      pkgs.git
      pkgs.vim
      pkgs.htop
    ];

    users.mutableUsers = true;
    users.defaultUserShell = pkgs.bashInteractive;
    users.users = {
      yuto = {
        isNormalUser = true;
        shell = pkgs.bash;
        description = "Yuto";
        password = "";
        createHome = true;
        homeMode = "755";
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDLrT2/gQXhOz4E4xSphB8EXouild5qNOnZ6ZVXuTnf167z8xxSB10mxNey2gKDaIVig6I/tRFeYy6/N/QutbBlKI/+GNPjGCcVJI0hf7fTZGL4caTW8ggcXRz4LAsFp3JBf6Li0FVrGz5ojD0Etbl54BDn033q/tlVRhme5bXJ6s73yRg04kqdQsWVBRJwyzbUUmCQPrZd9i5Nh4QFVuhZljEyUWIStajE+c9v8OOiY1svv+XjKBjyWphP16HqgzvnEDf5+MQ5AUxE05IvJx43UY43CKTe3evzt4F/IqSdYwYGIQ55DaseRmf5zmHLU8MTTkksmOPQEzJL0nBzAmxyGV3PsMYPoIN+1/gJmxCO6ZaaCxYr9SFK/yoRW5e0PFX433xPhNsITBq7jUrVg6BQ/lr0ntRfvd7pRhFq8v02R3jWokL/99skxp1kjVF42bXEJXYPpHF3XAUhYscjOwmWj8dJgsIsSIKIjh7gRVYxQGrZQXOcJQjMytFgXy7fWHM= yuto@Yutos-MacBook-Pro.local" # Yuto's Sodium
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPtVvX9uhSWD1DPBIRqgkNzFXqjdqvWB/WtDy4seaiJl" # 1Password "ssh key - main"
        ];
      };
      awang = { isNormalUser = true; homeMode = "755"; };
      bigpapalikescheese = { isNormalUser = true; homeMode = "755"; };
      blizz = { isNormalUser = true; homeMode = "755"; };
      cookiedamonstuh = { isNormalUser = true; homeMode = "755"; };
      disguise = { isNormalUser = true; homeMode = "755"; };
      edawg = { isNormalUser = true; homeMode = "755"; };
      emerald = { isNormalUser = true; homeMode = "755"; };
      geb = { isNormalUser = true; homeMode = "755"; };
      jjonn = { isNormalUser = true; homeMode = "755"; };
      kale = { isNormalUser = true; homeMode = "755"; };
      nugnug = { isNormalUser = true; homeMode = "755"; };
      pteronatyl = { isNormalUser = true; homeMode = "755"; };
      uraniumra = { isNormalUser = true; homeMode = "755"; };
      starptr = { isNormalUser = true; homeMode = "755"; linger = true; openssh.authorizedKeys.keyFiles = [ ../keys/starptr/id_rsa-sodium.pub ]; };
      yart = { isNormalUser = true; homeMode = "755"; };
    };

    systemd.user.services.example-service = {
      enable = true;
      #after = [ "network.target" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.uutils-coreutils-noprefix}/bin/true";
        Type = "oneshot";
      };
    };

    # Let's Encrypt
    # see https://discourse.nixos.org/t/nixos-nginx-acme-ssl-certificates-for-multiple-domains/19608/3 for an example
    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "acme.management@yart.me";
        dnsProvider = "cloudflare";
      };
    };
    security.sudo.wheelNeedsPassword = false;

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];
      allowedUDPPorts = [ 443 ];
    };

    #services.dbus = {
    #  enable = true;
    #};
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        UsePAM = true;
      };
    };

    # Serverreff-specific config
    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."hello.serverref.andref.app" = {
        enableACME = true;
        addSSL = true;
        locations."/".extraConfig = ''
          default_type text/html;
          return 200 "<!DOCTYPE html><h1>Hello from serverref!</h1>\n";
        '';
      };
      virtualHosts."wiki.andref.app" = {
        enableACME = true;
        addSSL = true;
      };
      virtualHosts."andref.app" = {
        enableACME = true;
        forceSSL = true;
        root = ../build/andref-homepages/root;
      };
      virtualHosts."tilde.andref.app" = {
        enableACME = true;
        forceSSL = true;
        root = ../build/andref-homepages/tilde;
        locations."~ ^/~(.+?)(/.*)?$" = {
          alias = "/home/$1/public_html$2";
          index = "index.html index.htm";
          extraConfig = ''
            autoindex on;
          '';
        };
      };
    };
    systemd.services.nginx.serviceConfig.ProtectHome = false;

    services.dokuwiki = {
      webserver = "nginx";
      sites = {
        "wiki.andref.app" = {
          enable = true;
          settings = {
            #baseurl = "https://wiki.andref.app";
            title = "wikiref";
            useacl = true;
            superuser = "admin";
            useheading = true;
            userewrite = 1;
          };
        };
      };
    };

    # TODO: move to a normal user service under starptr
    systemd.services.fleeting = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "The fleeting discord bot";
      serviceConfig = {
        Type = "exec";
        User = "yuto";
        Restart = "on-failure";

        # Point to the fleeting binary
        WorkingDirectory = ''/home/yuto/src/fleeting'';
        ExecStart = ''/home/yuto/src/fleeting/target/debug/fleeting'';
      };
    };
  }