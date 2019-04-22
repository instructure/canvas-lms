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
import {OverrideShape, requiredIfDetail} from '../../assignmentData'
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
    onChangeOverride: requiredIfDetail,
    variant: oneOf(['summary', 'detail']).isRequired,
    readOnly: bool
  }

  static defaultProps = {
    readOnly: false
  }

  // TODO: need the scoreToKeep data
  constructor(props) {
    super(props)

    this.state = {
      scoreToKeep: 'most_recent' // TODO: need the data
    }
  }

  onChangeAttemptsAllowed = (_event, selection) => {
    const limit = selection.value === 'unlimited' ? null : 1
    this.props.onChangeOverride('allowedAttempts', limit)
  }

  onChangeAttemptLimit = (_event, number) => {
    this.props.onChangeOverride('allowedAttempts', number)
  }

  onChangeScoreToKeep = (_event, selection) => {
    this.setState({scoreToKeep: selection.value})
  }

  renderLimit() {
    const attempts = this.props.override.allowedAttempts === null ? 'unlimited' : 'limited'
    return (
      <FlexItem data-testid="OverrideAttempts-Limit">
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
      </FlexItem>
    )
  }

  renderAttempts() {
    if (this.props.override.allowedAttempts !== null) {
      const limit = this.props.override.allowedAttempts
      const label = I18n.t({one: 'Attempt', other: 'Attempts'}, {count: limit})

      return (
        <FlexItem margin="0 small" data-testid="OverrideAttempts-Attempts">
          <NumberInput
            readOnly={this.props.readOnly}
            inline
            width="5.5rem"
            label={<ScreenReaderContent>Attempts</ScreenReaderContent>}
            min={1}
            value={limit}
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
        {this.props.override.allowedAttempts === null
          ? I18n.t('Unlimited Attempts')
          : I18n.t(
              {one: '1 Attempt', other: '%{count} Attempts'},
              {count: this.props.override.allowedAttempts}
            )}
      </Text>
    )
  }

  render() {
    return this.props.variant === 'summary' ? this.renderSummary() : this.renderDetail()
  }
}
