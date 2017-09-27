const React = require("react")
const {
  ColorWrap,
  Saturation,
  Hue,
  Alpha
} = require("react-color/lib/components/common")
const Pointer = require("./pointer")
const PointerCircle = require("react-color/lib/components/photoshop/PhotoshopPointerCircle")
  .default
console.log(Pointer, PointerCircle)

class ColorPicker extends React.Component {
  render() {
    return (
      <div>
        <div style={{ position: "relative", height: 150, marginTop: 10 }}>
          <Saturation {...this.props} pointer={PointerCircle} />
        </div>
        <div style={{ position: "relative", height: 10, marginTop: 10 }}>
          <Hue {...this.props} pointer={Pointer} />
        </div>
        <div style={{ position: "relative", height: 10, marginTop: 10 }}>
          <Alpha {...this.props} pointer={Pointer} />
        </div>
      </div>
    )
  }
}

module.exports = ColorWrap(ColorPicker)
