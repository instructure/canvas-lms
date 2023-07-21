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
import {useScope as useI18nScope} from '@canvas/i18n'
import {OverrideShape} from '../../assignmentData'
import OverrideAttempts from './OverrideAttempts'
import OverrideAssignTo from './OverrideAssignTo'
import OverrideSubmissionTypes from './OverrideSubmissionTypes'
import TeacherViewContext from '../TeacherViewContext'
import AvailabilityDates from '@canvas/assignments/react/AvailabilityDates'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'

import {Responsive} from '@instructure/ui-responsive'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('assignments_2')

export default class OverrideSummary extends React.Component {
  static contextType = TeacherViewContext

  static propTypes = {
    override: OverrideShape,
  }

  renderTitle(override) {
    return <Text weight="bold">{override.title}</Text>
  }

  renderAttemptsAllowedAndSubmissionTypes(override) {
    return (
      <Text>
        <OverrideAttempts allowedAttempts={override.allowedAttempts} variant="summary" />
        <div style={{display: 'inline-block', padding: '0 .5em'}}>|</div>
        <OverrideSubmissionTypes variant="summary" override={override} />
      </Text>
    )
  }

  renderDueDate(override) {
    return (
      <Text color="secondary">
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
    )
  }

  // it's unfortunate but when both unlock and lock dates exist
  // AvailabilityDates only prefixes with "Available" if the formatStyle="long"
  // If I chnage it there, it will alter the Student view
  renderAvailability(override) {
    // both dates exist, manually add Available prefix
    if (override.unlockAt && override.lockAt) {
      return (
        <Text color="secondary">
          {I18n.t('Available ')}
          <AvailabilityDates assignment={override} formatStyle="short" />
        </Text>
      )
    }
    // only one date exists, AvailabilityDates will include the Available prefix
    if (override.unlockAt || override.lockAt) {
      return (
        <Text color="secondary">
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
            largerScreen: {minWidth: '36rem'},
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
                  {this.renderAttemptsAllowedAndSubmissionTypes(override)}
                </View>
              </View>
            )

            const rightColumn = (
              <View display="block">
                <View display="block" margin="0 0 xxx-small">
                  {this.renderDueDate(override)}
                </View>
                <View display="block">{this.renderAvailability(override)}</View>
              </View>
            )

            return (
              <View as="div" data-testid="OverrideSummary">
                {largerScreen ? (
                  <Flex justifyItems="space-between">
                    <Flex.Item shouldGrow={true} shouldShrink={true}>
                      {leftColumn}
                    </Flex.Item>
                    <Flex.Item textAlign="end">{rightColumn}</Flex.Item>
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
