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

import {CURRENT_USER} from './constants'
import {
  DISCUSSION_ENTRY_ALL_ROOT_ENTRIES_QUERY,
  DISCUSSION_SUBENTRIES_QUERY,
} from '../../graphql/Queries'
import {Discussion} from '../../graphql/Discussion'
import {DiscussionEntry} from '../../graphql/DiscussionEntry'
import {useScope as createI18nScope} from '@canvas/i18n'
import $ from '@canvas/rails-flash-notifications'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {loadErrorMessages, loadDevMessages} from '@apollo/client/dev'
const I18n = createI18nScope('discussion_topics_post')

export const getSpeedGraderUrl = (authorId = null, entryId = null) => {
  let speedGraderUrl = ENV.SPEEDGRADER_URL_TEMPLATE
  if (authorId !== null) {
    speedGraderUrl = speedGraderUrl.replace(/%3Astudent_id/, authorId)
  }

  if (entryId !== null) {
    speedGraderUrl = speedGraderUrl.concat(`&entry_id=${entryId}`)
  }

  return speedGraderUrl
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
  entryCountChange,
) => {
  const options = {
    id: discussionTopicGraphQLId,
    fragment: Discussion.fragment,
    fragmentName: 'Discussion',
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
      data,
    })
  }
}

export const updateDiscussionEntryRootEntryCounts = (cache, discussionEntry, unreadCountChange) => {
  const discussionEntryOptions = {
    id: btoa('DiscussionEntry-' + discussionEntry.rootEntryId),
    fragment: DiscussionEntry.fragment,
    fragmentName: 'DiscussionEntry',
  }

  const data = JSON.parse(JSON.stringify(cache.readFragment(discussionEntryOptions)))
  data.rootEntryParticipantCounts.unreadCount += unreadCountChange

  cache.writeFragment({
    ...discussionEntryOptions,
    data,
  })
}

