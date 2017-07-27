const React = require('react')
const { ColorWrap, Saturation, Hue, Alpha } = require('react-color/lib/components/common')

class ColorPicker extends React.Component {
  render () {
    return <div>
      <div style={{ position: 'relative', height: 200, marginTop: 10 }}><Saturation {...this.props} /></div>
      <div style={{ position: 'relative', height: 10, marginTop: 10 }}><Hue {...this.props} /></div>
      <div style={{ position: 'relative', height: 10, marginTop: 10 }}><Alpha {...this.props} /></div>
    </div>
  }
}

module.exports = ColorWrap(ColorPicker)