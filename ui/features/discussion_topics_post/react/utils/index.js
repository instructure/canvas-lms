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

import {DISCUSSION_SUBENTRIES_QUERY} from '../../graphql/Queries'
import {Discussion} from '../../graphql/Discussion'
import {DiscussionEntry} from '../../graphql/DiscussionEntry'

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

export const updateDiscussionTopicEntryCounts = (
  cache,
  discussionTopicGraphQLId,
  entryCountChange
) => {
  const options = {
    id: discussionTopicGraphQLId,
    fragment: Discussion.fragment,
    fragmentName: 'Discussion'
  }

  const data = JSON.parse(JSON.stringify(cache.readFragment(options)))
  if (data) {
    if (entryCountChange?.unreadCountChange) {
      const newUnreadCount = entryCountChange.unreadCountChange + data.entryCounts.unreadCount
      data.entryCounts.unreadCount = newUnreadCount < 0 ? 0 : newUnreadCount
    }
    if (entryCountChange?.repliesCountChange) {
      const newRepliesCount = entryCountChange.repliesCountChange + data.entryCounts.repliesCount
      data.entryCounts.repliesCount = newRepliesCount < 0 ? 0 : newRepliesCount
    }
    cache.writeFragment({
      ...options,
      data
    })
  }
}

export const addReplyToDiscussionEntry = (cache, variables, newDiscussionEntry) => {
  try {
    // Creates an object containing the data that needs to be updated
    // Writes that new data to the cache using the id of the object
    const discussionEntryOptions = {
      id: variables.discussionEntryID,
      fragment: DiscussionEntry.fragment,
      fragmentName: 'DiscussionEntry'
    }
    const data = JSON.parse(JSON.stringify(cache.readFragment(discussionEntryOptions)))
    if (data) {
      if (data.rootEntryParticipantCounts) {
        data.lastReply = {
          createdAt: newDiscussionEntry.createdAt,
          __typename: 'DiscussionEntry'
        }
      }

      data.subentriesCount += 1
      data.rootEntryParticipantCounts.repliesCount += 1

      cache.writeFragment({
        ...discussionEntryOptions,
        data
      })
    }
    // The writeQuery creates a subentry query shape using the data from the new discussion entry
    // Using that query object it tries to find the cached subentry query for that reply and add the new reply to the cache
    const subEntriesOptions = {
      query: DISCUSSION_SUBENTRIES_QUERY,
      variables
    }

    const currentSubentriesQueryData = JSON.parse(
      JSON.stringify(cache.readQuery(subEntriesOptions))
    )
    if (currentSubentriesQueryData) {
      const subentriesLegacyNode = currentSubentriesQueryData.legacyNode
      if (variables.sort === 'desc') {
        subentriesLegacyNode.discussionSubentriesConnection.nodes.unshift(newDiscussionEntry)
      } else {
        subentriesLegacyNode.discussionSubentriesConnection.nodes.push(newDiscussionEntry)
      }

      cache.writeQuery({...subEntriesOptions, data: currentSubentriesQueryData})
    }
  } catch (e) {
    // If a subentry query has never been called for the entry being replied to, an exception will be thrown
    // This doesn't matter functionally because the expansion button will be visible and upon clicking it the
    // subentry query will be called, getting the new reply
    // Future new replies to the thread will not throw an exception because the subentry query is now in the cache
  }
}

export const resolveAuthorRoles = (isAuthor, discussionRoles) => {
  if (isAuthor && discussionRoles) {
    return discussionRoles.concat('Author')
  }
  return discussionRoles
}

export const responsiveQuerySizes = ({mobile = false, tablet = false, desktop = false} = {}) => {
  const querySizes = {}
  if (mobile) {
    querySizes.mobile = {maxWidth: '767px'}
  }
  if (tablet) {
    querySizes.tablet = {minWidth: '768px'}
  }
  if (desktop) {
    querySizes.desktop = {minWidth: tablet ? '1024px' : '768px'}
  }
  return querySizes
}

export const isTopicAuthor = (topicAuthor, entryAuthor) => {
  return topicAuthor && entryAuthor && topicAuthor._id === entryAuthor._id
}
