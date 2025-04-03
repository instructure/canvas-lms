/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {Avatar, type AvatarProps} from '@instructure/ui-avatar'
import {Link, type LinkProps} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'

export interface UserLinkProps {
  size: AvatarProps['size']
  href: LinkProps['href']
  name: string
  pronouns?: string
  avatar_url: string
  avatarName: AvatarProps['name']
}

export default function UserLink(props: UserLinkProps): JSX.Element {
  const {size, name, avatarName, avatar_url, pronouns, href} = props
  return (
    <Link href={href}>
      <Avatar
        size={size}
        name={avatarName}
        src={avatar_url}
        margin="0 x-small xxx-small 0"
        data-fs-exclude={true}
      />
      {name} {pronouns && <Text fontStyle="italic">({pronouns})</Text>}
    </Link>
  )
}
