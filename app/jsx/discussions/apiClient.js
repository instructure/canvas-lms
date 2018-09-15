/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import axios from 'axios'
import {encodeQueryString} from '../shared/queryString'

function discussionQueryString(contextType, page) {
  const params = [
    {per_page: 50},
    {plain_messages: true},
    {include_assignment: true},
    {exclude_assignment_descriptions: true},
    {exclude_context_module_locked_topics: true},
    {page}
  ]

  if (contextType === 'course') {
    params.push({'include[]': 'sections_user_count'})
    params.push({'include[]': 'sections'})
  }
  return encodeQueryString(params)
}

export function getDiscussions({contextType, contextId}, {page}) {
  const queryString = discussionQueryString(contextType, page)
  return axios.get(`/api/v1/${contextType}s/${contextId}/discussion_topics?${queryString}`)
}

export function headDiscussions({contextType, contextId}) {
  const page = 1
  const queryString = discussionQueryString(contextType, page)
  return axios.head(`/api/v1/${contextType}s/${contextId}/discussion_topics?${queryString}`)
}

export function updateDiscussion({contextType, contextId}, discussion, updatedFields) {
  const url = `/api/v1/${contextType}s/${contextId}/discussion_topics/${discussion.id}`
  return axios.put(url, updatedFields)
}

export function deleteDiscussion({contextType, contextId}, {discussion}) {
  const url = `/api/v1/${contextType}s/${contextId}/discussion_topics/${discussion.id}`
  return axios.delete(url)
}

export function subscribeToTopic({contextType, contextId}, {id}) {
  return axios.put(`/api/v1/${contextType}s/${contextId}/discussion_topics/${id}/subscribed`)
}

export function unsubscribeFromTopic({contextType, contextId}, {id}) {
  return axios.delete(`/api/v1/${contextType}s/${contextId}/discussion_topics/${id}/subscribed`)
}

export function getUserSettings({currentUserId}) {
  return axios.get(`/api/v1/users/${currentUserId}/settings`)
}

export function getCourseSettings({contextId}) {
  return axios.get(`/api/v1/courses/${contextId}/settings`)
}

export function saveCourseSettings({contextId}, settings) {
  return axios.put(`/api/v1/courses/${contextId}/settings`, settings)
}

export function saveUserSettings({currentUserId}, settings) {
  return axios.put(`/api/v1/users/${currentUserId}/settings`, settings)
}

export function duplicateDiscussion({contextType, contextId}, discussionId) {
  return axios.post(
    `/api/v1/${contextType}s/${contextId}/discussion_topics/${discussionId}/duplicate`
  )
}

export function reorderPinnedDiscussions({contextType, contextId}, order) {
  const postData = {order: order.join(',')}
  const url = `/api/v1/${contextType}s/${contextId}/discussion_topics/reorder`
  return axios.post(url, postData)
}
