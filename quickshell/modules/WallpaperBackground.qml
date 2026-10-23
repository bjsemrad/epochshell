import QtQuick
import qs.commonwidgets
import Quickshell
import Quickshell.Wayland
import qs.theme as T
import qs.services as S

Scope {
    id: root

    // Sticky: a daemon restart briefly reports no backend, which would blank the desktop.
    property bool drawing: false

    function follow() {
        if (S.Wallpaper.backend === "shell") root.drawing = true;
        else if (S.Wallpaper.backend === "hyprpaper") root.drawing = false;
    }

    Component.onCompleted: follow()

    Connections {
        target: S.Wallpaper
        function onBackendChanged() {
            root.follow();
        }
    }

    Variants {
        model: root.drawing ? Quickshell.screens : []

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "epochshell-wallpaper"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: T.Config.background
            mask: Region {}

            readonly property string wanted: S.Wallpaper.current
            readonly property string fitMode: S.Wallpaper.fitMode

            property Image front: imageA
            property Image incoming: null

            readonly property int fill: {
                switch (fitMode) {
                case "contain":
                    return Image.PreserveAspectFit;
                case "tile":
                    return Image.Tile;
                // hyprpaper's "fill" and hyprctl's "fit" both mean stretch.
                case "stretch":
                case "fill":
                case "fit":
                    return Image.Stretch;
                default:
                    return Image.PreserveAspectCrop;
                }
            }

            readonly property real pixelRatio: modelData.devicePixelRatio || 1
            readonly property size decodeSize: fill === Image.Tile
                ? Qt.size(0, 0)
                : Qt.size(Math.ceil(modelData.width * pixelRatio), Math.ceil(modelData.height * pixelRatio))

            onWantedChanged: show(wanted)
            Component.onCompleted: show(wanted)

            // Each path segment is escaped: a # or ? in a file name would be read as a fragment or
            // query.
            function urlFor(path) {
                return "file://" + path.split("/").map(encodeURIComponent).join("/");
            }

            function show(path) {
                if (win.incoming && path && String(win.incoming.source) === urlFor(path)) return;
                settle();
                if (!path) {
                    imageA.source = "";
                    imageB.source = "";
                    return;
                }
                const url = urlFor(path);
                if (String(win.front.source) === url && win.front.status === Image.Ready) return;

                const back = win.front === imageA ? imageB : imageA;
                win.incoming = back;
                back.opacity = 0;
                back.z = 1;
                win.front.z = 0;
                back.source = url;
                // An image already in memory can be Ready before onStatusChanged fires.
                if (back.status === Image.Ready) fade.begin(back);
            }

            function settle() {
                const coming = win.incoming;
                if (!coming) return;
                win.incoming = null;
                fade.stop();
                if (coming.status === Image.Ready) {
                    coming.opacity = 1;
                    const old = win.front;
                    win.front = coming;
                    old.source = "";
                } else {
                    coming.source = "";
                }
            }

            function arrived(image) {
                if (image !== win.incoming) return;
                if (image.status === Image.Ready) {
                    fade.begin(image);
                } else if (image.status === Image.Error) {
                    console.log("wallpaper: cannot load", image.source);
                    win.incoming = null;
                    image.source = "";
                }
            }

            NumberAnimation {
                id: fade
                property: "opacity"
                to: 1
                duration: Ui.wallpaperFadeMs
                easing.type: Easing.InOutQuad

                function begin(image) {
                    fade.target = image;
                    fade.from = image.opacity;
                    fade.restart();
                }

                onFinished: win.settle()
            }

            Image {
                id: imageA
                anchors.fill: parent
                asynchronous: true
                // Uncached: Qt's cache would keep every full-screen image stepped past in the
                // picker.
                cache: false
                smooth: true
                fillMode: win.fill
                sourceSize: win.decodeSize
                onStatusChanged: win.arrived(imageA)
            }

            Image {
                id: imageB
                anchors.fill: parent
                asynchronous: true
                cache: false
                smooth: true
                opacity: 0
                fillMode: win.fill
                sourceSize: win.decodeSize
                onStatusChanged: win.arrived(imageB)
            }
        }
    }
}
