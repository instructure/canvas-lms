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

import {AnonymousUser} from '../../../graphql/AnonymousUser'
import {AuthorInfo} from '../../components/AuthorInfo/AuthorInfo'
import {DeletedPostMessage} from '../../components/DeletedPostMessage/DeletedPostMessage'
import {PostMessage} from '../../components/PostMessage/PostMessage'
import PropTypes from 'prop-types'
import React, {useContext} from 'react'
import {getDisplayName, userNameToShow} from '../../utils'
import {SearchContext} from '../../utils/constants'
import {Attachment} from '../../../graphql/Attachment'
import {User} from '../../../graphql/User'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import {ReplyPreview} from '../../components/ReplyPreview/ReplyPreview'
import theme from '@instructure/canvas-theme'
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints'

const DiscussionEntryContainerBase = ({breakpoints, ...props}) => {
  const {searchTerm} = useContext(SearchContext)

  const getDeletedDisplayName = discussionEntry => {
    const editor = discussionEntry.editor
    const author = discussionEntry.author
    const anonymousAuthor = discussionEntry.anonymousAuthor
    if (editor) {
      if (author) {
        return userNameToShow(
          editor.displayName || editor.shortName,
          author._id,
          editor.courseRoles
        )
      }
      if (anonymousAuthor) {
        return userNameToShow(
          editor.displayName || editor.shortName,
          anonymousAuthor._id,
          editor.courseRoles
        )
      }
    } else {
      return getDisplayName(discussionEntry)
    }
  }

  if (props.deleted) {
    return (
      <DeletedPostMessage
        deleterName={getDeletedDisplayName(props.discussionEntry)}
        timingDisplay={props.timingDisplay}
        deletedTimingDisplay={props.editedTimingDisplay}
      >
        {props.children}
      </DeletedPostMessage>
    )
  }

  const hasAuthor = Boolean(props.author || props.anonymousAuthor)

  const depth = props.discussionEntry?.depth || 0
  const threadMode = (depth > 1 && !searchTerm) || props.threadParent
  const hrMarginLeftRem = -2 - (depth - 1) * 1.5

  const direction = breakpoints.desktopNavOpen ? 'row' : 'column-reverse'
  const postUtilitiesAlign = breakpoints.desktopNavOpen && !threadMode ? 'start' : 'stretch'
  const additionalSeparatorStyles = breakpoints.mobileOnly
    ? {width: '100vw', marginLeft: `${hrMarginLeftRem}rem`}
    : {}
  let authorInfoPadding = '0 0 0 x-small'
  let postUtilitiesMargin = '0 0 x-small 0'
  let postMessagePaddingNoAuthor = '0 x-small x-small x-small'
  let postMessagePadding = '0 x-small 0 x-small'

  if (breakpoints.desktopNavOpen) {
    postUtilitiesMargin = threadMode ? '0 0 x-small small' : '0'
    authorInfoPadding = threadMode ? '0 0 small xx-small' : '0'
    postMessagePadding = props.isTopic ? '0 0 small xx-small' : '0 0 0 xx-large'
    postMessagePaddingNoAuthor = '0 0 small small'
  } else if (breakpoints.tablet) {
    postMessagePadding = '0 xx-small xx-small'
    postMessagePaddingNoAuthor = '0 xx-small xx-small'
  }

  return (
    <Flex direction="column" data-authorid={props.author?._id}>
      <Flex.Item shouldGrow={true} shouldShrink={true} overflowY="visible">
        <Flex direction={props.isTopic ? direction : 'row'}>
          {hasAuthor && (
            <Flex.Item shouldGrow={true} shouldShrink={true} padding={authorInfoPadding}>
              <AuthorInfo
                author={props.author}
                threadParent={props.threadParent}
                anonymousAuthor={props.anonymousAuthor}
                editor={props.editor}
                isUnread={props.isUnread}
                isForcedRead={props.isForcedRead}
                isSplitView={props.isSplitView}
                timingDisplay={props.timingDisplay}
                createdAt={props.createdAt}
                updatedAt={props.updatedAt}
                editedTimingDisplay={props.editedTimingDisplay}
                lastReplyAtDisplay={props.lastReplyAtDisplay}
                showCreatedAsTooltip={!props.isTopic}
                isTopicAuthor={props.isTopicAuthor}
                discussionEntryVersions={
                  props.discussionEntry?.discussionEntryVersionsConnection?.nodes || []
                }
                reportTypeCounts={props.discussionEntry?.reportTypeCounts}
                threadMode={threadMode}
                toggleUnread={props.toggleUnread}
                breakpoints={breakpoints}
              />
            </Flex.Item>
          )}
          <Flex.Item
            align={postUtilitiesAlign}
            margin={hasAuthor ? postUtilitiesMargin : '0'}
            overflowX="hidden"
            overflowY="hidden"
            shouldGrow={!hasAuthor}
          >
            {props.postUtilities}
          </Flex.Item>
        </Flex>
      </Flex.Item>
      <Flex.Item
        padding={hasAuthor ? postMessagePadding : postMessagePaddingNoAuthor}
        overflowY="visible"
        overflowX="visible"
      >
        {props.quotedEntry && <ReplyPreview {...props.quotedEntry} />}
        <PostMessage
          isTopic={props.isTopic}
          threadMode={threadMode && !props.isTopic}
          discussionEntry={props.discussionEntry}
          discussionAnonymousState={props.discussionTopic?.anonymousState}
          canReplyAnonymously={props.discussionTopic?.canReplyAnonymously}
          title={props.title}
          message={props.message}
          attachment={props.attachment}
          isEditing={props.isEditing}
          onSave={props.onSave}
          onCancel={props.onCancel}
          isSplitView={props.isSplitView}
          discussionTopic={props.discussionTopic}
        >
          {props.attachment && (
            <View as="div" padding="small none none">
              <Link href={props.attachment.url}>{props.attachment.displayName}</Link>
            </View>
          )}
          {props.children}
          {!props.isTopic && (
            <hr
              data-testid="post-separator"
              style={{
                height: theme.variables.borders.widthSmall,
                borderColor: '#E8EAEC',
                margin: `${theme.variables.spacing.medium} 0`,
                ...additionalSeparatorStyles,
              }}
            />
          )}
        </PostMessage>
      </Flex.Item>
    </Flex>
  )
}

