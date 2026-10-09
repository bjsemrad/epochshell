//@ pragma Env QT_FFMPEG_DECODING_HW_DEVICE_TYPES=vaapi
//@ pragma Env QT_FFMPEG_ENCODING_HW_DEVICE_TYPES=vaapi
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1
//@ pragma UseQApplication
//@ pragma IconTheme kora

import Quickshell
import Quickshell.Wayland
import qs.modules
import qs.modules.lock
import qs.modules.idle

ShellRoot {
    // First, so the wallpaper is up as early as the shell can manage. It draws only when EpochOxide
    // says the shell is the wallpaper backend; under hyprpaper it is an empty scope.
    WallpaperBackground {}

    Bar {}
    Notifications {}
    SoundOSD {}
    MediaOSD {}
    BrightnessOSD {}
    KeyboardBacklightOSD {}
    Polkit {}

    // One launcher for the session, not one per bar. Bar.qml builds its contents under
    // Variants { model: Quickshell.screens }, so the overlay used to be duplicated per screen.
    LauncherOverlay {}

    // Also one per session rather than one per screen: it covers every output and applies to all
    // of them at once.
    WallpaperOverlay {}

    // And the theme switcher, likewise one for the session.
    ThemeOverlay {}
    SettingsOverlay {}

    // The session lock. Last, so nothing declared after it can end up drawn above it -- though the
    // compositor puts lock surfaces above everything regardless.
    LockScreen {}

    // Lock, screen off and suspend on idle, and locking for logind and before sleep. Inert unless
    // ~/.config/epochshell-idle.json exists (programs.epochshell.idle in home-manager).
    Idle {}

    Ipc {}
}
