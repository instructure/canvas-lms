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

import {Alert} from '../../components/Alert/Alert'
import {Button} from '@instructure/ui-buttons'
import DirectShareUserModal from '../../../../../shared/direct-sharing/react/components/DirectShareUserModal'
import DirectShareCourseTray from '../../../../../shared/direct-sharing/react/components/DirectShareCourseTray'
import {Discussion} from '../../../graphql/Discussion'
import {DiscussionPostToolbar} from '../../components/DiscussionPostToolbar/DiscussionPostToolbar'
import {Flex} from '@instructure/ui-flex'
import I18n from 'i18n!discussion_posts'
import {PostMessage} from '../../components/PostMessage/PostMessage'
import {PostToolbar} from '../../components/PostToolbar/PostToolbar'
import PropTypes from 'prop-types'
import React, {useState} from 'react'

const dateOptions = {
  month: 'short',
  day: 'numeric',
  hour: 'numeric',
  minute: 'numeric'
}

export const DiscussionTopicContainer = props => {
  const [sendToOpen, setSendToOpen] = useState(false)
  const [copyToOpen, setCopyToOpen] = useState(false)

  const discussionTopicData = {
    title: props.discussionTopic.title || '',
    authorName: props.discussionTopic.author.name || '',
    avatarUrl: props.discussionTopic.author.avatarUrl || '',
    message: props.discussionTopic.message || '',
    postedAt:
      Intl.DateTimeFormat(I18n.currentLocale(), dateOptions).format(
        new Date(props.discussionTopic?.postedAt)
      ) || '',
    subscribed: props.discussionTopic.subscribed || false,
    published: props.discussionTopic.published || false,
    replies: props.discussionTopic.entryCounts.repliesCount || '',
    unread: props.discussionTopic.entryCounts.unreadCount || '',
    isGraded: !!props.discussionTopic.assignment && !!props.discussionTopic.assignment.dueAt
  }

  if (discussionTopicData.isGraded) {
    discussionTopicData.dueAt = Intl.DateTimeFormat(I18n.currentLocale(), dateOptions).format(
      new Date(props.discussionTopic.assignment.dueAt)
    )
    discussionTopicData.pointsPossible = props.discussionTopic.assignment.pointsPossible || 0
  }

  const course = {
    id: ENV?.context_asset_string
      ? ENV.context_asset_string.split('_')[0] === 'course'
        ? ENV.context_asset_string.split('_')[1]
        : null
      : null
  }

  const directShareUserModalProps = {
    open: sendToOpen,
    courseId: course.id,
    contentShare: {content_type: 'discussion_topic', content_id: props.discussionTopic._id},
    onDismiss: () => {
      setSendToOpen(false)
    }
  }

  const directShareCourseTrayProps = {
    open: copyToOpen,
    sourceCourseId: course.id,
    contentSelection: {discussion_topics: [props.discussionTopic._id]},
    onDismiss: () => {
      setCopyToOpen(false)
    }
  }

  return (
    <>
      <Flex as="div" direction="column">
        <Flex.Item margin="0 0 large" overflowY="hidden" overflowX="hidden">
          <DiscussionPostToolbar
            selectedView="all"
            sortDirection="asc"
            isCollapsedReplies
            onSearchChange={() => {}}
            onViewFilter={() => {}}
            onSortClick={() => {}}
            onCollapseRepliesToggle={() => {}}
            onTopClick={() => {}}
          />
        </Flex.Item>
        <Flex.Item>
          <div style={{border: '1px solid #c7cdd1', borderRadius: '5px'}}>
            {discussionTopicData.isGraded && (
              <div style={{padding: '0 1.5rem 0'}}>
                <Alert
                  contextDisplayText="Section 2"
                  dueAtDisplayText={discussionTopicData.dueAt}
                  pointsPossible={discussionTopicData.pointsPossible}
                />
              </div>
            )}
            <Flex
              direction="row"
              justifyItems="space-between"
              padding="medium small small"
              alignItems="start"
            >
              <Flex.Item>
                <PostMessage
                  authorName={discussionTopicData.authorName}
                  avatarUrl={discussionTopicData.avatarUrl}
                  pillText={I18n.t('Author')}
                  timingDisplay={discussionTopicData.postedAt}
                  message={discussionTopicData.title}
                >
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
                <PostToolbar
                  onReadAll={() => {}}
                  onDelete={props.hasTeacherPermissions ? () => {} : null}
                  onToggleComments={props.hasTeacherPermissions ? () => {} : null}
                  infoText={I18n.t('%{replies} replies, %{unread} unread', {
                    replies: discussionTopicData.replies,
                    unread: discussionTopicData.unread
                  })}
                  onSend={
                    props.discussionTopic.permissions.readAsAdmin
                      ? () => {
                          setSendToOpen(true)
                        }
                      : null
                  }
                  onCopy={
                    props.discussionTopic.permissions.readAsAdmin
                      ? () => {
                          setCopyToOpen(true)
                        }
                      : null
                  }
                  onEdit={props.hasTeacherPermissions ? () => {} : null}
                  onTogglePublish={props.hasTeacherPermissions ? () => {} : null}
                  onToggleSubscription={() => {}}
                  isPublished={discussionTopicData.published}
                  isSubscribed={discussionTopicData.subscribed}
                  commentsEnabled
                />
              </Flex.Item>
            </Flex>
          </div>
        </Flex.Item>
      </Flex>
      <DirectShareUserModal {...directShareUserModalProps} />
      <DirectShareCourseTray {...directShareCourseTrayProps} />
    </>
  )
}

DiscussionTopicContainer.propTypes = {
  /**
   * Indicates if this Discussion Topic is graded.
   * Providing this property will result in the graded info
   * to be rendered
   */
  discussionTopic: PropTypes.instanceOf(Discussion.shape).isRequired,
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

export default DiscussionTopicContainer
