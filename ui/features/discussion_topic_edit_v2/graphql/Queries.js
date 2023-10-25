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

import {Course} from './Course'
import {Group} from './Group'
import {DiscussionTopic} from './DiscussionTopic'
import gql from 'graphql-tag'

export const DISCUSSION_TOPIC_QUERY = gql`
  query GetDiscussionTopic($discussionTopicId: ID!) {
    legacyNode(_id: $discussionTopicId, type: Discussion) {
      ...DiscussionTopic
    }
  }
  ${DiscussionTopic.fragment}
`

export const COURSE_QUERY = gql`
  query GetCourseQuery($courseId: ID!) {
    legacyNode(_id: $courseId, type: Course) {
      ...Course
    }
  }
  ${Course.fragment}
`

export const GROUP_QUERY = gql`
  query GetGroupQuery($groupId: ID!) {
    legacyNode(_id: $groupId, type: Group) {
      ...Group
    }
  }
  ${Group.fragment}
`
