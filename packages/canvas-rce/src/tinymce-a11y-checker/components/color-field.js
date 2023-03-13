/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React from 'react'
import ReactDOM from 'react-dom'
import contrast from 'wcag-element-contrast'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import ColorPicker from './color-picker'

export default class ColorField extends React.Component {
  static stringifyRGBA(rgba) {
    if (rgba.a === 1) {
      return `rgb(${rgba.r}, ${rgba.g}, ${rgba.b})`
    }
    return `rgba(${rgba.r}, ${rgba.g}, ${rgba.b}, ${rgba.a})`
  }

  state = {width: 200}

  componentDidMount() {
    this.setState({width: ReactDOM.findDOMNode(this).offsetWidth})
  }

  handlePickerChange = color => {
    this.props.onChange({
      target: {
        name: this.props.name,
        value: ColorField.stringifyRGBA(color.rgb),
      },
    })
  }

  render() {
    return (
      <View as="div">
        <TextInput data-testid="color-field-text-input" {...this.props} />
        <ColorPicker
          data-testid="color-field-color-picker"
          color={contrast.parseRGBA(this.props.value)}
          onChange={this.handlePickerChange}
        />
      </View>
    )
  }
}
