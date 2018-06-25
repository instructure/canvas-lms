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
import I18n from 'i18n!outcomes'
import Flex, { FlexItem } from '@instructure/ui-layout/lib/components/Flex'
import View from '@instructure/ui-layout/lib/components/View'
import ToggleGroup from '@instructure/ui-toggle-details/lib/components/ToggleGroup'
import List, { ListItem } from '@instructure/ui-elements/lib/components/List'
import Pill from '@instructure/ui-elements/lib/components/Pill'
import Text from '@instructure/ui-elements/lib/components/Text'
import natcompare from 'compiled/util/natcompare'
import Outcome from './Outcome'
import * as shapes from './shapes'

const outcomeGroupHeader = (outcomeGroup, numMastered, numGroup) => (
  <Flex justifyItems="space-between">
    <FlexItem padding="0 x-small 0 0"><Text size="large" weight="bold">{ outcomeGroup.title }</Text></FlexItem>
    <FlexItem><Pill text={I18n.t('%{numMastered} of %{numGroup} Mastered', { numMastered, numGroup })} /></FlexItem>
  </Flex>
)

export default class OutcomeGroup extends React.Component {
  static propTypes = {
    outcomeGroup: shapes.outcomeGroupShape.isRequired,
    outcomes: PropTypes.arrayOf(shapes.outcomeShape).isRequired,
    expanded: PropTypes.bool.isRequired,
    expandedOutcomes: ImmutablePropTypes.set.isRequired,
    onExpansionChange: PropTypes.func.isRequired,
    outcomeProficiency: shapes.outcomeProficiencyShape
  }

  static defaultProps = {
    outcomeProficiency: null
  }

  handleToggle = (_event, expanded) => {
    this.props.onExpansionChange('group', this.props.outcomeGroup.id, expanded)
  }

  render () {
    const { outcomeGroup, outcomes, expanded, expandedOutcomes, onExpansionChange, outcomeProficiency } = this.props
    const numMastered = outcomes.filter((o) => o.mastered).length
    const numGroup = outcomes.length

    return (
      <View as="div" className="outcomeGroup">
        <ToggleGroup
          summary={outcomeGroupHeader(outcomeGroup, numMastered, numGroup)}
          toggleLabel={I18n.t('Toggle outcomes for %{title}', { title: outcomeGroup.title })}
          expanded={expanded}
          onToggle={this.handleToggle}
        >
          <List variant="unstyled" delimiter="solid">
            {
              outcomes.sort(natcompare.byKey('title')).map((outcome) => (
                <ListItem key={outcome.id} margin="0">
                  <Outcome
                    outcome={outcome}
                    expanded={expandedOutcomes.has(outcome.expansionId)}
                    onExpansionChange={onExpansionChange}
                    outcomeProficiency={outcomeProficiency} />
                </ListItem>
              ))
            }
          </List>
        </ToggleGroup>
      </View>
    )
  }
}
