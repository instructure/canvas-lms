/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import ReactDOM from 'react-dom'
import RadioInput from '@instructure/ui-forms/lib/components/RadioInput'
import RadioInputGroup from '@instructure/ui-forms/lib/components/RadioInputGroup'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

export default class PolicyCell extends React.Component {
  static renderAt (elt, props) {
    ReactDOM.render(<PolicyCell {...props} />, elt)
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
      onChange={(e, val) => this.handleValueChanged(val)}
    >
      {this.renderRadioInputs()}
    </RadioInputGroup>
  }
}
