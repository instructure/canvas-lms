/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {AnonymousAvatar} from '@canvas/discussions/react/components/AnonymousAvatar/AnonymousAvatar'
import {Avatar} from '@instructure/ui-avatar'
import {getDisplayName, isAnonymous, hideStudentNames} from '../../utils'

interface AuthorAvatarProps {
  entry: Record<string, any>
  avatarSize: 'x-small' | 'small' | 'medium'
}

const AuthorAvatar = ({entry, avatarSize}: AuthorAvatarProps) => {
  const avatarUrl = isAnonymous(entry) ? null : entry?.author?.avatarUrl

  return (
    <>
      {!isAnonymous(entry) && !hideStudentNames && (
        <Avatar
          size={avatarSize}
          name={getDisplayName(entry)}
          src={avatarUrl || undefined}
          margin="0"
          data-testid="author_avatar"
        />
      )}
      {!isAnonymous(entry) && hideStudentNames && (
        <AnonymousAvatar seedString={entry.author?._id} size={avatarSize} />
      )}
      {isAnonymous(entry) && (
        <AnonymousAvatar seedString={entry.anonymousAuthor?.shortName} size={avatarSize} />
      )}
    </>
  )
}

export {AuthorAvatar}
