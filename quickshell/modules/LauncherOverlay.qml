import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.commonwidgets
import qs.services as S
import qs.theme as T

PanelWindow {
    id: root
    readonly property int pdfThumbnailPx: 512
    readonly property int previewTextBytes: 16000
    readonly property int previewImagePx: 1024
    readonly property int clipboardPreviewChars: 60

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusiveZone: 0
    focusable: true
    readonly property string screenName: {
        const focused = S.CompositorService.monitors.find(m => m.focused === true);
        if (focused) return String(focused.name);
        return Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "";
    }
    screen: Quickshell.screens.find(s => s.name === root.screenName) || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
    WlrLayershell.namespace: "epochshell-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: _visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    readonly property bool ledgeMode: T.Config.barIsLedge && T.Config.launcherStyle !== "floating"

    property int currentIndex: -1
    // Hover only takes the selection after a real pointer move: rows appearing under a resting
    // pointer also deliver hover events.
    property bool hoverSelects: false
    property point hoverPoint: Qt.point(-1, -1)
    property bool hoverPointKnown: false
    property bool selectionAtTop: true

    function resetSelection() {
        root.hoverSelects = false;
        root.hoverPointKnown = false;
        root.selectionAtTop = true;
    }

    // Qt re-delivers hover at the same position when rows move under a resting pointer; only a
    // changed position is a real move.
    function hoverMoved(point) {
        const moved = root.hoverPointKnown
            && (point.x !== root.hoverPoint.x || point.y !== root.hoverPoint.y);
        root.hoverPoint = point;
        root.hoverPointKnown = true;
        return moved;
    }

    function selectRow(index) {
        root.selectionAtTop = false;
        if (root.currentIndex === index) return;
        root.currentIndex = index;
        listView.currentIndex = index;
    }
    property bool _visible: false
    property bool showingProviders: false
    readonly property bool backendDown: S.LauncherService.backendError.length > 0

    ListModel {
        id: providerModel
    }

    function appendProviderRow(name, prefix, text, subtext, icon) {
        providerModel.append({
            provider: "provider",
            name: name,
            identifier: prefix,
            text: text,
            subtext: subtext,
            icon: icon || "",
            action: "",
            preview: "",
            previewType: ""
        });
    }

    function providerFilter() {
        return root.showingProviders ? inputField.text.trim().toLowerCase() : "";
    }

    function providerMatches(filter, name, label, description, prefix) {
        if (filter.length === 0) return true;
        return [name, label, description, prefix]
            .some(field => String(field || "").toLowerCase().indexOf(filter) !== -1);
    }

    function buildProviderMenu() {
        const filter = root.providerFilter();
        providerModel.clear();
        for (const cap of S.LauncherService.providerCapabilities) {
            if (!cap.supportsQuery) continue;
            const prefix = cap.prefixes.length > 0 ? cap.prefixes[0] : "";
            if (!root.providerMatches(filter, cap.name, cap.namePretty, cap.description, prefix)) continue;
            root.appendProviderRow(cap.name, prefix, cap.namePretty, cap.description, cap.icon);
        }
        if (root.providerMatches(filter, "all", "All providers", "Search across every provider", S.LauncherService.allPrefix)) {
            root.appendProviderRow(S.LauncherService.allPrefix, S.LauncherService.allPrefix, "All providers", "Search across every provider", "");
        }
        root.resetSelection();
        root.currentIndex = providerModel.count > 0 ? 0 : -1;
        listView.currentIndex = root.currentIndex;
    }

    visible: _visible

    function open() {
        S.PopupManager.closeAll();
        panelAnimate = false;
        inputField.text = "";
        S.LauncherService.setScope("");
        showingProviders = false;
        resetSelection();
        currentIndex = -1;
        previewVisible = false;
        previewText = "";
        previewImage = "";
        previewProvider = "";
        previewSubtext = "";
        _visible = true;
        S.LauncherService.refreshProviders();
        S.LauncherService.setQuery("");
        inputField.forceActiveFocus();
        panelAnimateTimer.start();
    }

    Timer {
        id: panelAnimateTimer
        interval: Ui.launcherAnimateDelay
        repeat: false
        onTriggered: root.panelAnimate = true
    }

    function close() {
        _visible = false;
        inputField.text = "";
        S.LauncherService.setScope("");
        showingProviders = false;
        resetSelection();
        currentIndex = -1;
        listView.currentIndex = -1;
    }

    function toggle() {
        if (_visible) {
            close();
        } else {
            open();
        }
    }

    Component.onDestruction: S.PopupManager.unregisterLauncher(root)

    function chooseProviderRow(row) {
        root.scopeTo(row.name);
    }

    function scopeTo(name) {
        root.showingProviders = false;
        root.resetSelection();
        S.LauncherService.setScope(name);
        inputField.text = "";
        inputField.forceActiveFocus();
    }

    property string pendingProvider: ""

    function openProviders() {
        root.open();
        root.showingProviders = true;
        root.buildProviderMenu();
        inputField.forceActiveFocus();
    }

    function openProvider(name) {
        root.open();
        root.pendingProvider = name;
        root.applyPendingProvider();
    }

    function applyPendingProvider() {
        if (root.pendingProvider.length === 0) return;
        const name = root.pendingProvider;
        root.pendingProvider = "";
        root.scopeTo(name);
    }

    // Read the model, not listView.itemAtIndex(): delegates do not exist yet on the first
    // population of a freshly shown window.
    function rowAt(index) {
        const model = root.showingProviders ? providerModel : S.LauncherService.results;
        if (index < 0 || index >= model.count) return null;
        return model.get(index);
    }

    function activateCurrent() {
        if (currentIndex < 0) return;
        const row = root.rowAt(currentIndex);
        if (!row) return;
        if (root.showingProviders) {
            root.chooseProviderRow(row);
            return;
        }
        S.LauncherService.activate(row.provider, row.identifier, row.action);
        close();
    }

    function defaultScope() {
        return S.LauncherService.providerAvailable("apps") ? "apps" : "";
    }

    function scopedProvider() {
        const typed = S.LauncherService.prefixFor(inputField.text);
        if (typed.length === 0 && S.LauncherService.scope.length > 0) return S.LauncherService.scope;
        const prefix = typed;
        if (prefix.length > 0) return prefix === S.LauncherService.allPrefix ? "" : S.LauncherService.providerForPrefix(prefix);
        if (S.LauncherService.providerAvailable("calc") && S.LauncherService.isMathQuery(inputField.text)) return "calc";
        return root.defaultScope();
    }

    function scopeLabel() {
        if (root.showingProviders) return "Choose provider";
        if (S.LauncherService.prefixFor(inputField.text) === S.LauncherService.allPrefix) return "All providers";
        const provider = root.scopedProvider();
        if (provider === S.LauncherService.allPrefix) return "All providers";
        return provider.length > 0 ? S.LauncherService.prettyName(provider) : "All providers";
    }

    function activeProvider() {
        if (root.showingProviders) return "";
        const provider = root.scopedProvider();
        if (provider === S.LauncherService.allPrefix) return "";
        return provider.indexOf(",") === -1 ? provider : "";
    }

    function chipActive(name, prefix) {
        if (root.showingProviders) return false;
        const typed = S.LauncherService.prefixFor(inputField.text);
        if (typed.length > 0) return typed === prefix;
        return name === root.scopedProvider();
    }

    function providerLabel(name, identifier) {
        if (name === "provider") return identifier || "→";
        return name;
    }

    property bool previewVisible: false
    property string previewProvider: ""
    property string previewTitle: ""
    property string previewText: ""
    property url previewImage: ""
    property string previewSubtext: ""
    property int previewReqCounter: 0
    property bool panelAnimate: true

    readonly property int previewTextMax: 4000
    readonly property var nativeImageExtensions: ["png", "jpg", "jpeg", "gif", "bmp", "ico", "svg"]
    readonly property var convertibleImageExtensions: ["pdf", "heic", "heif", "webp", "tiff", "tif", "avif", "tga", "icns"]
    readonly property string previewCacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/epochshell/previews"

    function truncate(text, max) {
        if (typeof text !== "string") return "";
        return text.length > max ? text.slice(0, max) + "…" : text;
    }

    function fileUrl(path) {
        return Qt.resolvedUrl(path);
    }

    function fileExtension(path) {
        const idx = path.lastIndexOf(".");
        return idx < 0 ? "" : path.slice(idx + 1).toLowerCase();
    }

    function isNativeImagePath(path) {
        return nativeImageExtensions.indexOf(fileExtension(path)) !== -1;
    }

    function isConvertibleImagePath(path) {
        return convertibleImageExtensions.indexOf(fileExtension(path)) !== -1;
    }

    function pathStamp(path) {
        let h = 0x811c9dc5;
        for (let i = 0; i < path.length; i++) {
            h ^= path.charCodeAt(i) & 0xff;
            h = Math.imul(h, 0x01000193);
        }
        return (h >>> 0).toString(16).padStart(8, "0");
    }

    function requestThumbnail(path) {
        const cache = root.previewCacheDir + "/" + root.pathStamp(path) + ".png";
        const ext = root.fileExtension(path);
        const convert = ext === "pdf"
            ? "pdftoppm -f 1 -l 1 -png -singlefile -scale-to " + root.pdfThumbnailPx + " \"$1\" \"${2%.png}\""
            : "convert \"$1[0]\" -thumbnail 512x512 -background none \"$2\"";
        previewThumbProc.running = false;
        previewThumbProc.previewReq = root.previewReqCounter = root.previewReqCounter + 1;
        previewThumbProc.targetCache = cache;
        previewThumbProc.command = [
            "sh", "-c",
            "mkdir -p \"$(dirname \"$2\")\" && { [ -f \"$2\" ] || " + convert + "; }",
            "sh", path, cache
        ];
        previewThumbProc.running = true;
    }

    function refreshPreview() {
        previewTimer.stop();
        previewReqCounter++;
        if (!_visible) {
            previewVisible = false;
            return;
        }
        const row = root.rowAt(currentIndex);
        if (!row) {
            previewVisible = false;
            previewText = "";
            previewImage = "";
            return;
        }
        const provider = String(row.provider || "");
        const preview = String(row.preview || "");
        if ((provider === "files" || provider === "clipboard") && preview.length > 0) {
            previewVisible = true;
            previewProvider = provider;
            previewTitle = provider === "clipboard" ? "CLIPBOARD" : "FILE";
            previewSubtext = row.text;
            if (row.previewType === "text") {
                previewText = root.truncate(preview, root.previewTextMax);
                previewImage = "";
            } else if (isNativeImagePath(preview)) {
                previewText = "";
                previewImage = root.fileUrl(preview);
            } else if (isConvertibleImagePath(preview)) {
                previewText = "";
                previewImage = "";
                root.requestThumbnail(preview);
            } else {
                previewText = "";
                previewImage = "";
                previewFileProc.running = false;
                previewFileProc.previewReq = root.previewReqCounter = root.previewReqCounter + 1;
                previewFileProc.command = [
                    "sh", "-c",
                    "if [ -d \"$1\" ]; then ls -A \"$1\" | head -c " + root.previewTextBytes + "; else head -c " + root.previewTextBytes + " \"$1\" 2>/dev/null; fi",
                    "sh", preview
                ];
                previewFileProc.running = true;
            }
            return;
        }
        previewVisible = false;
        previewText = "";
        previewImage = "";
    }

    Timer {
        id: previewTimer
        interval: Ui.previewDelay
        repeat: false
        onTriggered: root.refreshPreview()
    }

    Process {
        id: previewFileProc
        property int previewReq: -1
        stdout: StdioCollector {
            id: previewFileOut
            waitForEnd: true
            onStreamFinished: {
                if (previewFileProc.previewReq !== root.previewReqCounter) return;
                const out = text || "";
                root.previewText = out.trim().length > 0 ? root.truncate(out, 16000) : "";
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (previewFileProc.previewReq !== root.previewReqCounter) return;
                if ((text || "").trim().length > 0 && root._visible && root.previewProvider === "files") {
                    root.previewText = "";
                }
            }
        }
    }

    Process {
        id: previewThumbProc
        property int previewReq: -1
        property string targetCache: ""
        onExited: function (exitCode, exitStatus) {
            if (previewThumbProc.previewReq !== root.previewReqCounter) return;
            if (exitCode === 0) root.previewImage = root.fileUrl(previewThumbProc.targetCache);
        }
    }

    onCurrentIndexChanged: previewTimer.restart()

    // Escape is handled on the field: Keys cannot attach to a PanelWindow (it is not an Item).

    readonly property string mode: root.showingProviders ? "providers" : root.activeProvider()
    readonly property bool split: mode === "files" || mode === "clipboard"
    readonly property int listWidth: Ui.launcherWidth
    readonly property int keybindsWidth: Math.min(Math.round(root.width * Ui.launcherScreenFraction), Ui.launcherKeybindsWidth)
    readonly property int splitWidth: Math.min(Math.round(root.width * Ui.launcherScreenFraction), Ui.launcherSplitWidth)
    readonly property int panelWidth: split ? splitWidth : mode === "keybinds" ? keybindsWidth : listWidth
    readonly property int maxHeight: Math.min(Math.round(root.height * Ui.launcherScreenFraction), Ui.launcherMaxHeight)
    readonly property int rowHeight: Ui.rowHeight
    readonly property int promptHeight: Ui.launcherPromptHeight

    readonly property string promptGlyph: {
        if (root.showingProviders) return ";";
        const typed = S.LauncherService.prefixFor(inputField.text);
        if (typed.length > 0) return typed;
        const scoped = S.LauncherService.scope;
        if (scoped.length > 0) {
            const prefix = S.LauncherService.prefixForProvider(scoped);
            if (prefix.length > 0) return prefix;
        }
        return "›";
    }

    function baseName(path) {
        const p = String(path || "").replace(/\/+$/, "");
        return p.slice(p.lastIndexOf("/") + 1) || p;
    }
    function homeRelativeDir(path) {
        const p = String(path || "").replace(/\/+$/, "");
        const dir = p.slice(0, Math.max(0, p.lastIndexOf("/")));
        const home = Quickshell.env("HOME") || "";
        return home.length > 0 && dir.indexOf(home) === 0 ? "~" + dir.slice(home.length) : dir;
    }

    function glyphIcon(icon) {
        return icon.length > 0 && icon.length <= 2 && icon.charCodeAt(0) > 0x2000;
    }
    function enterLabel(row) {
        if (root.showingProviders) return "↵ open";
        const action = String(row.action || "").toLowerCase();
        if (action.length > 0 && action.length <= 12) return "↵ " + action;
        return row.provider === "clipboard" ? "↵ copy" : row.provider === "calc" ? "↵ copy" : row.provider === "run" ? "↵ run" : "↵ open";
    }
    function statusFor(row) {
        if (root.showingProviders) {
            if (row.name === "apps") return "default";
            return String(row.identifier || "");
        }
        if (row.provider === "apps") {
            const id = String(row.identifier || "").replace(/\.desktop$/, "");
            const window = id.length > 0 ? S.CompositorService.findWindow(id) : null;
            return window ? "on " + window.workspace : "";
        }
        if (row.provider === "windows") {
            const window = S.CompositorService.windows.find(w => String(w.id) === String(row.identifier));
            if (!window) return "";
            return "ws " + window.workspace + (S.CompositorService.isNiri && !window.floating ? " · col " + (Number(window.x) || 0) : "");
        }
        if (root.mode !== row.provider && root.mode !== "providers") return S.LauncherService.prettyName(row.provider).toLowerCase();
        return "";
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.ledgeMode
        color: Qt.rgba(0, 0, 0, Ui.backdropAlpha)
    }

    BackgroundEffect.blurRegion: (root.ledgeMode ? T.Config.barBlur : T.Config.popupBlur) ? launcherBlur : null
    Region {
        id: launcherBlur
        Region {
            item: panel
            radius: T.Config.popupRadius
        }
        Region {
            x: panel.x
            y: panel.y
            width: panel.width
            height: root.ledgeMode ? Math.min(panel.height, T.Config.popupRadius) : 0
        }
    }

    AttachedSurface {
        id: ledgeShape
        visible: root.ledgeMode
        x: Math.round((root.width - width) / 2)
        y: 0
        width: panel.width
        height: panel.height
        flare: 0
        radius: T.Config.popupRadius
        fillColor: T.Config.barBackground
        outlineOpacity: 1
    }

    Rectangle {
        id: panel
        width: root.panelWidth
        height: Math.min(content.implicitHeight, root.maxHeight)
        x: Math.round((root.width - width) / 2)
        y: root.ledgeMode ? 0 : Math.round(root.height * Ui.launcherTop)
        radius: root.ledgeMode ? 0 : T.Config.popupRadius
        antialiasing: true
        color: root.ledgeMode ? "transparent" : T.Config.popupBackground
        border.width: root.ledgeMode ? 0 : 1
        border.color: T.Config.outline
        clip: true

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        ColumnLayout {
            id: content
            width: parent.width
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: root.promptHeight
                Layout.leftMargin: Ui.launcherInset
                Layout.rightMargin: Ui.launcherInset
                spacing: Ui.spaceXL

                Text {
                    text: root.promptGlyph
                    color: T.Config.accent
                    font.pixelSize: Ui.valueSize + 2
                    font.family: Ui.font
                }

                TextInput {
                    id: inputField
                    Layout.fillWidth: true
                    color: Ui.value
                    font.pixelSize: Ui.valueSize + 2
                    font.family: Ui.font
                    clip: true
                    selectedTextColor: T.Config.background
                    selectionColor: T.Config.accent
                    selectByMouse: true
                    activeFocusOnTab: false

                    Keys.onPressed: event => {
                        if (event.key !== Qt.Key_Backspace) return;
                        if (inputField.text.length > 0) return;
                        if (root.showingProviders) {
                            root.showingProviders = false;
                            S.LauncherService.setQuery("");
                            event.accepted = true;
                            return;
                        }
                        if (S.LauncherService.scope.length === 0) return;
                        S.LauncherService.setScope("");
                        event.accepted = true;
                    }
                    Keys.onDownPressed: event => {
                        root.moveSelection(1);
                        event.accepted = true;
                    }
                    Keys.onUpPressed: event => {
                        root.moveSelection(-1);
                        event.accepted = true;
                    }
                    Keys.onTabPressed: event => {
                        root.moveSelection(1);
                        event.accepted = true;
                    }
                    Keys.onReturnPressed: event => {
                        root.activateCurrent();
                        event.accepted = true;
                    }
                    Keys.onEscapePressed: event => {
                        root.close();
                        event.accepted = true;
                    }

                    onTextChanged: {
                        root.resetSelection();
                        if (!root.showingProviders && text === ";") {
                            // Set the mode before clearing the text: clearing re-enters this
                            // handler.
                            root.showingProviders = true;
                            inputField.text = "";
                            root.buildProviderMenu();
                            S.LauncherService.setQuery("");
                            return;
                        }
                        if (root.showingProviders) {
                            root.buildProviderMenu();
                            return;
                        }
                        S.LauncherService.setQuery(text);
                    }
                }

                Text {
                    text: {
                        if (S.LauncherService.searching) return "searching…";
                        const label = root.showingProviders ? "providers" : root.scopeLabel().toLowerCase();
                        return label + (root.mode === "apps" ? " · ; for providers" : "");
                    }
                    color: Ui.key
                    font.pixelSize: Ui.detailSize
                    font.family: Ui.font
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Ui.divider
            }

            RowLayout {
                visible: root.mode === "calc" && listView.count > 0
                Layout.fillWidth: true
                Layout.leftMargin: Ui.launcherInset
                Layout.rightMargin: Ui.launcherInset
                Layout.topMargin: Ui.spaceL
                Layout.bottomMargin: Ui.spaceL
                spacing: Ui.space2XL
                Text {
                    Layout.fillWidth: true
                    text: { const row = root.rowAt(0); return row ? String(row.text) : ""; }
                    color: Ui.value
                    font.pixelSize: Ui.calcSize
                    font.family: Ui.font
                    elide: Text.ElideRight
                }
                Text {
                    text: "↵ copy"
                    color: Ui.detail
                    font.pixelSize: Ui.detailSize
                    font.family: Ui.font
                }
            }

            RowLayout {
                visible: !(root.mode === "calc")
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(Math.max(listView.contentHeight, root.rowHeight) + Ui.spaceM + Ui.space2XL,
                    root.maxHeight - root.promptHeight - 1)
                spacing: 0

                Item {
                    Layout.preferredWidth: root.split ? Math.round(root.panelWidth * Ui.launcherListFraction) : root.panelWidth
                    Layout.fillHeight: true

                    ListView {
                        id: listView
                        anchors.fill: parent
                        anchors.topMargin: Ui.spaceM
                        anchors.bottomMargin: Ui.space2XL
                        clip: true
                        model: root.showingProviders ? providerModel : S.LauncherService.results
                        spacing: 0
                        focus: false
                        boundsBehavior: Flickable.StopAtBounds
                        keyNavigationWraps: true

                        section.property: root.mode === "apps" ? "provider" : ""
                        section.delegate: Item {
                            required property string section
                            width: listView.width
                            height: section === "apps" ? 0 : Ui.sectionLabelHeight
                            visible: section !== "apps"
                            Text {
                                x: Ui.launcherInset
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: Ui.spaceS
                                text: S.LauncherService.prettyName(section).toLowerCase()
                                color: Ui.key
                                font.pixelSize: Ui.detailSize
                                font.family: Ui.font
                            }
                        }

                        delegate: Item {
                            id: delegateRoot
                            required property int index
                            required property string provider
                            required property string identifier
                            required property string text
                            required property string subtext
                            required property string icon
                            required property string action
                            required property string preview
                            required property string previewType
                            readonly property bool isCurrent: root.currentIndex === index
                            readonly property bool appIcon: (provider === "apps" || provider === "windows") && icon.length > 0 && !root.glyphIcon(icon)
                            readonly property string name: root.showingProviders ? (listView.model.get(index) ? String(listView.model.get(index).name || "") : "") : ""
                            readonly property bool keycaps: provider === "keybinds" && keysPart.length > 0
                            readonly property string keysPart: provider === "keybinds" ? subtext.split(" · ")[0].trim() : ""
                            readonly property string commandPart: provider === "keybinds" ? subtext.split(" · ").slice(1).join(" · ").trim() : ""

                            width: listView.width
                            height: root.rowHeight

                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: Ui.spaceXL
                                anchors.rightMargin: Ui.spaceXL
                                radius: Ui.hoverRadius
                                color: delegateRoot.isCurrent ? Ui.hover : "transparent"
                            }
                            Rectangle {
                                visible: delegateRoot.isCurrent
                                x: Ui.spaceXL
                                anchors.verticalCenter: parent.verticalCenter
                                width: Ui.tick
                                height: parent.height - Ui.rowHoverInset
                                color: T.Config.accent
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Ui.launcherInset
                                anchors.rightMargin: Ui.launcherInset
                                spacing: Ui.spaceXL

                                Item {
                                    Layout.preferredWidth: Ui.iconColumn
                                    Layout.preferredHeight: Ui.iconSize
                                    Image {
                                        id: iconImage
                                        anchors.centerIn: parent
                                        width: Ui.iconSize
                                        height: Ui.iconSize
                                        visible: delegateRoot.icon.length > 0 && !root.glyphIcon(delegateRoot.icon) && status === Image.Ready
                                        source: delegateRoot.icon.length > 0 && !root.glyphIcon(delegateRoot.icon) ? "image://icon/" + delegateRoot.icon : ""
                                        sourceSize.width: Ui.appIconSource
                                        sourceSize.height: Ui.appIconSource
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        visible: !iconImage.visible
                                        text: root.glyphIcon(delegateRoot.icon) ? delegateRoot.icon
                                            : delegateRoot.provider === "provider" ? (delegateRoot.identifier.length > 0 ? delegateRoot.identifier : "󰀻")
                                            : delegateRoot.provider === "clipboard" ? "󰅌"
                                            : delegateRoot.provider === "files" ? "󰈔"
                                            : delegateRoot.provider === "run" ? "󰆍"
                                            : delegateRoot.provider === "calc" ? "󰃬"
                                            : (delegateRoot.text.length > 0 ? delegateRoot.text.charAt(0).toUpperCase() : "?")
                                        color: delegateRoot.isCurrent ? T.Config.accent : Ui.detail
                                        font.pixelSize: Ui.iconSize
                                        font.family: Ui.font
                                    }
                                }

                                Text {
                                    Layout.preferredWidth: delegateRoot.keycaps ? Math.min(implicitWidth, delegateRoot.width * Ui.keybindNameFraction) : Math.min(implicitWidth, delegateRoot.width * Ui.nameFraction)
                                    Layout.minimumWidth: 0
                                    text: delegateRoot.provider === "clipboard" ? root.truncate(delegateRoot.text.replace(/\s+/g, " "), root.clipboardPreviewChars)
                                        : delegateRoot.provider === "files" ? root.baseName(delegateRoot.text)
                                        : delegateRoot.text
                                    color: Ui.value
                                    font.pixelSize: Ui.valueSize
                                    font.family: Ui.font
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    text: delegateRoot.keycaps ? delegateRoot.commandPart
                                        : delegateRoot.provider === "clipboard" ? delegateRoot.subtext.replace(/\s+/g, " ")
                                        : delegateRoot.provider === "files" ? root.homeRelativeDir(delegateRoot.text)
                                        : delegateRoot.subtext
                                    color: Ui.detail
                                    font.pixelSize: Ui.detailSize
                                    font.family: Ui.font
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                Item {
                                    visible: delegateRoot.keycaps
                                    Layout.preferredWidth: caps.implicitWidth
                                    Layout.minimumWidth: caps.implicitWidth
                                    Layout.preferredHeight: parent.height
                                    Row {
                                        id: caps
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: Ui.spaceXS
                                        Repeater {
                                            model: delegateRoot.keycaps ? delegateRoot.keysPart.split("+").map(k => k.trim()).filter(k => k.length > 0) : []
                                            delegate: Rectangle {
                                                required property string modelData
                                                width: capText.implicitWidth + Ui.keycapPadX
                                                height: capText.implicitHeight + Ui.keycapPadY
                                                radius: Ui.keycapRadius
                                                color: "transparent"
                                                border.width: 1
                                                border.color: Ui.alpha(T.Config.surfaceText, Ui.keycapBorderAlpha)
                                                Text {
                                                    id: capText
                                                    anchors.centerIn: parent
                                                    text: modelData
                                                    color: Ui.value
                                                    font.pixelSize: Ui.detailSize - 1
                                                    font.family: Ui.font
                                                }
                                            }
                                        }
                                    }
                                }

                                Text {
                                    readonly property var row: ({ provider: delegateRoot.provider, identifier: delegateRoot.identifier, action: delegateRoot.action, name: delegateRoot.name })
                                    text: delegateRoot.isCurrent ? root.enterLabel(row) : root.statusFor(row)
                                    color: delegateRoot.isCurrent ? Ui.value : Ui.detail
                                    font.pixelSize: Ui.detailSize
                                    font.family: Ui.font
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: if (root.hoverSelects) root.selectRow(delegateRoot.index)
                                onPositionChanged: mouse => {
                                    if (!root.hoverMoved(delegateRoot.mapToItem(null, mouse.x, mouse.y))) return;
                                    root.hoverSelects = true;
                                    root.selectRow(delegateRoot.index);
                                }
                                onClicked: root.selectRow(delegateRoot.index)
                                onDoubleClicked: {
                                    root.selectRow(delegateRoot.index);
                                    root.activateCurrent();
                                }
                            }
                        }

                        onCountChanged: {
                            if (listView.count === 0) {
                                root.previewVisible = false;
                                root.currentIndex = -1;
                                return;
                            }
                            if (root.selectionAtTop || root.currentIndex < 0 || root.currentIndex >= listView.count) {
                                root.currentIndex = 0;
                                listView.currentIndex = 0;
                                listView.positionViewAtBeginning();
                            }
                            previewTimer.restart();
                        }
                    }

                    RowLayout {
                        visible: listView.count === 0 && !S.LauncherService.searching
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: Ui.spaceS
                        height: root.rowHeight
                        anchors.leftMargin: Ui.launcherInset
                        anchors.rightMargin: Ui.launcherInset
                        Text {
                            Layout.fillWidth: true
                            text: root.backendDown ? "launcher backend not running" : "no matches"
                            color: root.backendDown ? Ui.danger : Ui.detail
                            font.pixelSize: Ui.valueSize
                            font.family: Ui.font
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: !root.backendDown
                            text: "; providers"
                            color: Ui.key
                            font.pixelSize: Ui.detailSize
                            font.family: Ui.font
                        }
                    }
                }

                Rectangle {
                    visible: root.split
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: Ui.divider
                }

                ColumnLayout {
                    visible: root.split
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: Ui.space3XL
                    spacing: Ui.spaceL

                    Text {
                        Layout.fillWidth: true
                        text: {
                            const row = root.rowAt(root.currentIndex);
                            if (!row) return "";
                            const parts = [];
                            if (root.previewImage.toString().length > 0) parts.push(root.mode === "files" ? root.fileExtension(String(row.preview || "")) || "image" : "image");
                            else if (root.previewText.length > 0) parts.push(root.mode === "files" ? (root.fileExtension(String(row.preview || "")) || "text") : "text", root.previewText.length + " chars");
                            parts.push(root.enterLabel(row));
                            return parts.join(" · ");
                        }
                        color: Ui.key
                        font.pixelSize: Ui.detailSize
                        font.family: Ui.font
                        elide: Text.ElideRight
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.previewText.length > 0 && root.previewImage.toString().length === 0
                        clip: true
                        contentWidth: width
                        contentHeight: previewBody.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        Text {
                            id: previewBody
                            width: parent.width
                            text: root.previewText
                            color: Ui.value
                            font.pixelSize: Ui.detailSize
                            font.family: Ui.font
                            wrapMode: Text.WrapAnywhere
                            textFormat: Text.PlainText
                        }
                    }

                    Image {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.previewImage.toString().length > 0
                        source: root.previewImage
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        sourceSize.width: root.previewImagePx
                    }

                    Item {
                        Layout.fillHeight: true
                        visible: root.previewText.length === 0 && root.previewImage.toString().length === 0
                    }
                }
            }
        }
    }

    function moveSelection(delta) {
        const count = listView.count;
        if (count === 0) {
            currentIndex = -1;
            return;
        }
        hoverSelects = false;
        hoverPointKnown = false;
        selectionAtTop = false;
        currentIndex = (currentIndex + delta + count) % count;
        listView.currentIndex = currentIndex;
        listView.positionViewAtIndex(currentIndex, ListView.Center);
    }

    Connections {
        target: S.LauncherService
        function onProvidersUpdated() {
            root.buildProviderMenu();
            root.applyPendingProvider();
        }
        function onResultsUpdated() {
            if (!root._visible || root.showingProviders) return;
            if (listView.count === 0) {
                root.previewVisible = false;
                root.currentIndex = -1;
                listView.currentIndex = -1;
                return;
            }
            if (root.selectionAtTop || root.currentIndex < 0 || root.currentIndex >= listView.count) {
                root.currentIndex = 0;
                listView.currentIndex = 0;
                listView.positionViewAtBeginning();
            }
            previewTimer.restart();
        }
    }

    Component.onCompleted: {
        root.buildProviderMenu()
        S.PopupManager.registerLauncher(root)
    }
}
