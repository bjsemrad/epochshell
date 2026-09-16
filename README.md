# Epoch Shell

Epoch Shell is a personal desktop shell built with [Quickshell](https://quickshell.org/) for a Wayland desktop. It provides the bar, popups, notifications, OSDs, launcher, and polkit prompt used by the session.

The project is intentionally pragmatic: it keeps only the pieces used by the current configuration and favors a small, understandable QML codebase over a generalized shell framework.

## Features

- Top bar with workspace indicators, launcher, media indicator, clock, weather, network, Bluetooth, volume, Tailscale, LocalSend, battery, notifications, system tray items, and system menu.
- LocalSend panel for discovering nearby devices and sending them a file, backed by EpochOxide.
- Capture panel in the bar drawer for region, window, and monitor screenshots and OCR text capture,
  with clipboard, save, and pointer switches, backed by EpochOxide.
- Record panel beside it for starting and stopping screen recordings. Its icon stands down while a
  recording runs, replaced by the indicator below, so only one thing on the bar is about recording
  at a time.
- Night mode toggle in the system menu, with a bar indicator while the screen is warmed.
- Nix panel showing which flake inputs can be updated, with a check button, an update action, and
  a rebuild action per host -- all of which open a terminal rather than changing anything silently.
  Its indicator sits with the alerts, so waiting updates show with the drawer shut.
- Recording indicator next to the drawer arrow: a pulsing dot and elapsed time while a recording
  runs, wherever it was started from, and a click to stop it. It shares that row with the Tailscale
  and LocalSend alerts, and several can show at once.
- Custom launcher backed by `epochoxide` for applications, files, clipboard, windows, and calculator results.
- Notification daemon UI with notification history and do-not-disturb support, including the
  screenshot notifications `epochctl capture screenshot` produces, thumbnail and all.
- Battery panel showing the CPU power profile, governor, energy preference, turbo state, which
  daemon is managing them, battery wear and cycle count, and a stay-awake switch.
- Keyboard backlight OSD alongside the volume, media, and screen brightness ones.
- Sound, media, and brightness OSDs.
- Network, Bluetooth, audio, battery, weather, calendar, media, notification, and system popups.
- Built-in polkit authentication agent with password and fingerprint-aware UI.
- Thirty-one named themes, with a live picker in the system menu that previews a palette on hover, and
  `epochctl theme set` for keybindings and scripts.
- Optional external config override file at `~/.config/epochshell/config.toml`.

## Layout

```text
quickshell/
  shell.qml                  # Shell root
  Bar.qml                    # Top bar
  Polkit.qml                 # Polkit authentication prompt
  Notifications.qml          # Notification windows
  SoundOSD.qml               # Volume OSD
  MediaOSD.qml               # Media OSD
  BrightnessOSD.qml          # Brightness OSD
  commonwidgets/             # Shared UI building blocks
  modules/                   # Bar modules and launcher
  popups/                    # Popup panels
  services/                  # QML singletons and backend integrations
  theme/Config.qml           # Defaults, theme selection, and optional TOML overrides
  theme/themes/*.toml        # Shipped palettes: dark and its accent variants, light, and more
```

## Running Locally

Run the repo version directly during development:

```bash
quickshell -p /home/brian/projects/EpochShell/quickshell -vv
```

If the installed system service is already running, stop it first to avoid duplicate notification and polkit registration:

```bash
systemctl --user stop epochshell.service
quickshell -p /home/brian/projects/EpochShell/quickshell -vv
```

When finished:

```bash
Ctrl-C
systemctl --user start epochshell.service
```

To reduce Qt font database noise during development:

```bash
quickshell -p /home/brian/projects/EpochShell/quickshell -vv --log-rules 'qt.text.font.db=false'
```

## Launcher

The launcher is implemented in `quickshell/modules/LauncherOverlay.qml` and uses `quickshell/services/LauncherService.qml` to query EpochOxide over `$XDG_RUNTIME_DIR/epochoxide.sock`.

Open/toggle is wired through the launcher icon on the bar and the launcher IPC target:

```bash
quickshell ipc call launcher toggle
```

Provider prefixes come from EpochOxide itself: the launcher reads the `providers` response and
routes on the `prefixes` each provider reports (configured under `[query_prefixes]` in the
EpochOxide config), so the shell never hardcodes them. With the EpochOxide defaults that is:

| Prefix | Provider |
|--------|----------|
| `/` | Files |
| `>` | Runner |
| `#` | Clipboard |
| `@` | Windows |
| `=` | Calculator |

Each custom menu in EpochOxide's `menus_dir` is a provider of its own, named after the menu, so it
takes a prefix the same way and is jumped straight into rather than drilled down to. Giving the
keybinds menu `?` is a `"?" = "keybinds"` line in `[query_prefixes]`.

Two prefixes are the shell's own, not the backend's:

| Prefix | Meaning |
|--------|---------|
| `*` | All available providers |
| `;` | Provider picker (lists every live provider with its prefix) |

Typing a math expression can route to the calculator provider automatically when `calc` is available.

The launcher IPC can jump straight to any provider, which is how the compositor binds open a menu:

```bash
qs ipc -p ~/.config/epochshell call launcher openProvider keybinds
qs ipc -p ~/.config/epochshell call launcher openKeybinds   # the same, kept for existing binds
```

Bitwarden/rbw support is intentionally not included in the current config.

### Custom menus

A menu is a TOML file in EpochOxide's `menus_dir` (`~/.config/epochoxide/menus`), and each one
becomes a provider named after the menu — searched by prefix, listed in the picker under its own
name and icon. Entries either run a command on Enter or hand back text to copy, and `command`
replaces the entry list with a generator that produces them live. See EpochOxide's README for the
file format; the shell reads whatever the backend reports.

An `icon` is either a freedesktop icon name resolved through the icon theme (`input-keyboard`) or
a Nerd Font glyph drawn in the theme font (`icon = "󰌌"`), at menu level, entry level, or both —
a menu's icon is the fallback for entries that name none. Anything short and outside the ASCII
range is treated as a glyph, so icon names are never mistaken for one.

Menus are deployed the same way as everything else here — from the dotfiles repo, not by hand.
`users/brian/modules/epochshell/` holds the keybinds menu: `menus/keybinds.sh` reads the running
compositor's binds (niri's `config.kdl`, else `hyprctl binds` cross-referenced against
`hyprland.lua` so a Lua config's binds still get readable names), wrapped in a derivation that
carries its own `jq`/`python3`, and a `home.file` entry writes the `keybinds.toml` that points at
it. The shortcut is one line in the EpochOxide settings:

```nix
programs.epochshell.epochoxide.settings.query_prefixes = {
  "?" = "keybinds";
};
```

Home Manager installs and starts EpochOxide by default when EpochShell is enabled. The backend can be configured through `programs.epochshell.epochoxide`:

```nix
programs.epochshell = {
  enable = true;

  epochoxide = {
    enable = true;
    enableService = true;
    socket = "%t/epochoxide.sock";
    runtimePackages = with pkgs; [ wl-clipboard xclip xdg-utils wmctrl tesseract libqalculate imagemagick librsvg fd ];
    settings = {
      file_roots = [ "~" ];
      persistent_index = true;
      provider_enabled.files = true;
      provider_enabled.clipboard = true;
    };
  };
};
```

Launcher sizing:

- Normal mode: fixed launcher panel size from the QML defaults.
- Files mode (`/`): `60%` screen width by `60%` screen height.
- Clipboard mode (`:`): `60%` screen width by `60%` screen height.
- Preview pane width scales relative to the current panel width.

## Polkit

`quickshell/Polkit.qml` registers a Quickshell polkit agent at:

```text
/org/epochshell/PolkitAgent
```

Only one polkit agent can be active for a session. If local development does not show the prompt, another agent is probably already registered. Check the logs for:

```text
epochshell polkit agent registered
```

Test a prompt with:

```bash
pkexec ls /root
```

The prompt supports password auth and a fingerprint waiting state when `pam_fprintd.so` is present in `/etc/pam.d/polkit-1`. It also checks laptop lid state and falls back to password when the reader is physically unavailable.

## Theming

The palette is a named theme file. Two ship with the shell, in `quickshell/theme/themes/`:

| Theme              | What it is |
| ------------------ | ---------- |
| `dark`             | One Dark's palette on a near-black ground. Also mirrored as the built-in fallback in `theme/Config.qml`, so a shell that cannot find any theme file still looks right. |
| `dark-*`           | `dark` in each of One Dark's other accents: `red`, `green`, `purple`, `orange`, `yellow`, `cyan`. One line each -- see **Extending a theme** below. |
| `one-dark`         | The parent `dark` is derived from, on its native `#282c34`. |
| `ayu-dark`         | The closest thing to `dark` in the wild -- same near-black ground, vivid accent. |
| `material-ocean`   | The softest text here; deep blue-black. |
| `flexoki-dark`     | `dark`'s darkness at a warm-neutral temperature. |
| `catppuccin-mocha` | Violet-tinted surfaces, close together. |
| `tokyo-night`      | Deep blue-black, bright blue accent. |
| `kanagawa`         | Ink-dark and warm; the deepest black of the set. |
| `gruvbox`          | Warm retro, on bg0. The one that proves nothing assumes a cool-toned ground. |
| `gruvbox-hard`     | The same palette on bg0_h -- gruvbox's hard-contrast ground, and nothing else. |
| `everforest`       | Green-grey and warm, green accent. |
| `nord`             | Muted arctic blue-greys; the narrowest surface range here. |
| `rose-pine`        | Soft and desaturated, iris accent. |
| `dracula`          | High-saturation slate, purple accent. |
| `monokai`          | The loudest set here: near-white text, high chroma, warm olive ground. |
| `solarized-dark`   | Teal surfaces rather than grey; the sternest test of a role-based palette. |
| `light`            | Plain white ground, for checking a module reads the surface roles rather than assuming a dark one. |
| `catppuccin-latte` | Warm light, low-contrast. |
| `solarized-light`  | Cream light, sharing solarized-dark's named colours exactly. |
| `ghost-pastel`     | Lavender and rose pastels on a faintly pink near-black, with pale text. |
| `batou`            | Warm greys, near-monochrome. Four colours in it carry any real chroma. |
| `last-horizon`     | Dusty rose and cool greys, desaturated throughout. |
| `solitude`         | Monochrome blue-greys with one saturated colour, kept for errors. |
| `periphery`        | Cold teals on near-black green, amber reserved for warnings. |
| `dark-deep`        | **The default.** `dark` on a deeper ground -- two lines, via `extends`. The built-in fallback is still `dark`, so a shell that finds no theme file at all lands one shade lighter rather than nowhere. |

Every one is checked for contrast: text and accent against the ground, and a visible step between
the ground and the hover surface. Several needed adjusting off their canonical values to get
there -- usually a comment colour too dark to serve as hint text -- and each says which in its own
file.

Switch from the **system menu**: the Theme row at the bottom of the settings group opens a picker
beside the menu, one row per theme found on disk with a swatch strip of its actual colours.
**Hovering a row wears the theme** -- the whole shell repaints so you can see it rather than guess
from a name -- and only a click keeps it. Moving away puts back what you had. The row hides itself
when there is only one theme to choose from.

The same switch from a terminal, a keybinding or a script, which keeps the choice across restarts:

```sh
epochctl theme list          # every theme that can be selected, and which is current
epochctl theme set light     # switch, and remember
epochctl theme get           # what is in force, and the file it came from
epochctl theme reset         # forget the pick, back to the configured default
```

The launcher reaches the same commands through the `themes` menu (see `epochoxide/examples/menus/themes.toml`).

### Extending a theme

A theme can build on another with `extends`, which is how the `dark-*` family stays one palette:

```toml
# dark-red.toml, in full
extends = "dark"

accent = "#e55561"
```

The parent is applied first, then the child's own keys on top, so a colour fixed in `dark` is fixed
in every variant. Inheritance is exactly one level deep -- a parent's own `extends` is ignored,
which means there is no cycle to worry about. A theme naming itself is ignored too.

The picker resolves this as well: a variant's swatch is drawn from the palette it inherits, not
from the two lines in its own file.

### Writing a theme

A theme is the same flat key/value format as `config.toml`, so it can set any key -- colours,
but also fonts and sizes if a theme wants a different feel. Copy one of the shipped files to
`~/.local/share/epochshell/themes/<name>.toml` and edit it; a user theme shadows a shipped one of
the same name, so `light.toml` there replaces the one below.

Precedence, lowest first:

1. Built-in defaults in `theme/Config.qml`
2. The theme file
3. `~/.config/epochshell/config.toml`

So a key set in `config.toml` holds whatever theme is selected, which is what you want for a
personal tweak and not what you want for a whole palette.

### Where things live

Themes and the selection are deliberately **not** kept beside `config.toml`. The flake installs the
whole shell tree at `~/.config/epochshell`, which on a home-manager machine makes that directory a
read-only symlink into the nix store -- nothing can be written there, and nothing written survives a
rebuild. So:

| What | Where |
| ---- | ----- |
| Shipped themes | `<shell root>/theme/themes/*.toml` |
| Your themes | `~/.local/share/epochshell/themes/*.toml` |
| The selected theme | `~/.local/state/epochshell/theme` |
| Key overrides | `~/.config/epochshell/config.toml` (see the caveat below) |

Both the theme files and the selection are watched, so a switch or an edit shows up without a
reload, and a second shell instance follows along.

`config.toml` can also name a starting theme, for a machine where that file is generated rather
than edited:

```toml
theme = "light"
```

A live `epochctl theme set` beats it; `epochctl theme reset` gives it back.

> **Caveat on `config.toml`:** on a home-manager install this file sits inside that read-only
> store symlink and so cannot exist at all. Overriding individual keys there is only available on
> an install that puts the shell somewhere other than `~/.config/epochshell`. Themes and theme
> selection work either way, which is why they live elsewhere.

## Wallpaper

A full-screen picker over whatever images are on disk. Reach it from the **Wallpaper row in the
system menu**, with `epochctl wallpaper toggle`, or bind it:

```lua
hl.bind("SUPER + SHIFT + B", exec("epochctl wallpaper toggle"))
```

Arrow keys or hjkl to browse, Enter to keep, Escape to put back what was there. **Moving the
selection applies the wallpaper immediately** -- switching is a single call and the thing being
chosen is the whole screen, so there is no preview smaller or more honest than the real one.

Without opening anything:

```sh
epochctl wallpaper list        # every image found, current marked with *
epochctl wallpaper set <path>
epochctl wallpaper next        # cycle, for a keybinding
epochctl wallpaper refresh     # after adding images
```

### Where it looks

Set `wallpaper_dirs` in EpochOxide's `config.toml`. The default is:

```toml
wallpaper_dirs = [
  "~/.config/hypr",
  "~/Pictures/Wallpapers",
  "~/Wallpapers",
  "~/.local/share/wallpapers",
]
```

`~` is expanded, each directory is searched two levels deep for jpg, jpeg, png and webp, and one
that does not exist is skipped without complaint -- so dropping images into any of them just works.

The search follows symlinks, without which a home-manager wallpaper directory looks empty:
everything in it is a link into the nix store.

`~/Pictures` itself is deliberately not in the list. The scan goes two levels deep, so it would pull
in `~/Pictures/Screenshots` and bury the wallpapers under every screenshot ever taken.

### How it applies

Through `hyprctl hyprpaper wallpaper ",<path>"`, which switches with no reload. Two things about
hyprpaper shape this:

- Its `listactive` reports what was loaded at startup and does **not** follow a live switch, so it
  cannot answer "what is set now". The shell remembers instead.
- Its config lives in `~/.config/hypr`, which on a home-manager machine is a read-only symlink into
  the nix store, so the choice cannot be written back there.

So the choice is kept in `~/.local/state/epochshell/wallpaper` and re-applied at startup. That is
what makes a switch outlive a reboot; without it hyprpaper would start from its own config again.

Paths are used exactly as found -- `~/.config/hypr/foo.jpg`, not the `/nix/store` path it resolves
to. hyprpaper matches on the path it was given.

## Configuration

Epoch Shell has built-in defaults in `quickshell/theme/Config.qml`. You can override any supported value with:

```text
~/.config/epochshell/config.toml
```

The file is optional. If it does not exist, defaults are used. If it exists, it is treated as a partial override: include only the keys you want to change.

The file is watched by Quickshell, so changes are reloaded at runtime.

Example:

```toml
accent = "#ff00aa"
background = "#0e1013"
fontFamily = "JetBrainsMono Nerd Font Propo"
fontSizeLarge = 22
barHeight = 44
workspaceStripMaxWidthRatio = 0.35
panelAnimationsEnabled = true
```

The parser supports flat TOML-style key/value lines:

```toml
key = "string"
key = 123
key = 0.45
key = true
```

Section headers are ignored, so grouped files like this are also accepted:

```toml
[theme]
accent = "#4fa6ed"
barHeight = 40
```

Unknown keys are ignored with a warning.

### Color Keys

```toml
accent = "#4fa6ed"
accentLightShade = "#1a4fa6ed"
inactive = "#bfa0a8b7"
active = "#a0a8b7"
activeSelection = "#282c34"
background = "#0e1013"
surface = "#1f2329"
surfaceVariant = "#323641"
surfaceContainer = "#1f2329"
surfaceContainerHigh = "#282c34"
surfaceContainerHighest = "#30363f"
surfaceText = "#a0a8b7"
outline = "#8c9199"
purple = "#bf68d9"
green = "#8ebd6b"
orange = "#cc9057"
blue = "#4fa6ed"
yellow = "#e2b86b"
cyan = "#48b0bd"
red = "#e55561"
bg_blue = "#61afef"
bg_yellow = "#e8c88c"
```

Derived colors such as `accentLightShade`, `inactive`, `active`, and `activeSelection` update automatically from their source colors unless explicitly overridden.

### Opacity

```toml
barOpacity = 1.0      # how solid the bar is, 0 fully see-through to 1 solid
popupOpacity = 1.0    # the same for every panel, OSD and overlay
```

Both ship solid: translucency is a taste rather than an improvement, so the shell looks the way it
always has until you ask otherwise.

The **Themes panel** carries a slider for each, which is the easy way to ask. Moving one applies it
live and writes nothing; letting go writes it to `~/.local/state/epochshell/settings.toml`. That
matters on a home-manager install, where `config.toml` cannot exist -- the settings file is
writable and wins over both the theme and `config.toml`.

The percentage counts the same way the key does: **100% is solid**, lower lets the wallpaper
through. Both apply the theme's `background` at that alpha, so a theme that changes the ground
changes these with it, and a theme may set either key itself.

`popupOpacity` covers every floating surface: bar panels, the launcher, notification cards, the
polkit prompt and all four OSDs. Containers drawn *inside* a panel paint no ground of their own,
so they show the card's rather than stacking a second layer of translucency on it.

Turning the bar down works best with a compositor blur behind it. On Hyprland:

```lua
hl.layer_rule({
  name = "epochshell-blur",
  match = { namespace = "^(quickshell)$" },
  blur = true,
})
```

### Font Keys

```toml
fontFamily = "JetBrainsMono Nerd Font Propo"
fontSizeNormal = 14
fontSizeMedium = 16
fontSizeLarge = 18
fontSizeXLarge = 24
fontSizeSubtext = 11
```

### Bar Keys

```toml
barHeight = 40
barIconSize = 18
barClockSize = 11
barWeatherSize = 14
barModuleSpacing = 10
barGroupIconSpacing = 20
barIconTextSpacing = 5
barModuleHorizontalPadding = 14
barModuleVerticalPadding = 10
workspaceIcons = true
workspaceStripMaxWidthRatio = 0.45
```

Derived bar values such as `barClockSize`, `barWeatherSize`, `barGroupIconSpacing`, `barModuleHorizontalPadding`, and `barModuleVerticalPadding` update automatically unless explicitly overridden.

### Popup And Card Keys

```toml
popupPadding = 10
popupRadius = 10
popupLayoutSpacing = 8
cardRadius = 10
cardHeight = 50
cardMargin = 14
cardSpacing = 10
selectedBorderWidth = 1
networkPopupWidth = 400
tailscalePopupWidth = 600
bluetoothPopupWidth = 400
audioPopupWidth = 550
systemTrayPopupWidth = 300
systemPopupWidth = 300
batteryPopupWidth = 250
musicPlayerWidth = 600
controlCenterPopupWidth = 700
```

### Layout And Misc Keys

```toml
widthPaddingLarge = 20
widthPaddingSmall = 14
heightPaddingSmall = 5
layoutMarginSmall = 5
layoutSpacingLarge = 20
layoutSpacingSmall = 20
roundRadius = 20
cornerRadius = 18
connectedIconSize = 40
headerSize = 40
panelBottomMargin = 5
panelBottomMarginMedium = 15
statMargin = 12
tailscalePeersFontSize = 14
panelAnimationsEnabled = false
hideInactiveWorkspaces = true
```

### Switch Keys

```toml
switchHeight = 42
switchWidth = 24
switchKnobSize = 20
switchKnobRadius = 10
```

### System Action Keys

```toml
settingsHeaderHeight = 30
settingsHeaderSpacing = 10
systemActionSize = 40
systemActionRadius = 10
systemActionMargin = 30
systemActionSpacing = 10
```

### Volume Slider Keys

```toml
volumeSliderSize = 40
volumeSliderRadius = 20
volumeSliderMargin = 30
volumeSliderSpacing = 10
```

## Nix Updates

The Home Manager module carries the flake watcher's settings, which it passes to EpochOxide:

```nix
programs.epochshell.nixUpdates = {
  enable = true;
  flake = "~/nixconfig";
  checkIntervalMinutes = 60;
  updateCommand = "nixupdate";          # runs through your login shell, so aliases work
  hosts = [
    { name = "thor"; rebuild = "nixswitch"; }
  ];
};
```

Checking never writes to the flake. `updateCommand` and each host's `rebuild` run in a terminal, in
the flake's directory, through your login shell interactively -- so a shell alias is a valid
command here -- and the terminal stays open when the command finishes so its output survives.

Hosts you do not list are read from the flake's `nixosConfigurations` and fall back to
`rebuildCommand` with `%HOST%` substituted; with no `rebuildCommand` they are shown without a
rebuild action rather than with one that cannot work.

## Dependencies

Epoch Shell expects these tools/services to be available in the session:

- `quickshell`
- `epochoxide` for launcher results, activation, Tailscale state/actions, LocalSend
  discovery/transfers, and screen capture
- `grim`, `slurp`, and `libnotify` for screenshots: EpochOxide takes the shot and announces it with
  `notify-send`, which this shell answers as the session's notification server. The Home Manager
  module installs all three.
- `tesseract` for the capture panel's OCR row; the panel hides it when tesseract is missing.
- `wf-recorder` for the record panel and its bar indicator, dimmed and disabled the same way.
- `nix` and a terminal for the Nix panel's check, update, and rebuild actions.
- `hyprlock` for the lock action
- `wpctl`/PipeWire stack for audio controls
- `networkmanager` stack for network controls
- `bluetoothctl`/BlueZ stack for Bluetooth controls
- `tailscale` for EpochOxide's Tailscale backend
- LocalSend needs no local app: EpochOxide speaks the protocol itself, so the panel finds devices
  whether or not the desktop app is running here
- `pkexec`/polkit for privileged auth prompts
- Optional `pam_fprintd.so` configuration for fingerprint auth

Some modules are compositor-aware. Hyprland and Niri support are represented by compositor services and workspace modules.

## Development Notes

- The active shell root is `quickshell/shell.qml`.
- Theme and sizing defaults live in `quickshell/theme/Config.qml`; palettes live in `quickshell/theme/themes/`.
- QML services are registered in `quickshell/services/qmldir`.
- The current codebase intentionally omits older grouped bar, overview, Nix update, and Bitwarden/rbw paths.
- Live installed config may be generated or read-only depending on the system setup; for development, run directly with `quickshell -p` from this repo.
