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
import {useScope as useI18nScope} from '@canvas/i18n'

import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'

import EditableNumber from './EditableNumber'

const I18n = useI18nScope('assignments_2')

const editLabel = I18n.t('Edit Points')
const label = I18n.t('Points')

export default class AssignmentPoints extends React.Component {
  static propTypes = {
    mode: oneOf(['view', 'edit']).isRequired,
    pointsPossible: oneOfType([number, string]),
    onChange: func.isRequired,
    onChangeMode: func.isRequired,
    onValidate: func.isRequired,
    invalidMessage: func.isRequired,
    readOnly: bool,
  }

  static defaultProps = {
    readOnly: false,
  }

  constructor(props) {
    super(props)

    this.state = {
      isValid: props.onValidate('pointsPossible', props.pointsPossible),
    }
  }

  static getDerivedStateFromProps(props, state) {
    const isValid = props.onValidate('pointsPossible', props.pointsPossible)
    return isValid !== state.isValid ? {isValid} : null
  }

  isPointsValid = value => this.props.onValidate('pointsPossible', value)

  round = value => Math.round(parseFloat(value) * 100) / 100

  handlePointsChange = strValue => {
    const isValid = this.isPointsValid(strValue)
    this.setState({isValid}, () => {
      let val = strValue
      if (isValid) {
        // round to 2 decimal places
        val = this.round(strValue)
      }
      this.props.onChange(val)
    })
  }

  handlePointsInputChange = strValue => {
    const isValid = this.isPointsValid(strValue)
    this.setState({isValid}, () => {
      if (!isValid) {
        showFlashAlert({
          message: this.props.invalidMessage('pointsPossible') || I18n.t('Error'),
          type: 'error',
          srOnly: true,
        })
      }
      this.props.onChange(strValue)
    })
  }

  render() {
    const sty = this.props.mode === 'view' ? {marginTop: '7px'} : {}
    const msg = this.state.isValid ? null : (
      <View as="div" textAlign="end" margin="xx-small 0 0 0">
        <span style={{whiteSpace: 'nowrap'}}>
          <Text color="danger">{this.props.invalidMessage('pointsPossible')}</Text>
        </span>
      </View>
    )
    return (
      <div style={sty} data-testid="AssignmentPoints">
        <Flex alignItems="center" justifyItems="end">
          <Flex.Item margin="0 x-small 0 0">
            <EditableNumber
              mode={this.props.mode}
              inline={true}
              size="large"
              value={this.props.pointsPossible}
              onChange={this.handlePointsChange}
              onChangeMode={this.props.onChangeMode}
              onInputChange={this.handlePointsInputChange}
              label={editLabel}
              editButtonPlacement="start"
              required={true}
              readOnly={this.props.readOnly}
            />
          </Flex.Item>
          <Flex.Item>
            <Text size="large">{label}</Text>
          </Flex.Item>
        </Flex>
        {msg}
      </div>
    )
  }
}
