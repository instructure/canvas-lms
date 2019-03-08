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
import I18n from 'i18n!assignments_2'
import {OverrideShape} from '../../assignmentData'
import OverrideAttempts from './OverrideAttempts'
import OverrideAssignTo from './OverrideAssignTo'
import OverrideSubmissionTypes from './OverrideSubmissionTypes'
import TeacherViewContext from '../TeacherViewContext'
import AvailabilityDates from '../../../shared/AvailabilityDates'
import FriendlyDatetime from '../../../../shared/FriendlyDatetime'

import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Text from '@instructure/ui-elements/lib/components/Text'
import View from '@instructure/ui-layout/lib/components/View'
import Responsive from '@instructure/ui-layout/lib/components/Responsive'

export default class OverrideSummary extends React.Component {
  static contextType = TeacherViewContext

  static propTypes = {
    override: OverrideShape
  }

  renderTitle(override) {
    return <Text weight="bold">{override.title}</Text>
  }

  renderAttemptsAllowed(override) {
    const allowed = override.allowedAttempts
    const attempts = Number.isInteger(allowed) ? allowed : 1
    return <Text>{I18n.t({one: '1 Attempt', other: '%{count} Attempts'}, {count: attempts})}</Text>
  }

  renderSubmissionTypesAndDueDate(override) {
    return (
      <Text>
        <OverrideSubmissionTypes variant="summary" override={override} />
        <Text>
          <div style={{display: 'inline-block', padding: '0 .5em'}}>|</div>
          {override.dueAt ? (
            <FriendlyDatetime
              prefix={I18n.t('Due: ')}
              dateTime={override.dueAt}
              format={I18n.t('#date.formats.full')}
            />
          ) : (
            I18n.t('No Due Date')
          )}
        </Text>
      </Text>
    )
  }

  // it's unfortunate but when both unlock and lock dates exist
  // AvailabilityDates only prefixes with "Available" if the formatStyle="long"
  // If I chnage it there, it will alter the Student view
  renderAvailability(override) {
    // both dates exist, manually add Available prefix
    if (override.unlockAt && override.lockAt) {
      return (
        <Text>
          {I18n.t('Available ')}
          <AvailabilityDates assignment={override} formatStyle="short" />
        </Text>
      )
    }
    // only one date exists, AvailabilityDates will include the Available prefix
    if (override.unlockAt || override.lockAt) {
      return (
        <Text>
          <AvailabilityDates assignment={override} formatStyle="short" />
        </Text>
      )
    }
    // no dates exist, so the assignment is simply Available
    return <Text>{I18n.t('Available')}</Text>
  }

  render() {
    const override = this.props.override
    if (override) {
      return (
        <Responsive
          match="media"
          query={{
            largerScreen: {minWidth: '36rem'}
          }}
        >
          {(props, matches) => {
            const largerScreen = matches.includes('largerScreen')

            const leftColumn = (
              <View display="block" margin={largerScreen ? '0' : '0 0 small'}>
                <View display="block" margin="0 0 xxx-small">
                  <OverrideAssignTo override={override} variant="summary" />
                </View>
                <View display="block">
                  <OverrideAttempts override={override} variant="summary" />
                </View>
              </View>
            )

            const rightColumn = (
              <View display="block">
                <View display="block" margin="0 0 xxx-small">
                  {this.renderSubmissionTypesAndDueDate(override)}
                </View>
                <View display="block">{this.renderAvailability(override)}</View>
              </View>
            )

            return (
              <View as="div" data-testid="OverrideSummary">
                {largerScreen ? (
                  <Flex justifyItems="space-between">
                    <FlexItem grow shrink>
                      {leftColumn}
                    </FlexItem>
                    <FlexItem textAlign="end">{rightColumn}</FlexItem>
                  </Flex>
                ) : (
                  <View display="block">
                    {leftColumn}
                    {rightColumn}
                  </View>
                )}
              </View>
            )
          }}
        </Responsive>
      )
    } else {
      return <View as="div" />
    }
  }
}
