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
import {getDisplayName, isAnonymous, resolveAuthorRoles, responsiveQuerySizes} from '../../utils'
import {RolePillContainer} from '../RolePillContainer/RolePillContainer'
import {SearchContext} from '../../utils/constants'
import {SearchSpan} from '../SearchSpan/SearchSpan'
import {User} from '../../../graphql/User'

import {Avatar} from '@instructure/ui-avatar'
import {Badge} from '@instructure/ui-badge'
import {Flex} from '@instructure/ui-flex'
import {Responsive} from '@instructure/ui-responsive'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Tooltip} from '@instructure/ui-tooltip'
import {DiscussionEntryVersion} from '../../../graphql/DiscussionEntryVersion'
import {DiscussionEntryVersionHistory} from '../DiscussionEntryVersionHistory/DiscussionEntryVersionHistory'
import {ReportsSummaryBadge} from '../ReportsSummaryBadge/ReportsSummaryBadge'
import theme from '@instructure/canvas-theme'

const I18n = useI18nScope('discussion_posts')

export const AuthorInfo = props => {
  const {searchTerm} = useContext(SearchContext)

  const hasAuthor = Boolean(props.author || props.anonymousAuthor)
  const avatarUrl = isAnonymous(props) ? null : props.author?.avatarUrl

  const getUnreadBadgeOffset = avatarSize => {
    if (avatarSize === 'medium') return '11px'
    if (avatarSize === 'x-small') return '3px'
    return '7px'
  }

  // author is not a role found in courseroles,
  // so we can always assume that if there is 1 course role,
  // the author in this component will have to roles (author, and the course role)
  const hasMultipleRoles = props.author?.courseRoles?.length > 0

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({tablet: true, desktop: true})}
      props={{
        tablet: {
          authorNameTextSize: 'x-small',
          timestampTextSize: 'x-small',
          nameAndRoleDirection: 'column',
          badgeMarginLeft: '-16px',
          avatarSize: props.threadMode ? 'x-small' : 'small',
        },
        desktop: {
          authorNameTextSize: props.threadMode ? 'small' : 'medium',
          timestampTextSize: props.threadMode ? 'x-small' : 'small',
          nameAndRoleDirection: 'row',
          badgeMarginLeft: props.threadMode ? '-16px' : '-24px',
          avatarSize: props.threadMode && !props.threadParent ? 'small' : 'medium',
        },
        mobile: {
          authorNameTextSize: 'small',
          timestampTextSize: 'x-small',
          nameAndRoleDirection: 'column',
          badgeMarginLeft: '-16px',
          avatarSize: 'small',
        },
      }}
      render={responsiveProps => (
        <Flex>
          <Flex.Item align="start">
            {props.isUnread && (
              <div
                style={{
                  float: 'left',
                  marginLeft: responsiveProps.badgeMarginLeft,
                  marginTop: hasAuthor ? getUnreadBadgeOffset(responsiveProps.avatarSize) : '2px',
                }}
                data-testid="is-unread"
                data-isforcedread={props.isForcedRead}
              >
                <Badge
                  type="notification"
                  placement="start center"
                  standalone={true}
                  formatOutput={() => (
                    <ScreenReaderContent>{I18n.t('Unread post')}</ScreenReaderContent>
                  )}
                />
              </div>
            )}
            {hasAuthor && !isAnonymous(props) && (
              <Avatar
                size={responsiveProps.avatarSize}
                name={getDisplayName(props)}
                src={avatarUrl}
                margin="0"
                data-testid="author_avatar"
              />
            )}
            {hasAuthor && isAnonymous(props) && (
              <AnonymousAvatar
                seedString={props.anonymousAuthor.shortName}
                size={responsiveProps.avatarSize}
              />
            )}
          </Flex.Item>
          <Flex.Item shouldShrink={true}>
            <Flex direction="column" margin="0 0 0 small">
              {hasAuthor && (
                <Flex.Item>
                  <Flex
                    direction={hasMultipleRoles ? 'column' : responsiveProps.nameAndRoleDirection}
                  >
                    <Flex.Item padding="0 small 0 0">
                      <Text
                        weight="bold"
                        size={responsiveProps.authorNameTextSize}
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
                            responsiveProps={responsiveProps}
                            searchTerm={searchTerm}
                            discussionEntryProps={props}
                          />
                        )}
                      </Text>
                    </Flex.Item>
                    <Flex.Item margin="0 0 0 xx-small" overflowY="hidden">
                      <RolePillContainer
                        discussionRoles={resolveAuthorRoles(
                          props.isTopicAuthor,
                          props.author?.courseRoles
                        )}
                        data-testid="pill-container"
                      />
                    </Flex.Item>
                    {props.reportTypeCounts && props.reportTypeCounts.total && (
                      <ReportsSummaryBadge reportTypeCounts={props.reportTypeCounts} />
                    )}
                  </Flex>
                </Flex.Item>
              )}
              <Flex.Item overflowX="hidden" padding="0 0 0 xx-small">
                <Timestamps
                  author={props.author}
                  editor={props.editor}
                  createdAt={props.createdAt}
                  updatedAt={props.updatedAt}
                  timingDisplay={props.timingDisplay}
                  editedTimingDisplay={props.editedTimingDisplay}
                  lastReplyAtDisplay={props.lastReplyAtDisplay}
                  showCreatedAsTooltip={props.showCreatedAsTooltip}
                  timestampTextSize={responsiveProps.timestampTextSize}
                />
                {ENV.discussion_entry_version_history &&
                  props.discussionEntryVersions.length > 1 && (
                    <DiscussionEntryVersionHistory
                      textSize={responsiveProps.timestampTextSize}
                      discussionEntryVersions={props.discussionEntryVersions}
                    />
                  )}
              </Flex.Item>
            </Flex>
          </Flex.Item>
        </Flex>
      )}
    />
  )
}

