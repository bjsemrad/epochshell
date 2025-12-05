import QtQuick
import QtQuick.Layouts
import qs.theme as T

Text {
  renderType: Text.NativeRendering
  verticalAlignment: Text.AlignVCenter
  font {
    hintingPreference: Font.PreferFullHinting
    pointSize: 12
  }
  color: T.Config.fgDark
}
