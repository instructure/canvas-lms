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
import ToggleDetails from '@instructure/ui-toggle-details/lib/components/ToggleDetails'
import List, { ListItem } from '@instructure/ui-elements/lib/components/List'
import Pill from '@instructure/ui-elements/lib/components/Pill'
import Text from '@instructure/ui-elements/lib/components/Text'
import IconArrowOpenDown from '@instructure/ui-icons/lib/Solid/IconArrowOpenDown'
import IconArrowOpenEnd from '@instructure/ui-icons/lib/Solid/IconArrowOpenEnd'
import Outcome from './Outcome'
import * as shapes from './shapes'

const spacyIcon = (expanded) => () => {
  const Icon = expanded ? IconArrowOpenDown : IconArrowOpenEnd
  return (
    <View padding="0 0 0 small"><Icon /></View>
  )
}

const outcomeGroupHeader = (outcomeGroup, numMastered, numGroup) => (
  <Flex justifyItems="space-between" padding="medium x-small">
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
    onExpansionChange: PropTypes.func.isRequired
  }

  handleToggle = (_event, expanded) => {
    this.props.onExpansionChange('group', this.props.outcomeGroup.id, expanded)
  }

  render () {
    const { outcomes, outcomeGroup, expanded, expandedOutcomes, onExpansionChange } = this.props
    const numMastered = outcomes.filter((o) => o.mastered).length
    const numGroup = outcomes.length

    return (
      <View as="div" className="outcomeGroup" borderWidth="small" background="default" borderRadius="large">
        <ToggleDetails
          divider="solid"
          icon={spacyIcon(false)}
          iconExpanded={spacyIcon(true)}
          summary={outcomeGroupHeader(outcomeGroup, numMastered, numGroup)}
          expanded={expanded}
          onToggle={this.handleToggle}
          fluidWidth
        >
          <View as="div" borderWidth="small 0 0 0">
            <List variant="unstyled" divider="solid">
              {
                outcomes.map((outcome) => (
                  <ListItem key={outcome.id} margin="0">
                    <Outcome
                      outcome={outcome}
                      expanded={expandedOutcomes.has(outcome.expansionId)}
                      onExpansionChange={onExpansionChange} />
                  </ListItem>
                ))
              }
            </List>
          </View>
        </ToggleDetails>
      </View>
    )
  }
}
