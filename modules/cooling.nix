# /etc/nixos/modules/cooling.nix
{ pkgs, lib, userList, config, ... }:
let
  # Gates the HP Victus-specific fan curve below. Other machines simply use a
  # different hostname in their local.nix and get the stock nbfc-linux package.
  isVictusLaptop = config.networking.hostName == "nixos-victus";
  
  # Custom nbfc-linux build with sysconfdir set to /etc and our fan curve
  # bundled in. Only used on this laptop; other hosts get the stock package.
  nbfc-linux-victus = pkgs.nbfc-linux.overrideAttrs (old: {
    version = "0.4.1";
    src = pkgs.fetchFromGitHub {
      owner = "nbfc-linux";
      repo = "nbfc-linux";
      rev = "0.4.1";
      hash = "sha256-4geSne23Jw7LSl7xtP3Fff4VHAZwENJp+XxxGRUPHKw=";
    };
    buildFlags = (old.buildFlags or []) ++ [ "sysconfdir=/etc" ];
    postInstall = (old.postInstall or "") + ''
      install -Dm644 ${../conf/nbfc/hp-victus-custom.json} "$out/share/nbfc/configs/HP Victus 15-fb0xxx Custom.json"
    '';
  });

  nbfcPkg = if isVictusLaptop then nbfc-linux-victus else pkgs.nbfc-linux;

  # Absolute paths, required for the sudo rules below to match exactly
  nbfcCmd = "${nbfcPkg}/bin/nbfc";
  systemctlCmd = "/run/current-system/sw/bin/systemctl";

  # Generic fan control script, works on any host with nbfc installed
  fanScript = pkgs.writeShellScriptBin "fan_control.sh" ''
    #!/bin/bash
    declare action="$1"
    declare param="$2"
    declare -i HARD_LIMIT=100
    declare STATE_FILE="/tmp/fan_speed_memory_$(whoami)"
    declare -i step=''${param:-2}
    if ! systemctl is-active --quiet nbfc_service
    then
        sudo ${systemctlCmd} restart nbfc_service
        sleep 2
    fi
    declare -i current_speed
    declare -i new_speed
    if [ -f "$STATE_FILE" ]
    then
        current_speed=$(cat "$STATE_FILE")
    else
        current_speed=$(sudo ${nbfcCmd} status | grep -m1 "Target" | sed 's/.*Target: \([0-9]*\).*/\1/')
        if [ -z "$current_speed" ]
        then
            current_speed=20
        fi
    fi
    if [ "$action" == "auto" ]
    then
        sudo ${nbfcCmd} set -a
        rm -f "$STATE_FILE"
    elif [ "$action" == "set" ]
    then
        declare -i target=''${param:-100}
        if [ $target -gt $HARD_LIMIT ]
        then
            target=$HARD_LIMIT
        fi
        if [ $target -lt 0 ]
        then
            target=0
        fi
        sudo ${nbfcCmd} set -s $target
        echo "$target" > "$STATE_FILE"
    elif [ "$action" == "plus" ]
    then
        if [ $current_speed -lt 30 ]
        then
            new_speed=30
        else
            new_speed=$((current_speed + step))
        fi
        if [ $new_speed -gt $HARD_LIMIT ]
        then
            new_speed=$HARD_LIMIT
        fi
        sudo ${nbfcCmd} set -s $new_speed
        echo "$new_speed" > "$STATE_FILE"
    elif [ "$action" == "minus" ]
    then
        new_speed=$((current_speed - step))
        if [ $new_speed -lt 0 ]
        then
            new_speed=0
        fi
        sudo ${nbfcCmd} set -s $new_speed
        echo "$new_speed" > "$STATE_FILE"
    fi
  '';
in
{
  # Installed and active on every host, regardless of model
  environment.systemPackages = [
    fanScript
    nbfcPkg
  ];
  systemd.packages = [ nbfcPkg ];
  systemd.services.nbfc_service.wantedBy = [ "multi-user.target" ];
  systemd.services.nbfc_service.path = [ nbfcPkg pkgs.kmod ];
  systemd.services.nbfc_service.after = [ "systemd-udev-settle.service" ];
  systemd.services.nbfc_service.wants = [ "systemd-udev-settle.service" ];

  # Host-specific: wait for the integrated AMD GPU sensor before starting.
  # Irrelevant on hosts without that sensor.
  systemd.services.nbfc_service.serviceConfig.ExecStartPre = lib.optionals isVictusLaptop [
    "${pkgs.bash}/bin/bash -c 'for i in $(seq 1 30); do grep -l amdgpu /sys/class/hwmon/hwmon*/name 2>/dev/null && exit 0; sleep 1; done; exit 1'"
  ];

  # Force auto mode on boot, in case a manual speed was left set previously
  systemd.services.nbfc-auto = {
    description = "Set NBFC fan control to auto mode at boot";
    after = [ "nbfc_service.service" ];
    requires = [ "nbfc_service.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ nbfcPkg ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
      ExecStart = "${nbfcCmd} set -a";
    };
  };

  # Grant each user passwordless access to fan control commands
  security.sudo.extraRules = builtins.map (user: {
    users = [ user ];
    commands = [
      {
        command = "/run/current-system/sw/bin/systemctl restart nbfc_service";
        options = [ "NOPASSWD" ];
      }
      {
        command = "${nbfcCmd}";
        options = [ "NOPASSWD" ];
      }
    ];
  }) userList;
}
