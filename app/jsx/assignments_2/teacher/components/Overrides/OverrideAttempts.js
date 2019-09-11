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
import {bool, oneOf, number} from 'prop-types'
import I18n from 'i18n!assignments_2'
import {requiredIfDetail} from '../../assignmentData'
import {Flex, View} from '@instructure/ui-layout'
import {NumberInput} from '@instructure/ui-number-input'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y'
import {Select} from '@instructure/ui-forms'
import {Text} from '@instructure/ui-elements'

import NumberHelper from '../../../../shared/helpers/numberHelper'

export default class OverrideAttempts extends React.Component {
  static propTypes = {
    allowedAttempts: number,
    onChange: requiredIfDetail,
    variant: oneOf(['summary', 'detail']).isRequired,
    readOnly: bool
  }

  static defaultProps = {
    readOnly: false
  }

  onChangeAttemptsAllowed = (_event, selection) => {
    const limit = selection.value === 'unlimited' ? null : 1
    this.props.onChange('allowedAttempts', limit)
  }

  /* eslint-disable no-restricted-globals */
  onChangeAttemptLimit = (_event, number) => {
    const value = NumberHelper.parse(number)
    if (isNaN(value)) {
      return
    }
    this.props.onChange('allowedAttempts', Math.trunc(value))
  }

  onIncrementAttemptLimit = _event => {
    const value = NumberHelper.parse(this.props.allowedAttempts)
    if (isNaN(value)) {
      return
    }
    this.props.onChange('allowedAttempts', value + 1)
  }

  onDecrementAttemptLimit = _event => {
    const value = NumberHelper.parse(this.props.allowedAttempts)
    if (isNaN(value)) {
      return
    }
    if (value > 1) {
      this.props.onChange('allowedAttempts', value - 1)
    }
  }
  /* eslint-enable no-restricted-globals */

  renderLimit() {
    const attempts = this.props.allowedAttempts === null ? 'unlimited' : 'limited'
    return (
      <Flex.Item data-testid="OverrideAttempts-Limit" margin="0 small 0 0">
        <Select
          readOnly={this.props.readOnly}
          label={I18n.t('Attempts Allowed')}
          selectedOption={attempts}
          onChange={this.onChangeAttemptsAllowed}
          allowEmpty={false}
        >
          <option value="limited">{I18n.t('Limited')}</option>
          <option value="unlimited">{I18n.t('Unlimited')}</option>
        </Select>
      </Flex.Item>
    )
  }

  renderAttempts() {
    if (this.props.allowedAttempts !== null) {
      const limit = this.props.allowedAttempts
      const label = I18n.t({one: 'Attempt', other: 'Attempts'}, {count: limit})

      return (
        <Flex.Item margin="small 0 0" data-testid="OverrideAttempts-Attempts">
          <NumberInput
            readOnly={this.props.readOnly}
            inline
            width="5.5rem"
            label={<ScreenReaderContent>Attempts</ScreenReaderContent>}
            min={1}
            value={`${limit}`}
            onChange={this.onChangeAttemptLimit}
            onIncrement={this.onIncrementAttemptLimit}
            onDecrement={this.onDecrementAttemptLimit}
          />
          <PresentationContent>
            <View display="inline-block" margin="0 0 0 small">
              <Text>{label}</Text>
            </View>
          </PresentationContent>
        </Flex.Item>
      )
    }
    return null
  }

  renderDetail() {
    return (
      <View display="block" margin="0 0 small 0" data-testid="OverrideAttempts-Detail">
        <Flex alignItems="end" margin="0 0 small 0" wrapItems>
          {this.renderLimit()}
          {this.renderAttempts()}
        </Flex>
      </View>
    )
  }

  renderSummary() {
    return (
      <Text data-testid="OverrideAttempts-Summary">
        {this.props.allowedAttempts === null
          ? I18n.t('Unlimited Attempts')
          : I18n.t(
              {one: '1 Attempt', other: '%{count} Attempts'},
              {count: this.props.allowedAttempts}
            )}
      </Text>
    )
  }

  render() {
    return this.props.variant === 'summary' ? this.renderSummary() : this.renderDetail()
  }
}
