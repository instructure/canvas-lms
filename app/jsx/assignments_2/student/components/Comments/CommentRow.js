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
import Avatar from '@instructure/ui-elements/lib/components/Avatar'
import FriendlyDatetime from '../../../../shared/FriendlyDatetime'
import I18n from 'i18n!assignments_2'
import Link from '@instructure/ui-elements/lib/components/Link'
import React from 'react'
import Text from '@instructure/ui-elements/lib/components/Text'
import {CommentShape} from '../../assignmentData'
import {VideoPlayer} from '@instructure/ui-media-player'
import {getIconByType} from '../../../../shared/helpers/mimeClassIconHelper'

function CommentRow(props) {
  const author = props.comment.author
  const mediaObject = props.comment.mediaObject
  if (mediaObject) {
    mediaObject.mediaSources.forEach(function(mediaSource) {
      mediaSource.label = `${mediaSource.width}x${mediaSource.height}`
    })
  }
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
        <Text color={props.comment._id === 'pending' ? 'secondary' : null}>
          {props.comment.comment}
        </Text>
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
          <VideoPlayer
            tracks={[
              {
                src:
                  'http://localhost:3000/media_objects/m-2bpCURwK6FnmB6kJzeuuF1PuboAraKdc/media_tracks/7',
                label: 'en',
                type: 'subtitles',
                language: 'en'
              },
              {
                src:
                  'http://localhost:3000/media_objects/m-2bpCURwK6FnmB6kJzeuuF1PuboAraKdc/media_tracks/7',
                label: 'fr',
                type: 'subtitles',
                language: 'fr'
              }
            ]}
            sources={mediaObject.mediaSources}
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
