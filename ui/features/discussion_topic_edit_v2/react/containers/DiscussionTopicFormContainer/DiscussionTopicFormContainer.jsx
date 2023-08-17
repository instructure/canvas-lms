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
import {COURSE_QUERY, DISCUSSION_TOPIC_QUERY} from '../../../graphql/Queries'
import {CREATE_DISCUSSION_TOPIC} from '../../../graphql/Mutations'

import LoadingIndicator from '@canvas/loading-indicator'
import DiscussionTopicForm from '../../components/DiscussionTopicForm/DiscussionTopicForm'

export default function DiscussionTopicFormContainer() {
  const {data: courseData, loading: courseIsLoading} = useQuery(COURSE_QUERY, {
    variables: {
      courseId: ENV.context_id, // TODO: what if it's a group?
    },
  })
  const currentCourse = courseData?.legacyNode
  const sections = currentCourse?.sectionsConnection?.nodes
  const groupCategories = currentCourse?.groupSetsConnection?.nodes

  const isEditing = !!ENV.discussion_topic_id
  const {data: topicData, loading: topicIsLoading} = useQuery(DISCUSSION_TOPIC_QUERY, {
    variables: {
      discussionTopicId: ENV.discussion_topic_id,
    },
  })
  const currentDiscussionTopic = topicData?.legacyNode

  const [createDiscussionTopic] = useMutation(CREATE_DISCUSSION_TOPIC, {
    onCompleted: completionData => {
      const new_discussion_topic = completionData?.createDiscussionTopic?.discussionTopic
      const discussion_topic_id = new_discussion_topic?._id
      const context_type = new_discussion_topic?.contextType
      if (discussion_topic_id && context_type) {
        if (context_type === 'Course') {
          window.location.assign(
            `/courses/${ENV.context_id}/discussion_topics/${discussion_topic_id}`
          )
        } else if (context_type === 'Group') {
          window.location.assign(
            `/groups/${ENV.context_id}/discussion_topics/${discussion_topic_id}`
          )
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
      // TODO: implement these as the backend becomes ready for them
      // isAnnouncement,
      // sectionIdsToPostTo,
      // discussionAnonymousState,
      // anonymousAuthorState,
      // respondBeforeReply,
      // enablePodcastFeed,
      // includeRepliesInFeed,
      // isGraded, (phase 2)
      // allowLiking,
      // onlyGradersCanLike,
      // addToTodo,
      // todoDate,
      // isGroupDiscussion,
      // groupCategoryId,
      // availableFrom,
      // availableUntil,
      shouldPublish,
    }) => {
      createDiscussionTopic({
        variables: {
          contextId: ENV.context_id,
          contextType: 'Course',
          title,
          message,
          // TODO: implement these as the backend becomes ready for them
          // isAnnouncement:,
          // discussionType: 'side_comment',
          // delayedPostAt: availableFrom,
          // lockAt: availableUntil,
          // podcastEnabled: enablePodcastFeed,
          // podcastHasStudentPosts: includeRepliesInFeed,
          // requireInitialPost: respondBeforeReply,
          // pinned: false,
          // todoDate,
          // groupCategoryId: null,
          // allowRating: allowLiking,
          // onlyGradersCanRate: onlyGradersCanLike,
          // anonymousState: discussionAnonymousState === 'off' ? null : discussionAnonymousState,
          // isAnonymousAuthor: anonymousAuthorState,
          // specificSections: sectionIdsToPostTo,
          // locked: false,
          published: shouldPublish,
        },
      })
    },
    [createDiscussionTopic]
  )

  // TODO implement this update discussion mutation when the backend is ready
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

  if (courseIsLoading || topicIsLoading) {
    return <LoadingIndicator />
  }

  return (
    <DiscussionTopicForm
      isEditing={isEditing}
      currentDiscussionTopic={currentDiscussionTopic}
      isStudent={ENV.is_student}
      sections={sections}
      groupCategories={groupCategories}
      onSubmit={
        isEditing
          ? () => {
              // eslint-disable-next-line no-console
              console.log('change this to call updateDiscussionTopicOnSubmit later')
            }
          : createDiscussionTopicOnSubmit
      }
    />
  )
}
