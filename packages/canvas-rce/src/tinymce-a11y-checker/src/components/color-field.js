import React from "react"
import ReactDOM from "react-dom"
import contrast from "wcag-element-contrast"
import { TextInput } from "@instructure/ui-forms"
import { View } from "@instructure/ui-layout"
import ColorPicker from "./color-picker"

export default class ColorField extends React.Component {
  static stringifyRGBA(rgba) {
    if (rgba.a === 1) {
      return `rgb(${rgba.r}, ${rgba.g}, ${rgba.b})`
    }
    return `rgba(${rgba.r}, ${rgba.g}, ${rgba.b}, ${rgba.a})`
  }

  state = { width: 200 }

  componentDidMount() {
    this.setState({ width: ReactDOM.findDOMNode(this).offsetWidth })
  }

  handlePickerChange = color => {
    this.props.onChange({
      target: {
        name: this.props.name,
        value: ColorField.stringifyRGBA(color.rgb)
      }
    })
  }

  render() {
    return (
      <View as="div">
        <TextInput {...this.props} />
        <ColorPicker
          color={contrast.parseRGBA(this.props.value)}
          onChange={this.handlePickerChange}
        />
      </View>
    )
  }
}
