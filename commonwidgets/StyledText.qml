import QtQuick
import QtQuick.Layouts
import "../theme" as T
Text {
  renderType: Text.NativeRendering //: Text.QtRendering
  verticalAlignment: Text.AlignVCenter
  font {
    hintingPreference: Font.PreferFullHinting
    pointSize: 12
  }
  color: T.Config.fgDark
}
