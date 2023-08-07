/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useCallback} from 'react'

import {useQuery, useMutation} from 'react-apollo'
import {DISCUSSION_TOPIC_QUERY} from '../../../graphql/Queries'
import {CREATE_DISCUSSION_TOPIC} from '../../../graphql/Mutations'

import LoadingIndicator from '@canvas/loading-indicator'
import DiscussionTopicForm from '../../components/DiscussionTopicForm/DiscussionTopicForm'

export default function DiscussionTopicFormContainer() {
  const is_editing = !!ENV.discussion_topic_id
  const {data: topic_data, loading: topic_is_loading} = useQuery(DISCUSSION_TOPIC_QUERY, {
    variables: {
      discussionTopicId: 120 /* ENV.disscusion_topic_id, */,
    },
  })
  const currentDiscussionTopic = topic_data?.legacyNode

  const [createDiscussionTopic] = useMutation(CREATE_DISCUSSION_TOPIC, {
    onCompleted: completionData => {
      const new_discussion_topic = completionData?.createDiscussionTopic?.discussionTopic
      const discussion_topic_id = new_discussion_topic?._id
      const context_type = new_discussion_topic?.contextType
      if (discussion_topic_id && context_type) {
        if (context_type === 'Course') {
          window.location.assign(
            `/courses/${ENV.course_id}/discussion_topics/${discussion_topic_id}`
          )
        } else if (context_type === 'Group') {
          window.location.assign(`/groups/${ENV.group_id}/discussion_topics/${discussion_topic_id}`)
        } else {
          // TODO: show error page and/or redirect
          // eslint-disable-next-line no-console
          console.log('invalid context type!')
        }
      } else {
        // TODO: handle this
        // eslint-disable-next-line no-console
        console.log('invalid discussion!')
      }
    },
    onError: () => {
      // TODO: handle mutation error and potentially try again
      // eslint-disable-next-line no-console
      console.log('error!')
    },
  })

  const createDiscussionTopicOnSubmit = useCallback(
    ({
      title,
      message,
      sectionIdsToPostTo,
      discussionAnonymousState,
      anonymousAuthorState,
      respondBeforeReply,
      enablePodcastFeed,
      includeRepliesInFeed,
      // isGraded, (phase 2)
      allowLiking,
      onlyGradersCanLike,
      // addToTodo,
      todoDate,
      // isGroupDiscussion,
      // groupCategoryId,
      availableFrom,
      availableUntil,
      shouldPublish,
    }) => {
      createDiscussionTopic({
        variables: {
          contextId: ENV.course_id,
          contextType: 'Course',
          isAnnouncement: false,
          title,
          message,
          discussionType: 'side_comment',
          delayedPostAt: availableFrom,
          lockAt: availableUntil,
          podcastEnabled: enablePodcastFeed,
          podcastHasStudentPosts: includeRepliesInFeed,
          requireInitialPost: respondBeforeReply,
          pinned: false,
          todoDate,
          groupCategoryId: null,
          allowRating: allowLiking,
          onlyGradersCanRate: onlyGradersCanLike,
          anonymousState: discussionAnonymousState === 'off' ? null : discussionAnonymousState,
          isAnonymousAuthor: anonymousAuthorState,
          specificSections: sectionIdsToPostTo,
          locked: false,
          published: shouldPublish,
        },
      })
    },
    [createDiscussionTopic]
  )

  // const updateDiscussionTopicOnSubmit = useCallback(
  //   ({
  //     title,
  //     message,
  //     sectionsToPostTo,
  //     discussionAnonymousState,
  //     anonymousAuthorState,
  //     respondBeforeReply,
  //     enablePodcastFeed,
  //     includeRepliesInFeed,
  //     // isGraded,
  //     allowLiking,
  //     onlyGradersCanLike,
  //     // sortByLikes,
  //     // addToTodo,
  //     todoDate,
  //     // isGroupDiscussion,
  //     // groupSet,
  //     availableFrom,
  //     availableUntil,
  //     shouldPublish,
  //     // postedAt,
  //   }) => {
  //     updateDiscussionTopic({
  //       variables: {
  //         contextId: ENV.course_id,
  //         contextType: 'Course',
  //         isAnnouncement: false,
  //         title,
  //         message,
  //         discussionType: 'side_comment',
  //         delayedPostAt: availableFrom,
  //         lockAt: availableUntil,
  //         podcastEnabled: enablePodcastFeed,
  //         podcastHasStudentPosts: includeRepliesInFeed,
  //         requireInitialPost: respondBeforeReply,
  //         pinned: false,
  //         todoDate,
  //         groupCategoryId: null,
  //         allowRating: allowLiking,
  //         onlyGradersCanRate: onlyGradersCanLike,
  //         anonymousState: discussionAnonymousState === 'off' ? null : discussionAnonymousState,
  //         isAnonymousAuthor: anonymousAuthorState,
  //         specificSections: sectionsToPostTo,
  //         locked: false,
  //         published: shouldPublish,
  //       },
  //     })
  //   },
  //   [updateDiscussionTopic]
  // )

  if (topic_is_loading) {
    return <LoadingIndicator />
  }

  return (
    <DiscussionTopicForm
      isEditing={is_editing}
      currentDiscussionTopic={currentDiscussionTopic}
      isStudent={false /* ENV.is_student */}
      sections={[]}
      groupCategories={[]}
      onSubmit={
        createDiscussionTopicOnSubmit /* is_editing ? updateDiscussionTopicOnSubmit : ... */
      }
    />
  )
}