DiscussionEntryContainerBase.propTypes = {
  isTopic: PropTypes.bool,
  postUtilities: PropTypes.node,
  author: User.shape,
  anonymousAuthor: AnonymousUser.shape,
  children: PropTypes.node,
  title: PropTypes.string,
  discussionEntry: PropTypes.object,
  discussionTopic: PropTypes.object,
  message: PropTypes.string,
  isEditing: PropTypes.bool,
  onSave: PropTypes.func,
  onCancel: PropTypes.func,
  isSplitView: PropTypes.bool,
  editor: User.shape,
  isUnread: PropTypes.bool,
  isForcedRead: PropTypes.bool,
  createdAt: PropTypes.string,
  timingDisplay: PropTypes.string,
  editedTimingDisplay: PropTypes.string,
  lastReplyAtDisplay: PropTypes.string,
  deleted: PropTypes.bool,
  isTopicAuthor: PropTypes.bool,
  threadParent: PropTypes.bool,
  quotedEntry: PropTypes.object,
  attachment: Attachment.shape,
  toggleUnread: PropTypes.func,
  breakpoints: breakpointsShape,
}

DiscussionEntryContainerBase.defaultProps = {
  deleted: false,
  threadParent: false,
  breakpoints: breakpointsShape,
}

export const DiscussionEntryContainer = WithBreakpoints(DiscussionEntryContainerBase)
