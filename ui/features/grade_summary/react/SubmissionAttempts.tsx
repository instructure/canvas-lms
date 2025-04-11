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

import React, {useEffect, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {IconButton} from '@instructure/ui-buttons'
import {IconDiscussionLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import canvas from '@instructure/ui-themes'
import type {
  Attachment,
  SubmissionComment,
  MediaSource,
  MediaTrack,
  MediaObject,
} from '../../../api.d'
import useStore from './stores'
import {Badge} from '@instructure/ui-badge'
import {Link} from '@instructure/ui-link'
// @ts-expect-error
import {MediaPlayer} from '@instructure/ui-media-player'
import {getIconByType} from '@canvas/mime/react/mimeClassIconHelper'
import sanitizeHtml from 'sanitize-html-with-tinymce'
import {containsHtmlTags, formatMessage} from '@canvas/util/TextHelper'
import {StudioPlayer, type StudioPlayerProps} from '@instructure/studio-player'
import {GlobalEnv} from '../../../shared/global/env/GlobalEnv'
import {Spacing} from '@instructure/emotion'

const I18n = createI18nScope('grade_summary')

declare const ENV: GlobalEnv & {
  consolidated_media_player?: boolean
}

type AttachmentProps = Pick<Attachment, 'id' | 'mime_class' | 'display_name' | 'url'>
type SubmissionCommentProps = Pick<
  SubmissionComment,
  'id' | 'comment' | 'author_name' | 'is_read' | 'display_updated_at' | 'media_object'
> & {attachments: AttachmentProps[]}

export type SubmissionAttemptsProps = {
  attempts: {
    [key: string]: SubmissionCommentProps[]
  }
}

export default function SubmissionAttempts({attempts}: SubmissionAttemptsProps) {
  const assignmentUrl = useStore(state => state.submissionTrayAssignmentUrl)
  const [allAttemptCounts, setAllAttemptCounts] = useState<string[]>([])

  useEffect(() => {
    setAllAttemptCounts(Object.keys(attempts).sort((a, b) => (a > b ? -1 : 1)))
  }, [attempts])

  return (
    <>
      {allAttemptCounts?.map(attempt => (
        <View as="div" key={`comment-attempt-${attempt}`} padding="0 0 medium 0">
          <View as="div" background="secondary">
            <Flex as="div" justifyItems="space-between">
              <View as="div" margin="x-small small">
                <Text size="small" weight="bold" data-testid="submission-comment-attempt">
                  {I18n.t('Attempt %{attempt} Feedback:', {attempt})}
                </Text>
              </View>
              <IconButton
                size="small"
                color="primary"
                screenReaderLabel={I18n.t('See comments details')}
                margin="x-small medium"
                href={assignmentUrl}
              >
                <IconDiscussionLine />
              </IconButton>
            </Flex>
          </View>
          <SubmissionAttemptComments comments={attempts[attempt]} />
        </View>
      ))}
    </>
  )
}

type SubmissionAttemptProps = {
  comments?: SubmissionCommentProps[]
}

function SubmissionAttemptComments({comments}: SubmissionAttemptProps) {
  if (!comments) return null

  const {borders, colors, spacing} = canvas
  const isNewMediaPlayer = ENV.consolidated_media_player ?? false

  return (
    <>
      {comments.map((comment, i) => {
        const mediaObject = comment.media_object
        const formattedComment = containsHtmlTags(comment.comment)
          ? sanitizeHtml(comment.comment)
          : formatMessage(comment.comment)

        return (
          <Flex as="div" direction="column" key={comment.id} data-testid="submission-comment">
            <div
              style={{
                margin: `${spacing.small}`,
                ...(i > 0 && {
                  borderTop: `${borders.widthSmall} solid ${colors.contrasts.grey1214}`,
                  paddingTop: `${spacing.small}`,
                }),
              }}
            >
              <Text weight="bold" size="small">
                {I18n.t('%{display_updated_at}', {display_updated_at: comment.display_updated_at})}
              </Text>
              {!comment.is_read && (
                <View
                  as="span"
                  position="absolute"
                  insetInlineEnd="1.5rem"
                  data-testid="submission-comment-unread"
                >
                  <Badge type="notification" standalone={true} placement="end center" />
                </View>
              )}
            </div>
            <View as="div" margin="0 medium 0 small">
              <Text
                size="small"
                data-testid="submission-comment-content"
                dangerouslySetInnerHTML={{
                  __html: formattedComment,
                }}
              />
            </View>
            {comment.attachments?.map(attachment => (
              <View
                as="div"
                margin="0 medium 0 small"
                key={attachment.id}
                data-testid={`attachment-${attachment.id}`}
              >
                <Link
                  href={attachment.url}
                  isWithinText={false}
                  renderIcon={getIconByType(attachment.mime_class)}
                >
                  {attachment.display_name}
                </Link>
              </View>
            ))}
            {mediaObject &&
              (isNewMediaPlayer ? (
                <CommentStudioPlayer mediaObject={mediaObject} />
              ) : (
                <CommentMediaPlayer mediaObject={mediaObject} />
              ))}
            <View as="div" textAlign="end" margin="0 medium 0 0">
              <Text weight="bold" size="small" data-testid="submission-comment-author">
                - {I18n.t('%{display_name}', {display_name: comment.author_name})}
              </Text>
            </View>
          </Flex>
        )
      })}
    </>
  )
}

type CommentMediaPlayerProps = {
  mediaObject: MediaObject
}
function CommentMediaPlayer({mediaObject}: CommentMediaPlayerProps) {
  const mediaSources: MediaSource[] = []
  const mediaTracks: MediaTrack[] = []

  for (const it of mediaObject.media_sources) {
    mediaSources.push({
      ...it,
      src: it.url,
      label: `${it.width}x${it.height}`,
    })
  }

  for (const it of mediaObject.media_tracks) {
    mediaTracks.push({
      ...it,
      src: `/media_objects/${mediaObject.id}/media_tracks/${it.id}`,
      label: it.locale,
      type: it.kind,
      language: it.locale,
    })
  }

  const styles = {
    padding: '0 small' as Spacing,
  }
  return (
    <View data-testid="submission-comment-media" as="span" {...styles}>
      <MediaPlayer sources={mediaSources} tracks={mediaTracks} />
    </View>
  )
}

function CommentStudioPlayer({mediaObject}: CommentMediaPlayerProps) {
  const mediaSources: StudioPlayerProps['src'] = []
  const mediaCaptions: StudioPlayerProps['captions'] = []

  for (const it of mediaObject.media_sources) {
    mediaSources.push({
      src: it.url,
      type: it.content_type as any,
      width: Number(it.width),
      height: Number(it.height),
    })
  }

  for (const it of mediaObject.media_tracks) {
    mediaCaptions.push({
      src: `/media_objects/${mediaObject.id}/media_tracks/${it.id}`,
      label: it.locale,
      type: it.kind as any,
      language: it.locale,
    })
  }

  const styles = {height: '300px', padding: '0 small' as Spacing}

  return (
    <View data-testid="submission-comment-media" as="span" {...styles}>
      <StudioPlayer
        src={mediaSources}
        captions={mediaCaptions}
        title={I18n.t('Play Media Comment')}
      />
    </View>
  )
}
