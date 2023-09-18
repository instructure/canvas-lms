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

import React, {useContext} from 'react'

import {useQuery, useMutation} from 'react-apollo'
import {COURSE_QUERY, DISCUSSION_TOPIC_QUERY} from '../../../graphql/Queries'
import {CREATE_DISCUSSION_TOPIC} from '../../../graphql/Mutations'

import LoadingIndicator from '@canvas/loading-indicator'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {useScope as useI18nScope} from '@canvas/i18n'
import DiscussionTopicForm from '../../components/DiscussionTopicForm/DiscussionTopicForm'

const I18n = useI18nScope('discussion_create')

export default function DiscussionTopicFormContainer() {
  const {setOnFailure} = useContext(AlertManagerContext)
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
    skip: !isEditing,
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
          setOnFailure(I18n.t('Invalid context type'))
        }
      } else {
        setOnFailure(I18n.t('Error creating discussion topic'))
      }
    },
    onError: () => {
      setOnFailure(I18n.t('Error creating discussion topic'))
    },
  })

  if (courseIsLoading || topicIsLoading) {
    return <LoadingIndicator />
  }

  return (
    <DiscussionTopicForm
      isEditing={isEditing}
      currentDiscussionTopic={currentDiscussionTopic}
      isStudent={ENV.current_user_is_student}
      sections={sections}
      groupCategories={groupCategories}
      onSubmit={({
        title,
        message,
        shouldPublish,
        requireInitialPost,
        discussionAnonymousState,
        availableFrom,
        availableUntil,
        anonymousAuthorState,
        allowLiking,
        onlyGradersCanLike,
      }) => {
        if (isEditing) {
          console.log('call updateDiscussion')
        } else {
          createDiscussionTopic({
            variables: {
              contextId: ENV.context_id,
              contextType: 'Course',
              title,
              message,
              published: shouldPublish,
              requireInitialPost,
              anonymousState: discussionAnonymousState,
              delayedPostAt: availableFrom,
              lockAt: availableUntil,
              isAnonymousAuthor: anonymousAuthorState,
              allowRating: allowLiking,
              onlyGradersCanRate: onlyGradersCanLike,
            },
          })
        }
      }}
    />
  )
}
