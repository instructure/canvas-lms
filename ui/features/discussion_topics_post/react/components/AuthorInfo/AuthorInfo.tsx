/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {AnonymousUser} from '../../../graphql/AnonymousUser'
import {useScope as createI18nScope} from '@canvas/i18n'
import React, {useContext, useMemo} from 'react'
import {
  getDisplayName,
  hideStudentNames,
  isAnonymous,
  resolveAuthorRoles,
  userNameToShow,
} from '../../utils'
import {RolePillContainer} from '../RolePillContainer/RolePillContainer'
import {SearchContext} from '../../utils/constants'
import {SearchSpan} from '../SearchSpan/SearchSpan'
import {User} from '../../../graphql/User'

import {Avatar} from '@instructure/ui-avatar'
import {Badge} from '@instructure/ui-badge'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {DiscussionEntryVersion} from '../../../graphql/DiscussionEntryVersion'
import {DiscussionEntryVersionHistory} from '../DiscussionEntryVersionHistory/DiscussionEntryVersionHistory'
import {ReportsSummaryBadge} from '../ReportsSummaryBadge/ReportsSummaryBadge'
import theme from '@instructure/canvas-theme'
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints'
import {parse} from '@instructure/moment-utils'
import DateHelper from '@canvas/datetime/dateHelper'

const I18n = createI18nScope('discussion_posts')

interface UserType {
  id?: string
  _id?: string
  avatarUrl?: string
  displayName?: string
  htmlUrl?: string
  courseRoles?: string[]
  pronouns?: string
  shortName?: string
}

interface AnonymousUserType {
  id?: string
  avatarUrl?: string
  shortName?: string
}

interface AuthorInfoProps {
  /**
   * Object containing author information
   */
  author?: UserType
  /**
   * Object containing anonymous author information
   */
  anonymousAuthor?: AnonymousUserType
  /**
   * Object containing editor information
   */
  editor?: UserType
  /**
   * Determines if the unread badge should be displayed
   */
  isUnread?: boolean
  /**
   * Marks whether an unread message has a forcedReadState
   */
  isForcedRead?: boolean
  /**
   * Boolean to determine if we are in the split view
   */
  createdAt?: string
  /**
   * Display text for the relative time information. This prop is expected
   * to be provided as a string of the exact text to be displayed, not a
   * timestamp to be formatted.
   */
  timingDisplay?: string
  /**
   * Denotes time of last edit.
   * Display text for the relative time information. This prop is expected
   * to be provided as a string of the exact text to be displayed, not a
   * timestamp to be formatted.
   */
  editedTimingDisplay?: string
  /**
   * Last Reply Date if there are discussion replies
   */
  lastReplyAtDisplay?: string
  /**
   * Whether or not we render the created at date in a tooltip
   */
  showCreatedAsTooltip?: boolean
  /**
   * Boolean to determine if the author is the topic author
   */
  isTopicAuthor?: boolean
  discussionEntryVersions?: any[]
  reportTypeCounts?: {
    total?: number
  }
  threadMode?: boolean
  threadParent?: boolean
  toggleUnread?: () => void
  breakpoints?: {
    miniTablet?: boolean
    tablet?: boolean
    desktop?: boolean
    desktopNavOpen?: boolean
    desktopOnly?: boolean
    mobileOnly?: boolean
    ICEDesktop?: boolean
  }
  delayedPostAt?: string
  isTopic?: boolean
  published?: boolean
  isAnnouncement?: boolean
  isSplitView?: boolean
}

