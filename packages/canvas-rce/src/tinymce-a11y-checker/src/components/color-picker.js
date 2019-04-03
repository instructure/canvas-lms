import React from "react"
import {
  ColorWrap,
  Saturation,
  Hue,
  Alpha
} from "react-color/lib/components/common"
import Pointer from "./pointer"
import PointerCircle from "react-color/lib/components/photoshop/PhotoshopPointerCircle"

function ColorPicker(props) {
  return (
    <div>
      <div style={{ position: "relative", height: 150, marginTop: 10 }}>
        <Saturation {...props} pointer={PointerCircle} />
      </div>
      <div style={{ position: "relative", height: 10, marginTop: 10 }}>
        <Hue {...props} pointer={Pointer} />
      </div>
      <div style={{ position: "relative", height: 10, marginTop: 10 }}>
        <Alpha {...props} pointer={Pointer} />
      </div>
    </div>
  )
}

export default ColorWrap(ColorPicker)
