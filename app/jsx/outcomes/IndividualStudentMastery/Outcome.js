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
import I18n from 'i18n!outcomes'
import View from '@instructure/ui-layout/lib/components/View'
import Flex, { FlexItem } from '@instructure/ui-layout/lib/components/Flex'
import ToggleDetails from '@instructure/ui-toggle-details/lib/components/ToggleDetails'
import List, { ListItem } from '@instructure/ui-elements/lib/components/List'
import Pill from '@instructure/ui-elements/lib/components/Pill'
import Text from '@instructure/ui-elements/lib/components/Text'
import IconArrowOpenDown from '@instructure/ui-icons/lib/Solid/IconArrowOpenDown'
import IconArrowOpenEnd from '@instructure/ui-icons/lib/Solid/IconArrowOpenEnd'
import IconOutcomes from '@instructure/ui-icons/lib/Line/IconOutcomes'
import natcompare from 'compiled/util/natcompare'
import AssignmentResult from './AssignmentResult'
import * as shapes from './shapes'

const spacyIcon = (expanded) => () => {
  const Icon = expanded ? IconArrowOpenDown : IconArrowOpenEnd
  return (
    <View padding="0 0 0 small"><Icon /></View>
  )
}

export default class Outcome extends React.Component {
  static propTypes = {
    outcome: shapes.outcomeShape.isRequired,
    expanded: PropTypes.bool.isRequired,
    onExpansionChange: PropTypes.func.isRequired
  }

  handleToggle = (_event, expanded) => {
    this.props.onExpansionChange('outcome', this.props.outcome.expansionId, expanded)
  }

  renderHeader () {
    const { outcome } = this.props
    const { mastered, results, title } = outcome
    const numAlignments = results.length

    return (
      <Flex direction="row" justifyItems='space-between' padding="small x-small">
        <FlexItem>
          <Flex direction="column">
            <FlexItem>
              <Text size="medium">
                <Flex>
                  <FlexItem><IconOutcomes /></FlexItem>
                  <FlexItem padding="0 x-small">{ title }</FlexItem>
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

  render () {
    const { outcome, expanded } = this.props
    const { results } = outcome

    return (
      <ToggleDetails
        divider="dashed"
        icon={spacyIcon(false)}
        iconExpanded={spacyIcon(true)}
        summary={this.renderHeader()}
        expanded={expanded}
        onToggle={this.handleToggle}
        fluidWidth
      >
        <View as="div" borderWidth="small 0 0 0">
          <List variant="unstyled" delimiter="dashed">
          {
            results.sort(natcompare.byKey('submitted_or_assessed_at')).reverse().map((result) => (
              <ListItem key={result.id}><AssignmentResult result={result} outcome={outcome} /></ListItem>
            ))
          }
          </List>
        </View>
      </ToggleDetails>
    )
  }
}
