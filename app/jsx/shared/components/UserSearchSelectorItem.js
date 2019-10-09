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

import {Avatar, Text} from '@instructure/ui-elements'
import {Flex} from '@instructure/ui-layout'

import basicUser from '../proptypes/user'

UserSearchSelectorItem.propTypes = {
  user: basicUser
}

export default function UserSearchSelectorItem({user}) {
  const {display_name, email, avatar_image_url} = user
  return (
    <Flex>
      <Flex.Item>
        <Avatar name={display_name} src={avatar_image_url} />
      </Flex.Item>
      <Flex.Item padding="0 0 0 small" grow>
        <Flex direction="column">
          <Flex.Item>
            <Text size="medium">{display_name}</Text>
          </Flex.Item>
          <Flex.Item>
            <Text size="small">{email}</Text>
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}
