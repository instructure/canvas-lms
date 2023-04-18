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
import PropTypes from 'prop-types'
import ImmutablePropTypes from 'react-immutable-proptypes'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {ToggleGroup} from '@instructure/ui-toggle-details'
import {Text} from '@instructure/ui-text'
import {Pill} from '@instructure/ui-pill'
import {List} from '@instructure/ui-list'
import natcompare from '@canvas/util/natcompare'
import TruncateWithTooltip from '../TruncateWithTooltip'
import Outcome from './Outcome'
import * as shapes from './shapes'
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints'

const I18n = useI18nScope('IndividualStudentMasteryOutcomeGroup')

const outcomeGroupHeader = (outcomeGroup, numMastered, numGroup, isVertical) => (
  <Flex
    padding="0 0 0 xxx-small"
    justifyItems={isVertical ? null : 'space-between'}
    direction={isVertical ? 'column' : 'row'}
  >
    <Flex.Item padding="0 x-small 0 0" size={isVertical ? undefined : '0'} shouldGrow={true}>
      <Text size="large" weight="bold">
        <TruncateWithTooltip>{outcomeGroup.title}</TruncateWithTooltip>
      </Text>
    </Flex.Item>
    <Flex.Item>
      <Pill>{I18n.t('%{numMastered} of %{numGroup} Mastered', {numMastered, numGroup})}</Pill>
    </Flex.Item>
  </Flex>
)

class OutcomeGroup extends React.Component {
  static propTypes = {
    outcomeGroup: shapes.outcomeGroupShape.isRequired,
    outcomes: PropTypes.arrayOf(shapes.outcomeShape).isRequired,
    expanded: PropTypes.bool.isRequired,
    expandedOutcomes: ImmutablePropTypes.set.isRequired,
    onExpansionChange: PropTypes.func.isRequired,
    outcomeProficiency: shapes.outcomeProficiencyShape,
    breakpoints: breakpointsShape,
  }

  static defaultProps = {
    outcomeProficiency: null,
    breakpoints: {},
  }

  handleToggle = (_event, expanded) => {
    this.props.onExpansionChange('group', this.props.outcomeGroup.id, expanded)
  }

  render() {
    const {
      outcomeGroup,
      outcomes,
      expanded,
      expandedOutcomes,
      onExpansionChange,
      outcomeProficiency,
      breakpoints,
    } = this.props
    const numMastered = outcomes.filter(o => o.mastered).length
    const numGroup = outcomes.length
    const isVertical = !breakpoints.tablet

    return (
      <View as="div" className="outcomeGroup">
        <ToggleGroup
          summary={outcomeGroupHeader(outcomeGroup, numMastered, numGroup, isVertical)}
          toggleLabel={I18n.t('Toggle outcomes for %{title}', {title: outcomeGroup.title})}
          expanded={expanded}
          onToggle={this.handleToggle}
        >
          <List isUnstyled={true} delimiter="solid">
            {outcomes.sort(natcompare.byKey('title')).map(outcome => (
              <List.Item key={outcome.id} margin="0">
                <Outcome
                  outcome={outcome}
                  expanded={expandedOutcomes.has(outcome.expansionId)}
                  onExpansionChange={onExpansionChange}
                  outcomeProficiency={outcomeProficiency}
                />
              </List.Item>
            ))}
          </List>
        </ToggleGroup>
      </View>
    )
  }
}

export default WithBreakpoints(OutcomeGroup)
