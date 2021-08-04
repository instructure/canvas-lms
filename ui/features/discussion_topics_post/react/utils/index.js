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

import {Discussion} from '../../graphql/Discussion'
import {DiscussionEntry} from '../../graphql/DiscussionEntry'
import {DISCUSSION_SUBENTRIES_QUERY} from '../../graphql/Queries'
import {ISOLATED_VIEW_INITIAL_PAGE_SIZE} from './constants'

export const isGraded = (assignment = null) => {
  return assignment !== null
}

export const getSpeedGraderUrl = (courseId, assignmentId, authorId = null) => {
  let speedGraderUrl = `/courses/${courseId}/gradebook/speed_grader?assignment_id=${assignmentId}`

  if (authorId !== null) {
    speedGraderUrl += `&student_id=${authorId}`
  }

  return speedGraderUrl
}

export const getEditUrl = (courseId, discussionTopicId) => {
  return `/courses/${courseId}/discussion_topics/${discussionTopicId}/edit`
}

export const getPeerReviewsUrl = (courseId, assignmentId) => {
  return `/courses/${courseId}/assignments/${assignmentId}/peer_reviews`
}

export const getGroupDiscussionUrl = (groupId, childDiscussionId) => {
  return `/groups/${groupId}/discussion_topics/${childDiscussionId}`
}

export const getReviewLinkUrl = (courseId, assignmentId, revieweeId) => {
  return `/courses/${courseId}/assignments/${assignmentId}/submissions/${revieweeId}`
}

export const addReplyToDiscussion = (cache, discussionTopicGraphQLId) => {
  const options = {
    id: discussionTopicGraphQLId,
    fragment: Discussion.fragment,
    fragmentName: 'Discussion'
  }
  const data = JSON.parse(JSON.stringify(cache.readFragment(options)))

  if (data) {
    data.entryCounts.repliesCount += 1

    cache.writeFragment({
      ...options,
      data
    })
  }
}

export const addReplyToDiscussionEntry = (cache, perPage, newDiscussionEntry, courseID) => {
  try {
    const options = {
      query: DISCUSSION_SUBENTRIES_QUERY,
      variables: {
        discussionEntryID: newDiscussionEntry.parent.id,
        last: ISOLATED_VIEW_INITIAL_PAGE_SIZE,
        sort: 'asc',
        courseID
      }
    }
    const currentSubentries = JSON.parse(JSON.stringify(cache.readQuery(options)))

    if (currentSubentries) {
      const subentriesLegacyNode = currentSubentries.legacyNode
      subentriesLegacyNode.subentriesCount += 1

      subentriesLegacyNode.discussionSubentriesConnection.nodes.push(newDiscussionEntry)

      cache.writeQuery({...options, data: currentSubentries})
    }
    // eslint-disable-next-line no-empty
  } catch (e) {}
}

export const resolveAuthorRoles = (isAuthor, discussionRoles) => {
  if (isAuthor) {
    return discussionRoles.concat('Author')
  }
  return discussionRoles
}
