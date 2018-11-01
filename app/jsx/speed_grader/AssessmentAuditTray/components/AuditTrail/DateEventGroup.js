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

import React, {PureComponent} from 'react'
import List, {ListItem} from '@instructure/ui-elements/lib/components/List'
import Text from '@instructure/ui-elements/lib/components/Text'
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!speed_grader'
import timezone from 'timezone'

import AuditEvent from './AuditEvent'
import * as propTypes from './propTypes'

function dateString(date) {
  const monthAndDay = timezone.format(date, '%B %-d')
  const time = timezone.format(date, '%-l:%M%P')
  return I18n.t('%{monthAndDay} starting at %{time}', {monthAndDay, time})
}

export default class DateEventGroup extends PureComponent {
  static propTypes = {
    dateEventGroup: propTypes.dateEventGroup.isRequired
  }

  render() {
    const {auditEvents, startDate} = this.props.dateEventGroup

    return (
      <View as="div" margin="medium none">
        <Text as="h4" fontStyle="italic" size="small" weight="bold">
          {dateString(startDate)}
        </Text>

        <List variant="unstyled">
          {auditEvents.map(({auditEvent, studentAnonymity}) => (
            <ListItem key={auditEvent.id} margin="small none none none">
              <AuditEvent auditEvent={auditEvent} studentAnonymity={studentAnonymity} />
            </ListItem>
          ))}
        </List>
      </View>
    )
  }
}
