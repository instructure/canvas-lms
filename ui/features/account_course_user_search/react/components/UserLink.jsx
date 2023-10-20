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
import {Avatar} from '@instructure/ui-avatar'
import {Link} from '@instructure/ui-link'

export default function UserLink({size, avatar_url, name, avatarName, ...propsToPassOnToLink}) {
  return (
    <Link
      themeOverride={{mediumPaddingHorizontal: '0', mediumHeight: '1rem'}}
      data-heap-redact-text=""
      {...propsToPassOnToLink}
    >
      <Avatar
        size={size}
        name={avatarName}
        src={avatar_url}
        margin="0 x-small xxx-small 0"
        data-fs-exclude={true}
        data-heap-redact-attributes="name"
      />
      {name}
    </Link>
  )
}

UserLink.propTypes = {
  size: Avatar.propTypes.size,
  href: Link.propTypes.href,
  name: Avatar.propTypes.name,
  avatarName: Avatar.propTypes.name,
  avatar_url: Avatar.propTypes.src,
}
