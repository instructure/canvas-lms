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

import {PostToolbar} from '../../components/PostToolbar/PostToolbar'
import React from 'react'
import {getSpeedGraderUrl, getEditUrl, getPeerReviewsUrl} from '../../utils'
import PropTypes from 'prop-types'
import I18n from 'i18n!discussion_posts'

export const PostToolbarContainer = props => {
  return (
    <PostToolbar
      onReadAll={!props.requiresInitialPost ? props.onMarkAllAsRead : null}
      onDelete={
        props.discussionTopicData?.permissions?.delete
          ? () => {
              if (
                // eslint-disable-next-line no-alert
                window.confirm(I18n.t('Are you sure you want to delete this topic?'))
              ) {
                props.deleteDiscussionTopic({
                  variables: {
                    id: props.discussionTopicData._id
                  }
                })
              }
            }
          : null
      }
      repliesCount={props.discussionTopicData.replies}
      unreadCount={props.discussionTopicData.unread}
      onSend={
        props.discussionTopicData?.permissions?.copyAndSendTo
          ? () => {
              props.setSendToOpen(true)
            }
          : null
      }
      onCopy={
        props.discussionTopicData?.permissions?.copyAndSendTo
          ? () => {
              props.setCopyToOpen(true)
            }
          : null
      }
      onEdit={
        props.discussionTopicData?.permissions?.update
          ? () => {
              window.location.assign(getEditUrl(ENV.course_id, props.discussionTopicData._id))
            }
          : null
      }
      onTogglePublish={
        props.discussionTopicData?.permissions?.moderateForum ? props.onPublish : null
      }
      onToggleSubscription={props.onSubscribe}
      onOpenSpeedgrader={
        props.discussionTopicData?.permissions?.speedGrader
          ? () => {
              window.open(
                getSpeedGraderUrl(ENV.course_id, props.discussionTopicData.assignment._id),
                '_blank'
              )
            }
          : null
      }
      onPeerReviews={
        props.discussionTopicData?.permissions?.peerReview
          ? () => {
              window.location.assign(
                getPeerReviewsUrl(ENV.course_id, props.discussionTopicData.assignment._id)
              )
            }
          : null
      }
      onShowRubric={props.discussionTopicData?.permissions?.showRubric ? () => {} : null}
      onAddRubric={props.discussionTopicData?.permissions?.addRubric ? () => {} : null}
      isPublished={props.discussionTopicData.published}
      canUnpublish={props.canUnpublish}
      isSubscribed={props.discussionTopicData.subscribed}
      onOpenForComments={
        props.discussionTopicData?.permissions?.openForComments
          ? () => {
              props.onToggleLocked(false)
            }
          : null
      }
      onCloseForComments={
        props.canCloseForComments
          ? () => {
              props.onToggleLocked(true)
            }
          : null
      }
      onShareToCommons={
        props.discussionTopicData?.permissions?.manageContent &&
        ENV.discussion_topic_menu_tools?.length > 0
          ? () => {
              window.location.assign(
                `${ENV.discussion_topic_menu_tools[0].base_url}&discussion_topics%5B%5D=${props.discussionTopicData._id}`
              )
            }
          : null
      }
    />
  )
}

PostToolbarContainer.propTypes = {
  canUnpublish: PropTypes.bool,
  canCloseForComments: PropTypes.bool,
  deleteDiscussionTopic: PropTypes.func,
  discussionTopicData: PropTypes.object,
  requiresInitialPost: PropTypes.bool,
  onPublish: PropTypes.func,
  onToggleLocked: PropTypes.func,
  onMarkAllAsRead: PropTypes.func,
  onSubscribe: PropTypes.func,
  setSendToOpen: PropTypes.func,
  setCopyToOpen: PropTypes.func
}

export default PostToolbarContainer
