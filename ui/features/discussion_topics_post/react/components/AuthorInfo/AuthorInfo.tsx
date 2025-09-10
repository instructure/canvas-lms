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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {useContext} from 'react'
import {getDisplayName, isAnonymous, resolveAuthorRoles} from '../../utils'
import {RolePillContainer} from '../RolePillContainer/RolePillContainer'
import {SearchContext} from '../../utils/constants'
import {Badge} from '@instructure/ui-badge'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {DiscussionEntryVersionHistory} from '../DiscussionEntryVersionHistory/DiscussionEntryVersionHistory'
import {ReportsSummaryBadge} from '../ReportsSummaryBadge/ReportsSummaryBadge'
import WithBreakpoints from '@canvas/with-breakpoints'
import {AuthorAvatar} from './AuthorAvatar'
import {Timestamps} from './Timestamps'
import {NameLink} from './NameLink'
import {IconPinSolid} from '@instructure/ui-icons'

const I18n = createI18nScope('discussion_posts')

export interface UserType {
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

export interface AuthorInfoProps {
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
  isPinned: boolean
  pinnedBy: UserType
}

const AuthorInfoBase = ({breakpoints, ...props}: AuthorInfoProps) => {
  const {searchTerm} = useContext(SearchContext)

  const hasAuthor = Boolean(props.author || props.anonymousAuthor)

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
            <AuthorAvatar entry={props} avatarSize={avatarSize} />
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
              isPinned={props.isPinned}
              pinnedBy={props.pinnedBy}
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

export const AuthorInfo = WithBreakpoints(AuthorInfoBase)
