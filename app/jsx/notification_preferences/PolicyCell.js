import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import RadioInput from 'instructure-ui/lib/components/RadioInput'
import RadioInputGroup from 'instructure-ui/lib/components/RadioInputGroup'
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent'

const PropTypes = React.PropTypes

export default class PolicyCell extends React.Component {
  static renderAt (elt, props) {
    ReactDOM.render(<PolicyCell {...props} />, elt)
  }

  constructor () {
    super()
    this.handleValueChanged = this.handleValueChanged.bind(this)
  }

  static propTypes = {
    selection: PropTypes.string,
    category: PropTypes.string,
    channelId: PropTypes.string,
    buttonData: PropTypes.array,
    onValueChanged: PropTypes.func,
  }

  handleValueChanged (newValue) {
    if (this.props.onValueChanged) {
      this.props.onValueChanged(this.props.category, this.props.channelId, newValue)
    }
  }

  renderIcon (iconName, title) {
    return <span>
      <i aria-hidden="true" className={iconName} />
      <ScreenReaderContent>{title}</ScreenReaderContent>
    </span>
  }

  renderRadioInput(iconName, title, value) {
    return <RadioInput
      key={value}
      label={this.renderIcon(iconName, title)}
      value={value}
      id={`cat_${this.props.category}_ch_${this.props.channelId}_${value}`}
    />
  }

  renderRadioInputs() {
    const buttonData = this.props.buttonData
    return buttonData.map((button) => {
      return this.renderRadioInput(button.icon, button.title, button.code)
    })
  }

  render () {
    return <RadioInputGroup
      name={Math.floor(1 + Math.random() * 0x10000).toString()}
      description=""
      variant="toggle"
      size="small"
      defaultValue={this.props.selection}
      onChange={this.handleValueChanged}
    >
      {this.renderRadioInputs()}
    </RadioInputGroup>
  }
}
