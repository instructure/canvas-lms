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
import I18n from 'i18n!assignments_2'
import React from 'react'
import ReactPlayer from 'react-player'
import {CommentShape} from '../../assignmentData'
import Avatar from '@instructure/ui-elements/lib/components/Avatar'
import Link from '@instructure/ui-elements/lib/components/Link'
import Text from '@instructure/ui-elements/lib/components/Text'
import FriendlyDatetime from '../../../../shared/FriendlyDatetime'
import {getIconByType} from '../../../../shared/helpers/mimeClassIconHelper'

function CommentRow(props) {
  const author = props.comment.author
  const mediaObject = props.comment.mediaObject
  return (
    <div className="comment-row-container" data-testid="comment-row">
      <div className="comment-avatar-container">
        <Avatar
          name={author ? author.shortName : I18n.t('Anonymous')}
          src={author ? author.avatarUrl : ''}
          margin="0 small 0 0"
        />
      </div>
      <div className="comment-text-comment-container">
        <Text weight="light" size="small">
          {author ? author.shortName : I18n.t('Anonymous')}{' '}
          <FriendlyDatetime
            prefix={I18n.t('at')}
            format={I18n.t('#date.formats.full_with_weekday')}
            dateTime={props.comment.updatedAt}
          />
        </Text>
        <Text>{props.comment.comment}</Text>
        {props.comment.attachments.map(attachment => (
          <Link
            key={attachment._id}
            href={attachment.url}
            icon={getIconByType(attachment.mimeClass)}
          >
            {attachment.displayName}
          </Link>
        ))}
        {mediaObject && (
          <ReactPlayer
            height={mediaObject.mediaType !== 'audio' ? '360px' : '70px'}
            url={mediaObject.mediaSources}
            config={{file: {attributes: {title: mediaObject.title}}}}
            controls
          />
        )}
      </div>
    </div>
  )
}

CommentRow.propTypes = {
  comment: CommentShape.isRequired
}

export default React.memo(CommentRow)
