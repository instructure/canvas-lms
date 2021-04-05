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

import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {PostMessage} from '../PostMessage/PostMessage'
import DiscussionPostToolbar from '../DiscussionResponseToolbar/DiscussionPostToolbar'
import {PostToolbar} from '../PostToolbar/PostToolbar'
import I18n from 'i18n!discussion_posts'
import {Button} from '@instructure/ui-buttons'
import {Alert} from '../Alert/Alert'
import PropTypes from 'prop-types'

const DiscussionTopicContainer = props => {
  const mockedData = {
    discussionPostToolbar: {
      selectedView: 'all',
      sortDirection: 'asc',
      isCollapsedReplies: true,
      onSearchChange: () => {},
      onViewFilter: () => {},
      onSortClick: () => {},
      onCollapseRepliesToggle: () => {},
      onTopClick: () => {}
    },
    alert: {
      contextDisplayText: 'Section 2',
      dueAtDisplayText: 'Jan 26 11:49pm',
      pointsPossible: 5
    },
    postMessage: {
      authorName: 'Testy McTest',
      pillText: I18n.t('Author'),
      timingDisplay: I18n.t('around yesterday'),
      message: 'This is a test message. Do not translate.'
    },
    PostToolbar: {
      onReadAll: () => {},
      onDelete: props.hasTeacherPermissions ? () => {} : null,
      onToggleComments: props.hasTeacherPermissions ? () => {} : null,
      infoText: '24 replies, 4 unread',
      onSend: props.hasTeacherPermissions ? () => {} : null,
      onCopy: props.hasTeacherPermissions ? () => {} : null,
      onEdit: props.hasTeacherPermissions ? () => {} : null,
      onTogglePublish: props.hasTeacherPermissions ? () => {} : null,
      onToggleSubscription: () => {},
      isPublished: true,
      isSubscribed: true,
      commentsEnabled: true
    }
  }

  return (
    <Flex as="div" direction="column">
      <Flex.Item margin="0 0 large" overflowY="hidden" overflowX="hidden">
        <DiscussionPostToolbar {...mockedData.discussionPostToolbar} />
      </Flex.Item>
      <Flex.Item>
        <div style={{border: '1px solid #c7cdd1', borderRadius: '5px'}}>
          {props.isGraded && (
            <div style={{padding: '0 1.5rem 0'}}>
              <Alert {...mockedData.alert} />
            </div>
          )}
          <Flex
            direction="row"
            justifyItems="space-between"
            padding="medium small small"
            alignItems="start"
          >
            <Flex.Item>
              <PostMessage {...mockedData.postMessage}>
                {props.onReply && (
                  <Button
                    color="primary"
                    onReply={props.onReply}
                    data-testid="discussion-topic-reply"
                  >
                    {I18n.t('Reply')}
                  </Button>
                )}
              </PostMessage>
            </Flex.Item>
            <Flex.Item>
              <PostToolbar {...mockedData.PostToolbar} />
            </Flex.Item>
          </Flex>
        </div>
      </Flex.Item>
    </Flex>
  )
}

export default DiscussionTopicContainer

DiscussionTopicContainer.propTypes = {
  /**
   * Indicates if this Discussion Topic is graded.
   * Providing this property will result in the graded info
   * to be rendered
   */
  isGraded: PropTypes.bool,
  /**
   * Indicates if current user has teacher permissions
   * on this Discussion Post.
   * Providing this property will result in manage Actions
   * to be rendered
   */
  hasTeacherPermissions: PropTypes.bool,
  /**
   * Behavior for clicking the reply button,
   * Providing this property will result in
   * rendering the Reply button
   */
  onReply: PropTypes.func
}
