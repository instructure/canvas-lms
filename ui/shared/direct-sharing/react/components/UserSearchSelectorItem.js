/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

// import I18n from 'i18n!user_search_selector_item'
import React from 'react'

import {Text} from '@instructure/ui-text'
import {Avatar} from '@instructure/ui-avatar'
import {Flex} from '@instructure/ui-flex'

import {basicUser} from '@canvas/users/react/proptypes/user'

UserSearchSelectorItem.propTypes = {
  user: basicUser
}

export default function UserSearchSelectorItem({user}) {
  const {name, email, avatar_url} = user
  return (
    <Flex>
      <Flex.Item>
        <Avatar name={name} src={avatar_url} data-fs-exclude />
      </Flex.Item>
      <Flex.Item padding="0 0 0 small" grow>
        <Flex direction="column">
          <Flex.Item>
            <Text size="medium">{name}</Text>
          </Flex.Item>
          <Flex.Item>
            <Text size="small">{email}</Text>
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}
