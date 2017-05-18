/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import I18n from 'i18n!student_context_tray'
import React from 'react'
import PropTypes from 'prop-types'
import InstUIAvatar from 'instructure-ui/lib/components/Avatar'
import Typography from 'instructure-ui/lib/components/Typography'
import Link from 'instructure-ui/lib/components/Link'

class Avatar extends React.Component {
  static propTypes = {
    user: PropTypes.shape({
      name: PropTypes.string,
      avatar_url: PropTypes.string,
      short_name: PropTypes.string,
      id: PropTypes.string
    }).isRequired,
    courseId: PropTypes.oneOfType([
      PropTypes.string,
      PropTypes.number
    ]).isRequired,
    canMasquerade: PropTypes.bool.isRequired,
  }

  render () {
    const {user, courseId, canMasquerade} = this.props

    if (Object.keys(user).includes('avatar_url')) {
      const name = user.short_name || user.name || 'user';
      return (
        <div className="StudentContextTray__Avatar">
          <Link href={`/courses/${this.props.courseId}/users/${user.id}`} aria-label={I18n.t('Go to %{name}\'s profile', {name})}>
            <InstUIAvatar
              size="x-large"
              name={user.name}
              src={user.avatar_url}
            />
          </Link>
          {
            canMasquerade ? (
              <Typography size="x-small" weight="bold" as="div">
                <a
                  href={`/courses/${courseId}?become_user_id=${user.id}`}
                  aria-label={I18n.t('Masquerade as %{name}', { name: user.short_name })}
                >
                  {I18n.t('Masquerade')}
                </a>
              </Typography>
            ) : (
              null
            )
          }
        </div>
      )
    }
    return null
  }
}

export default Avatar
