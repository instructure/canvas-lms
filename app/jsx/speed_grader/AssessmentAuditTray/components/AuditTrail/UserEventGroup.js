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
import ApplyTheme from '@instructure/ui-themeable/lib/components/ApplyTheme'
import Text from '@instructure/ui-elements/lib/components/Text'
import ToggleDetails from '@instructure/ui-toggle-details/lib/components/ToggleGroup'
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!speed_grader'

import DateEventGroup from './DateEventGroup'
import * as propTypes from './propTypes'
import {roleLabelFor} from '../../AuditTrailHelpers'

const themeOverride = {
  [View.theme]: {
    borderStyle: 'dashed'
  }
}

export default class UserEventGroup extends PureComponent {
  static propTypes = {
    userEventGroup: propTypes.userEventGroup.isRequired
  }

  render() {
    const {dateEventGroups, user} = this.props.userEventGroup
    const userName = user.name || I18n.t('Unknown User')
    const roleLabel = roleLabelFor(user)

    return (
      <View as="div">
        <ApplyTheme theme={themeOverride}>
          <ToggleDetails
            border={false}
            id={`user-event-group-${user.id}`}
            summary={
              <Text as="h3">
                <Text weight="bold">{userName}</Text> ({roleLabel})
              </Text>
            }
            toggleLabel={I18n.t('Assessment audit events for %{userName}', {userName})}
          >
            <div>
              {dateEventGroups.map(dateEventGroup => (
                <DateEventGroup dateEventGroup={dateEventGroup} key={dateEventGroup.startDateKey} />
              ))}
            </div>
          </ToggleDetails>
        </ApplyTheme>

        <View as="div" borderWidth="none none small" margin="none" padding="none" />
      </View>
    )
  }
}