AuthorInfo.propTypes = {
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
  updatedAt: PropTypes.string,
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
}

const Timestamps = props => {
  const editText = useMemo(() => {
    if (!props.editedTimingDisplay || props.createdAt === props.updatedAt) {
      return null
    }

    if (props.editor && props.editor?._id !== props.author?._id) {
      return (
        <span data-testid="editedByText">
          {I18n.t('Edited by')} <NameLink userType="editor" user={props.editor} />{' '}
          {I18n.t('%{editedTimingDisplay}', {
            editedTimingDisplay: props.editedTimingDisplay,
          })}
        </span>
      )
    } else {
      return I18n.t('Edited %{editedTimingDisplay}', {
        editedTimingDisplay: props.editedTimingDisplay,
      })
    }
  }, [props.editedTimingDisplay, props.createdAt, props.updatedAt, props.editor, props.author])

  return (
    <Flex wrap="wrap">
      {(!props.showCreatedAsTooltip || !editText) && (
        <Flex.Item overflowX="hidden" padding="xx-small xx-small xx-small 0">
          <Text size={props.timestampTextSize}>{props.timingDisplay}</Text>
        </Flex.Item>
      )}
      {editText && props.showCreatedAsTooltip && (
        <Flex.Item
          data-testid="created-tooltip"
          overflowX="hidden"
          padding="xx-small xx-small xx-small 0"
        >
          <Tooltip
            renderTip={I18n.t('Created %{timingDisplay}', {timingDisplay: props.timingDisplay})}
          >
            {/* eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex */}
            <span tabIndex="0">
              <Text size={props.timestampTextSize}>{editText}</Text>
            </span>
          </Tooltip>
        </Flex.Item>
      )}
      {editText && !props.showCreatedAsTooltip && (
        <Flex.Item overflowX="hidden" padding="xx-small xx-small xx-small 0">
          <Text size={props.timestampTextSize}>{editText}</Text>
        </Flex.Item>
      )}
      {props.lastReplyAtDisplay && (
        <Flex.Item overflowX="hidden">
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
  updatedAt: PropTypes.string,
  timingDisplay: PropTypes.string,
  editedTimingDisplay: PropTypes.string,
  lastReplyAtDisplay: PropTypes.string,
  showCreatedAsTooltip: PropTypes.bool,
  timestampTextSize: PropTypes.string,
}

const NameLink = props => {
  return (
    <div
      className={
        props.user?.courseRoles?.includes('StudentEnrollment') ? 'student_context_card_trigger' : ''
      }
      style={
        props.userType === 'author'
          ? {
              marginBottom: '0.3rem',
              marginTop: theme.variables.spacing.xxSmall,
              marginLeft: theme.variables.spacing.xxSmall,
              display: 'inline-block',
            }
          : {display: 'inline'}
      }
      data-testid={`student_context_card_trigger_container_${props.userType}`}
      data-student_id={props.user?._id}
      data-course_id={ENV.course_id}
    >
      <Link href={props.user?.htmlUrl} isWithinText={false}>
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
                size={props.responsiveProps.authorNameTextSize}
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
  responsiveProps: PropTypes.object,
  searchTerm: PropTypes.string,
  discussionEntryProps: PropTypes.object,
}
