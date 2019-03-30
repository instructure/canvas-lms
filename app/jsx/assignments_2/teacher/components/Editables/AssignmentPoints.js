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

    this.state = {
      isValid: this.isPointsValid(props.pointsPossible)
    }
  }

  handlePointsChange = value => {
    // round to 2 decimal places
    const val = Math.round(parseFloat(value) * 100) / 100
    this.props.onChange(val)
  }

  handlePointsInputChnage = value => {
    this.setState({isValid: this.isPointsValid(value)})
  }

  // beause isNan is not the same as Number.isNaN
  /* eslint-disable no-restricted-globals */
  isPointsValid = strValue => {
    if (!strValue) return false // it's required
    if (isNaN(strValue)) return false // must be a number
    return parseFloat(strValue) >= 0 // must be non-negative
  }
  /* eslint-enable no-restricted-globals */

  render() {
    const sty = this.props.mode === 'view' ? {marginTop: '7px'} : {}
    return (
      <div style={sty} data-testid="AssignmentPoints">
        <Flex alignItems="center" justifyItems="end">
          <FlexItem margin="0 x-small 0 0">
            <EditableNumber
              mode={this.props.mode}
              inline
              size="large"
              value={this.props.pointsPossible}
              onChange={this.handlePointsChange}
              onChangeMode={this.props.onChangeMode}
              onInputChange={this.handlePointsInputChnage}
              isValid={this.isPointsValid}
              label={I18n.t('Edit Points')}
              editButtonPlacement="start"
              required
              readOnly={this.props.readOnly}
            />
          </FlexItem>
          <FlexItem>
            <Text size="large">{I18n.t('Points')}</Text>
          </FlexItem>
        </Flex>
        {this.state.isValid ? null : (
          <View as="div" textAlign="end" margin="xx-small 0 0 0">
            <Text color="error">{I18n.t('Points must be a number >= 0')}</Text>
          </View>
        )}
      </div>
    )
  }
}
