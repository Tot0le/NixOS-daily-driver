{ config, pkgs, lib, ... }:

let
  # Source tree the serpantinum package is built from. It also carries the
  # compositors/ examples, which the package itself does not install.
  upstream = config.programs.serpantinum.package.src;

  # Shortcut catalog shared with the GNOME layer
  shortcutCatalog = import ../../conf/shortcuts.list.nix;

  # Catalog entries upstream already covers: volume and media keys go through
  # the shell so its on-screen display stays in sync. They stay in the catalog
  # for GNOME but are not pushed to Hyprland.
  coveredByUpstream = [ "volUp" "volDown" "mute" "play" "next" "prev" ];

  hyprlandShortcuts = removeAttrs (
    shortcutCatalog.commonApps
    // shortcutCatalog.terminalTools
    // shortcutCatalog.graphicTools
  ) coveredByUpstream;

  # Upstream shortcuts moved to another key. `from` must match the key string
  # upstream binds (case included); `to` also replaces whatever upstream binds
  # there. To see what changed upstream before updating, diff keybinds.lua.
  remaps = [
    # Clipboard history on Super+V. This also drops the volume popup that
    # upstream puts on that key, which is not used here.
    { from = "SUPER + C"; to = "SUPER + V"; cmd = "serpantinum msg toggle clipboard"; }
    # Frees Super+R
    { from = "SUPER + R"; to = "SUPER + SHIFT + R"; cmd = "serpantinum reload"; }
  ];

  # GNOME accelerator ("<Super><Shift>f", ", XF86AudioStop") to a Hyprland Lua
  # key string ("SUPER + SHIFT + F", "XF86AudioStop"). Single letters are
  # upper-cased because hl.unbind is case-sensitive and upstream binds "SUPER + F".
  toLuaKey = accel:
    let
      modTokens = [ "<Super>" "<Ctrl>" "<Shift>" "<Alt>" ];
      modNames = [ "SUPER" "CTRL" "SHIFT" "ALT" ];
      mods = lib.concatLists (lib.zipListsWith
        (token: name: lib.optional (lib.hasInfix token accel) name)
        modTokens modNames);
      rawKey = lib.removePrefix ", "
        (builtins.replaceStrings modTokens (map (_: "") modTokens) accel);
      key = if builtins.stringLength rawKey == 1 then lib.toUpper rawKey else rawKey;
    in lib.concatStringsSep " + " (mods ++ [ key ]);

  keyOf = data: toLuaKey (builtins.elemAt data 2);
  cmdOf = data: builtins.elemAt data 1;
  allKeys = (map (r: r.to) remaps) ++ lib.mapAttrsToList (_: keyOf) hyprlandShortcuts;

  # pcall: unbinding a key nothing is bound to must not abort the config
  remapBinds = lib.concatStringsSep "\n" (map (r: ''
    pcall(hl.unbind, ${builtins.toJSON r.from})
    pcall(hl.unbind, ${builtins.toJSON r.to})
    hl.bind(${builtins.toJSON r.to}, hl.dsp.exec_cmd(${builtins.toJSON r.cmd}))
  '') remaps);

  # Each catalog shortcut replaces any upstream bind on the same key
  catalogBinds = lib.concatStringsSep "\n" (lib.mapAttrsToList (_: data: ''
    pcall(hl.unbind, ${builtins.toJSON (keyOf data)})
    hl.bind(${builtins.toJSON (keyOf data)}, hl.dsp.exec_cmd(${builtins.toJSON (cmdOf data)}))
  '') hyprlandShortcuts);
in
{
  programs.serpantinum = {
    enable = true;
    # The Hyprland autostart launches the daemon; the default systemd unit is
    # tied to graphical-session.target and would also start in a GNOME session
    systemd.enable = false;
  };

  assertions = [
    {
      assertion = builtins.length allKeys == builtins.length (lib.unique allKeys);
      message = "Two shortcuts resolve to the same Hyprland key (remaps and shortcuts.list.nix).";
    }
  ];

  # Compositor modules (variables, env, autostart, monitors, settings, keybinds)
  # read straight from upstream and updated with `nix flake update serpantinum`
  xdg.configFile."hypr/config".source = "${upstream}/compositors/hyprland/config";

  # Upstream entry point, followed by this machine's overrides
  xdg.configFile."hypr/hyprland.lua".text =
    builtins.readFile "${upstream}/compositors/hyprland/hyprland.lua"
    + ''

      -- Machine overrides, placed after the upstream modules so they win.
      -- Upstream defaults to a US keyboard; this machine is AZERTY.
      hl.config({ input = { kb_layout = "fr" } })

      -- Upstream shortcuts moved to another key
      ${remapBinds}

      -- Shortcuts from the shared catalog
      ${catalogBinds}

      -- Workspaces by physical key code, so they work on AZERTY, where the digit
      -- row needs Shift. Bound straight to Hyprland instead of going through
      -- `serpantinum msg workspace`. Kept last and wrapped in pcall: a mistake
      -- here must not take the shortcuts above down with it.
      for i = 1, 10 do
        local code = "code:" .. (9 + i)
        local ws = tostring(i)
        pcall(hl.unbind, "SUPER + " .. (i % 10))
        pcall(hl.unbind, "SUPER + SHIFT + " .. (i % 10))
        pcall(function()
          hl.bind("SUPER + " .. code, hl.dsp.focus({ workspace = ws }))
          hl.bind("SUPER + SHIFT + " .. code, hl.dsp.window.move({ workspace = ws }))
        end)
      end
    '';

  # Tools called by the upstream autostart and keybindings, plus what the
  # catalog shortcuts and the shell UI need once the system module is gone
  home.packages = with pkgs; [
    cliphist                   # clipboard history
    easyeffects                # audio effects
    playerctl                  # media keys
    pamixer                    # volume entries of the shared catalog (GNOME)
    jq
    tree
    ripgrep
    fd
    nerd-fonts.iosevka         # shell UI icons, installed by the upstream system module
    nerd-fonts.jetbrains-mono  # same fonts the previous setup installed for the shell UI
  ];
}
