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
import {responsiveQuerySizes} from '../../utils'
import {SearchContext} from '../../utils/constants'
import {Attachment} from '../../../graphql/Attachment'
import {User} from '../../../graphql/User'

import {Flex} from '@instructure/ui-flex'
import {Responsive} from '@instructure/ui-responsive'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import {ReplyPreview} from '../../components/ReplyPreview/ReplyPreview'

export const DiscussionEntryContainer = props => {
  const {searchTerm} = useContext(SearchContext)

  if (props.deleted) {
    return (
      <DeletedPostMessage
        deleterName={props.editor ? props.editor?.displayName : props.author?.displayName}
        timingDisplay={props.timingDisplay}
        deletedTimingDisplay={props.editedTimingDisplay}
      >
        {props.children}
      </DeletedPostMessage>
    )
  }

  const hasAuthor = Boolean(props.author || props.anonymousAuthor)

  const threadMode = (props.discussionEntry?.depth > 1 && !searchTerm) || props.threadParent

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({tablet: true, desktop: true, mobile: false})}
      props={{
        tablet: {
          direction: 'column-reverse',
          authorInfo: {
            padding: '0',
          },
          postUtilities: {
            align: 'stretch',
            margin: '0 0 x-small 0',
            padding: 'xx-small',
          },
          postMessage: {
            padding: '0 xx-small xx-small',
            paddingNoAuthor: '0 xx-small xx-small',
            margin: 'xx-small 0 0 0',
          },
        },
        desktop: {
          direction: 'row',
          authorInfo: {
            padding: threadMode ? '0 0 small xx-small' : 'xx-small 0 0 0',
          },
          postUtilities: {
            align: threadMode ? 'stretch' : 'start',
            margin: threadMode ? '0 0 x-small small' : '0',
            padding: 'xx-small',
          },
          postMessage: {
            padding: threadMode || props.isTopic ? '0 0 small xx-small' : '0 0 small xx-large',
            paddingNoAuthor: '0 0 small small',
            margin: '0',
          },
        },
        mobile: {
          direction: 'column-reverse',
          authorInfo: {
            padding: '0',
          },
          postUtilities: {
            align: 'stretch',
            margin: '0 0 x-small 0',
            padding: 'xx-small',
          },
          postMessage: {
            padding: '0 xx-small xx-small',
            paddingNoAuthor: '0 xx-small xx-small',
            margin: 'xx-small 0 0 0',
          },
        },
      }}
      render={responsiveProps => (
        // If you change the left padding here, please update the DiscussionThreadContainer getReplyLeftMargin function
        <Flex direction="column" padding="0 0 small small" data-authorid={props.author?._id}>
          <Flex.Item shouldGrow={true} shouldShrink={true} overflowY="visible">
            <Flex direction={props.isTopic ? responsiveProps.direction : 'row'}>
              {hasAuthor && (
                <Flex.Item
                  shouldGrow={true}
                  shouldShrink={true}
                  padding={responsiveProps?.authorInfo?.padding}
                >
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
                  />
                </Flex.Item>
              )}
              <Flex.Item
                align={responsiveProps?.postUtilities?.align}
                margin={hasAuthor ? responsiveProps?.postUtilities?.margin : '0'}
                overflowX="hidden"
                overflowY="hidden"
                shouldGrow={!hasAuthor}
                padding={responsiveProps?.postUtilities?.padding}
              >
                {props.postUtilities}
              </Flex.Item>
            </Flex>
          </Flex.Item>
          <Flex.Item
            padding={
              hasAuthor
                ? responsiveProps?.postMessage?.padding
                : responsiveProps?.postMessage?.paddingNoAuthor
            }
            margin={props.isTopic ? '0' : responsiveProps?.postMessage?.margin}
            overflowY="hidden"
            overflowX="hidden"
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
            </PostMessage>
          </Flex.Item>
        </Flex>
      )}
    />
  )
}

DiscussionEntryContainer.propTypes = {
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
  updatedAt: PropTypes.string,
  timingDisplay: PropTypes.string,
  editedTimingDisplay: PropTypes.string,
  lastReplyAtDisplay: PropTypes.string,
  deleted: PropTypes.bool,
  isTopicAuthor: PropTypes.bool,
  threadParent: PropTypes.bool,
  quotedEntry: PropTypes.object,
  attachment: Attachment.shape,
}

DiscussionEntryContainer.defaultProps = {
  deleted: false,
  threadParent: false,
}
