# QuickShell (QML) modular bar
Entry: `shell.qml` (top bar)

Colors and fonts imported from your Waybar `style.css` into `components/Theme.qml`.
Popups: Volume, Brightness, Calendar, Network (stub calls provided).

Place in `~/.config/quickshell/` and run:
  quickshell reload

Notes:
- The modules use simple commands via `Qt.openUrlExternally("bash -c '...'")` for scroll/click actions.
- To remove the Timer in Clock entirely, switch to a time signal from your environment or keep this 60s refresh.
- Hook Hyprland window/title/taskbar using your QuickShell's Hyprland QML plugin if available.
