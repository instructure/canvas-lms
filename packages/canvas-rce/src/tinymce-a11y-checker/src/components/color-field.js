import React from "react"
import ReactDOM from "react-dom"
import contrast from "wcag-element-contrast"
import TextInput from "@instructure/ui-forms/lib/components/TextInput"
import View from "@instructure/ui-layout/lib/components/View"
import ColorPicker from "./color-picker"

export default class ColorField extends React.Component {
  static stringifyRGBA(rgba) {
    if (rgba.a === 1) {
      return `rgb(${rgba.r}, ${rgba.g}, ${rgba.b})`
    }
    return `rgba(${rgba.r}, ${rgba.g}, ${rgba.b}, ${rgba.a})`
  }

  constructor() {
    super()
    this.state = { width: 200 }
    this.handlePickerChange = this.handlePickerChange.bind(this)
  }

  static get displayName() {
    return "ColorField"
  }

  componentDidMount() {
    this.setState({ width: ReactDOM.findDOMNode(this).offsetWidth })
  }

  handlePickerChange(color) {
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
