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
// @ts-expect-error
import contrast from 'wcag-element-contrast'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import ColorPicker from './color-picker'
import {stringifyRGBA, restrictColorValues, parseRGBA} from '../utils/colors'

type Props = {
  label: string
  name: string
  value: string
  onChange: (e: any) => void
}

export default class ColorField extends React.Component<Props> {
  state = {
    textValue: this.props.value,
  }

  handleTextChange = (
    event: React.ChangeEvent<HTMLInputElement> & {target: {name: string; value: string}}
  ) => {
    const rgba = parseRGBA(event.target.value.trim())
    const newValue = rgba ? stringifyRGBA(restrictColorValues(rgba)) : this.props.value
    this.setState({textValue: newValue})
    this.props.onChange({
      target: {
        name: this.props.name,
        value: newValue,
      },
    })
  }

  handlePickerChange = (color: {rgb: {r: number; g: number; b: number; a: number}}) => {
    const newValue = stringifyRGBA(color.rgb)
    this.setState({textValue: newValue})
    this.props.onChange({
      target: {
        name: this.props.name,
        value: newValue,
      },
    })
  }

  render() {
    return (
      <View as="div">
        <TextInput
          data-testid="color-field-text-input"
          renderLabel={this.props.label}
          value={this.state.textValue}
          onChange={e => this.setState({textValue: e.target.value})}
          onBlur={this.handleTextChange}
        />
        <ColorPicker
          data-testid="color-field-color-picker"
          color={contrast.parseRGBA(this.props.value)}
          onChange={this.handlePickerChange}
        />
      </View>
    )
  }
}
