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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
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
import {PUBLISH_DISCUSSION_TOPIC, SUBSCRIBE_TO_DISCUSSION_TOPIC} from '../../../graphql/Mutations'
import React, {useContext, useState} from 'react'
import {useMutation} from 'react-apollo'

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
    authorName: props.discussionTopic?.author?.name || '',
    avatarUrl: props.discussionTopic?.author?.avatarUrl || '',
    can_unpublish: props.discussionTopic.canUnpublish || false,
    _id: props.discussionTopic._id,
    isGraded: !!props.discussionTopic?.assignment && !!props.discussionTopic.assignment.dueAt,
    message: props.discussionTopic.message || '',
    permissions: {
      update: props.discussionTopic.permissions.update
    },
    postedAt: props.discussionTopic?.postedAt
      ? Intl.DateTimeFormat(I18n.currentLocale(), dateOptions).format(
          new Date(props.discussionTopic?.postedAt)
        )
      : '',
    published: props.discussionTopic?.published || false,
    readAsAdmin: !!props.discussionTopic?.permissions?.readAsAdmin,
    replies: props.discussionTopic?.entryCounts?.repliesCount || 0,
    subscribed: props.discussionTopic?.subscribed || false,
    title: props.discussionTopic?.title || '',
    unread: props.discussionTopic?.entryCounts?.unreadCount || 0
  }

  if (discussionTopicData.isGraded) {
    discussionTopicData.dueAt = Intl.DateTimeFormat(I18n.currentLocale(), dateOptions).format(
      new Date(props.discussionTopic.assignment.dueAt)
    )
    discussionTopicData.pointsPossible = props.discussionTopic.assignment.pointsPossible || 0
  }

  const infoTextStrings = {
    replies: I18n.t('%{replies} replies', {replies: discussionTopicData.replies}),
    unread: I18n.t(', %{unread} unread', {unread: discussionTopicData.unread})
  }

  const getInfoText = () => {
    let infoText = ''
    if (discussionTopicData.replies && discussionTopicData.replies > 0) {
      infoText = infoTextStrings.replies
      if (discussionTopicData.unread && discussionTopicData.unread > 0) {
        infoText += infoTextStrings.unread
      }
    }
    return infoText
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

  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)

  const [publishDiscussionTopic] = useMutation(PUBLISH_DISCUSSION_TOPIC, {
    onCompleted: data => {
      if (!data.updateDiscussionTopic.errors) {
        setOnSuccess(
          data.updateDiscussionTopic.discussionTopic.published
            ? I18n.t('You have successfully published the discussion topic.')
            : I18n.t('You have successfully unpublished the discussion topic.')
        )
      } else {
        setOnFailure(I18n.t('There was an unexpected error updating the discussion topic.'))
      }
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error updating the discussion topic.'))
    }
  })

  const onPublish = () => {
    publishDiscussionTopic({
      variables: {
        discussionTopicId: discussionTopicData._id,
        published: !discussionTopicData.published
      }
    })
  }

  const [subscribeToDiscussionTopic] = useMutation(SUBSCRIBE_TO_DISCUSSION_TOPIC, {
    onCompleted: data => {
      if (!data.subscribeToDiscussionTopic.errors) {
        setOnSuccess(
          data.subscribeToDiscussionTopic.discussionTopic.subscribed
            ? I18n.t('You have successfully subscribed to the discussion topic.')
            : I18n.t('You have successfully unsubscribed from the discussion topic.')
        )
      } else {
        setOnFailure(I18n.t('There was an unexpected error updating the discussion topic.'))
      }
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error updating the discussion topic.'))
    }
  })

  const onSubscribe = () => {
    subscribeToDiscussionTopic({
      variables: {
        discussionTopicId: discussionTopicData._id,
        subscribed: !discussionTopicData.subscribed
      }
    })
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
                  message={discussionTopicData.message}
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
                  onDelete={discussionTopicData.readAsAdmin ? () => {} : null}
                  onToggleComments={discussionTopicData.readAsAdmin ? () => {} : null}
                  infoText={getInfoText()}
                  onSend={
                    discussionTopicData.readAsAdmin
                      ? () => {
                          setSendToOpen(true)
                        }
                      : null
                  }
                  onCopy={
                    discussionTopicData.readAsAdmin
                      ? () => {
                          setCopyToOpen(true)
                        }
                      : null
                  }
                  onEdit={discussionTopicData.readAsAdmin ? () => {} : null}
                  onTogglePublish={
                    discussionTopicData.permissions.update && discussionTopicData.readAsAdmin
                      ? onPublish
                      : null
                  }
                  onToggleSubscription={onSubscribe}
                  isPublished={discussionTopicData.published}
                  canUnpublish={discussionTopicData.can_unpublish}
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
   * Behavior for clicking the reply button,
   * Providing this property will result in
   * rendering the Reply button
   */
  onReply: PropTypes.func
}

export default DiscussionTopicContainer
