/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {Avatar} from '@instructure/ui-avatar'
import {Link} from '@instructure/ui-link'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('course_people')

const AvatarLink = ({avatarUrl, name, href}) => {
  return (
    <Link href={href}>
      <Avatar
        size="small"
        src={avatarUrl}
        name={name}
        alt={I18n.t('Avatar for %{user_name}', {user_name: name})}
      />
    </Link>
  )
}

AvatarLink.propTypes = {
  avatarUrl: string,
  name: string.isRequired,
  href: string.isRequired,
}

AvatarLink.defaultProps = {
  avatarUrl: null,
}

export default AvatarLink
