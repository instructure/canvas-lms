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
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!speed_grader'

import UserEventGroup from './UserEventGroup'
import * as propTypes from './propTypes'

export default class AuditTrail extends PureComponent {
  static propTypes = {
    auditTrail: propTypes.auditTrail.isRequired
  }

  render() {
    const {userEventGroups} = this.props.auditTrail
    const userEventGroupData = []

    Object.keys(userEventGroups).forEach(userId => {
      userEventGroupData.push({
        userEventGroup: userEventGroups[userId],
        userId,
        // A user could be unknown in the event we do not have user info loaded
        // for this user id. Display "Unknown User" as a fallback.
        userName: I18n.t('Unknown User')
      })
    })

    return (
      <View as="div" id="assessment-audit-trail">
        {userEventGroupData.map(datum => (
          <UserEventGroup
            key={datum.userId}
            userEventGroup={datum.userEventGroup}
            userId={datum.userId}
            userName={datum.userName}
          />
        ))}
      </View>
    )
  }
}
