const React = require('react')
const ReactDOM = require('react-dom')
const contrast = require('wcag-element-contrast')
const TextInput = require('instructure-ui/lib/components/TextInput').default
const Container = require('instructure-ui/lib/components/Container').default
const ColorPicker = require('./color-picker')

class ColorField extends React.Component {
  static stringifyRGBA (rgba) {
    if (rgba.a === 1) {
      return `rgb(${rgba.r}, ${rgba.g}, ${rgba.b})`
    }
    return `rgba(${rgba.r}, ${rgba.g}, ${rgba.b}, ${rgba.a})`
  }

  constructor () {
    super()
    this.state = { width: 200 }
    this.handlePickerChange = this.handlePickerChange.bind(this)
  }

  componentDidMount () {
    this.setState({ width: ReactDOM.findDOMNode(this).offsetWidth })
  }

  handlePickerChange (color) {
    this.props.onChange({ target: {
      name: this.props.name,
      value: ColorField.stringifyRGBA(color.rgb)
    }})
  }

  render () {
    return <Container as="div">
      <TextInput {...this.props} />
      <ColorPicker
        color={contrast.parseRGBA(this.props.value)}
        onChange={this.handlePickerChange}
      />
    </Container>
  }
}

module.exports = ColorField
