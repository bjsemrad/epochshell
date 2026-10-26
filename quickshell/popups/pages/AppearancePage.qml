import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S
import qs.theme as T

ColumnLayout {
    id: page

    property bool showBack: false
    property var panel: null
    signal back()
    signal openTheme()

    Layout.fillWidth: true
    spacing: 0

    function choose(key, value) {
        T.Config[key] = value;
        T.Config.setSetting(key, value);
    }

    PageHeader {
        showBack: page.showBack
        title: "appearance"
        onBack: page.back()
    }

    SectionHeader { text: "theme" }
    ListRow {
        visible: T.Config.availableThemes.length > 1
        icon: "󰏘"
        value: "theme"
        detail: T.Config.themeName
        hasPage: true
        onOpened: page.openTheme()
    }
    ListRow {
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

    SectionHeader { text: "bar" }
    KeyRow {
        key: "style"
        Choice {
            options: ["full", { value: "floating", label: "float" }, "centered"]
            current: ["floating", "centered"].indexOf(T.Config.barStyle) >= 0 ? T.Config.barStyle : "full"
            onPicked: v => page.choose("barStyle", v)
        }
    }
    KeyRow {
        visible: T.Config.barCentered
        key: "span"
        Choice {
            options: ["pill", "full"]
            current: T.Config.barSpanFull ? "full" : "pill"
            onPicked: v => page.choose("barSpan", v)
        }
    }
    KeyRow {
        visible: T.Config.barCentered && !T.Config.barSpanFull
        key: "ledge"
        toggles: true
        onToggled: page.choose("barLedge", !T.Config.barLedge)
        ToggleSwitch {
            checked: T.Config.barLedge
            onToggled: page.choose("barLedge", !T.Config.barLedge)
        }
    }
    KeyRow {
        key: "status"
        Choice {
            options: [{ value: "individual", label: "icons" }, "dashboard"]
            current: T.Config.statusStyle === "dashboard" ? "dashboard" : "individual"
            onPicked: v => page.choose("statusStyle", v)
        }
    }
    KeyRow {
        key: "opacity"
        LevelSlider {
            value: T.Config.barOpacity
            onMoved: v => T.Config.barOpacity = v
            onCommitted: v => T.Config.setSetting("barOpacity", v)
        }
    }
    KeyRow {
        key: "blur"
        Choice {
            options: ["off", "bar", "all"]
            current: !T.Config.blur ? "off" : T.Config.blurPopups ? "all" : "bar"
            onPicked: v => {
                page.choose("blur", v !== "off");
                if (v !== "off") page.choose("blurPopups", v === "all");
            }
        }
    }
    KeyRow {
        visible: T.Config.barFloating && !T.Config.barIsLedge
        key: "top gap"
        LevelSlider {
            value: T.Config.barFloatingGap / Ui.topGapMax
            step: 1 / Ui.topGapMax
            label: T.Config.barFloatingGap + "px"
            onMoved: v => T.Config.barFloatingGap = Math.round(v * Ui.topGapMax)
            onCommitted: v => T.Config.setSetting("barFloatingGap", Math.round(v * Ui.topGapMax))
        }
    }
    KeyRow {
        visible: T.Config.barFloating
        key: "side gap"
        LevelSlider {
            value: T.Config.barFloatingSideGap / Ui.sideGapMax
            step: 1 / Ui.sideGapMax
            label: T.Config.barFloatingSideGap + "px"
            onMoved: v => T.Config.barFloatingSideGap = Math.round(v * Ui.sideGapMax)
            onCommitted: v => T.Config.setSetting("barFloatingSideGap", Math.round(v * Ui.sideGapMax))
        }
    }

    SectionHeader { text: "workspaces" }
    KeyRow {
        key: "style"
        Choice {
            options: ["pill", "plain", "ledge", "minimap"]
            current: ["plain", "ledge", "minimap"].indexOf(T.Config.workspaceStyle) >= 0 ? T.Config.workspaceStyle : "pill"
            onPicked: v => page.choose("workspaceStyle", v)
        }
    }
    KeyRow {
        key: "icons"
        toggles: true
        onToggled: page.choose("workspaceIcons", !T.Config.workspaceIcons)
        ToggleSwitch {
            checked: T.Config.workspaceIcons
            onToggled: page.choose("workspaceIcons", !T.Config.workspaceIcons)
        }
    }
    KeyRow {
        visible: T.Config.workspaceStyle === "ledge" || T.Config.workspaceStyle === "minimap"
        key: "icon limit"
        Stepper {
            value: T.Config.workspaceIconLimit
            from: 0
            to: Ui.iconLimitMax
            onStepped: v => page.choose("workspaceIconLimit", v)
        }
    }

    KeyRow {
        visible: T.Config.workspaceStyle === "ledge" || T.Config.workspaceStyle === "minimap"
        key: "colour"
        Choice {
            options: ["color", "mono"]
            current: T.Config.workspaceIconsMono ? "mono" : "color"
            onPicked: v => page.choose("workspaceIconColor", v)
        }
    }
    KeyRow {
        visible: T.Config.workspaceStyle === "minimap"
        key: "title"
        toggles: true
        onToggled: page.choose("workspaceShowTitle", !T.Config.workspaceShowTitle)
        ToggleSwitch {
            checked: T.Config.workspaceShowTitle
            onToggled: page.choose("workspaceShowTitle", !T.Config.workspaceShowTitle)
        }
    }

    SectionHeader { text: "panels" }
    KeyRow {
        key: "launcher"
        Choice {
            options: ["attached", "floating"]
            current: T.Config.launcherStyle === "floating" ? "floating" : "attached"
            onPicked: v => page.choose("launcherStyle", v)
        }
    }
    KeyRow {
        key: "attach"
        Choice {
            options: ["attached", "floating"]
            current: T.Config.panelStyle === "floating" ? "floating" : "attached"
            onPicked: v => page.choose("panelStyle", v)
        }
    }
    KeyRow {
        key: "outline"
        Choice {
            options: ["none", "panel", "fade", "bar"]
            current: ["none", "panel", "fade", "bar"].indexOf(T.Config.panelOutline) >= 0 ? T.Config.panelOutline : "none"
            onPicked: v => page.choose("panelOutline", v)
        }
    }
}
