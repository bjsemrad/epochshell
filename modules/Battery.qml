import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import "../commonwidgets" as CW

RowLayout {
    id: root

    property real percentage: 0
    property bool charging: false
    property string iconName: ""
    property color color: (!charging && percentage < 20) ? "red" : "white"

    Component.onCompleted: {
        if (UPower.displayDevice) {
            percentage = UPower.displayDevice.percentage
            charging   = (UPower.displayDevice.state === UPowerDeviceState.Charging)
            iconName   = iconForBattery()
        }
    }

    Connections {
        target: UPower.displayDevice

        function onPercentageChanged() {
            root.percentage = UPower.displayDevice.percentage
            root.iconName = iconForBattery()
        }

        function onStateChanged() {
            root.charging = (UPower.displayDevice.state === UPowerDeviceState.Charging)
            root.iconName = iconForBattery()
        }
    }

    function iconForBattery() {
      let pct = Math.round(root.percentage > 0 ? root.percentage * 100 : 1)
      let charging = root.charging
      function pick(base) {
          return charging
            ? `${base}-charging-symbolic`
            : `${base}-symbolic`
          }

      if (pct > 95) return pick("battery-full")
      if (pct > 70) return pick("battery-good")
      if (pct > 45) return pick("battery-medium")
      if (pct > 20) return pick("battery-low")
      if (pct > 5)  return pick("battery-caution")
      return pick("battery-empty")
    }

    IconImage {
        implicitSize: 16
        source: Quickshell.iconPath(root.iconName)
    }

    // Text {
    //     text: `${Math.round(percentage)}%`
    //     color: root.color
    //     font.pixelSize: 12
    // }
}


// import QtQuick
// import QtQuick.Layouts
// import Quickshell
// import Quickshell.Widgets
// import Quickshell.Services.UPower
// import "../commonwidgets" as CW
//
// RowLayout {
//   id: root
//   property real percentage: UPower.displayDevice.percentage
//   property real charging: UPower.displayDevice.state === UPowerDeviceState.Charging
//   property color color: (!charging && percentage * 100 < 20) ? "red" : "white"
//   spacing: 0
//
//   // Build icon name
//     function iconForBattery() {
//         if (!root) return "battery-missing-symbolic"
//
//         let pct = Math.round(root.percentage ?? 0)
//
//         function icon(level) {
//             return charging
//                 ? `battery-level-${level}-charging-symbolic`
//                 : `battery-level-${level}-symbolic`
//         }
//
//         if (pct >= 95) return icon(100)
//         if (pct >= 80) return icon(90)
//         if (pct >= 60) return icon(70)
//         if (pct >= 40) return icon(50)
//         if (pct >= 20) return icon(30)
//         return icon(10)
//       }
//
//    IconImage {
//         // anchors.centerIn: parent
//         implicitSize: 16
//         source: Quickshell.iconPath(iconForBattery())
//       }
//
//    Connections {
//     target: UPower.displayDevice
//
//     function onPercentageChanged() {
//         root.percentage = UPower.displayDevice.percentage
//     }
//
//     function onStateChanged() {
//         root.charging = (UPower.displayDevice.state === UPowerDeviceState.Charging)
//     }
// }
//
//

  // CW.FontIcon {
  //   Layout.alignment: Qt.AlignVCenter
  //   color: root.color
  //   iconSize: 15
  //   text: {
  //     const iconNumber = Math.round(root.percentage * 7);
  //     return root.charging ? "battery_android_bolt" : `battery_android_${iconNumber >= 7 ? "full" : iconNumber}`;
  //   }
  // }

  // CW.StyledText {
  //   Layout.alignment: Qt.AlignVCenter
  //   Layout.fillHeight: true
  //   Layout.leftMargin: 10
  //   text: `${Math.round(percentage * 100)}%`
  //   color: root.color
  // }
// }
