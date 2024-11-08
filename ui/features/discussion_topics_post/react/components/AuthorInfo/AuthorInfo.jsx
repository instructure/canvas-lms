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
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
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

const I18n = useI18nScope('discussion_posts')

const AuthorInfoBase = ({breakpoints, ...props}) => {
  const {searchTerm} = useContext(SearchContext)

  const hasAuthor = Boolean(props.author || props.anonymousAuthor)
  const avatarUrl = isAnonymous(props) ? null : props.author?.avatarUrl

  const getUnreadBadgeOffset = avatarSize => {
    if (avatarSize === 'x-small') return '-8px'
    if (avatarSize === 'small') return '-6px'
    return '-5px'
  }

  // author is not a role found in courseroles,
  // so we can always assume that if there is 1 course role,
  // the author in this component will have to roles (author, and the course role)
  const timestampTextSize = breakpoints.desktopNavOpen ? 'small' : 'x-small'
  const authorNameTextSize = breakpoints.desktopNavOpen ? 'small' : 'medium'
  const authorInfoPadding = breakpoints.mobileOnly ? '0 0 0 x-small' : '0 0 0 small'
  let avatarSize = 'small'

  if (breakpoints.desktopNavOpen) {
    avatarSize = props.threadMode && !props.threadParent ? 'small' : 'medium'
  } else if (breakpoints.mobileOnly) {
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
                src={avatarUrl}
                margin="0"
                data-testid="author_avatar"
              />
            )}
            {hasAuthor && !isAnonymous(props) && hideStudentNames && (
              <AnonymousAvatar seedString={props.author._id} size={avatarSize} />
            )}
            {hasAuthor && isAnonymous(props) && (
              <AnonymousAvatar seedString={props.anonymousAuthor.shortName} size={avatarSize} />
            )}
          </div>
        )}
      </Flex.Item>
      <Flex.Item shouldShrink={true}>
        <Flex direction="column" margin={authorInfoPadding}>
          {hasAuthor && (
            <Flex.Item overflowY="hidden">
              <Flex wrap="wrap" gap="0 small" direction={breakpoints.mobileOnly ? 'column' : 'row'}>
                <Text
                  weight="bold"
                  size={authorNameTextSize}
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
                      mobileOnly={breakpoints.mobileOnly}
                    />
                  )}
                </Text>
                <Flex.Item
                  overflowX="hidden"
                  padding={breakpoints.mobileOnly ? '0 0 0 xx-small' : '0'}
                >
                  <RolePillContainer
                    discussionRoles={resolveAuthorRoles(
                      props.isTopicAuthor,
                      props.author?.courseRoles
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
              mobileOnly={breakpoints.mobileOnly}
              isTopic={props.isTopic}
              published={props.published}
              isAnnouncement={props.isAnnouncement}
            />
            {ENV.discussion_entry_version_history && props.discussionEntryVersions.length > 1 && (
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

AuthorInfoBase.propTypes = {
  /**
   * Object containing author information
   */
  author: User.shape,
  /**
   * Object containing anonymous author information
   */
  anonymousAuthor: AnonymousUser.shape,
  /**
   * Object containing editor information
   */
  editor: User.shape,
  /**
   * Determines if the unread badge should be displayed
   */
  isUnread: PropTypes.bool,
  /**
   * Marks whether an unread message has a forcedReadState
   */
  isForcedRead: PropTypes.bool,
  /**
   * Boolean to determine if we are in the split view
   */
  createdAt: PropTypes.string,
  /**
   * Display text for the relative time information. This prop is expected
   * to be provided as a string of the exact text to be displayed, not a
   * timestamp to be formatted.
   */
  timingDisplay: PropTypes.string,
  /**
   * Denotes time of last edit.
   * Display text for the relative time information. This prop is expected
   * to be provided as a string of the exact text to be displayed, not a
   * timestamp to be formatted.
   */
  editedTimingDisplay: PropTypes.string,
  /**
   * Last Reply Date if there are discussion replies
   */
  lastReplyAtDisplay: PropTypes.string,
  /**
   * Whether or not we render the created at date in a tooltip
   */
  showCreatedAsTooltip: PropTypes.bool,
  /**
   * Boolean to determine if the author is the topic author
   */
  isTopicAuthor: PropTypes.bool,
  discussionEntryVersions: PropTypes.arrayOf(DiscussionEntryVersion.shape),
  reportTypeCounts: PropTypes.object,
  threadMode: PropTypes.bool,
  threadParent: PropTypes.bool,
  toggleUnread: PropTypes.func,
  breakpoints: breakpointsShape,
  delayedPostAt: PropTypes.string,
  isTopic: PropTypes.bool,
  published: PropTypes.bool,
  isAnnouncement: PropTypes.bool,
}

const Timestamps = props => {
  const isTeacher = ENV?.current_user_roles && ENV?.current_user_roles.includes('teacher')
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
                props.editor.courseRoles
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

      return I18n.t('Posted %{delayedPostAt}', {delayedPostAt: DateHelper.formatDatetimeForDiscussions(props.delayedPostAt)})
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
          <Text size={props.timestampTextSize}>{createdAtText}</Text>
        </Flex.Item>
      )}
      {delayedPostText && (
        <Flex.Item overflowX="hidden" padding={timestampsPadding}>
          <Text size={props.timestampTextSize}>
            {createdAtText && ' | '}
            {delayedPostText}
          </Text>
        </Flex.Item>
      )}
      {editText && (
        <Flex.Item overflowX="hidden" padding={timestampsPadding}>
          <Text size={props.timestampTextSize}>
            {' | '}
            {editText}
          </Text>
        </Flex.Item>
      )}
      {props.lastReplyAtDisplay && (
        <Flex.Item overflowX="hidden" padding="0 xx-small 0 0">
          {' | '}
          <Text size={props.timestampTextSize}>
            {I18n.t('Last reply %{lastReplyAtDisplay}', {
              lastReplyAtDisplay: props.lastReplyAtDisplay,
            })}
          </Text>
        </Flex.Item>
      )}
    </Flex>
  )
}

Timestamps.propTypes = {
  author: User.shape,
  editor: User.shape,
  createdAt: PropTypes.string,
  delayedPostAt: PropTypes.string,
  editedTimingDisplay: PropTypes.string,
  lastReplyAtDisplay: PropTypes.string,
  timestampTextSize: PropTypes.string,
  mobileOnly: PropTypes.bool,
  isTopic: PropTypes.bool,
  published: PropTypes.bool,
  isAnnouncement: PropTypes.bool,
}

const NameLink = props => {
  let classnames = ''
  if (props.user?.courseRoles?.includes('StudentEnrollment'))
    classnames = 'student_context_card_trigger'
  if (props.mobileOnly) classnames += ' author_post'

  const fontWeight = {fontWeight: props.mobileOnly ? 700 : 400}
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
      <Link href={props.user?.htmlUrl} isWithinText={false} themeOverride={fontWeight}>
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
                size={props.authorNameTextSize}
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

NameLink.propTypes = {
  userType: PropTypes.string,
  user: User.shape,
  searchTerm: PropTypes.string,
  mobileOnly: PropTypes.bool,
  authorNameTextSize: PropTypes.string,
  discussionEntryProps: PropTypes.object,
}

export const AuthorInfo = WithBreakpoints(AuthorInfoBase)
