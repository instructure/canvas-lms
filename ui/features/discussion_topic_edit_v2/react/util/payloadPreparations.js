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
  overrideIds = {
    groupId: null,
    courseSectionId: null,
    studentIds: null,
    noopId: null,
  },
  overrideTitle = null
) => {
  return {
    dueAt: overrideDueDate || null,
    lockAt: overrideAvailableUntil || null,
    unlockAt: overrideAvailableFrom || null,
    groupId: overrideIds.groupIds || null,
    courseSectionId: overrideIds.courseSectionId || null,
    studentIds: overrideIds.studentIds || null,
    noopId: overrideIds.noopId || null,
    title: overrideTitle || null,
  }
}

const prepareAssignmentOverridesPayload = (
  assignedInfoList,
  defaultEveryoneOption,
  masteryPathsOption
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
    const groupIds = assignedList.filter(assetCode => assetCode.includes('group'))

    // If the override is a module override, don't update it
    if (contextModuleId) return null

    // override for student ids
    if (studentIds.length > 0) {
      preparedOverrides.push(
        prepareOverride(
          info.dueDate || null,
          info.availableUntil || null,
          info.availableFrom || null,
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
            {
              courseSectionId: sectionId.split('_').reverse()[0] || null,
            }
          )
        )
      })
    }

    // override for group ids
    if (groupIds.length > 0) {
      groupIds.forEach(groupId => {
        preparedOverrides.push(
          prepareOverride(
            info.dueDate || null,
            info.availableUntil || null,
            info.availableFrom || null,
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

export const prepareCheckpointsPayload = (
  pointsPossibleReplyToTopic,
  pointsPossibleReplyToEntry,
  replyToEntryRequiredCount,
  isCheckpoints
) => {
  return isCheckpoints
    ? [
        {
          checkpointLabel: REPLY_TO_TOPIC,
          pointsPossible: pointsPossibleReplyToTopic,
          dates: [],
          repliesRequired: replyToEntryRequiredCount,
        },
        {
          checkpointLabel: REPLY_TO_ENTRY,
          pointsPossible: pointsPossibleReplyToEntry,
          dates: [],
          repliesRequired: replyToEntryRequiredCount,
        },
      ]
    : []
}

export const prepareAssignmentPayload = (
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
  isCheckpoints,
  existingAssignment
) => {
  /*
  Return null if the assignment is not graded and there is no existing assignment.
  This is so that we can trigger the deletion of an existing assignment if the graded checkbox is unselected
  since the endpoint looks for an assignment payload.
  */
  if (!isGraded && !existingAssignment) return null

  const everyoneOverride =
    assignedInfoList.find(
      info =>
        info.assignedList.includes(defaultEveryoneOption.assetCode) ||
        info.assignedList.includes(defaultEveryoneElseOption.assetCode)
    ) || {}
  // Common payload properties for graded assignments
  let payload = {
    postToSis,
    gradingType: displayGradeAs,
    assignmentGroupId: assignmentGroup || null,
    peerReviews: preparePeerReviewPayload(
      isEditing,
      peerReviewAssignment,
      peerReviewsPerStudent,
      peerReviewDueDate,
      intraGroupPeerReviews
    ),
    assignmentOverrides: prepareAssignmentOverridesPayload(
      assignedInfoList,
      defaultEveryoneOption,
      masteryPathsOption
    ),
    onlyVisibleToOverrides: !Object.keys(everyoneOverride).length,
    gradingStandardId: gradingSchemeId || null,
    forCheckpoints: isCheckpoints,
  }
  // Additional properties if graded assignment is not checkpointed
  if (!isCheckpoints) {
    payload = {
      ...payload,
      pointsPossible,
      dueAt: everyoneOverride.dueDate || null,
      lockAt: everyoneOverride.availableUntil || null,
      unlockAt: everyoneOverride.availableFrom || null,
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
