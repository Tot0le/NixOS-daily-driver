{ config, pkgs, lib, ... }:

let
  # Source tree the serpantinum package is built from. It also carries the
  # compositors/ examples, which the package itself does not install.
  upstream = config.programs.serpantinum.package.src;
  upstreamConfig = "${upstream}/compositors/hyprland/config";

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

  # Upstream shortcuts moved (new key) or disabled (null): see conf/hyprland-shortcuts.nix
  remaps = import ../../conf/hyprland-shortcuts.nix;
  movedRemaps = lib.filterAttrs (_: to: to != null) remaps;
  disabledKeys = lib.attrNames (lib.filterAttrs (_: to: to == null) remaps);

  # keybinds.lua writes a key either as `mainMod .. " + Q"` or as a plain string
  superPrefix = "SUPER + ";
  luaKeyForms = key:
    (lib.optional (lib.hasPrefix superPrefix key)
      ''mainMod .. " + ${lib.removePrefix superPrefix key}"'')
    ++ [ ''"${key}"'' ];

  upstreamKeybinds = builtins.readFile "${upstreamConfig}/keybinds.lua";

  isBoundUpstream = key:
    lib.any (form: lib.hasInfix form upstreamKeybinds) (luaKeyForms key);

  # Drop the whole bind line of every disabled shortcut
  keptLines = lib.filter
    (line: !(lib.hasPrefix "hl.bind(" line
      && lib.any (key: lib.any (form: lib.hasInfix form line) (luaKeyForms key)) disabledKeys))
    (lib.splitString "\n" upstreamKeybinds);

  # Rewrite the key of every moved shortcut. One single pass, so swapping two
  # keys is safe.
  keyRewrites = lib.concatLists (lib.mapAttrsToList (from: to:
    (lib.optional (lib.hasPrefix superPrefix from) {
      pattern = ''mainMod .. " + ${lib.removePrefix superPrefix from}"'';
      replacement =
        if lib.hasPrefix superPrefix to
        then ''mainMod .. " + ${lib.removePrefix superPrefix to}"''
        else ''"${to}"'';
    })
    ++ [ { pattern = ''"${from}"''; replacement = ''"${to}"''; } ]
  ) movedRemaps);

  patchedKeybinds = builtins.replaceStrings
    (map (r: r.pattern) keyRewrites)
    (map (r: r.replacement) keyRewrites)
    (lib.concatStringsSep "\n" keptLines);

  # Upstream configuration directory with only keybinds.lua replaced
  hyprConfig = pkgs.runCommand "serpantinum-hyprland-config" { } ''
    cp -r ${upstreamConfig} $out
    chmod -R u+w $out
    cp ${pkgs.writeText "keybinds.lua" patchedKeybinds} $out/keybinds.lua
  '';

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
  allKeys = (lib.attrValues movedRemaps) ++ lib.mapAttrsToList (_: keyOf) hyprlandShortcuts;

  # Each catalog shortcut replaces any upstream bind on the same key.
  # pcall: unbinding a key nothing is bound to must not abort the config.
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
      message = "Two shortcuts resolve to the same Hyprland key (conf/hyprland-shortcuts.nix and conf/shortcuts.list.nix).";
    }
    {
      assertion = lib.all isBoundUpstream (lib.attrNames remaps);
      message = "conf/hyprland-shortcuts.nix lists a key serpantinum no longer binds: it was renamed or removed upstream.";
    }
    {
      assertion = lib.all (to: (!(isBoundUpstream to)) || (remaps ? ${to})) (lib.attrValues movedRemaps);
      message = "conf/hyprland-shortcuts.nix moves a shortcut onto a key serpantinum already uses: move or disable that one too.";
    }
  ];

  # Compositor modules read from upstream, with the shortcut changes applied
  xdg.configFile."hypr/config".source = hyprConfig;

  # Upstream entry point, followed by this machine's overrides
  xdg.configFile."hypr/hyprland.lua".text =
    builtins.readFile "${upstream}/compositors/hyprland/hyprland.lua"
    + ''

      -- Machine overrides, placed after the upstream modules so they win.
      -- Upstream defaults to a US keyboard; this machine is AZERTY.
      hl.config({ input = { kb_layout = "fr" } })

      -- Shortcuts from the shared catalog
      ${catalogBinds}

      -- Workspaces by physical key code, so they work on AZERTY, where the digit
      -- row needs Shift. Bound straight to Hyprland instead of going through
      -- `serpantinum msg workspace`, which does nothing under a Lua config.
      -- Wrapped in pcall: a mistake here must not take the shortcuts above down.
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

      -- Per-user overrides: edit ~/.config/hypr/local.lua, then `hyprctl reload`
      require("local")
    '';

  # Each user gets an empty local.lua once; it is never overwritten afterwards
  home.activation.ensureHyprLocalLua = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ ! -e "$HOME/.config/hypr/local.lua" ]; then
      mkdir -p "$HOME/.config/hypr"
      printf '%s\n' '-- Personal Hyprland overrides, loaded last. Apply with: hyprctl reload' > "$HOME/.config/hypr/local.lua"
    fi
  '';

  # Tools called by the upstream autostart and keybindings, plus what the
  # catalog shortcuts and the shell UI need
  home.packages = with pkgs; [
    cliphist                   # clipboard history
    easyeffects                # audio effects
    playerctl                  # media keys
    pamixer                    # volume entries of the shared catalog (GNOME)
    nerd-fonts.iosevka         # shell UI icons
    nerd-fonts.jetbrains-mono  # same fonts the previous setup installed
    jq
    tree
    ripgrep
    fd
  ];
}
