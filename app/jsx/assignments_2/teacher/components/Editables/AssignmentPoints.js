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
import {bool, func, number, oneOf, oneOfType, string} from 'prop-types'
import I18n from 'i18n!assignments_2'

import {Flex, FlexItem, View} from '@instructure/ui-layout'
import {Text} from '@instructure/ui-elements'

import EditableNumber from './EditableNumber'

const invalidMessage = I18n.t('Points must be a number >= 0')
const editLabel = I18n.t('Edit Points')
const label = I18n.t('Points')

// beause isNan is not the same as Number.isNaN
/* eslint-disable no-restricted-globals */
const isPointsValid = strValue => {
  if (!strValue) return false // it's required
  if (isNaN(strValue)) return false // must be a number
  return parseFloat(strValue) >= 0 // must be non-negative
}
/* eslint-enable no-restricted-globals */

export default class AssignmentPoints extends React.Component {
  static propTypes = {
    mode: oneOf(['view', 'edit']).isRequired,
    pointsPossible: oneOfType([number, string]),
    onChange: func.isRequired,
    onChangeMode: func.isRequired,
    readOnly: bool
  }

  static defaultProps = {
    readOnly: true
  }

  constructor(props) {
    super(props)

    // need to track the value so we don't pass
    // invalid values up to our parent
    const strValue = `${props.pointsPossible}`
    this.state = {
      strValue,
      isValid: isPointsValid(strValue)
    }
  }

  static getDerivedStateFromProps(props, state) {
    // if the current state is invalid, don't replace the state
    // it's there to track invalid values
    if (state.isValid) {
      const strValue = `${props.pointsPossible}`
      return {
        strValue,
        isValid: isPointsValid(strValue)
      }
    }
    return null
  }

  handlePointsChange = strValue => {
    const isValid = isPointsValid(strValue)
    this.setState({isValid, strValue})
    if (isValid) {
      // round to 2 decimal places
      const val = Math.round(parseFloat(strValue) * 100) / 100
      this.props.onChange(val)
    }
  }

  handlePointsInputChange = strValue => {
    const isValid = isPointsValid(strValue)
    this.setState({isValid, strValue})
    if (isValid) {
      this.props.onChange(parseFloat(strValue))
    }
  }

  // since we're updating InPlaceEdit.value as the user types,
  // it won't call onChange, since the value it has is up to date.
  // We need to round the value off when changing to view too
  // We can assume the current value is valid, because EditableNumber
  // won't leave edit mode unless it is.
  handleChangeMode = mode => {
    if (mode === 'view') {
      // round to 2 decimal places
      const val = Math.round(parseFloat(this.state.strValue) * 100) / 100
      this.setState({strValue: `${val}`}, () => {
        this.props.onChange(val)
      })
    }
    this.props.onChangeMode(mode)
  }

  render() {
    const sty = this.props.mode === 'view' ? {marginTop: '7px'} : {}
    const msg = this.state.isValid ? null : (
      <View as="div" textAlign="end" margin="xx-small 0 0 0">
        <Text color="error">{invalidMessage}</Text>
      </View>
    )
    return (
      <div style={sty} data-testid="AssignmentPoints">
        <Flex alignItems="center" justifyItems="end">
          <FlexItem margin="0 x-small 0 0">
            <EditableNumber
              mode={this.props.mode}
              inline
              size="large"
              value={this.state.strValue}
              onChange={this.handlePointsChange}
              onChangeMode={this.handleChangeMode}
              onInputChange={this.handlePointsInputChange}
              isValid={isPointsValid}
              label={editLabel}
              editButtonPlacement="start"
              required
              readOnly={this.props.readOnly}
            />
          </FlexItem>
          <FlexItem>
            <Text size="large">{label}</Text>
          </FlexItem>
        </Flex>
        {msg}
      </div>
    )
  }
}
