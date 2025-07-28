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

import {COURSE_QUERY, GROUP_QUERY} from '../../graphql/Queries'
import {
  defaultEveryoneOption,
  defaultEveryoneElseOption,
  ASSIGNMENT_OVERRIDE_GRAPHQL_TYPENAMES,
  masteryPathsOption,
  REPLY_TO_TOPIC,
  REPLY_TO_ENTRY,
} from './constants'
import {nanoid} from 'nanoid'

export const getContextQuery = contextType => {
  const contextQueryToUse = contextType === 'Course' ? COURSE_QUERY : GROUP_QUERY
  const contextQueryVariables =
    contextType === 'Course' ? {courseId: ENV.context_id} : {groupId: ENV.context_id}

  return {
    contextQueryToUse,
    contextQueryVariables,
  }
}

export const addNewGroupCategoryToCache = (cache, newCategory) => {
  const {contextQueryToUse, contextQueryVariables} = getContextQuery(
    ENV.context_is_not_group ? 'Course' : 'Group',
  )

  const data = JSON.parse(
    JSON.stringify(
      cache.readQuery({
        query: contextQueryToUse,
        variables: contextQueryVariables,
      }),
    ),
  )

  const relevantGroupCategoryData = {
    _id: newCategory.id,
    id: null,
    name: newCategory.name,
    __typename: 'GroupSet',
    groups: null,
  }

  if (data) {
    data.legacyNode.groupSets.push(relevantGroupCategoryData)
    cache.writeQuery({
      query: contextQueryToUse,
      variables: contextQueryVariables,
      data,
    })
  }
}

const getAssetCode = (assetType, assetId) => {
  if (assetType === ASSIGNMENT_OVERRIDE_GRAPHQL_TYPENAMES.SECTION)
    return `course_section_${assetId}`
  if (assetType === ASSIGNMENT_OVERRIDE_GRAPHQL_TYPENAMES.COURSE) return `course_${assetId}`
  if (assetType === ASSIGNMENT_OVERRIDE_GRAPHQL_TYPENAMES.GROUP) return `group_${assetId}`
  return masteryPathsOption.assetCode
}

const getAdhocAssetCode = studentOverride => `user_${studentOverride._id}`

const getAssignedList = override =>
  override.set.__typename === ASSIGNMENT_OVERRIDE_GRAPHQL_TYPENAMES.ADHOC
    ? override.set.students.map(getAdhocAssetCode)
    : [getAssetCode(override.set.__typename, override.set._id)]

