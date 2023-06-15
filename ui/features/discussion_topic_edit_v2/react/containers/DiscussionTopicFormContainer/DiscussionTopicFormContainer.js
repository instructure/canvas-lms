/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {useMutation} from 'react-apollo'
import {CREATE_DISCUSSION_TOPIC} from '../../../graphql/Mutations'

import LoadingIndicator from '@canvas/loading-indicator'

export default function DiscussionTopicFormContainer() {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [createDiscussionTopic, {data, loading}] = useMutation(CREATE_DISCUSSION_TOPIC, {
    onCompleted: completionData => {
      const new_discussion_topic = completionData?.createDiscussionTopic?.discussionTopic
      const discussion_topic_id = new_discussion_topic?.course_id
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

  if (loading) {
    return <LoadingIndicator />
  }

  return <div>Form goes here</div>
}
