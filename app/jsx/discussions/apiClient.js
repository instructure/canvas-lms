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

// In the the index.html.erb view for this page, we fire of `fetch` requests for all the
// get requests for all the discusisons we're going to render. We do this so they
// can start loading then and not have to wait until this JS file is loaded to start
// fetching. But since they are just raw `fetch` responses, we need to massage them
// into something that looks like an axios response, since that is what everything
// here is designed to deal with
let axiosResponses
function getFetchRequests() {
  return (
    axiosResponses ||
    (axiosResponses = (window.preloadedDiscussionTopicFetchRequests || []).map(fetchRequest => {
      return fetchRequest.then(res => {
        return res.json().then(json => {
          return {
            data: json,
            headers: {link: res.headers.get('Link')}
          }
        })
      })
    }))
  )
}

export function getDiscussions({contextType, contextId}, {page}) {
  return getFetchRequests()[page - 1]
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
