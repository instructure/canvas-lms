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
import Avatar from '@instructure/ui-elements/lib/components/Avatar'
import Link from '@instructure/ui-elements/lib/components/Link'

export default function UserLink({size, avatar_url, name, ...propsToPassOnToLink}) {
  return (
    <Link {...propsToPassOnToLink} size={size}>
      <Avatar size={size} name={name} src={avatar_url} margin="0 xxx-small xxx-small 0" />
      {name}
    </Link>
  )
}

UserLink.propTypes = {
  href: Link.propTypes.href,
  name: Avatar.propTypes.name,
  avatar_url: Avatar.propTypes.src
}
