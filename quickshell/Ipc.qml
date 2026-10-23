import Quickshell
import Quickshell.Io
import qs.services as S
import qs.theme as T

// IPC handlers must live at the shell root: one declared under Bar.qml's per-screen Variants
// registers once per screen.
Scope {
    id: root

    function reply(fields) {
        return JSON.stringify(fields);
    }

    function ok(extra) {
        const out = { ok: true };
        for (const key in (extra || {})) out[key] = extra[key];
        return root.reply(out);
    }

    function fail(message, extra) {
        const out = { ok: false, error: String(message) };
        for (const key in (extra || {})) out[key] = extra[key];
        return root.reply(out);
    }

    function unknownPanel(name) {
        return root.fail('unknown panel "' + String(name) + '"', { known: S.PopupManager.panelNames });
    }

    function panelState(name) {
        return {
            name: name,
            open: S.PopupManager.isPanelOpen(name),
            screens: S.PopupManager.popupsFor(name).length
        };
    }

    function screenNames() {
        const names = [];
        for (let i = 0; i < Quickshell.screens.length; i++) names.push(Quickshell.screens[i].name);
        return names;
    }

    function launcherOverlay() {
        return S.PopupManager.launcher;
    }

    IpcHandler {
        target: "panel"

        function toggle(name: string): string {
            if (!S.PopupManager.togglePanel(name)) return root.unknownPanel(name);
            return root.ok(root.panelState(name));
        }

        function open(name: string): string {
            if (!S.PopupManager.openPanel(name)) return root.unknownPanel(name);
            return root.ok(root.panelState(name));
        }

        function close(name: string): string {
            if (!S.PopupManager.closePanel(name)) return root.unknownPanel(name);
            return root.ok(root.panelState(name));
        }

        function status(name: string): string {
            if (!S.PopupManager.hasPanel(name)) return root.unknownPanel(name);
            return root.ok(root.panelState(name));
        }

        function closeAll(): string {
            S.PopupManager.closeAll();
            return root.ok({ closed: true });
        }

        function list(): string {
            return root.ok({ panels: S.PopupManager.panelNames.map(name => root.panelState(name)) });
        }
    }

    IpcHandler {
        target: "launcher"
        property bool isOpen: S.PopupManager.launcher ? S.PopupManager.launcher._visible : false

        function toggle(): string {
            const overlay = root.launcherOverlay();
            if (!overlay) return root.fail("launcher overlay is not loaded");
            overlay.toggle();
            return root.ok({ open: overlay._visible });
        }

        function open(): string {
            const overlay = root.launcherOverlay();
            if (!overlay) return root.fail("launcher overlay is not loaded");
            overlay.open();
            return root.ok({ open: true });
        }

        function close(): string {
            const overlay = root.launcherOverlay();
            if (!overlay) return root.fail("launcher overlay is not loaded");
            overlay.close();
            return root.ok({ open: false });
        }

        function providers(): string {
            const overlay = root.launcherOverlay();
            if (!overlay) return root.fail("launcher overlay is not loaded");
            overlay.openProviders();
            return root.ok({ open: true, providers: true });
        }

        function openProvider(name: string): string {
            const overlay = root.launcherOverlay();
            if (!overlay) return root.fail("launcher overlay is not loaded");
            overlay.openProvider(name);
            return root.ok({ open: true, provider: name });
        }
    }

    IpcHandler {
        target: "compositor"

        function state(): string {
            return root.ok({
                backend: S.CompositorService.backend,
                connected: S.CompositorService.connected,
                workspaces: S.CompositorService.workspaces,
                monitors: S.CompositorService.monitors,
                windows: S.CompositorService.windows.length,
                active_window: S.CompositorService.activeWindow
            });
        }

        function focusWorkspace(id: string): string {
            if (!S.CompositorService.connected) return root.fail("EpochOxide is not reachable");
            S.CompositorService.focusWorkspace(id);
            return root.ok({ workspace: id });
        }

        function focusWindow(id: string): string {
            if (!S.CompositorService.connected) return root.fail("EpochOxide is not reachable");
            S.CompositorService.focusWindow(id);
            return root.ok({ window: id });
        }
    }

    IpcHandler {
        target: "theme"

        function list(): string {
            return root.ok({ themes: T.Config.availableThemes, current: T.Config.themeName });
        }

        function get(): string {
            return root.ok({
                theme: T.Config.themeName,
                loaded: T.Config.themeLoaded,
                path: T.Config.themePath,
                selected: T.Config.selectedThemeName,
                configured: T.Config.configThemeName,
                themes: T.Config.availableThemes
            });
        }

        function set(name: string): string {
            if (!T.Config.selectTheme(name)) {
                return root.fail('unknown theme "' + String(name) + '"', { known: T.Config.availableThemes });
            }
            return root.ok({ theme: T.Config.themeName });
        }

        function reset(): string {
            T.Config.clearThemeSelection();
            return root.ok({ theme: T.Config.themeName });
        }

        function toggle(): string {
            const overlay = S.PopupManager.themeOverlay;
            if (!overlay) return root.fail("theme overlay is not loaded");
            overlay.toggle();
            return root.ok({ open: overlay._visible });
        }

        function open(): string {
            const overlay = S.PopupManager.themeOverlay;
            if (!overlay) return root.fail("theme overlay is not loaded");
            overlay.open();
            return root.ok({ open: true });
        }

        function close(): string {
            const overlay = S.PopupManager.themeOverlay;
            if (!overlay) return root.fail("theme overlay is not loaded");
            overlay.cancel();
            return root.ok({ open: false });
        }
    }

    IpcHandler {
        target: "settings"

        function toggle(): string {
            const overlay = S.PopupManager.settingsOverlay;
            if (!overlay) return root.fail("settings window is not loaded");
            overlay.toggle();
            return root.ok({ open: overlay._visible });
        }

        function open(): string {
            const overlay = S.PopupManager.settingsOverlay;
            if (!overlay) return root.fail("settings window is not loaded");
            overlay.open();
            return root.ok({ open: true });
        }

        function close(): string {
            const overlay = S.PopupManager.settingsOverlay;
            if (!overlay) return root.fail("settings window is not loaded");
            overlay.close();
            return root.ok({ open: false });
        }
    }

    IpcHandler {
        target: "wallpaper"

        function toggle(): string {
            const overlay = S.PopupManager.wallpaperOverlay;
            if (!overlay) return root.fail("wallpaper overlay is not loaded");
            overlay.toggle();
            return root.ok({ open: overlay._visible });
        }

        function open(): string {
            const overlay = S.PopupManager.wallpaperOverlay;
            if (!overlay) return root.fail("wallpaper overlay is not loaded");
            overlay.open();
            return root.ok({ open: true });
        }

        function close(): string {
            const overlay = S.PopupManager.wallpaperOverlay;
            if (!overlay) return root.fail("wallpaper overlay is not loaded");
            overlay.cancel();
            return root.ok({ open: false });
        }

        function list(): string {
            return root.ok({
                wallpapers: S.Wallpaper.wallpapers,
                current: S.Wallpaper.current,
                directories: S.Wallpaper.directories
            });
        }

        function set(path: string): string {
            if (!S.Wallpaper.set(path)) return root.fail("no wallpaper path given");
            return root.ok({ wallpaper: S.Wallpaper.current });
        }

        function next(): string {
            S.Wallpaper.step(1);
            return root.ok({ stepped: 1 });
        }

        function previous(): string {
            S.Wallpaper.step(-1);
            return root.ok({ stepped: -1 });
        }

        function refresh(): string {
            S.Wallpaper.refresh();
            return root.ok({ scanning: true });
        }
    }

    IpcHandler {
        target: "shell"

        function ping(): string {
            return root.ok({ pong: true });
        }

        function info(): string {
            return root.ok({
                instance_id: Quickshell.instanceId,
                shell_id: Quickshell.shellId,
                pid: Quickshell.processId,
                config_dir: Quickshell.configDir,
                shell_root: Quickshell.shellRoot,
                launch_time: String(Quickshell.launchTime),
                screens: root.screenNames(),
                panels: S.PopupManager.panelNames,
                providers: S.LauncherService.availableProviders,
                backend_connected: S.LauncherService.backendConnected,
                backend_error: S.LauncherService.backendError
            });
        }

        // Soft by default: a hard reload drops the notification daemon and polkit agent
        // registrations.
        function reload(): string {
            Quickshell.reload(false);
            return root.ok({ reloaded: true, hard: false });
        }

        function reloadHard(): string {
            Quickshell.reload(true);
            return root.ok({ reloaded: true, hard: true });
        }
    }

    // Deliberately no unlock: anything able to run `qs ipc` could end the lock.
    IpcHandler {
        target: "lock"

        function lock(): string {
            S.Lock.lock();
            return root.ok({ locked: S.Lock.locked, secure: S.Lock.secure });
        }

        function status(): string {
            return root.ok({ locked: S.Lock.locked, secure: S.Lock.secure });
        }
    }
}
