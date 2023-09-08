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
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {ToggleGroup} from '@instructure/ui-toggle-details'
import {Text} from '@instructure/ui-text'
import {Pill} from '@instructure/ui-pill'
import {List} from '@instructure/ui-list'
import natcompare from '@canvas/util/natcompare'
import AssignmentResult from './AssignmentResult'
import UnassessedAssignment from './UnassessedAssignment'
import OutcomePopover from './OutcomePopover'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'
import TruncateWithTooltip from '../TruncateWithTooltip'
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints'
import * as shapes from './shapes'

const I18n = useI18nScope('IndividualStudentMasteryOutcome')

class Outcome extends React.Component {
  static propTypes = {
    outcome: shapes.outcomeShape.isRequired,
    expanded: PropTypes.bool.isRequired,
    onExpansionChange: PropTypes.func.isRequired,
    outcomeProficiency: shapes.outcomeProficiencyShape,
    breakpoints: breakpointsShape,
  }

  static defaultProps = {
    outcomeProficiency: null,
    breakpoints: {},
  }

  handleToggle = (_event, expanded) => {
    this.props.onExpansionChange('outcome', this.props.outcome.expansionId, expanded)
  }

  renderScoreAndPill() {
    const {outcome} = this.props
    const {mastered, score, points_possible, results} = outcome
    const text = mastered ? I18n.t('Mastered') : I18n.t('Not mastered')
    const pillAttributes = mastered ? {variant: 'success'} : {}

    return (
      <Flex direction="row" justifyItems="start" padding="0 0 0 x-small">
        {_.isNumber(score) && !_.every(results, ['hide_points', true]) && (
          <Flex.Item padding="0 x-small 0 0">
            <span>
              <PresentationContent>
                <Text size="medium">
                  {score}/{points_possible}
                </Text>
              </PresentationContent>
              <ScreenReaderContent>
                {I18n.t('%{score} out of %{points_possible} points', {
                  score,
                  points_possible,
                })}
              </ScreenReaderContent>
            </span>
          </Flex.Item>
        )}
        <Flex.Item>
          <Pill {...pillAttributes}>{text}</Pill>
        </Flex.Item>
      </Flex>
    )
  }

  renderHeader() {
    const {outcome, outcomeProficiency, breakpoints} = this.props
    const {assignments, display_name, title} = outcome
    const numAlignments = assignments.length
    const verticalLayout = !breakpoints.tablet

    return (
      <Flex
        direction={verticalLayout ? 'column' : 'row'}
        justifyItems={verticalLayout ? null : 'space-between'}
        alignItems={verticalLayout ? 'stretch' : null}
        data-selenium="outcome"
      >
        <Flex.Item shouldShrink={true} as="div">
          <Text size="medium">
            <Flex>
              <Flex.Item>
                <OutcomePopover outcome={outcome} outcomeProficiency={outcomeProficiency} />
              </Flex.Item>
              <Flex.Item shouldShrink={true}>
                <TruncateWithTooltip>{display_name || title}</TruncateWithTooltip>
              </Flex.Item>
            </Flex>
          </Text>
          {verticalLayout && this.renderScoreAndPill()}
          <View as="div" padding="0 0 0 x-small">
            <Text size="small">
              {I18n.t(
                {
                  zero: 'No alignments',
                  one: '%{count} alignment',
                  other: '%{count} alignments',
                },
                {count: I18n.n(numAlignments)}
              )}
            </Text>
          </View>
        </Flex.Item>
        {!verticalLayout && <Flex.Item>{this.renderScoreAndPill()}</Flex.Item>}
      </Flex>
    )
  }

  renderDetails() {
    const {outcome, outcomeProficiency} = this.props
    const {assignments, results} = outcome
    const assignmentsWithResults = _.filter(results, r =>
      r.assignment.id.startsWith('assignment_')
    ).map(r => r.assignment.id.split('_')[1])
    const assessmentsWithResults = _.filter(results, r =>
      r.assignment.id.startsWith('live_assessments/assessment_')
    ).map(r => r.assignment.id.split('_')[2])
    const unassessed = _.filter(
      assignments,
      a =>
        (a.assignment_id && !_.includes(assignmentsWithResults, a.assignment_id.toString())) ||
        (a.assessment_id && !_.includes(assessmentsWithResults, a.assessment_id.toString()))
    )
    return (
      <List isUnstyled={true} delimiter="dashed">
        {results
          .sort(natcompare.byKey('submitted_or_assessed_at'))
          .reverse()
          .map(result => (
            <List.Item key={result.id}>
              <AssignmentResult
                result={result}
                outcome={outcome}
                outcomeProficiency={outcomeProficiency}
              />
            </List.Item>
          ))}
        {unassessed.map(assignment => (
          <List.Item key={`a${assignment.assignment_id}`}>
            <UnassessedAssignment assignment={assignment} />
          </List.Item>
        ))}
      </List>
    )
  }

  renderEmpty() {
    return (
      <View as="div" padding="small">
        <Text>{I18n.t('No alignments are available for this outcome.')}</Text>
      </View>
    )
  }

  render() {
    const {outcome, expanded} = this.props
    const {assignments, title} = outcome
    const hasAlignments = assignments.length > 0
    return (
      <ToggleGroup
        summary={this.renderHeader()}
        toggleLabel={I18n.t('Toggle alignment details for %{title}', {title})}
        expanded={expanded}
        onToggle={this.handleToggle}
        border={false}
      >
        {hasAlignments ? this.renderDetails() : this.renderEmpty()}
      </ToggleGroup>
    )
  }
}

export default WithBreakpoints(Outcome)
