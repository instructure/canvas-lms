/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import $ from 'jquery'
import '@canvas/datetime/jquery' // $.datetimeString
import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'

import {List} from '@instructure/ui-list'
import {View} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import {Tooltip} from '@instructure/ui-tooltip'
import {ToggleGroup} from '@instructure/ui-toggle-details'

const I18n = useI18nScope('course_settings')

const usersList = userIds => {
  if (userIds && userIds.length > 0) {
    return (
      <List size="small">
        {userIds.map(listItem => (
          <List.Item key={listItem}>
            <Link href={`/users/${listItem}`}>{listItem}</Link>
          </List.Item>
        ))}
      </List>
    )
  }
}

const debugInfoItem = (item, index) => {
  if (item && item.msg && item.msg.length > 0) {
    return (
      <List.Item key={index}>
        <Tooltip renderTip={$.datetimeString(item.timestamp)}>{item.msg}</Tooltip>
        {usersList(item.user_ids)}
      </List.Item>
    )
  }
}

const MicrosoftSyncDebugInfo = ({debugInfo}) => {
  const [expanded, setExpanded] = useState(false)

  return (
    <View as="div" borderWidth="none none small none" borderColor="primary" padding="small small">
      <ToggleGroup
        summary={I18n.t('Debugging Info (Advanced)...')}
        expanded={expanded}
        onToggle={() => setExpanded(!expanded)}
        toggleLabel={I18n.t('Toggle Debugging Info')}
      >
        <List size="small">{debugInfo.map(debugInfoItem)}</List>
      </ToggleGroup>
    </View>
  )
}

export default MicrosoftSyncDebugInfo
