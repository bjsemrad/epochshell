pragma Singleton
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/epochshell"
    readonly property string configPath: configDir + "/config.toml"

    // Themes are named files of the same key/value lines config.toml uses, looked up in two
    // places: the user's own, then the ones shipped with the shell, so a user theme shadows a
    // shipped one of the same name.
    //
    // They are NOT kept beside config.toml, and neither is the selection below. The flake installs
    // the whole shell tree at `~/.config/epochshell`, so on a home-manager machine that directory
    // is a read-only symlink into the nix store -- nothing can be written there, and nothing the
    // user writes can survive a rebuild. Themes the user writes go under XDG data, and the
    // selection under XDG state, both of which are theirs.
    readonly property string dataDir: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/epochshell"
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/epochshell"
    readonly property string userThemeDir: dataDir + "/themes"
    readonly property string bundledThemeDir: Quickshell.shellRoot + "/theme/themes"
    readonly property string selectionPath: stateDir + "/theme"

    // Settings changed from inside the shell. config.toml is the declarative answer and is often
    // not writable -- on a home-manager install it cannot exist at all -- so anything the user
    // adjusts through a control lands here instead, and wins over both the theme and config.toml
    // because it is the most explicit thing anyone has said.
    readonly property string settingsPath: stateDir + "/settings.toml"
    readonly property string defaultThemeName: "dark"

    // The theme in force, and whether its file was actually found: `themeLoaded` false with a
    // non-empty name means the shell is wearing the built-in defaults under a name that promised
    // something else.
    property string themeName: defaultThemeName
    readonly property string themePath: themeName === ""
        ? ""
        : (themeFromUserDir ? userThemeDir : bundledThemeDir) + "/" + themeName + ".toml"
    property bool themeLoaded: false
    readonly property var availableThemes: themeScan.names

    // Which theme to wear is asked in two places, because the two are different questions. The
    // state file is what was last picked, at runtime, by a person; config.toml's `theme` key is
    // what to start from when nobody has picked anything -- the declarative answer, for a Nix
    // machine where config.toml is generated rather than edited. A live pick wins over it.
    property string selectedThemeName: ""
    property string configThemeName: defaultThemeName

    // The switch in flight, and what to go back to if its file turns out not to exist.
    // `committedThemeName` is the last name whose file actually loaded -- what is really on screen.
    property string pendingSelection: ""
    property string previousSelection: ""
    property string committedThemeName: ""

    // A theme being tried on. It paints the whole shell like a real switch, and that is the point
    // -- the only honest preview of a palette is the palette -- but it is never written down, so
    // moving the mouse away or closing the panel puts back whatever was actually chosen.
    property string previewThemeName: ""

    // A theme may name another to build on with `extends`, which is how a family of one palette in
    // several accents stays one palette: the variants carry the line that differs and nothing else,
    // so a colour fixed in the parent is fixed in all of them.
    //
    // Exactly one level deep. A parent's own `extends` is ignored, which costs nothing real -- a
    // chain is not a thing anyone has wanted yet -- and means there is no cycle to detect.
    property string parentThemeName: ""
    readonly property string parentThemePath: parentThemeName === ""
        ? ""
        : (parentFromUserDir ? userThemeDir : bundledThemeDir) + "/" + parentThemeName + ".toml"
    property bool parentFromUserDir: true
    onParentThemeNameChanged: parentFromUserDir = true

    // The texts the palette is built from, kept separate so each can change on its own: editing
    // a theme file must not need config.toml re-read, or the other way round.
    property string configText: ""
    property string themeText: ""
    property string parentThemeText: ""
    property string settingsText: ""

    // The user theme dir is tried first and the bundled one second, by flipping this on a failed
    // load rather than by asking whether either file exists -- FileView answers that question by
    // loading or not.
    property bool themeFromUserDir: true
    onThemeNameChanged: themeFromUserDir = true
    readonly property var colorKeys: [
        "accent", "accentLightShade", "inactive", "active", "activeSelection",
        "background", "surface", "surfaceVariant", "surfaceContainer", "surfaceContainerHigh",
        "surfaceContainerHighest", "surfaceText", "outline", "purple", "green", "orange",
        "blue", "yellow", "cyan", "red", "bg_blue", "bg_yellow"
    ]
    readonly property var boolKeys: ["panelAnimationsEnabled", "hideInactiveWorkspaces", "workspaceIcons"]
    readonly property var realKeys: ["workspaceStripMaxWidthRatio", "barOpacity", "popupOpacity"]
    readonly property var stringKeys: ["fontFamily"]
    // `theme` is read out of config.toml but is not a style property: it decides which file the
    // style properties come from, so it is handled before the rest rather than assigned like one.
    readonly property string themeKey: "theme"
    // Handled the same way and for the same reason: it decides where values come from rather than
    // being one of them.
    readonly property string extendsKey: "extends"
    readonly property var intKeys: [
        "popupPadding", "popupRadius", "popupLayoutSpacing", "barIconSize", "barClockSize",
        "barWeatherSize", "barModuleSpacing", "barGroupIconSpacing", "barIconTextSpacing",
        "barModuleHorizontalPadding", "barModuleVerticalPadding", "widthPaddingLarge",
        "widthPaddingSmall", "heightPaddingSmall", "layoutMarginSmall", "layoutSpacingLarge",
        "layoutSpacingSmall", "roundRadius", "connectedIconSize", "fontSizeNormal",
        "fontSizeMedium", "fontSizeLarge", "fontSizeXLarge", "fontSizeSubtext",
        "cardRadius", "cardHeight", "cardMargin", "cardSpacing", "networkPopupWidth",
        "tailscalePopupWidth", "localsendPopupWidth", "bluetoothPopupWidth", "audioPopupWidth", "systemTrayPopupWidth",
        "systemPopupWidth", "batteryPopupWidth", "musicPlayerWidth", "controlCenterPopupWidth", "homeAssistantPopupWidth",
        "capturePopupWidth", "nixPopupWidth", "tailscalePeersFontSize", "selectedBorderWidth", "panelBottomMargin",
        "panelBottomMarginMedium", "statMargin", "barHeight", "cornerRadius", "headerSize",
        "switchHeight", "switchWidth", "switchKnobSize", "switchKnobRadius",
        "settingsHeaderHeight", "settingsHeaderSpacing", "systemActionSize",
        "systemActionRadius", "systemActionMargin", "systemActionSpacing", "volumeSliderSize",
        "volumeSliderRadius", "volumeSliderMargin", "volumeSliderSpacing"
    ]

    property color accent: blue
    property color accentLightShade: Qt.rgba(Qt.color(accent).r, Qt.color(accent).g, Qt.color(accent).b, 0.10)
    property color inactive: Qt.rgba(Qt.color(surfaceText).r, Qt.color(surfaceText).g, Qt.color(surfaceText).b, 0.75)
    property color active: surfaceText
    property color activeSelection: surfaceContainerHigh //Qt.rgba(Qt.color(surfaceContainerHigh).r, Qt.color(surfaceContainerHigh).g, Qt.color(surfaceContainerHigh).b, 0.25)

    property color background: "#0e1013"
    property color surface: "#1f2329"
    property color surfaceVariant: "#323641"
    property color surfaceContainer: "#1f2329"
    property color surfaceContainerHigh: "#282c34" //"#272a2f"
    property color surfaceContainerHighest: "#30363f"
    property color surfaceText: "#a0a8b7"
    property color outline: "#8c9199"

    // ───────────────────────────────────────────────
    //  ACCENT COLORS
    // ───────────────────────────────────────────────
    //
    property color purple: "#bf68d9"
    property color green: "#8ebd6b"
    property color orange: "#cc9057"
    property color blue: "#4fa6ed"
    property color yellow: "#e2b86b"
    property color cyan: "#48b0bd"
    property color red: "#e55561"
    property color bg_blue: "#61afef"
    property color bg_yellow: "#e8c88c"

    /* Misc */
    property string fontFamily: "JetBrainsMono Nerd Font Propo"

    property int popupPadding: 10
    property int popupRadius: 10
    property int popupLayoutSpacing: 8

    property int barIconSize: 18
    property int barClockSize: fontSizeSubtext
    property int barWeatherSize: fontSizeNormal
    property int barModuleSpacing: 10
    property int barGroupIconSpacing: barModuleVerticalPadding * 2
    property int barIconTextSpacing: 5
    property int barModuleHorizontalPadding: widthPaddingSmall
    property int barModuleVerticalPadding: popupPadding

    property int widthPaddingLarge: 20
    property int widthPaddingSmall: 14
    property int heightPaddingSmall: 5

    property int layoutMarginSmall: 5
    property int layoutSpacingLarge: 20
    property int layoutSpacingSmall: 20

    property int roundRadius: 20
    property int connectedIconSize: 40

    property int fontSizeNormal: 14
    property int fontSizeMedium: 16

    property int fontSizeLarge: 18
    property int fontSizeXLarge: 24
    property int fontSizeSubtext: 11

    property int cardRadius: 10
    property int cardHeight: 50
    property int cardMargin: 14
    property int cardSpacing: 10

    property int networkPopupWidth: 400
    property int tailscalePopupWidth: 700
    property int localsendPopupWidth: 420
    property int bluetoothPopupWidth: 400
    property int audioPopupWidth: 550
    property int systemTrayPopupWidth: 300
    property int systemPopupWidth: 300
    property int batteryPopupWidth: 250
    property int musicPlayerWidth: 600
    property int controlCenterPopupWidth: 700
    property int homeAssistantPopupWidth: 420
    property int capturePopupWidth: 320
    property int nixPopupWidth: 380

    property int tailscalePeersFontSize: 14

    property int selectedBorderWidth: 1
    property int panelBottomMargin: 5
    property int panelBottomMarginMedium: 15

    property int statMargin: 12

    property int barHeight: 40
    property int cornerRadius: 18

    property int headerSize: 40

    property int switchHeight: 42
    property int switchWidth: 24
    property int switchKnobSize: 20
    property int switchKnobRadius: 10

    property int settingsHeaderHeight: 30
    property int settingsHeaderSpacing: 10

    property int systemActionSize: 40
    property int systemActionRadius: 10
    property int systemActionMargin: 30
    property int systemActionSpacing: 10

    property int volumeSliderSize: 40
    property int volumeSliderRadius: 20
    property int volumeSliderMargin: 30
    property int volumeSliderSpacing: 10

    property bool panelAnimationsEnabled: false

    property bool hideInactiveWorkspaces: true
    property bool workspaceIcons: true
    property real workspaceStripMaxWidthRatio: 0.45

    // How much of the wallpaper shows through the bar and the panels, 0 transparent to 1 solid.
    //
    // This is what stops the bar reading as a stripe laid over the desktop: a fully opaque bar is
    // its own flat colour, and against a wallpaper of a slightly different darkness the join shows
    // as a seam. Letting a little of the picture through means the bar takes on whatever is behind
    // it and the join disappears -- on a dark wallpaper it is nearly invisible, on a bright one it
    // still reads as a bar because the theme's ground is doing most of the work.
    //
    // Solid by default. Translucency is a taste, not an improvement -- the shell should look the
    // way it always has until someone asks otherwise -- so these ship at 1 and the sliders in the
    // Themes panel are how you ask.
    //
    // Those sliders write to the settings file rather than config.toml, which matters because
    // config.toml cannot exist at all on a home-manager install.
    property real barOpacity: 1.0
    property real popupOpacity: 1.0

    // The ground with its opacity applied, which is what actually gets painted. Bindings rather
    // than values written by updateDerived(): they depend on `background`, which a theme may set,
    // and on the opacity, which config.toml may set, so they have to follow both.
    readonly property color barBackground: Qt.rgba(background.r, background.g, background.b, barOpacity)
    readonly property color popupBackground: Qt.rgba(background.r, background.g, background.b, popupOpacity)

    // config.toml says which theme to use and overrides anything it wants on top of it. Both
    // files are watched, and either changing rebuilds the palette from both -- editing a theme
    // must not need config.toml re-read, or the other way round.
    FileView {
        path: root.configPath
        watchChanges: true
        printErrors: false
        onLoaded: root.acceptConfig(text())
        onLoadFailed: root.acceptConfig("")
        onFileChanged: reload()
    }

    FileView {
        id: themeFile
        path: root.themePath
        watchChanges: true
        printErrors: false

        onLoaded: {
            root.themeLoaded = true;
            root.committedThemeName = root.themeName;
            root.themeText = text();
            // A changed parent re-points the parent FileView, which rebuilds again on load. When
            // there is no parent the text is cleared here, so dropping an `extends` line takes
            // effect without a reload.
            const parent = root.readExtends(root.themeText);
            if (parent === "") root.parentThemeText = "";
            root.parentThemeName = parent;
            // A pick is only kept once its file has actually loaded, so a name that turns out not
            // to exist never makes it into the state file to greet the next session.
            if (root.pendingSelection !== "" && root.pendingSelection === root.themeName) {
                root.pendingSelection = "";
                selectionWriter.setText(root.themeName + "\n");
            }
            root.rebuild();
        }

        onLoadFailed: {
            // The user's theme dir is only where we look first; falling through to the shipped
            // copy is the ordinary case and says nothing.
            //
            // The reload is not redundant: re-pointing `path` after a load has already failed does
            // not start another one on its own, so without this the fallback sets the right path
            // and then sits there never reading it. callLater, because the path binding has not
            // settled on the new directory yet at the moment this runs.
            if (root.themeFromUserDir) {
                root.themeFromUserDir = false;
                Qt.callLater(themeFile.reload);
                return;
            }

            // A preview of something that is not there: drop it and stay on what was chosen. This
            // is checked before the pending-selection case because a preview never has one.
            if (root.previewThemeName !== "") {
                console.warn("EpochShell theme not found:", root.themeName, "-- ending preview");
                root.endPreview();
                return;
            }

            // A switch to a theme that is not there. The list this was checked against is a
            // snapshot and can be out of date -- a file deleted since, a name typed at a shell
            // that had not looked lately -- so the answer is to stay on the theme that does
            // exist rather than strip the shell back to its defaults over a typo.
            if (root.pendingSelection !== "" && root.committedThemeName !== "") {
                console.warn("EpochShell theme not found:", root.themeName, "-- staying on", root.committedThemeName);
                root.pendingSelection = "";
                root.selectedThemeName = root.previousSelection;
                root.resolveTheme();
                return;
            }

            // Nothing to fall back to: this is the theme asked for at startup, and it is missing.
            root.themeLoaded = false;
            root.themeText = "";
            if (root.themeName !== "") {
                console.warn("Unknown EpochShell theme:", root.themeName, "-- known:", root.availableThemes.join(", ") || "none");
            }
            root.rebuild();
        }

        onFileChanged: reload()
    }

    // The theme named by `extends`, looked up in the same two places and in the same order.
    FileView {
        id: parentFile
        path: root.parentThemePath
        watchChanges: true
        printErrors: false

        onLoaded: {
            root.parentThemeText = text();
            root.rebuild();
        }

        onLoadFailed: {
            if (root.parentFromUserDir) {
                root.parentFromUserDir = false;
                Qt.callLater(parentFile.reload);
                return;
            }
            // A theme extending something that is not there still applies its own values -- it is
            // just missing whatever it expected to inherit, which is worth saying out loud.
            root.parentThemeText = "";
            if (root.parentThemeName !== "") {
                console.warn("EpochShell theme", root.themeName, "extends unknown theme:", root.parentThemeName);
            }
            root.rebuild();
        }

        onFileChanged: reload()
    }

    // Every theme on disk, and enough of each one's palette to draw it without wearing it.
    //
    // One pass that cats the files rather than a find for names and then a read per theme: a
    // picker wants to show colours, and colours only come from opening the file. The user's
    // directory is listed first and a name already seen is ignored, which is what makes a user
    // theme shadow a shipped one.
    //
    // Refreshed whenever the palette is rebuilt, the cheapest moment that reliably follows anyone
    // editing any of this.
    Process {
        id: themeScan
        property var names: []
        property var palettes: ({})
        command: ["sh", "-c",
            "for f in '" + root.userThemeDir + "'/*.toml '" + root.bundledThemeDir + "'/*.toml; do "
            + "[ -e \"$f\" ] || continue; "
            + "echo \"@@theme $(basename \"$f\" .toml)\"; cat \"$f\"; done"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.applyThemeScan(text)
        }
    }

    // The colours a picker draws on a theme's own ground to show what it is like. Not the surface
    // ramp: three greys a few percent apart are three identical dark squares at swatch size, which
    // is all the surfaces of a dark theme are. Text, accent and two named colours actually differ
    // between themes, and drawn on the theme's `background` they carry the ground as well.
    readonly property var swatchKeys: ["surfaceText", "accent", "green", "red"]

    function applyThemeScan(raw) {
        const names = [];
        const palettes = {};
        const parents = {};
        const lines = String(raw || "").split("\n");
        let current = "";

        for (let i = 0; i < lines.length; i++) {
            const rawLine = lines[i];

            if (rawLine.startsWith("@@theme ")) {
                const name = rawLine.slice(8).trim();
                // Already seen means the user's copy of this name won; the shipped one is shadowed.
                current = (name === "" || palettes[name] !== undefined) ? "" : name;
                if (current !== "") {
                    names.push(current);
                    palettes[current] = {};
                }
                continue;
            }

            if (current === "") continue;

            const line = root.stripTomlComment(rawLine);
            const eq = line.indexOf("=");
            if (eq < 0) continue;

            const key = line.slice(0, eq).trim();

            if (key === root.extendsKey) {
                parents[current] = String(root.parseTomlValue(line.slice(eq + 1))).trim();
                continue;
            }

            if (root.colorKeys.indexOf(key) === -1) continue;
            palettes[current][key] = String(root.parseTomlValue(line.slice(eq + 1)));
        }

        // A variant's file holds only what differs, so its swatch has to be drawn from the parent
        // it inherits the rest of. Done after the loop because a parent may be read after its
        // child -- the directory is walked alphabetically, not in dependency order.
        for (const name in parents) {
            const parent = palettes[parents[name]];
            if (!parent || parents[name] === name) continue;
            const merged = {};
            for (const key in parent) merged[key] = parent[key];
            for (const key in palettes[name]) merged[key] = palettes[name][key];
            palettes[name] = merged;
        }

        names.sort();
        themeScan.names = names;
        themeScan.palettes = palettes;
    }

    // One colour out of a theme's palette without applying it, falling back to what the shell is
    // wearing: a theme that sets only some keys inherits the rest, and the swatch should say so.
    function themeColor(name, key) {
        const palette = themeScan.palettes[name];
        const value = palette && palette[key];
        return (typeof value === "string" && value.length > 0) ? value : root[key];
    }

    function stripTomlComment(line) {
        let quoted = false;
        let escaped = false;
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (escaped) {
                escaped = false;
                continue;
            }
            if (c === "\\") {
                escaped = true;
                continue;
            }
            if (c === '"') quoted = !quoted;
            if (c === "#" && !quoted) return line.slice(0, i).trim();
        }
        return line.trim();
    }

    function parseTomlValue(raw) {
        const value = raw.trim();
        if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
            return value.slice(1, -1);
        }
        if (value === "true") return true;
        if (value === "false") return false;
        const numberValue = Number(value);
        if (!Number.isNaN(numberValue)) return numberValue;
        return value;
    }

    function resetDefaults() {
        purple = "#bf68d9";
        green = "#8ebd6b";
        orange = "#cc9057";
        blue = "#4fa6ed";
        yellow = "#e2b86b";
        cyan = "#48b0bd";
        red = "#e55561";
        bg_blue = "#61afef";
        bg_yellow = "#e8c88c";

        accent = blue;
        background = "#0e1013";
        surface = "#1f2329";
        surfaceVariant = "#323641";
        surfaceContainer = "#1f2329";
        surfaceContainerHigh = "#282c34";
        surfaceContainerHighest = "#30363f";
        surfaceText = "#a0a8b7";
        outline = "#8c9199";

        fontFamily = "JetBrainsMono Nerd Font Propo";
        popupPadding = 10;
        popupRadius = 10;
        popupLayoutSpacing = 8;
        barIconSize = 18;
        widthPaddingLarge = 20;
        widthPaddingSmall = 14;
        heightPaddingSmall = 5;
        layoutMarginSmall = 5;
        layoutSpacingLarge = 20;
        layoutSpacingSmall = 20;
        roundRadius = 20;
        connectedIconSize = 40;
        fontSizeNormal = 14;
        fontSizeMedium = 16;
        fontSizeLarge = 18;
        fontSizeXLarge = 24;
        fontSizeSubtext = 11;
        cardRadius = 10;
        cardHeight = 50;
        cardMargin = 14;
        cardSpacing = 10;
        networkPopupWidth = 400;
        tailscalePopupWidth = 700;
        localsendPopupWidth = 420;
        bluetoothPopupWidth = 400;
        audioPopupWidth = 550;
        systemTrayPopupWidth = 300;
        systemPopupWidth = 300;
        batteryPopupWidth = 250;
        musicPlayerWidth = 600;
        controlCenterPopupWidth = 700;
        homeAssistantPopupWidth = 420;
        capturePopupWidth = 320;
        nixPopupWidth = 380;
        tailscalePeersFontSize = 14;
        selectedBorderWidth = 1;
        panelBottomMargin = 5;
        panelBottomMarginMedium = 15;
        statMargin = 12;
        barHeight = 40;
        cornerRadius = 18;
        headerSize = 40;
        switchHeight = 42;
        switchWidth = 24;
        switchKnobSize = 20;
        switchKnobRadius = 10;
        settingsHeaderHeight = 30;
        settingsHeaderSpacing = 10;
        systemActionSize = 40;
        systemActionRadius = 10;
        systemActionMargin = 30;
        systemActionSpacing = 10;
        volumeSliderSize = 40;
        volumeSliderRadius = 20;
        volumeSliderMargin = 30;
        volumeSliderSpacing = 10;
        panelAnimationsEnabled = false;
        hideInactiveWorkspaces = true;
        workspaceIcons = true;
        workspaceStripMaxWidthRatio = 0.45;
        barOpacity = 1.0;
        popupOpacity = 1.0;

        updateDerived({});
    }

    function updateDerived(overridden) {
        if (!overridden.accentLightShade) accentLightShade = Qt.rgba(Qt.color(accent).r, Qt.color(accent).g, Qt.color(accent).b, 0.10);
        if (!overridden.inactive) inactive = Qt.rgba(Qt.color(surfaceText).r, Qt.color(surfaceText).g, Qt.color(surfaceText).b, 0.75);
        if (!overridden.active) active = surfaceText;
        if (!overridden.activeSelection) activeSelection = surfaceContainerHigh;
        if (!overridden.barClockSize) barClockSize = fontSizeSubtext;
        if (!overridden.barWeatherSize) barWeatherSize = fontSizeNormal;
        if (!overridden.barGroupIconSpacing) barGroupIconSpacing = barModuleVerticalPadding * 2;
        if (!overridden.barModuleHorizontalPadding) barModuleHorizontalPadding = widthPaddingSmall;
        if (!overridden.barModuleVerticalPadding) barModuleVerticalPadding = popupPadding;
    }

    function applyOverride(key, value, overridden) {
        if (colorKeys.indexOf(key) === -1 && boolKeys.indexOf(key) === -1 && realKeys.indexOf(key) === -1
                && stringKeys.indexOf(key) === -1 && intKeys.indexOf(key) === -1) {
            console.warn("Unknown EpochShell config key:", key);
            return;
        }

        try {
            if (colorKeys.indexOf(key) !== -1) root[key] = Qt.color(String(value));
            else if (boolKeys.indexOf(key) !== -1) root[key] = !!value;
            else if (realKeys.indexOf(key) !== -1) root[key] = Number(value);
            else if (stringKeys.indexOf(key) !== -1) root[key] = String(value);
            else {
                const n = Number(value);
                if (isNaN(n)) throw "expected number";
                root[key] = Math.round(n);
            }
            overridden[key] = true;
        } catch (e) {
            console.warn("Invalid EpochShell config value for", key + ":", value, e);
        }
    }

    // One pass over one file. `overridden` is carried across both files so a key the theme set and
    // the user then set again still counts as overridden once, and the derived colours know to
    // leave it alone.
    function applyText(raw, overridden) {
        const lines = String(raw || "").split("\n");

        for (let i = 0; i < lines.length; i++) {
            const line = root.stripTomlComment(lines[i]);
            if (!line || (line.startsWith("[") && line.endsWith("]"))) continue;

            const eq = line.indexOf("=");
            if (eq < 0) continue;

            const key = line.slice(0, eq).trim();
            // Already acted on: these chose the files this loop is reading.
            if (key === root.themeKey || key === root.extendsKey) continue;

            const value = root.parseTomlValue(line.slice(eq + 1));
            root.applyOverride(key, value, overridden);
        }
    }

    // Which theme config.toml asks for, read on its own and before anything is applied: it decides
    // where the rest of the values come from, so it cannot be one of them.
    function readThemeName(raw) {
        const lines = String(raw || "").split("\n");

        for (let i = 0; i < lines.length; i++) {
            const line = root.stripTomlComment(lines[i]);
            const eq = line.indexOf("=");
            if (eq < 0) continue;
            if (line.slice(0, eq).trim() !== root.themeKey) continue;
            return String(root.parseTomlValue(line.slice(eq + 1))).trim();
        }

        return root.defaultThemeName;
    }

    // Which theme this one builds on, read before any value is applied.
    function readExtends(raw) {
        const lines = String(raw || "").split("\n");

        for (let i = 0; i < lines.length; i++) {
            const line = root.stripTomlComment(lines[i]);
            const eq = line.indexOf("=");
            if (eq < 0) continue;
            if (line.slice(0, eq).trim() !== root.extendsKey) continue;
            const parent = String(root.parseTomlValue(line.slice(eq + 1))).trim();
            // A theme naming itself would load itself forever.
            return parent === root.themeName ? "" : parent;
        }

        return "";
    }

    function acceptConfig(raw) {
        root.configText = String(raw || "");
        root.configThemeName = root.readThemeName(root.configText);
        root.resolveTheme();
        root.rebuild();
    }

    // A preview beats a live pick beats the configured default. Changing the answer re-points the
    // theme FileView, which rebuilds again once it has loaded.
    function resolveTheme() {
        root.themeName = root.previewThemeName !== "" ? root.previewThemeName
            : root.selectedThemeName !== "" ? root.selectedThemeName
            : root.configThemeName;
    }

    function previewTheme(name) {
        const wanted = String(name || "").trim();
        if (wanted === "" || wanted === root.previewThemeName) return false;
        root.previewThemeName = wanted;
        root.resolveTheme();
        return true;
    }

    function endPreview() {
        if (root.previewThemeName === "") return false;
        root.previewThemeName = "";
        root.resolveTheme();
        return true;
    }

    // Defaults, then the theme, then the user. Rebuilt from scratch every time rather than patched,
    // so removing a line from either file puts back what it was covering up.
    function rebuild() {
        themeScan.running = true;
        root.resetDefaults();
        const overridden = {};
        root.applyText(root.parentThemeText, overridden);
        root.applyText(root.themeText, overridden);
        root.applyText(root.configText, overridden);
        root.applyText(root.settingsText, overridden);
        root.updateDerived(overridden);
    }

    // Pick a theme and keep it. The palette changes as soon as the name does; writing the state
    // file is what makes the pick outlast the session, and is also how another shell instance
    // hears about it, since they all watch the same file.
    //
    // An unknown name is refused rather than applied: applying it would drop the shell to the
    // built-in defaults, which looks like a theme that exists and is simply ugly.
    function selectTheme(name) {
        const wanted = String(name || "").trim();
        if (wanted === "") return false;
        // Checked against the snapshot so a mistyped name is refused while the caller is still
        // listening, rather than a moment later in the shell's log. The load itself is the real
        // check, and puts the old theme back if this one was wrong.
        if (root.availableThemes.length > 0 && root.availableThemes.indexOf(wanted) === -1) return false;

        // Its file is already loaded -- it is what is on screen, either because it was previewed
        // or because it was already chosen. There is no load to wait for, so commit now: waiting
        // for an onLoaded that will never fire again would leave the pick unwritten.
        if (wanted === root.committedThemeName) {
            root.previewThemeName = "";
            root.pendingSelection = "";
            root.previousSelection = root.selectedThemeName;
            root.selectedThemeName = wanted;
            root.resolveTheme();
            selectionWriter.setText(wanted + "\n");
            return true;
        }

        root.previewThemeName = "";
        root.previousSelection = root.selectedThemeName;
        root.pendingSelection = wanted;
        root.selectedThemeName = wanted;
        root.resolveTheme();
        return true;
    }

    // Back to whatever config.toml says, by forgetting the pick rather than by picking again.
    function clearThemeSelection() {
        root.previousSelection = root.selectedThemeName;
        root.pendingSelection = "";
        root.selectedThemeName = "";
        root.resolveTheme();
        selectionWriter.setText("\n");
        return true;
    }

    // Change one setting and keep it. The whole file is rewritten from a map rather than patched
    // line by line: it is the shell's own file, nobody hand-edits it, and rewriting means a key
    // set twice cannot end up in it twice.
    function setSetting(key, value) {
        const name = String(key || "").trim();
        if (name === "") return false;

        const values = {};
        const lines = root.settingsText.split("\n");
        for (let i = 0; i < lines.length; i++) {
            const line = root.stripTomlComment(lines[i]);
            const eq = line.indexOf("=");
            if (eq < 0) continue;
            values[line.slice(0, eq).trim()] = line.slice(eq + 1).trim();
        }

        values[name] = typeof value === "string" ? ('"' + value + '"') : String(value);

        const out = ["# Written by EpochShell. Settings changed from a control in the shell land",
                     "# here, and win over both the selected theme and config.toml.", ""];
        for (const k in values) out.push(k + " = " + values[k]);
        settingsWriter.setText(out.join("\n") + "\n");
        return true;
    }

    // Settings, watched the same way the pick is, so a change made in one instance reaches the rest.
    FileView {
        path: root.settingsPath
        watchChanges: true
        printErrors: false
        onLoaded: {
            root.settingsText = text();
            root.rebuild();
        }
        // No settings file is the ordinary state of a fresh install.
        onLoadFailed: {
            root.settingsText = "";
            root.rebuild();
        }
        onFileChanged: reload()
    }

    FileView {
        id: settingsWriter
        path: root.settingsPath
        printErrors: false
        atomicWrites: true
    }

    // The pick, watched so a change made by another instance -- or by hand -- arrives here too.
    FileView {
        id: selectionFile
        path: root.selectionPath
        watchChanges: true
        printErrors: false

        onLoaded: {
            root.selectedThemeName = String(text()).trim();
            root.resolveTheme();
        }

        // No pick yet is the ordinary state of a fresh install, not an error.
        onLoadFailed: {
            root.selectedThemeName = "";
            root.resolveTheme();
        }

        onFileChanged: reload()
    }

    // Writing through the watched view would have it fight its own change notification, so the
    // write goes through a second view of the same file that does not watch it. The directory has
    // to exist before anything can be written into it, which nothing else here guarantees.
    Process {
        id: stateDirMaker
        command: ["mkdir", "-p", root.stateDir]
        running: true
    }

    FileView {
        id: selectionWriter
        path: root.selectionPath
        printErrors: false
        atomicWrites: true
    }
}
