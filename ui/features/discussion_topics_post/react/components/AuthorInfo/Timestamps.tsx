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

import {ReactNode, useMemo} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {parse} from '@instructure/moment-utils'
import DateHelper from '@canvas/datetime/dateHelper'
import {UserType} from './AuthorInfo'
import {NameLink} from './NameLink'
import {hideStudentNames, userNameToShow} from '../../utils'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconPinSolid} from '@instructure/ui-icons'

const I18n = createI18nScope('discussion_topics_post')

interface TimestampsProps {
  author?: UserType
  editor?: UserType
  createdAt?: string
  delayedPostAt?: string
  editedTimingDisplay?: string
  lastReplyAtDisplay?: string
  timestampTextSize: string
  mobileOnly?: boolean
  isTopic?: boolean
  published?: boolean
  isAnnouncement?: boolean
  showCreatedAsTooltip?: boolean
  isPinned?: boolean
  pinnedBy?: UserType
  withoutPadding?: boolean
  container?: 'reply' | 'topic' | 'pinned' // only the pinned container is required at the moment
  replyNode?: ReactNode
}

const Timestamps = (props: TimestampsProps) => {
  const isTeacher =
    ENV?.current_user_roles &&
    ENV?.current_user_roles.includes('teacher') &&
    !ENV?.current_user_is_student

  const editText = useMemo(() => {
    if (!props.editedTimingDisplay) {
      return null
    }

    const editedDate = parse(props.editedTimingDisplay)
    const delayedDate = parse(props.delayedPostAt)
    // do not show edited by info for students if the post is edited before the delayed post date
    if (!isTeacher && delayedDate && editedDate?.isBefore(delayedDate)) {
      return null
    }

    // do not show edited by info for anonymous discussions
    if (props.editor && props.author && props.editor?._id !== props.author?._id) {
      return (
        <span data-testid="editedByText">
          {!hideStudentNames ? (
            <>
              {I18n.t('Edited by')} <NameLink userType="editor" user={props.editor} />{' '}
              {I18n.t('%{editedTimingDisplay}', {
                editedTimingDisplay: props.editedTimingDisplay,
              })}
            </>
          ) : (
            I18n.t('Edited by %{editorName} %{editedTimingDisplay}', {
              editorName: userNameToShow(
                props.editor.displayName || props.editor.shortName,
                props.author._id,
                props.editor.courseRoles,
              ),
              editedTimingDisplay: props.editedTimingDisplay,
            })
          )}
        </span>
      )
    } else {
      return I18n.t('Last edited %{editedTimingDisplay}', {
        editedTimingDisplay: props.editedTimingDisplay,
      })
    }
  }, [props.editedTimingDisplay, props.delayedPostAt, props.editor, props.author, isTeacher])

  const timestampsPadding = useMemo(() => {
    if (props.withoutPadding) {
      return '0 xx-small 0 0'
    }

    return props.mobileOnly ? '0 xx-small 0 0' : 'xx-small xx-small xx-small 0'
  }, [props.mobileOnly, props.withoutPadding])

  const createdAtText = useMemo(() => {
    // show basic date for replies
    if (!props.isTopic) {
      if (props.container === 'pinned') {
        return I18n.t('Posted on %{createdAt}', {createdAt: props.createdAt})
      } else {
        return props.createdAt
      }
    }
    // show the original created date for teachers
    if (isTeacher) {
      return I18n.t('Created %{createdAt}', {createdAt: props.createdAt})
    } else {
      // don't show the created date for students if the post is delayed
      return props.delayedPostAt
        ? null
        : I18n.t('Posted %{createdAt}', {createdAt: props.createdAt})
    }
  }, [isTeacher, props.createdAt, props.delayedPostAt, props.isTopic, props.container])

  const pinnedPostText = useMemo(() => {
    if (!ENV?.discussion_pin_post) return null

    if (!props.isPinned || !props.pinnedBy) return null

    return I18n.t('Pinned by %{pinnedByName}', {
      pinnedByName: props.pinnedBy.shortName,
    })
  }, [props.isPinned, props.pinnedBy])

  const delayedPostText = useMemo(() => {
    if (!props.isTopic) return null
    // duplicate createdAt for teachers if the post is instant
    if (isTeacher && !props.delayedPostAt && props.createdAt && props.published) {
      return I18n.t('Posted %{createdAt}', {createdAt: props.createdAt})
    }
    if (props.delayedPostAt) {
      // announcements are "published" always, so we need to compare dates
      if (props.isAnnouncement && parse(props.delayedPostAt)?.isAfter(new Date())) {
        return null
      }

      return I18n.t('Posted %{delayedPostAt}', {
        delayedPostAt: DateHelper.formatDatetimeForDiscussions(props.delayedPostAt),
      })
    }
  }, [
    isTeacher,
    props.createdAt,
    props.delayedPostAt,
    props.isAnnouncement,
    props.isTopic,
    props.published,
  ])

  const lastReplyAtText = useMemo(() => {
    if (props.container === 'pinned') {
      return I18n.t('Last reply on %{lastReplyAtDisplay}', {
        lastReplyAtDisplay: props.lastReplyAtDisplay,
      })
    }

    return I18n.t('Last reply %{lastReplyAtDisplay}', {
      lastReplyAtDisplay: props.lastReplyAtDisplay,
    })
  }, [props.lastReplyAtDisplay, props.container])

  return (
    <Flex wrap="wrap">
      {pinnedPostText && (
        <Flex.Item data-testid="pinned-by-user-text" overflowX="hidden" padding={timestampsPadding}>
          <Text size={props.timestampTextSize as any}>
            <IconPinSolid /> {pinnedPostText}
          </Text>
        </Flex.Item>
      )}
      {createdAtText && (
        <Flex.Item overflowX="hidden" padding={timestampsPadding}>
          <Text size={props.timestampTextSize as any}>
            {pinnedPostText && ' | '}
            {createdAtText}
          </Text>
        </Flex.Item>
      )}
      {delayedPostText && (
        <Flex.Item overflowX="hidden" padding={timestampsPadding}>
          <Text size={props.timestampTextSize as any}>
            {createdAtText && ' | '}
            {delayedPostText}
          </Text>
        </Flex.Item>
      )}
      {editText && (
        <Flex.Item overflowX="hidden" padding={timestampsPadding}>
          <Text size={props.timestampTextSize as any}>
            {' | '}
            {editText}
          </Text>
        </Flex.Item>
      )}
      {props.lastReplyAtDisplay && (
        <Flex.Item overflowX="hidden" padding="0 xx-small 0 0">
          <Text size={props.timestampTextSize as any} data-testid="last-reply-at-text">
            {' | '}
            {lastReplyAtText}
          </Text>
        </Flex.Item>
      )}
      {props.container === 'pinned' && props.replyNode}
    </Flex>
  )
}

export {Timestamps}
