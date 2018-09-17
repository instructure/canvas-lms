/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import makePromisePool from '../shared/makePromisePool'

const MAX_CONCURRENT_REQS = 5

export function getAnnouncements(
  {contextType, contextId, announcements, announcementsSearch},
  {page}
) {
  const {term, filter} = announcementsSearch
  const params = [
    {only_announcements: true},
    {per_page: 40},
    {page: page || announcements.currentPage},
    {search_term: term || null},
    {filter_by: filter || null},
    {no_avatar_fallback: '1'}
  ]

  if (contextType === 'course') {
    params.push({'include[]': 'sections_user_count'})
    params.push({'include[]': 'sections'})
  }

  const queryString = encodeQueryString(params)
  return axios.get(`/api/v1/${contextType}s/${contextId}/discussion_topics?${queryString}`)
}

export function lockAnnouncements({contextType, contextId}, announcements, locked = true) {
  return makePromisePool(
    announcements,
    annId => {
      const url = `/api/v1/${contextType}s/${contextId}/discussion_topics/${annId}`
      return axios.put(url, {locked})
    },
    {
      poolSize: MAX_CONCURRENT_REQS
    }
  )
}

export function deleteAnnouncements({contextType, contextId}, announcements) {
  return makePromisePool(
    announcements,
    annId => {
      const url = `/api/v1/${contextType}s/${contextId}/discussion_topics/${annId}`
      return axios.delete(url)
    },
    {
      poolSize: MAX_CONCURRENT_REQS
    }
  )
}

export function getExternalFeeds({contextType, contextId}) {
  const params = encodeQueryString([{per_page: 100}])
  return axios.get(`/api/v1/${contextType}s/${contextId}/external_feeds?${params}`)
}

export function deleteExternalFeed({contextType, contextId}, feedId) {
  return axios.delete(`/api/v1/${contextType}s/${contextId}/external_feeds/${feedId}`)
}

export function addExternalFeed({contextType, contextId}, {url, verbosity, header_match}) {
  const params = encodeQueryString([{url}, {verbosity}, {header_match: header_match || null}])

  return axios.post(`/api/v1/${contextType}s/${contextId}/external_feeds?${params}`)
}