export const buildDefaultAssignmentOverride = () => {
  return [
    {
      dueDateId: nanoid(),
      assignedList: [defaultEveryoneOption.assetCode],
      dueDate: '',
      availableFrom: '',
      availableUntil: '',
    },
  ]
}
export const buildAssignmentOverrides = discussion => {
  const target = discussion.assignment || discussion

  if (!target) return buildDefaultAssignmentOverride()

  let overrides =
    target === discussion.assignment
      ? target.assignmentOverrides
      : target.ungradedDiscussionOverrides
  overrides =
    overrides?.nodes?.map(override => ({
      dueDateId: override.id,
      assignedList: getAssignedList(override),
      dueDate: override.dueAt,
      availableFrom: override.unlockAt,
      availableUntil: override.lockAt,
      unassignItem: override.unassignItem,
      students: override.set.students,
      title: override.set.name,
      nonCollaborative: override.set.nonCollaborative,
      ...(override.contextModule && {
        context_module_id: override.contextModule._id,
        context_module_name: override.contextModule.name,
      }),
    })) || []

  const hasCourseOverride = overrides.some(obj =>
    obj.assignedList.some(item => item.includes('course') && !item.includes('section')),
  )

  let checkpointOverrides = []
  const everyoneDates = {}
  const hasCheckpoints =
    discussion?.assignment?.hasSubAssignments && discussion.assignment.checkpoints.length === 2

  if (hasCheckpoints && ENV.DISCUSSION_CHECKPOINTS_ENABLED) {
    // we need an override for each 'assignee type: everyone, section, students,...'
    // to determine, count union of reply_to_topic and required_reply + 1 for everyone if checkpoint.due_at
    const allAssignees = getCheckpointAssignees(discussion.assignment.checkpoints)
    checkpointOverrides = allAssignees.map(assignee => {
      const returnHash = {}
      returnHash.assignedList = assignee

      discussion.assignment.checkpoints.forEach(checkpoint => {
        // select the correct checkpoint override for the assignee;

        const override = checkpoint.assignmentOverrides.nodes.filter(override => {
          return JSON.stringify(assignee) === JSON.stringify(getAssignedList(override))
        })[0]
        if (override) {
          if (checkpoint.tag === REPLY_TO_TOPIC) {
            returnHash.replyToTopicOverrideId = override._id
            returnHash.replyToTopicDueDate = override.dueAt
          }
          if (checkpoint.tag === REPLY_TO_ENTRY) {
            returnHash.replyToEntryOverrideId = override._id
            returnHash.requiredRepliesDueDate = override.dueAt
          }
          returnHash.dueDateId = returnHash.dueDateId || override._id || null
          returnHash.availableFrom = returnHash.availableFrom || override.unlockAt || null
          returnHash.availableUntil = returnHash.availableUntil || override.lockAt || null

          // Add information based on override type
          if (override.set.__typename === ASSIGNMENT_OVERRIDE_GRAPHQL_TYPENAMES.ADHOC) {
            returnHash.students = override.set.students
            returnHash.student_ids = override.set.students.map(student => student._id)
          } else if (override.set.__typename === ASSIGNMENT_OVERRIDE_GRAPHQL_TYPENAMES.SECTION) {
            returnHash.id = override.set._id || null
            returnHash.title = override.set.name || null
          } else if (override.set.__typename === ASSIGNMENT_OVERRIDE_GRAPHQL_TYPENAMES.GROUP) {
            returnHash.id = override.set._id || null
            returnHash.nonCollaborative = override.set.nonCollaborative || null
            returnHash.title = override.set.name || null
          }
        }
      })
      return returnHash
    })

    const topicCheckpoint = discussion.assignment.checkpoints.find(
      checkpoint => checkpoint.tag === REPLY_TO_TOPIC,
    )
    const replyCheckpoint = discussion.assignment.checkpoints.find(
      checkpoint => checkpoint.tag === REPLY_TO_ENTRY,
    )

    if (topicCheckpoint.dueAt || topicCheckpoint.unlockAt || topicCheckpoint.lockAt) {
      everyoneDates.replyToTopicDueDate = topicCheckpoint.dueAt
      everyoneDates.availableFrom = topicCheckpoint.unlockAt
      everyoneDates.availableUntil = topicCheckpoint.lockAt
    }
    if (replyCheckpoint.dueAt || replyCheckpoint.unlockAt || replyCheckpoint.lockAt) {
      everyoneDates.requiredRepliesDueDate = replyCheckpoint.dueAt
      everyoneDates.availableFrom = replyCheckpoint.unlockAt
      everyoneDates.availableUntil = replyCheckpoint.lockAt
    }

    if (Object.keys(everyoneDates).length > 0) {
      everyoneDates.assignedList = ['everyone']
      checkpointOverrides.push(everyoneDates)
    }
    overrides = checkpointOverrides
  }

  // When this is true, then we do not have a everyone/everyone else option
  if (target.onlyVisibleToOverrides || !target.visibleToEveryone || hasCourseOverride)
    return overrides

  if (Object.keys(everyoneDates).length === 0) {
    overrides.push({
      dueDateId: nanoid(),
      assignedList:
        overrides.length > 0
          ? [defaultEveryoneElseOption.assetCode]
          : [defaultEveryoneOption.assetCode],
      dueDate: target.dueAt,
      availableFrom: target.unlockAt || target.delayedPostAt,
      availableUntil: target.lockAt,
    })
  }
  return overrides.length > 0 ? overrides : buildDefaultAssignmentOverride()
}

const getCheckpointAssignees = checkpoints => {
  if (checkpoints.length === 0) {
    return []
  } else {
    let allAssignees = []
    checkpoints.forEach(checkpoint => {
      const checkpointAssignees = checkpoint.assignmentOverrides?.nodes.map(override =>
        getAssignedList(override),
      )
      allAssignees = [...new Set([...allAssignees, ...checkpointAssignees])]
    })

    const uniqueTopLevelArrays = []
    const seenTopLevelArrays = new Set()

    // studentIds come in subArrays that have to be duplicate checked differently
    allAssignees.forEach(arr => {
      const arrString = JSON.stringify(arr)
      if (!seenTopLevelArrays.has(arrString)) {
        seenTopLevelArrays.add(arrString)
        uniqueTopLevelArrays.push(arr)
      }
    })
    return uniqueTopLevelArrays
  }
}
