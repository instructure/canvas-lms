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
import React from 'react'
import {Text} from '@instructure/ui-text'
import {Badge} from '@instructure/ui-badge'
import {Avatar} from '@instructure/ui-avatar'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import {getIconByType} from '@canvas/mime/react/mimeClassIconHelper'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {SubmissionHtmlComment} from '@canvas/assignments/graphql/student/SubmissionComment'
import {Link} from '@instructure/ui-link'
import sanitizeHtml from 'sanitize-html-with-tinymce'
import CanvasStudioPlayer from '@canvas/canvas-studio-player'
import {containsHtmlTags, formatMessage, stripHtmlTags} from '@canvas/util/TextHelper'

const I18n = createI18nScope('assignments_2')

export default function CommentRow(props) {
  const {author, mediaObject, read, htmlComment} = props.comment

  return (
    <div className="comment-row-container" data-testid="comment-row">
      <div className="comment-avatar-container">
        <div style={{display: 'flex', alignItems: 'center'}}>
          <Badge
            margin="0 xx-small 0 0"
            themeOverride={read ? {colorPrimary: 'white'} : undefined}
            type="notification"
            standalone={true}
          />
          <Avatar
            name={author ? stripHtmlTags(author.shortName) : I18n.t('Anonymous')}
            src={author ? author.avatarUrl : ''}
            margin="0 small 0 0"
            data-fs-exclude={true}
          />
        </div>
      </div>
      <div className="comment-text-comment-container">
        {!read && <ScreenReaderContent>{I18n.t('Unread')}</ScreenReaderContent>}
        <Text id={`comment-header-${props.comment._id}`} weight="light" size="small">
          {author ? stripHtmlTags(author.shortName) : I18n.t('Anonymous')}{' '}
          <FriendlyDatetime
            prefix={I18n.t('at')}
            format={I18n.t('#date.formats.full_with_weekday')}
            dateTime={props.comment.updatedAt}
          />
        </Text>
        <Text
          color={props.comment._id === 'pending' ? 'secondary' : null}
          wrap="break-word"
          data-testid="commentContent"
          dangerouslySetInnerHTML={{
            __html: containsHtmlTags(htmlComment)
              ? sanitizeHtml(htmlComment)
              : formatMessage(htmlComment),
          }}
        />
        {props.comment.attachments.map(attachment => (
          <Link
            key={attachment._id}
            href={attachment.url}
            isWithinText={false}
            renderIcon={getIconByType(attachment.mimeClass)}
            themeOverride={{mediumPaddingHorizontal: '0', mediumHeight: 'normal'}}
          >
            {attachment.displayName}
          </Link>
        ))}
        {mediaObject && (
          <CanvasStudioPlayer media_id={mediaObject._id} explicitSize={{width: 368, height: 206}} />
        )}
      </div>
    </div>
  )
}

CommentRow.propTypes = {
  comment: SubmissionHtmlComment.shape.isRequired,
}
