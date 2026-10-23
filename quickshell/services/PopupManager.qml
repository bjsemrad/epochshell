pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property var openPopups: []

    property var entries: []

    readonly property var panelNames: {
        const seen = [];
        for (const entry of root.entries) {
            if (seen.indexOf(entry.name) === -1) seen.push(entry.name);
        }
        return seen.sort();
    }

    property var launcher: null
    property var wallpaperOverlay: null
    property var themeOverlay: null
    property var settingsOverlay: null

    function register(popup, name) {
        if (openPopups.indexOf(popup) === -1) {
            openPopups.push(popup);
        }
        if (!name || name.length === 0) return;
        for (const entry of root.entries) {
            if (entry.popup === popup && entry.name === String(name)) return;
        }
        root.entries = root.entries.concat([{ name: String(name), popup: popup }]);
    }

    function unregister(popup) {
        const kept = [];
        for (const p of root.openPopups) {
            if (p !== popup) kept.push(p);
        }
        root.openPopups = kept;
        root.entries = root.entries.filter(entry => entry.popup !== popup);
    }

    function unregisterLauncher(overlay) {
        if (root.launcher === overlay) root.launcher = null;
    }

    function registerLauncher(overlay) {
        root.launcher = overlay;
    }

    function registerWallpaperOverlay(overlay) {
        root.wallpaperOverlay = overlay;
    }

    function registerThemeOverlay(overlay) {
        root.themeOverlay = overlay;
    }

    function registerSettingsOverlay(overlay) {
        root.settingsOverlay = overlay;
    }

    function popupsFor(name) {
        return root.entries.filter(entry => entry.name === name).map(entry => entry.popup);
    }

    function panelFor(name) {
        const list = root.popupsFor(name);
        return list.length > 0 ? list[0] : null;
    }

    function hasPanel(name) {
        return root.panelFor(name) !== null;
    }

    function isPanelOpen(name) {
        const popup = root.panelFor(name);
        return popup !== null && popup.open;
    }

    function show(popup, name) {
        if (typeof popup.showPage === "function")
            popup.showPage(name);
        else
            popup.showPanel();
    }

    function openPanel(name) {
        const popup = root.panelFor(name);
        if (!popup) return false;
        root.closeOthers(popup);
        root.show(popup, name);
        return true;
    }

    function closePanel(name) {
        const popup = root.panelFor(name);
        if (!popup) return false;
        popup.hidePanel();
        return true;
    }

    function togglePanel(name) {
        const popup = root.panelFor(name);
        if (!popup) return false;
        if (popup.open) {
            popup.hidePanel();
        } else {
            root.closeOthers(popup);
            root.show(popup, name);
        }
        return true;
    }

    // A panel opening closes the launcher: it holds the keyboard, and the panel would get no keys.
    function closeOthers(except) {
        if (root.launcher && root.launcher._visible && root.launcher !== except) root.launcher.close();
        for (let p of openPopups) {
            if (p !== except && p.open) {
                p.hidePanel();
            }
        }
    }

    function closeAll() {
        for (let p of openPopups) {
            if (p.open) {
                p.hidePanel();
            }
        }
    }
}