const AuthorInfoBase = ({breakpoints, ...props}: AuthorInfoProps) => {
  const {searchTerm} = useContext(SearchContext)

  const hasAuthor = Boolean(props.author || props.anonymousAuthor)
  const avatarUrl = isAnonymous(props) ? null : props.author?.avatarUrl

  const getUnreadBadgeOffset = (avatarSize: string) => {
    if (avatarSize === 'x-small') return '-8px'
    if (avatarSize === 'small') return '-6px'
    return '-5px'
  }

  // author is not a role found in courseroles,
  // so we can always assume that if there is 1 course role,
  // the author in this component will have to roles (author, and the course role)
  const timestampTextSize = 'small'
  const authorNameTextSize = 'medium'
  const authorInfoPadding = '0 0 0 small'
  let avatarSize: 'x-small' | 'small' | 'medium' = 'small'

  if (breakpoints?.desktopNavOpen) {
    avatarSize = props.threadMode && !props.threadParent ? 'small' : 'medium'
  } else if (breakpoints?.mobileOnly) {
    avatarSize = 'small'
  } else {
    // tablet
    avatarSize = props.threadMode ? 'x-small' : 'small'
  }

  return (
    <Flex>
      <Flex.Item align="start">
        {props.isUnread && (
          <div
            style={{
              float: 'left',
              marginTop: hasAuthor ? getUnreadBadgeOffset(avatarSize) : '2px',
              position: 'relative',
              zIndex: 1,
            }}
            data-testid="is-unread"
            data-isforcedread={props.isForcedRead}
          >
            <Badge
              type="notification"
              placement="start center"
              standalone={true}
              formatOutput={() => (
                <ScreenReaderContent>{I18n.t('Mark post as read')}</ScreenReaderContent>
              )}
            />
          </div>
        )}
        {hasAuthor && (
          <div
            style={{
              marginLeft: props.isUnread ? '-12px' : '0',
              display: 'initial',
            }}
          >
            {hasAuthor && !isAnonymous(props) && !hideStudentNames && (
              <Avatar
                size={avatarSize}
                name={getDisplayName(props)}
                src={avatarUrl || undefined}
                margin="0"
                data-testid="author_avatar"
              />
            )}
            {hasAuthor && !isAnonymous(props) && hideStudentNames && (
              <AnonymousAvatar seedString={props.author?._id} size={avatarSize} />
            )}
            {hasAuthor && isAnonymous(props) && (
              <AnonymousAvatar seedString={props.anonymousAuthor?.shortName} size={avatarSize} />
            )}
          </div>
        )}
      </Flex.Item>
      <Flex.Item shouldShrink={true}>
        <Flex direction="column" margin={authorInfoPadding}>
          {hasAuthor && (
            <Flex.Item overflowY="visible">
              <Flex
                wrap="wrap"
                gap="0 small"
                direction={breakpoints?.mobileOnly ? 'column' : 'row'}
              >
                <Text
                  weight="bold"
                  size={authorNameTextSize as any}
                  lineHeight="condensed"
                  data-testid="author_name"
                  wrap="break-word"
                >
                  {isAnonymous(props) ? (
                    getDisplayName(props)
                  ) : (
                    <NameLink
                      userType="author"
                      user={props.author}
                      authorNameTextSize={authorNameTextSize}
                      searchTerm={searchTerm}
                      discussionEntryProps={props}
                      mobileOnly={breakpoints?.mobileOnly}
                    />
                  )}
                </Text>
                <Flex.Item padding={breakpoints?.mobileOnly ? '0 0 0 xx-small' : '0'}>
                  <RolePillContainer
                    discussionRoles={resolveAuthorRoles(
                      props.isTopicAuthor,
                      props.author?.courseRoles,
                    )}
                    data-testid="pill-container"
                  />
                </Flex.Item>
                {ENV.discussions_reporting &&
                  props.reportTypeCounts &&
                  props.reportTypeCounts.total && (
                    <ReportsSummaryBadge reportTypeCounts={props.reportTypeCounts} />
                  )}
              </Flex>
            </Flex.Item>
          )}
          <Flex.Item overflowX="hidden" padding="0 0 0 xx-small">
            <Timestamps
              author={props.author}
              editor={props.editor}
              delayedPostAt={props.delayedPostAt}
              createdAt={props.createdAt}
              editedTimingDisplay={props.editedTimingDisplay}
              lastReplyAtDisplay={props.lastReplyAtDisplay}
              showCreatedAsTooltip={props.showCreatedAsTooltip}
              timestampTextSize={timestampTextSize}
              mobileOnly={breakpoints?.mobileOnly}
              isTopic={props.isTopic}
              published={props.published}
              isAnnouncement={props.isAnnouncement}
            />
            {(ENV as any).discussion_entry_version_history &&
              props.discussionEntryVersions &&
              props.discussionEntryVersions.length > 1 && (
                <DiscussionEntryVersionHistory
                  textSize={timestampTextSize}
                  discussionEntryVersions={props.discussionEntryVersions}
                />
              )}
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}

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

  const timestampsPadding = props.mobileOnly ? '0 xx-small 0 0' : 'xx-small xx-small xx-small 0'

  const createdAtText = useMemo(() => {
    // show basic date for replies
    if (!props.isTopic) return props.createdAt
    // show the original created date for teachers
    if (isTeacher) {
      return I18n.t('Created %{createdAt}', {createdAt: props.createdAt})
    } else {
      // don't show the created date for students if the post is delayed
      return props.delayedPostAt
        ? null
        : I18n.t('Posted %{createdAt}', {createdAt: props.createdAt})
    }
  }, [isTeacher, props.createdAt, props.delayedPostAt, props.isTopic])

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

  return (
    <Flex wrap="wrap">
      {createdAtText && (
        <Flex.Item overflowX="hidden" padding={timestampsPadding}>
          <Text size={props.timestampTextSize as any}>{createdAtText}</Text>
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
          {' | '}
          <Text size={props.timestampTextSize as any}>
            {I18n.t('Last reply %{lastReplyAtDisplay}', {
              lastReplyAtDisplay: props.lastReplyAtDisplay,
            })}
          </Text>
        </Flex.Item>
      )}
    </Flex>
  )
}

interface NameLinkProps {
  userType: string
  user?: UserType
  searchTerm?: string
  mobileOnly?: boolean
  authorNameTextSize?: string
  discussionEntryProps?: AuthorInfoProps
}

const NameLink = (props: NameLinkProps) => {
  let classnames = ''
  if (props.user?.courseRoles?.includes('StudentEnrollment'))
    classnames = 'student_context_card_trigger'
  if (props.mobileOnly) classnames += ' author_post'

  return (
    <div
      className={classnames}
      style={
        props.userType === 'author'
          ? {
              marginBottom: props.mobileOnly ? '0' : '0.3rem',
              marginTop: props.mobileOnly ? '0' : theme.spacing.xxSmall,
              marginLeft: theme.spacing.xxSmall,
              display: 'inline-block',
            }
          : {display: 'inline'}
      }
      data-testid={`student_context_card_trigger_container_${props.userType}`}
      data-student_id={props.user?._id}
      data-course_id={ENV.course_id}
    >
      <Link href={props.user?.htmlUrl} isWithinText={false} themeOverride={{fontWeight: 700}}>
        {props.userType === 'author' ? (
          <>
            <SearchSpan
              isSplitView={props.discussionEntryProps?.isSplitView}
              searchTerm={props.searchTerm}
              text={getDisplayName(props.discussionEntryProps)}
            />
            {props.user?.pronouns && (
              <Text
                lineHeight="condensed"
                size={props.authorNameTextSize as any}
                fontStyle="italic"
                data-testid="author-pronouns"
              >
                &nbsp;({props.user?.pronouns})
              </Text>
            )}
          </>
        ) : (
          props.user?.displayName
        )}
      </Link>
    </div>
  )
}

export const AuthorInfo = WithBreakpoints(AuthorInfoBase)
