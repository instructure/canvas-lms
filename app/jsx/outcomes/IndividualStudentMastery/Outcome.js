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
import I18n from 'i18n!outcomes'
import View from '@instructure/ui-layout/lib/components/View'
import Flex, { FlexItem } from '@instructure/ui-layout/lib/components/Flex'
import ToggleGroup from '@instructure/ui-toggle-details/lib/components/ToggleGroup'
import List, { ListItem } from '@instructure/ui-elements/lib/components/List'
import Pill from '@instructure/ui-elements/lib/components/Pill'
import Text from '@instructure/ui-elements/lib/components/Text'
import TruncateText from '@instructure/ui-elements/lib/components/TruncateText'
import natcompare from 'compiled/util/natcompare'
import AssignmentResult from './AssignmentResult'
import UnassessedAssignment from './UnassessedAssignment'
import OutcomePopover from './OutcomePopover'
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

  renderHeader () {
    const { outcome, outcomeProficiency } = this.props
    const { assignments, mastered, title } = outcome
    const numAlignments = assignments.length

    return (
      <Flex direction="row" justifyItems="space-between" data-selenium="outcome">
        <FlexItem shrink>
          <Flex direction="column">
            <FlexItem>
              <Text size="medium">
                <Flex>
                  <FlexItem>
                    <OutcomePopover outcome={outcome} outcomeProficiency={outcomeProficiency}/>
                  </FlexItem>
                  <FlexItem shrink padding="0 x-small"><TruncateText>{ title }</TruncateText></FlexItem>
                </Flex>
              </Text>
            </FlexItem>
            <FlexItem><Text size="small">{ I18n.t({
              zero: 'No alignments',
              one: '%{count} alignment',
              other: '%{count} alignments'
            }, { count: I18n.n(numAlignments) }) }</Text></FlexItem>
          </Flex>
        </FlexItem>
        <FlexItem>
        {
          mastered ? <Pill text={I18n.t('Mastered')} variant="success" /> : <Pill text={I18n.t('Not mastered')} />
        }
        </FlexItem>
      </Flex>
    )
  }

  renderDetails () {
    const { outcome, outcomeProficiency } = this.props
    const { assignments, results } = outcome
    const assignmentsWithResults = results.map((r) => r.assignment.id.split('_')[1])
    const unassessedAssignments = _.reject(assignments, (a) => (
      _.includes(assignmentsWithResults, a.assignment_id.toString()
    )))
    return (
      <List variant="unstyled" delimiter="dashed">
      {
        results.sort(natcompare.byKey('submitted_or_assessed_at')).reverse().map((result) => (
          <ListItem key={result.id}>
            <AssignmentResult result={result} outcome={outcome} outcomeProficiency={outcomeProficiency} />
          </ListItem>
        ))
      }
      {
        unassessedAssignments.map((assignment) => (
          <UnassessedAssignment assignment={assignment}/>
        ))
      }
      </List>
    )
  }

  renderEmpty () {
    return (
      <View as="div" padding="small">
        <Text>{ I18n.t('No alignments are available for this outcome.') }</Text>
      </View>
    )
  }

  render () {
    const { outcome, expanded } = this.props
    const { assignments, title } = outcome
    const hasAlignments = assignments.length > 0
    return (
      <ToggleGroup
        summary={this.renderHeader()}
        toggleLabel={I18n.t('Toggle alignment details for %{title}', { title })}
        expanded={expanded}
        onToggle={this.handleToggle}
        border={false}
      >
        { hasAlignments ? this.renderDetails() : this.renderEmpty() }
      </ToggleGroup>
    )
  }
}
