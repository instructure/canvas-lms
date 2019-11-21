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
import I18n from 'i18n!IndividualStudentMasteryOutcome'
import {View, Flex} from '@instructure/ui-layout'
import {ToggleGroup} from '@instructure/ui-toggle-details'
import {List, Pill, Text, TruncateText} from '@instructure/ui-elements'
import natcompare from 'compiled/util/natcompare'
import AssignmentResult from './AssignmentResult'
import UnassessedAssignment from './UnassessedAssignment'
import OutcomePopover from './OutcomePopover'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y'
import * as shapes from './shapes'

export default class Outcome extends React.Component {
  static propTypes = {
    outcome: shapes.outcomeShape.isRequired,
    expanded: PropTypes.bool.isRequired,
    onExpansionChange: PropTypes.func.isRequired,
    outcomeProficiency: shapes.outcomeProficiencyShape
  }

  static defaultProps = {
    outcomeProficiency: null
  }

  handleToggle = (_event, expanded) => {
    this.props.onExpansionChange('outcome', this.props.outcome.expansionId, expanded)
  }

  renderHeader() {
    const {outcome, outcomeProficiency} = this.props
    const {assignments, display_name, mastered, title, score, points_possible, results} = outcome
    const numAlignments = assignments.length
    const pillAttributes = {margin: '0 0 0 x-small', text: I18n.t('Not mastered')}
    if (mastered) {
      Object.assign(pillAttributes, {text: I18n.t('Mastered'), variant: 'success'})
    }

    return (
      <Flex direction="row" justifyItems="space-between" data-selenium="outcome">
        <Flex.Item shrink>
          <Flex direction="column">
            <Flex.Item>
              <Text size="medium">
                <Flex>
                  <Flex.Item>
                    <OutcomePopover outcome={outcome} outcomeProficiency={outcomeProficiency} />
                  </Flex.Item>
                  <Flex.Item shrink padding="0 x-small">
                    <TruncateText>{display_name || title}</TruncateText>
                  </Flex.Item>
                </Flex>
              </Text>
            </Flex.Item>
            <Flex.Item>
              <Text size="small">
                {I18n.t(
                  {
                    zero: 'No alignments',
                    one: '%{count} alignment',
                    other: '%{count} alignments'
                  },
                  {count: I18n.n(numAlignments)}
                )}
              </Text>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item>
          {_.isNumber(score) && !_.every(results, ['hide_points', true]) && (
            <span>
              <PresentationContent>
                <Text size="medium">
                  {score}/{points_possible}
                </Text>
              </PresentationContent>
              <ScreenReaderContent>
                {I18n.t('%{score} out of %{points_possible} points', {score, points_possible})}
              </ScreenReaderContent>
            </span>
          )}
          <Pill {...pillAttributes} />
        </Flex.Item>
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
      <List variant="unstyled" delimiter="dashed">
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
          <UnassessedAssignment
            key={
              assignment.assessment_id ? `a${assignment.assessment_id}` : assignment.assignment_id
            }
            assignment={assignment}
          />
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
