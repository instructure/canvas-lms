/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {REPLY_TO_TOPIC, REPLY_TO_ENTRY} from './constants'

const prepareOverride = (
  overrideDueDate,
  overrideAvailableUntil,
  overrideAvailableFrom,
  overrideUnassignItem,
  overrideIds = {
    groupId: null,
    courseSectionId: null,
    courseId: null,
    studentIds: null,
    noopId: null,
  },
  overrideTitle = null
) => {
  return {
    dueAt: overrideDueDate || null,
    lockAt: overrideAvailableUntil || null,
    unlockAt: overrideAvailableFrom || null,
    unassignItem: overrideUnassignItem || false,
    groupId: overrideIds.groupIds || null,
    courseSectionId: overrideIds.courseSectionId || null,
    courseId: overrideIds.courseId || null,
    studentIds: overrideIds.studentIds || null,
    noopId: overrideIds.noopId || null,
    title: overrideTitle || null,
  }
}

const prepareAssignmentOverridesPayload = (
  assignedInfoList,
  defaultEveryoneOption,
  masteryPathsOption,
  noDueDates = false
) => {
  const onlyVisibleToEveryone = assignedInfoList.every(
    info =>
      info.assignedList.length === 1 && info.assignedList[0] === defaultEveryoneOption.assetCode
  )

  if (onlyVisibleToEveryone) return null

  const preparedOverrides = []
  assignedInfoList.forEach(info => {
    const {assignedList, context_module_id: contextModuleId} = info
    const studentIds = assignedList.filter(assetCode => assetCode.includes('user'))
    const sectionIds = assignedList.filter(assetCode => assetCode.includes('section'))
    const courseIds = assignedList.filter(
      assetCode => assetCode.includes('course') && !assetCode.includes('section')
    )
    const groupIds = assignedList.filter(assetCode => assetCode.includes('group'))

    // If the override is a module override, don't update it
    if (contextModuleId) return null

    // remove due date if unsuported
    if (noDueDates) info.dueDate = null

    // override for student ids
    if (studentIds.length > 0) {
      preparedOverrides.push(
        prepareOverride(
          info.dueDate || null,
          info.availableUntil || null,
          info.availableFrom || null,
          info.unassignItem || false,
          {
            studentIds:
              studentIds.length > 0 ? studentIds.map(id => id.split('_').reverse()[0]) : null,
          }
        )
      )
    }

    // override for section ids
    if (sectionIds.length > 0) {
      sectionIds.forEach(sectionId => {
        preparedOverrides.push(
          prepareOverride(
            info.dueDate || null,
            info.availableUntil || null,
            info.availableFrom || null,
            info.unassignItem || false,
            {
              courseSectionId: sectionId.split('_').reverse()[0] || null,
            }
          )
        )
      })
    }

    // override for course ids
    if (courseIds.length > 0) {
      preparedOverrides.push(
        prepareOverride(
          info.dueDate || null,
          info.availableUntil || null,
          info.availableFrom || null,
          info.unassignItem || false,
          {
            courseId: 'everyone',
          }
        )
      )
    }

    // override for group ids
    if (groupIds.length > 0) {
      groupIds.forEach(groupId => {
        preparedOverrides.push(
          prepareOverride(
            info.dueDate || null,
            info.availableUntil || null,
            info.availableFrom || null,
            info.unassignItem || false,
            {
              groupIds: groupId.split('_').reverse()[0] || null,
            }
          )
        )
      })
    }
  })

  const masteryPathOverride = assignedInfoList.find(info =>
    info.assignedList.includes(masteryPathsOption.assetCode)
  )

  if (masteryPathOverride) {
    preparedOverrides.push(
      prepareOverride(
        masteryPathOverride.dueDate || null,
        masteryPathOverride.availableUntil || null,
        masteryPathOverride.availableFrom || null,
        masteryPathOverride.unassignItem || false,
        {
          noopId: '1',
        },
        masteryPathsOption.label
      )
    )
  }

  return preparedOverrides
}

const preparePeerReviewPayload = (
  isEditing,
  peerReviewAssignment,
  peerReviewsPerStudent,
  peerReviewDueDate,
  intraGroupPeerReviews
) => {
  return peerReviewAssignment === 'off'
    ? null
    : {
        automaticReviews: peerReviewAssignment === 'automatically',
        count: !isEditing && peerReviewAssignment === 'manually' ? 0 : peerReviewsPerStudent,
        enabled: true,
        dueAt: peerReviewDueDate || null,
        intraReviews: intraGroupPeerReviews,
      }
}

