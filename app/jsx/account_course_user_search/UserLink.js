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
import {string} from 'prop-types'

export default function UserLink ({ id, display_name, avatar_image_url }) {
  const url = `/users/${id}`
  return (
    <div className="ellipsis">
      {!!avatar_image_url &&
        <span className="ic-avatar UserLink__Avatar">
          <img src={avatar_image_url}  alt='' />
        </span>
      }
      <a href={url} className="user_link">{display_name}</a>
    </div>
  )
}

UserLink.propTypes = {
  id: string.isRequired,
  display_name: string.isRequired,
  avatar_image_url: string
}
