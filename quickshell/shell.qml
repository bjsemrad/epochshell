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
    WallpaperBackground {}

    Bar {}
    Notifications {}
    SoundOSD {}
    MediaOSD {}
    BrightnessOSD {}
    KeyboardBacklightOSD {}
    OsdCard {}
    Polkit {}

    LauncherOverlay {}

    AppearanceStrip {}

    SettingsOverlay {}

    LockScreen {}

    Idle {}

    Ipc {}
}
