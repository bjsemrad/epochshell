import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme as T
import qs.services as S

// The wallpaper itself, when this shell is what draws it: one background-layer surface per screen,
// showing whatever EpochOxide says is current.
//
// Only when EpochOxide reports `backend: "shell"`. Under hyprpaper this builds nothing at all, so
// the two never stack up and nothing is decoded twice. See wallpaper.rs for how the backend is
// chosen.
//
// On niri, the overview draws its backdrop rather than the background layer, so the wallpaper only
// shows behind the zoomed-out workspaces with a layer rule naming this surface:
//
//     layer-rule {
//         match namespace="^epochshell-wallpaper$"
//         place-within-backdrop true
//     }
Scope {
    id: root

    // Sticky: only an explicit answer changes it. A daemon restart briefly reports no backend at
    // all, and treating that as "stop drawing" would blank the desktop for as long as it takes.
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
            // Opaque on purpose, unlike every other surface here: nothing is meant to show through a
            // wallpaper, and an opaque surface is one the compositor can skip blending. This is
            // also what shows before the first image has decoded, and around a transparent one.
            color: T.Config.background
            // The desktop is not this surface's to click on.
            mask: Region {}

            readonly property string wanted: S.Wallpaper.current
            readonly property string fitMode: S.Wallpaper.fitMode

            // Two images, crossfaded: the new one decodes behind the old and fades in once it is
            // ready, so a switch never shows an empty frame -- and stepping through the picker
            // looks like a slideshow rather than a flicker.
            property Image front: imageA
            // The image being brought in, or null between switches.
            property Image incoming: null

            readonly property int fill: {
                switch (fitMode) {
                case "contain":
                    return Image.PreserveAspectFit;
                case "tile":
                    return Image.Tile;
                // hyprpaper.conf calls stretching "fill" and hyprctl calls it "fit"; all three words
                // mean the same thing here.
                case "stretch":
                case "fill":
                case "fit":
                    return Image.Stretch;
                default:
                    return Image.PreserveAspectCrop;
                }
            }

            // Decode at the size it will be shown, not the size of the file: an 8K image on a 1440p
            // screen is otherwise four times the memory for nothing. Tiles are left at their own
            // size (0 means unconstrained), since scaling those is exactly what tiling is not.
            //
            // Taken from the screen, not the window. The window passes through placeholder sizes
            // (100, 0, 500) before the compositor configures it, and every change of this size
            // restarts the decode -- measured at four decodes of the first image at startup.
            readonly property real pixelRatio: modelData.devicePixelRatio || 1
            readonly property size decodeSize: fill === Image.Tile
                ? Qt.size(0, 0)
                : Qt.size(Math.ceil(modelData.width * pixelRatio), Math.ceil(modelData.height * pixelRatio))

            onWantedChanged: show(wanted)
            Component.onCompleted: show(wanted)

            // Paths go into a URL, so each segment is escaped: a `#` or `?` in a file name would
            // otherwise be read as a fragment or a query and the image would not be found.
            function urlFor(path) {
                return "file://" + path.split("/").map(encodeURIComponent).join("/");
            }

            function show(path) {
                // Asked again for what is already on its way: the window's own startup does this,
                // and so do the two connections Wallpaper.qml keeps, which both hear of a switch.
                if (win.incoming && path && String(win.incoming.source) === urlFor(path)) return;
                // Mid-fade, the one fading in wins straight away; mid-decode, it is dropped. Only
                // the latest choice is worth waiting for.
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
                // An image already in memory can be Ready before onStatusChanged has anything to
                // report.
                if (back.status === Image.Ready) fade.begin(back);
            }

            // Finish whatever switch is under way: completed if its image arrived, abandoned if not.
            function settle() {
                const coming = win.incoming;
                if (!coming) return;
                win.incoming = null;
                fade.stop();
                if (coming.status === Image.Ready) {
                    coming.opacity = 1;
                    const old = win.front;
                    win.front = coming;
                    // Let the old decode go: two full-screen images per screen is the most this
                    // should ever hold, and only for the length of a fade.
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
                duration: 450
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
                // Held by this item only. Qt's cache would keep every image stepped past in the
                // picker alive, which is a lot of memory for full-screen pictures.
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
