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
import {DISCUSSION_TOPIC_QUERY} from '../../../graphql/Queries'
import {CREATE_DISCUSSION_TOPIC, UPDATE_DISCUSSION_TOPIC} from '../../../graphql/Mutations'
import LoadingIndicator from '@canvas/loading-indicator'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {useScope as useI18nScope} from '@canvas/i18n'
import DiscussionTopicForm from '../../components/DiscussionTopicForm/DiscussionTopicForm'

import {getContextQuery} from '../../util/utils'

const I18n = useI18nScope('discussion_create')

export default function DiscussionTopicFormContainer({apolloClient}) {
  const {setOnFailure} = useContext(AlertManagerContext)
  const contextType = ENV.context_is_not_group ? 'Course' : 'Group'
  const {contextQueryToUse, contextQueryVariables} = getContextQuery(contextType)

  const {data: contextData, loading: courseIsLoading} = useQuery(contextQueryToUse, {
    variables: contextQueryVariables,
  })
  const currentContext = contextData?.legacyNode
  const currentDiscussionTopicId = ENV.DISCUSSION_TOPIC?.ATTRIBUTES?.id
  const isEditing = !!currentDiscussionTopicId

  // sections and groupCategories are only available for Course and not group
  const sections = currentContext?.sectionsConnection?.nodes
  const groupCategories = currentContext?.groupSetsConnection?.nodes

  const {data: topicData, loading: topicIsLoading} = useQuery(DISCUSSION_TOPIC_QUERY, {
    skip: !isEditing,
    variables: {
      discussionTopicId: currentDiscussionTopicId,
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

  const [updateDiscussionTopic] = useMutation(UPDATE_DISCUSSION_TOPIC, {
    onCompleted: completionData => {
      const new_discussion_topic = completionData?.updateDiscussionTopic?.discussionTopic
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
        setOnFailure(I18n.t('Error Updating discussion topic'))
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
      isGroupContext={contextType === 'Group'}
      isEditing={isEditing}
      currentDiscussionTopic={currentDiscussionTopic}
      isStudent={ENV.current_user_is_student}
      assignmentGroups={currentContext?.assignmentGroupsConnection?.nodes}
      sections={sections}
      groupCategories={groupCategories}
      apolloClient={apolloClient}
      onSubmit={({
        title,
        message,
        sectionIdsToPostTo,
        shouldPublish,
        requireInitialPost,
        discussionAnonymousState,
        availableFrom,
        availableUntil,
        anonymousAuthorState,
        allowLiking,
        onlyGradersCanLike,
        addToTodo,
        todoDate,
        enablePodcastFeed,
        includeRepliesInFeed,
        locked,
        isAnnouncement,
        groupCategoryId,
        assignment,
      }) => {
        if (isEditing) {
          updateDiscussionTopic({
            variables: {
              discussionTopicId: currentDiscussionTopicId,
              title,
              message,
              specificSections: sectionIdsToPostTo.join(),
              published: shouldPublish,
              requireInitialPost,
              delayedPostAt: availableFrom,
              lockAt: availableUntil,
              allowRating: allowLiking,
              onlyGradersCanRate: onlyGradersCanLike,
              todoDate: addToTodo ? todoDate : null,
              podcastEnabled: enablePodcastFeed,
              podcastHasStudentPosts: includeRepliesInFeed,
              locked,
            },
          })
        } else {
          createDiscussionTopic({
            variables: {
              contextId: ENV.context_id,
              contextType: ENV.context_is_not_group ? 'Course' : 'Group',
              title,
              message,
              specificSections: sectionIdsToPostTo.join(),
              published: shouldPublish,
              requireInitialPost,
              anonymousState: discussionAnonymousState,
              delayedPostAt: availableFrom,
              lockAt: availableUntil,
              isAnonymousAuthor: anonymousAuthorState,
              allowRating: allowLiking,
              onlyGradersCanRate: onlyGradersCanLike,
              todoDate: addToTodo ? todoDate : null,
              podcastEnabled: enablePodcastFeed,
              podcastHasStudentPosts: includeRepliesInFeed,
              locked,
              isAnnouncement,
              groupCategoryId: groupCategoryId || null,
              assignment,
            },
          })
        }
      }}
    />
  )
}
