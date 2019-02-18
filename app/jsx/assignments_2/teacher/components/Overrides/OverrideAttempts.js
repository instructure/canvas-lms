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
import {bool, oneOf} from 'prop-types'
import I18n from 'i18n!assignments_2'
import {OverrideShape} from '../../assignmentData'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import NumberInput from '@instructure/ui-forms/lib/components/NumberInput'
import PresentationContent from '@instructure/ui-a11y/lib/components/PresentationContent'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Select from '@instructure/ui-forms/lib/components/Select'
import Text from '@instructure/ui-elements/lib/components/Text'
import View from '@instructure/ui-layout/lib/components/View'

export default class OverrideAttempts extends React.Component {
  static propTypes = {
    override: OverrideShape.isRequired,
    variant: oneOf(['summary', 'detail']).isRequired,
    readOnly: bool
  }

  static defaultProps = {
    readOnly: true
  }

  constructor(props) {
    super(props)
    const limit = props.override.allowedAttempts === null ? 'unlimited' : 'limited'
    let attempts = null
    if (limit === 'limited') {
      attempts = Number.isInteger(props.override.allowedAttempts)
        ? props.override.allowedAttempts
        : 1
    }

    this.state = {
      limit,
      attempts,
      scoreToKeep: 'most_recent' // TODO: need the data
    }
  }

  onChangeAttemptsAllowed = (_event, selection) => {
    const limit = selection.value
    if (this.state.limit === limit) return

    this.setState((prevState, _prevProps) => {
      let attempts = prevState.attempts
      if (limit === 'limited' && !attempts) {
        attempts = 1
      }
      return {limit, attempts}
    })
  }

  onChangeAttemptLimit = (event, number) => {
    this.setState({attempts: number})
  }

  onChangeScoreToKeep = (event, selection) => {
    this.setState({scoreToKeep: selection.value})
  }

  renderLimit() {
    return (
      <FlexItem data-testid="OverrideAttempts-Limit">
        <Select
          readOnly={this.props.readOnly}
          label={I18n.t('Attempts Allowed')}
          selectedOption={this.state.limit}
          onChange={this.onChangeAttemptsAllowed}
          allowEmpty={false}
        >
          <option value="limited">{I18n.t('Limited')}</option>
          <option value="unlimited">{I18n.t('Unlimited')}</option>
        </Select>
      </FlexItem>
    )
  }

  renderAttempts() {
    if (this.state.limit === 'limited') {
      const label = I18n.t({one: 'Attempt', other: 'Attempts'}, {count: this.state.attempts})

      return (
        <FlexItem margin="0 small" data-testid="OverrideAttempts-Attempts">
          <NumberInput
            readOnly={this.props.readOnly}
            inline
            width="5.5rem"
            label={<ScreenReaderContent>Attempts</ScreenReaderContent>}
            min={1}
            value={this.state.attempts}
            onChange={this.onChangeAttemptLimit}
          />
          <PresentationContent>
            <View display="inline-block" margin="0 0 0 small">
              <Text>{label}</Text>
            </View>
          </PresentationContent>
        </FlexItem>
      )
    }
    return null
  }

  renderScoreToKeep() {
    return (
      <Select
        inline
        label={I18n.t('Score to keep')}
        selectedOption={this.state.scoreToKeep}
        onChange={this.onChangeScoreToKeep}
        readOnly={this.props.readOnly}
        allowEmpty={false}
        data-testid="OverrideAttempts-ScoreToKeep"
      >
        <option value="average_score">{I18n.t('Average Score')}</option>
        <option value="highest_score">{I18n.t('Highest Score')}</option>
        <option value="most_recent">{I18n.t('Most Recent')}</option>
      </Select>
    )
  }

  renderDetail() {
    return (
      <View display="block" margin="0 0 small 0" data-testid="OverrideAttempts-Detail">
        <Flex alignItems="end" margin="0 0 small 0">
          {this.renderLimit()}
          {this.renderAttempts()}
        </Flex>
        {this.renderScoreToKeep()}
      </View>
    )
  }

  renderSummary() {
    return (
      <Text data-testid="OverrideAttempts-Summary">
        {this.state.attempts
          ? I18n.t({one: '1 Attempt', other: '%{count} Attempts'}, {count: this.state.attempts})
          : I18n.t('Unlimited Attempts')}
      </Text>
    )
  }

  render() {
    return this.props.variant === 'summary' ? this.renderSummary() : this.renderDetail()
  }
}