export const addReplyToDiscussionEntry = (cache, variables, newDiscussionEntry) => {
  try {
    // Creates an object containing the data that needs to be updated
    // Writes that new data to the cache using the id of the object
    const discussionEntryOptions = {
      id: btoa('DiscussionEntry-' + newDiscussionEntry.rootEntryId),
      fragment: DiscussionEntry.fragment,
      fragmentName: 'DiscussionEntry',
    }
    const data = JSON.parse(JSON.stringify(cache.readFragment(discussionEntryOptions)))
    if (data) {
      if (data.rootEntryParticipantCounts) {
        data.lastReply = {
          createdAt: newDiscussionEntry.createdAt,
          __typename: 'DiscussionEntry',
        }
      }

      data.subentriesCount += 1
      data.rootEntryParticipantCounts.repliesCount += 1

      cache.writeFragment({
        ...discussionEntryOptions,
        data,
      })
    }

    // The writeQuery creates a subentry query shape using the data from the new discussion entry
    // Using that query object it tries to find the cached subentry query for that reply and add the new reply to the cache
    const parentEntryOptions = {
      id: btoa('DiscussionEntry-' + newDiscussionEntry.rootEntryId),
      fragment: DiscussionEntry.fragment,
      fragmentName: 'DiscussionEntry',
    }
    const parentEntryData = JSON.parse(JSON.stringify(cache.readFragment(parentEntryOptions)))

    if (parentEntryData.subentriesCount) {
      const subEntriesOptions = {
        query: DISCUSSION_SUBENTRIES_QUERY,
        variables,
      }

      const currentSubentriesQueryData = JSON.parse(
        JSON.stringify(cache.readQuery(subEntriesOptions)),
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

      const parentQueryOptions = {
        query: DISCUSSION_SUBENTRIES_QUERY,
        variables: {
          ...variables,
          discussionEntryID:
            parentEntryData.parentId || parentEntryData.rootEntryId || parentEntryData._id,
        },
      }

      const parentQueryData = JSON.parse(JSON.stringify(cache.readQuery(parentQueryOptions)))

      if (parentQueryData) {
        const nodes = parentQueryData.legacyNode.discussionSubentriesConnection.nodes
        const entryIndex = nodes.findIndex(entry => entry._id === newDiscussionEntry.parentId)
        const currentEntry = nodes[entryIndex]

        currentEntry.subentriesCount = (currentEntry.subentriesCount || 0) + 1

        cache.writeQuery({...parentQueryOptions, data: parentQueryData})
      }

      return true
    } else {
      return false
    }
  } catch (e) {
    // If a subentry query has never been called for the entry being replied to, an exception will be thrown
    // This doesn't matter functionally because the expansion button will be visible and upon clicking it the
    // subentry query will be called, getting the new reply
    // Future new replies to the thread will not throw an exception because the subentry query is now in the cache
  }
}

export const addReplyToAllRootEntries = (cache, newDiscussionEntry) => {
  if (newDiscussionEntry.id === 'DISCUSSION_ENTRY_PLACEHOLDER') return
    const options = {
      query: DISCUSSION_ENTRY_ALL_ROOT_ENTRIES_QUERY,
      variables: {
        discussionEntryID: newDiscussionEntry.rootEntryId
      },
    }
    const rootEntry = JSON.parse(JSON.stringify(cache.readQuery(options)))
    if (rootEntry) {
      if (
        rootEntry.legacyNode.allRootEntries &&
        Array.isArray(rootEntry.legacyNode.allRootEntries)
      ) {
        rootEntry.legacyNode.allRootEntries.push(newDiscussionEntry)
      } else {
        rootEntry.legacyNode.allRootEntries = [newDiscussionEntry]
      }
      rootEntry.legacyNode.subentriesCount = (rootEntry.legacyNode.subentriesCount || 0) + 1
      rootEntry.legacyNode.rootEntryParticipantCounts = {
        ...rootEntry.legacyNode.rootEntryParticipantCounts,
        repliesCount: (rootEntry.legacyNode.rootEntryParticipantCounts?.repliesCount || 0) + 1
      }
      cache.writeQuery({...options, data: rootEntry})
    } else {
      addFirstReplyToAllRootEntries(cache, newDiscussionEntry)
    }
}

const addFirstReplyToAllRootEntries = (cache, newDiscussionEntry) => {
  //either we're adding what would be the first reply to a thread either the thread is not expanded, first reply means un-expanded anyway
  const discussionEntryOptions = {
    id: btoa('DiscussionEntry-' + newDiscussionEntry.parentId),
    fragment: DiscussionEntry.fragment,
    fragmentName: 'DiscussionEntry'
  }
  const rootEntry = JSON.parse(JSON.stringify(cache.readFragment(discussionEntryOptions)))
  if (rootEntry) {
    if (
      rootEntry.allRootEntries &&
      Array.isArray(rootEntry.allRootEntries)
    ) {
      rootEntry.allRootEntries.push(newDiscussionEntry)
    } else {
      rootEntry.allRootEntries = [newDiscussionEntry]
    }
    rootEntry.subentriesCount = (rootEntry.subentriesCount || 0) + 1
    rootEntry.rootEntryParticipantCounts = {
      __typename: 'DiscussionEntryCounts',
      unreadCount: (rootEntry.rootEntryParticipantCounts?.unreadCount || 0),
      repliesCount: (rootEntry.repliesCount || 0) + 1
    }
    rootEntry.lastReply = {
      createdAt: newDiscussionEntry.createdAt,
      __typename: 'DiscussionEntry'
    }

    cache.writeFragment({
      ...discussionEntryOptions,
      data: rootEntry
    })
  }
}


export const addSubentriesCountToParentEntry = (cache, newDiscussionEntry) => {
  // If the new discussion entry is a reply to a reply, update the subentries count on the parent entry.
  // Otherwise, it already happens correctly in the root entry level.
  if (newDiscussionEntry.parentId !== newDiscussionEntry.rootEntryId) {
    const discussionEntryOptions = {
      id: btoa('DiscussionEntry-' + newDiscussionEntry.parentId),
      fragment: DiscussionEntry.fragment,
      fragmentName: 'DiscussionEntry',
    }
    const data = JSON.parse(JSON.stringify(cache.readFragment(discussionEntryOptions)))
    if (data) {
      if (data.rootEntryParticipantCounts) {
        data.lastReply = {
          createdAt: newDiscussionEntry.createdAt,
          __typename: 'DiscussionEntry'
        }
        data.rootEntryParticipantCounts = {
          ...data.rootEntryParticipantCounts,
          unreadCount: (data.rootEntryParticipantCounts?.unreadCount || 0),
          repliesCount: (data.rootEntryParticipantCounts?.repliesCount || 0) + 1
        }
      }

      if (data.subentriesCount) {
        data.subentriesCount += 1
      } else {
        data.subentriesCount = 1
      }

      cache.writeFragment({
        ...discussionEntryOptions,
        data
      });
    }
  }
}

export const resolveAuthorRoles = (isAuthor, discussionRoles) => {
  if (isAuthor && discussionRoles) {
    return discussionRoles.concat('Author')
  }

  if (isAuthor && !discussionRoles) {
    return ['Author']
  }
  return discussionRoles
}

export const responsiveQuerySizes = ({mobile = false, tablet = false, desktop = false} = {}) => {
  const querySizes = {}
  if (mobile) {
    querySizes.mobile = {maxWidth: '767px'}
  }
  if (tablet) {
    querySizes.tablet = {maxWidth: '1023px'}
  }
  if (desktop) {
    querySizes.desktop = {minWidth: tablet ? '1024px' : '768px'}
  }
  return querySizes
}

export const isTopicAuthor = (topicAuthor, entryAuthor) => {
  return topicAuthor && entryAuthor && topicAuthor._id === entryAuthor._id
}

export const getOptimisticResponse = ({
  message = '',
  parentId = 'PLACEHOLDER',
  rootEntryId = null,
  quotedEntry = null,
  isAnonymous = false,
  depth = null,
  attachment = null,
} = {}) => {
  if (quotedEntry && Object.keys(quotedEntry).length !== 0) {
    quotedEntry = {
      createdAt: quotedEntry.createdAt,
      message: quotedEntry.message,
      author: {
        shortName: quotedEntry.author.shortName,
        __typename: 'User',
      },
      anonymousAuthor: null,
      editor: null,
      deleted: false,
      __typename: 'DiscussionEntry',
    }
  } else {
    quotedEntry = null
  }
  return {
    createDiscussionEntry: {
      discussionEntry: {
        id: 'DISCUSSION_ENTRY_PLACEHOLDER',
        _id: 'DISCUSSION_ENTRY_PLACEHOLDER',
        createdAt: new Date().toString(),
        updatedAt: new Date().toString(),
        deleted: false,
        message,
        ratingCount: null,
        ratingSum: null,
        subentriesCount: 0,
        entryParticipant: {
          rating: false,
          read: true,
          forcedReadState: false,
          reportType: null,
          __typename: 'EntryParticipant',
        },
        rootEntryParticipantCounts: {
          unreadCount: 0,
          repliesCount: 0,
          __typename: 'DiscussionEntryCounts',
        },
        author: !isAnonymous
          ? {
              id: 'USER_PLACEHOLDER',
              _id: ENV.current_user.id,
              avatarUrl: ENV.current_user.avatar_image_url,
              htmlUrl: ENV.current_user.html_url,
              displayName: ENV.current_user.display_name,
              courseRoles: [],
              pronouns: null,
              __typename: 'User',
            }
          : null,
        anonymousAuthor: isAnonymous
          ? {
              id: null,
              avatarUrl: null,
              shortName: CURRENT_USER,
              pronouns: null,
              __typename: 'AnonymousUser',
            }
          : null,
        editedAt: null,
        editor: null,
        lastReply: null,
        permissions: {
          attach: false,
          create: false,
          delete: false,
          rate: false,
          read: false,
          reply: false,
          update: false,
          viewRating: false,
          __typename: 'DiscussionEntryPermissions',
        },
        parentId,
        rootEntryId,
        quotedEntry,
        attachment: attachment
          ? {...attachment, id: 'ATTACHMENT_PLACEHOLDER', __typename: 'File'}
          : null,
        discussionEntryVersions: [],
        reportTypeCounts: {
          inappropriateCount: 0,
          offensiveCount: 0,
          otherCount: 0,
          total: 0,
          __typename: 'DiscussionEntryReportTypeCounts',
        },
        depth,
        __typename: 'DiscussionEntry',
      },
      mySubAssignmentSubmissions: [],
      errors: null,
      __typename: 'CreateDiscussionEntryPayload',
    },
  }
}

// data must contain data response to create discussion entry mutation
export const getCheckpointSubmission = (data, subAssignmentTag) => {
  return (
    data.createDiscussionEntry.mySubAssignmentSubmissions?.find(
      sub => sub.subAssignmentTag === subAssignmentTag,
    ) || {}
  )
}

export const buildQuotedReply = (nodes, previewId) => {
  if (!nodes) return ''
  let preview = {}
  nodes.every(reply => {
    if (reply._id === previewId) {
      preview = {
        _id: previewId,
        author: {shortName: getDisplayName(reply)},
        createdAt: reply.createdAt,
        message: reply.message,
      }
      return false
    }
    return true
  })
  return preview
}

export const isAnonymous = discussionEntry =>
  ENV.discussion_anonymity_enabled &&
  discussionEntry.anonymousAuthor !== null &&
  discussionEntry.author === null

const urlParams = new URLSearchParams(window.location.search)
const hiddenUserId = urlParams.get('hidden_user_id')
export const hideStudentNames = !!hiddenUserId

export const userNameToShow = (originalName, authorId, course_roles) => {
  if (hideStudentNames && course_roles?.includes('StudentEnrollment')) {
    return hiddenUserId === authorId ? I18n.t('This Student') : I18n.t('Discussion Participant')
  }
  return originalName
}

export const getDisplayName = discussionEntry => {
  if (isAnonymous(discussionEntry)) {
    if (discussionEntry.anonymousAuthor.shortName === CURRENT_USER) {
      if (!discussionEntry.anonymousAuthor.id) {
        return I18n.t('Anonymous (You)')
      }
      return I18n.t('Anonymous %{id} (You)', {id: discussionEntry.anonymousAuthor.id})
    }
    return I18n.t('Anonymous %{id}', {id: discussionEntry.anonymousAuthor.id})
  }

  const author = discussionEntry.author
  const name = author?.displayName || author?.shortName
  return userNameToShow(name, author?._id, author?.courseRoles)
}

export const showErrorWhenMessageTooLong = message => {
  // use DISCUSSION_ENTRY_SIZE_LIMIT for tests,
  // keep in mind, messages have opening and closing p tags,
  // which are 7 characters in total
  // since this is only to be used for testing
  // that consideration will be up to the tester using
  // this ENV var
  //
  // backend limitation is 64Kb -1
  const limit = ENV.DISCUSSION_ENTRY_SIZE_LIMIT || 63999
  const tooLong = new Blob([message]).size > limit
  if (tooLong === true) {
    const tooLongMessage = I18n.t('The message size has exceeded the maximum text length.')
    $.flashError(tooLongMessage, 2000)
    return true
  }
  return false
}

export const getTranslation = async (text, translateTargetLanguage) => {
  if (!text) return // Don't translate, if no content

  const apiPath = `/courses/${ENV.course_id}/translate`

  try {
    const {json} = await doFetchApi({
      method: 'POST',
      path: apiPath,
      body: {
        inputs: {
          src_lang: 'en', // TODO: detect source language.
          tgt_lang: translateTargetLanguage,
          text,
        },
      },
    })

    return json.translated_text
  } catch (e) {
    const response = await e.response.json()
    const error = new Error()
    Object.assign(error, {...response})
    throw error
  }
}
