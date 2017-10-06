import React from "react"
import {
  ColorWrap,
  Saturation,
  Hue,
  Alpha
} from "react-color/lib/components/common"
import Pointer from "./pointer"
import PointerCircle from "react-color/lib/components/photoshop/PhotoshopPointerCircle"

class ColorPicker extends React.Component {
  static get displayName() {
    return "ColorPicker"
  }

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

export default ColorWrap(ColorPicker)
