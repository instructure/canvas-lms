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
import {Avatar, Badge, Text} from '@instructure/ui-elements'
import {Button} from '@instructure/ui-buttons'
import FriendlyDatetime from '../../../../shared/FriendlyDatetime'
import {getIconByType} from '../../../../shared/helpers/mimeClassIconHelper'
import I18n from 'i18n!assignments_2'
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {SubmissionComment} from '../../graphqlData/SubmissionComment'
import {MediaPlayer} from '@instructure/ui-media-player'

export default function CommentRow(props) {
  const {author, mediaObject, read} = props.comment
  let mediaTracks = null
  if (mediaObject) {
    mediaObject.mediaSources.forEach(mediaSource => {
      mediaSource.label = `${mediaSource.width}x${mediaSource.height}`
    })
    mediaTracks = mediaObject?.mediaTracks.map(track => {
      return {
        src: `/media_objects/${mediaObject._id}/media_tracks/${track._id}`,
        label: track.locale,
        type: track.kind,
        language: track.locale
      }
    })
  }
  return (
    <div className="comment-row-container" data-testid="comment-row">
      <div className="comment-avatar-container">
        <Badge
          theme={read ? {colorPrimary: 'white'} : undefined}
          type="notification"
          standalone
          margin="0 small 0 0"
        />
        <Avatar
          name={author ? author.shortName : I18n.t('Anonymous')}
          src={author ? author.avatarUrl : ''}
          margin="0 small 0 0"
          data-fs-exclude
        />
      </div>
      <div className="comment-text-comment-container">
        {!read && <ScreenReaderContent>{I18n.t('Unread')}</ScreenReaderContent>}
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
          <Button
            variant="link"
            key={attachment._id}
            href={attachment.url}
            icon={getIconByType(attachment.mimeClass)}
            theme={{mediumPadding: '0', mediumHeight: 'normal'}}
          >
            {attachment.displayName}
          </Button>
        ))}
        {mediaObject && <MediaPlayer tracks={mediaTracks} sources={mediaObject.mediaSources} />}
      </div>
    </div>
  )
}

CommentRow.propTypes = {
  comment: SubmissionComment.shape.isRequired
}
