import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S
import qs.theme as T

// The look of the shell, Readout style: the theme and wallpaper, the bar, the workspaces and the
// panels. Writes through T.Config.setSetting,
// as the Appearance window does, so a choice applies live and is kept in settings.toml.
ColumnLayout {
    id: page

    property bool showBack: false
    // The panel this page is in, closed before an overlay (the wallpaper picker) opens.
    property var panel: null
    signal back()
    signal openTheme()

    Layout.fillWidth: true
    spacing: 0

    function choose(key, value) {
        T.Config[key] = value;
        T.Config.setSetting(key, value);
    }

    ReadoutHeader {
        showBack: page.showBack
        title: "appearance"
        onBack: page.back()
    }

    ReadoutSection { text: "theme" }
    ReadoutRow {
        visible: T.Config.availableThemes.length > 1
        icon: "󰏘"
        value: "theme"
        detail: T.Config.themeName
        hasPage: true
        onOpened: page.openTheme()
    }
    ReadoutRow {
        visible: S.Wallpaper.connected
        icon: "󰸉"
        value: "wallpaper"
        detail: S.Wallpaper.current.length > 0 ? S.Wallpaper.displayName(S.Wallpaper.current) : ""
        hasPage: S.Wallpaper.wallpapers.length > 0
        onOpened: {
            const overlay = S.PopupManager.wallpaperOverlay;
            if (!overlay) return;
            if (page.panel) page.panel.hidePanel();
            overlay.open();
        }
    }

    ReadoutSection { text: "bar" }
    ReadoutKeyRow {
        key: "style"
        ReadoutChoice {
            options: ["full", { value: "floating", label: "float" }, "centered"]
            current: ["floating", "centered"].indexOf(T.Config.barStyle) >= 0 ? T.Config.barStyle : "full"
            onPicked: v => page.choose("barStyle", v)
        }
    }
    ReadoutKeyRow {
        visible: T.Config.barCentered
        key: "ledge"
        ReadoutSwitch {
            checked: T.Config.barLedge
            onToggled: page.choose("barLedge", !T.Config.barLedge)
        }
    }
    ReadoutKeyRow {
        key: "status"
        ReadoutChoice {
            options: [{ value: "individual", label: "icons" }, "dashboard"]
            current: T.Config.statusStyle === "dashboard" ? "dashboard" : "individual"
            onPicked: v => page.choose("statusStyle", v)
        }
    }
    ReadoutKeyRow {
        key: "opacity"
        ReadoutGauge {
            value: T.Config.barOpacity
            onMoved: v => T.Config.barOpacity = v
            onCommitted: v => T.Config.setSetting("barOpacity", v)
        }
    }

    ReadoutSection { text: "workspaces" }
    ReadoutKeyRow {
        key: "style"
        ReadoutChoice {
            options: ["pill", "plain", "ledge"]
            current: ["plain", "ledge"].indexOf(T.Config.workspaceStyle) >= 0 ? T.Config.workspaceStyle : "pill"
            onPicked: v => page.choose("workspaceStyle", v)
        }
    }
    ReadoutKeyRow {
        key: "icons"
        ReadoutSwitch {
            checked: T.Config.workspaceIcons
            onToggled: page.choose("workspaceIcons", !T.Config.workspaceIcons)
        }
    }
    ReadoutKeyRow {
        visible: T.Config.workspaceStyle === "ledge"
        key: "icon limit"
        ReadoutStepper {
            value: T.Config.workspaceIconLimit
            from: 0
            to: 6
            onStepped: v => page.choose("workspaceIconLimit", v)
        }
    }

    ReadoutSection { text: "panels" }
    ReadoutKeyRow {
        key: "attach"
        ReadoutChoice {
            options: ["attached", "floating"]
            current: T.Config.panelStyle === "floating" ? "floating" : "attached"
            onPicked: v => page.choose("panelStyle", v)
        }
    }
    ReadoutKeyRow {
        key: "outline"
        ReadoutChoice {
            options: ["none", "panel", "fade", "bar"]
            current: ["none", "panel", "fade", "bar"].indexOf(T.Config.panelOutline) >= 0 ? T.Config.panelOutline : "none"
            onPicked: v => page.choose("panelOutline", v)
        }
    }
    ReadoutKeyRow {
        key: "opacity"
        ReadoutGauge {
            value: T.Config.panelOpacity
            onMoved: v => T.Config.panelOpacity = v
            onCommitted: v => T.Config.setSetting("panelOpacity", v)
        }
    }
}
