/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import React, {useCallback} from 'react'
import {Avatar} from '@instructure/ui-avatar'

import {users, type Announcement, type User} from '../../../../assets/data/announcements'
import {Flex} from '@instructure/ui-flex'

import {Text} from '@instructure/ui-text'

type AnnouncementViewProps = {
  announcement: Announcement
}

export const AnnouncementView = ({announcement}: AnnouncementViewProps) => {
  const user = users.find((user: User) => user.id === announcement.user_id)
  return (
    <Flex direction="column" padding="small">
      <Flex>
        <Avatar name={user.name} />
        <Flex direction="column" padding="small">
          <Text>{user.name}</Text>
          <Text>Author | Teacher</Text>
        </Flex>
      </Flex>
      <Flex direction="column" gap="none">
        <h1>{announcement.title}</h1>
        <span dangerouslySetInnerHTML={{__html: announcement.message}} />
      </Flex>
    </Flex>
  )
}
