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
import _ from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import CalculationMethodContent from '@canvas/grading/CalculationMethodContent'
import {Popover} from '@instructure/ui-popover'
import {IconInfoLine} from '@instructure/ui-icons'
import DatetimeDisplay from '@canvas/datetime/react/components/DatetimeDisplay'
import {CloseButton, IconButton} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints'
import * as shapes from './shapes'

const I18n = useI18nScope('IndividualStudentMasteryOutcomePopover')

class OutcomePopover extends React.Component {
  static propTypes = {
    outcome: shapes.outcomeShape.isRequired,
    outcomeProficiency: shapes.outcomeProficiencyShape,
    breakpoints: breakpointsShape,
  }

  static defaultProps = {
    outcomeProficiency: null,
    breakpoints: {},
  }

  constructor() {
    super()
    this.state = {linkHover: false, linkClicked: false}
  }

  getSelectedRating() {
    const {outcomeProficiency} = this.props
    const {points_possible, mastery_points, score} = this.props.outcome
    const hasScore = score >= 0
    if (outcomeProficiency && hasScore) {
      const totalPoints = points_possible || mastery_points
      const percentage = totalPoints ? score / totalPoints : score
      const maxRating = outcomeProficiency.ratings[0].points
      const scaledScore = maxRating * percentage
      return (
        _.find(outcomeProficiency.ratings, r => scaledScore >= r.points) ||
        _.last(outcomeProficiency.ratings)
      )
    } else if (hasScore) {
      return _.find(this.defaultProficiency(mastery_points).ratings, r => score >= r.points)
    }
    return null
  }

  defaultProficiency = _.memoize(mastery_points => ({
    ratings: [
      {points: mastery_points * 1.5, color: '127A1B', description: I18n.t('Exceeds Mastery')},
      {points: mastery_points, color: '0B874B', description: I18n.t('Meets Mastery')},
      {points: mastery_points / 2, color: 'FAB901', description: I18n.t('Near Mastery')},
      {points: 0, color: 'E0061F', description: I18n.t('Well Below Mastery')},
    ],
  }))

  latestTime() {
    const {outcome} = this.props
    if (outcome.results.length > 0) {
      return _.sortBy(outcome.results, r => -r.submitted_or_assessed_at)[0].submitted_or_assessed_at
    }
    return null
  }

  renderSelectedRating() {
    const selectedRating = this.getSelectedRating()
    return (
      <Text size="small" weight="bold">
        <div>
          {selectedRating && (
            <div style={{color: `#${selectedRating.color}`}}>{selectedRating.description}</div>
          )}
        </div>
      </Text>
    )
  }

  renderPopoverContent() {
    const latestTime = this.latestTime()
    const popoverContent = new CalculationMethodContent(this.props.outcome).present()
    const {method, exampleText, exampleScores, exampleResult} = popoverContent
    const {outcome, breakpoints} = this.props
    const isVertical = !breakpoints.miniTablet

    return (
      <View as="div" padding="large" maxWidth="30rem">
        <CloseButton
          placement="end"
          onClick={() => this.setState({linkHover: false, linkClicked: false})}
          screenReaderLabel={I18n.t('Click to close outcome details popover')}
        />
        <Text size="small">
          <Flex alignItems="stretch" direction="row" justifyItems="space-between">
            <Flex.Item shouldGrow={true} shouldShrink={true}>
              {/* word-wrap used for IE support */}
              <div style={{wordWrap: 'break-word', overflowWrap: 'break-word'}}>
                <Text size="small" weight="bold">
                  {outcome.title}
                </Text>
              </div>
              <div>
                {isVertical && <div>{this.renderSelectedRating()}</div>}
                {I18n.t('Last Assessment: ')}
                {isVertical && <br />}
                {latestTime ? (
                  <DatetimeDisplay datetime={latestTime} format="%b %d, %l:%M %p" />
                ) : (
                  I18n.t('No submissions')
                )}
              </div>
              {outcome.friendly_description && (
                <div style={{padding: '0.5rem 0 0 0'}}>{outcome.friendly_description}</div>
              )}
            </Flex.Item>
            {!isVertical && <Flex.Item align="stretch">{this.renderSelectedRating()}</Flex.Item>}
          </Flex>
          <hr role="presentation" />
          <div>
            <Text size="small" weight="bold">
              {I18n.t('Calculation Method')}
            </Text>
            <div>{method}</div>
            <div style={{padding: '0.5rem 0 0 0'}}>
              <Text size="small" weight="bold">
                {I18n.t('Example')}
              </Text>
            </div>
            <div>{exampleText}</div>
            <div>{I18n.t('1- Item Scores: %{exampleScores}', {exampleScores})}</div>
            <div>{I18n.t('2- Final Score: %{exampleResult}', {exampleResult})}</div>
          </div>
        </Text>
      </View>
    )
  }

  renderPopover() {
    return (
      <span>
        <Popover
          isShowingContent={this.state.linkHover || this.state.linkClicked}
          onHideContent={() => this.setState({linkHover: false, linkClicked: false})}
          placement="bottom"
          on={['hover', 'click']}
          shouldContainFocus={true}
          renderTrigger={
            <IconButton
              size="small"
              margin="xx-small"
              withBackground={false}
              withBorder={false}
              screenReaderLabel={I18n.t('Click to expand outcome details')}
              renderIcon={IconInfoLine}
              onClick={() => this.setState(prevState => ({linkClicked: !prevState.linkClicked}))}
              onMouseEnter={() => this.setState({linkHover: true})}
              onMouseLeave={() => this.setState({linkHover: false})}
            />
          }
        >
          {this.renderPopoverContent()}
        </Popover>
      </span>
    )
  }

  renderModal() {
    return (
      <span>
        <IconButton
          size="small"
          margin="xx-small"
          withBackground={false}
          withBorder={false}
          screenReaderLabel={I18n.t('Click to expand outcome details')}
          renderIcon={IconInfoLine}
          onClick={() => this.setState(prevState => ({linkClicked: !prevState.linkClicked}))}
        />
        <Modal
          open={this.state.linkClicked}
          onDismiss={() =>
            this.setState(prevState => prevState.linkClicked && this.setState({linkClicked: false}))
          }
          size="fullscreen"
          label={I18n.t('Outcome Details')}
        >
          <Modal.Body>{this.renderPopoverContent()}</Modal.Body>
        </Modal>
      </span>
    )
  }

  render() {
    const {breakpoints} = this.props
    const modalLayout = !breakpoints.miniTablet
    if (modalLayout) {
      return this.renderModal()
    } else {
      return this.renderPopover()
    }
  }
}

export default WithBreakpoints(OutcomePopover)