const setOnlyVisibleToOverrides = (assignedInfoList, everyoneOverride) => {
  const hasDefaultEveryone = !!Object.keys(everyoneOverride).length
  if (ENV.FEATURES?.selective_release_ui_api) {
    const contextModuleOverrides = assignedInfoList.filter(info => info.context_module_id != null)
    return !(hasDefaultEveryone || contextModuleOverrides.length === assignedInfoList.length)
  } else {
    return !hasDefaultEveryone
  }
}

export function convertToCheckpointsData(assignedInfoList) {
  const checkpoints_data = []

  const checkpoint_reply_to_topic = {
    checkpoint_label: REPLY_TO_TOPIC,
    dates: [],
  }

  const checkpoint_reply_to_entry = {
    checkpoint_label: REPLY_TO_ENTRY,
    dates: [],
  }

  assignedInfoList.forEach(item => {
    item.assignedList.forEach(assignee => {
      const {type, id} = extractTypeAndId(assignee)

      const return_hash = createCheckPointsDatesHash(
        type,
        id,
        item.replyToTopicDueDate,
        item.availableFrom,
        item.availableUntil
      )

      if (return_hash) {
        checkpoint_reply_to_topic.dates.push(return_hash)
      }
    })

    item.assignedList.forEach(assignee => {
      const {type, id} = extractTypeAndId(assignee)
      const return_hash = createCheckPointsDatesHash(
        type,
        id,
        item.requiredRepliesDueDate,
        item.availableFrom,
        item.availableUntil
      )

      if (return_hash) {
        checkpoint_reply_to_entry.dates.push(return_hash)
      }
    })

    if (item.assignedList.some(assignee => assignee.startsWith('user_'))) {
      const topicStudentIds = item.assignedList
        .filter(assignee => assignee.startsWith('user_'))
        .map(assignee => parseInt(assignee.substring(assignee.lastIndexOf('_') + 1), 10))

      const topic_return_hash = {
        type: 'override',
        dueAt: item.replyToTopicDueDate || null,
        setType: 'ADHOC',
        studentIds: topicStudentIds,
        unlockAt: item.availableFrom || null,
        lockAt: item.availableUntil || null,
      }

      checkpoint_reply_to_topic.dates.push(topic_return_hash)
    }

    if (item.assignedList.some(assignee => assignee.startsWith('user_'))) {
      const replyStudentIds = item.assignedList
        .filter(assignee => assignee.startsWith('user_'))
        .map(assignee => parseInt(assignee.substring(assignee.lastIndexOf('_') + 1), 10))

      const reply_return_hash = {
        type: 'override',
        dueAt: item.requiredRepliesDueDate || null,
        setType: 'ADHOC',
        studentIds: replyStudentIds,
        unlockAt: item.availableFrom || null,
        lockAt: item.availableUntil || null,
      }

      checkpoint_reply_to_entry.dates.push(reply_return_hash)
    }
  })
  checkpoints_data.push(checkpoint_reply_to_topic, checkpoint_reply_to_entry)
  return checkpoints_data
}

function extractTypeAndId(assignee) {
  if (assignee === 'everyone') {
    return {type: assignee, id: null}
  }
  const lastUnderscoreIndex = assignee.lastIndexOf('_')
  const type = assignee.substring(0, lastUnderscoreIndex)
  const id = parseInt(assignee.substring(lastUnderscoreIndex + 1), 10)

  return {type, id}
}

function createCheckPointsDatesHash(type, id, dueAt, unlockAt, lockAt) {
  const return_hash = {}

  if (type === 'everyone') {
    return_hash.type = 'everyone'
  } else if (type === 'course_section' || type === 'group' || type === 'course') {
    return_hash.type = 'override'
    return_hash.setType =
      type === 'course_section' ? 'CourseSection' : type === 'group' ? 'Group' : 'Course'
    return_hash.setId = id
  }
  return_hash.dueAt = dueAt || null
  return_hash.unlockAt = unlockAt || null
  return_hash.lockAt = lockAt || null

  return Object.keys(return_hash).length > 0 && type !== 'user' ? return_hash : null
}

