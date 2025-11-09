import QtQuick

Text {
  id: root
  property real fill: 0
  property real iconSize: 18
  color: "#898979"
  font {
    family: "Material Symbols Outlined"
    pixelSize: root.iconSize
    variableAxes: {
      "FILL": root.fill,
      "opsz": root.iconSize
    }
  }
}