export const prepareCheckpointsPayload = (
  assignedInfoList,
  pointsPossibleReplyToTopic,
  pointsPossibleReplyToEntry,
  replyToEntryRequiredCount,
  isCheckpoints
) => {
  // convert assignedInfoList to Api format
  const convertedAssignedInfoList = convertToCheckpointsData(assignedInfoList)

  return isCheckpoints
    ? [
        {
          checkpointLabel: REPLY_TO_TOPIC,
          pointsPossible: pointsPossibleReplyToTopic,
          dates: convertedAssignedInfoList[0].dates,
          repliesRequired: replyToEntryRequiredCount,
        },
        {
          checkpointLabel: REPLY_TO_ENTRY,
          pointsPossible: pointsPossibleReplyToEntry,
          dates: convertedAssignedInfoList[1].dates,
          repliesRequired: replyToEntryRequiredCount,
        },
      ]
    : []
}

const prepareEveryoneOrEveryoneElseOverride = (
  assignedInfoList,
  defaultEveryoneOption,
  defaultEveryoneElseOption
) =>
  assignedInfoList.find(
    info =>
      info.assignedList.includes(defaultEveryoneOption.assetCode) ||
      info.assignedList.includes(defaultEveryoneElseOption.assetCode)
  ) || {}

export const prepareAssignmentPayload = (
  abGuid,
  isEditing,
  title,
  pointsPossible,
  displayGradeAs,
  assignmentGroup,
  gradingSchemeId,
  isGraded,
  assignedInfoList,
  defaultEveryoneOption,
  defaultEveryoneElseOption,
  postToSis,
  peerReviewAssignment,
  peerReviewsPerStudent,
  peerReviewDueDate,
  intraGroupPeerReviews,
  masteryPathsOption,
  importantDates,
  isCheckpoints,
  existingAssignment
) => {
  /*
  Return null if the assignment is not graded and there is no existing assignment.
  This is so that we can trigger the deletion of an existing assignment if the graded checkbox is unselected
  since the endpoint looks for an assignment payload.
  */
  if (!isGraded && !existingAssignment) return null

  const everyoneOverride = prepareEveryoneOrEveryoneElseOverride(
    assignedInfoList,
    defaultEveryoneOption,
    defaultEveryoneElseOption
  )
  // Common payload properties for graded assignments
  let payload = {
    postToSis,
    gradingType: displayGradeAs,
    importantDates,
    assignmentGroupId: assignmentGroup || null,
    peerReviews: preparePeerReviewPayload(
      isEditing,
      peerReviewAssignment,
      peerReviewsPerStudent,
      peerReviewDueDate,
      intraGroupPeerReviews
    ),
    onlyVisibleToOverrides: setOnlyVisibleToOverrides(assignedInfoList, everyoneOverride),
    gradingStandardId: gradingSchemeId || null,
    forCheckpoints: isCheckpoints,
  }
  if (abGuid) {
    payload = {
      ...payload,
      abGuid,
    }
  }

  // Additional properties if graded assignment is not checkpointed
  if (!isCheckpoints) {
    payload = {
      ...payload,
      pointsPossible,
      dueAt: everyoneOverride.dueDate || null,
      lockAt: everyoneOverride.availableUntil || null,
      unlockAt: everyoneOverride.availableFrom || null,
      assignmentOverrides: prepareAssignmentOverridesPayload(
        assignedInfoList,
        defaultEveryoneOption,
        masteryPathsOption
      ),
    }
  }
  // Additional properties for editing of a graded assignment
  if (isEditing) {
    payload = {
      ...payload,
      setAssignment: isGraded,
    }
  }
  // Additional properties for creation of a graded assignment
  if (!isEditing) {
    payload = {
      ...payload,
      courseId: ENV.context_id,
      name: title,
    }
  }
  return payload
}

export const prepareUngradedDiscussionOverridesPayload = (
  assignedInfoList,
  defaultEveryoneOption,
  defaultEveryoneElseOption,
  masteryPathsOption
) => {
  const everyoneOverride = prepareEveryoneOrEveryoneElseOverride(
    assignedInfoList,
    defaultEveryoneOption,
    defaultEveryoneElseOption
  )

  return {
    dueAt: everyoneOverride.dueDate || null,
    lockAt: everyoneOverride.availableUntil || null,
    delayedPostAt: everyoneOverride.availableFrom || null,
    onlyVisibleToOverrides: setOnlyVisibleToOverrides(assignedInfoList, everyoneOverride),
    ungradedDiscussionOverrides: prepareAssignmentOverridesPayload(
      assignedInfoList,
      defaultEveryoneOption,
      masteryPathsOption,
      true
    ),
  }
}
