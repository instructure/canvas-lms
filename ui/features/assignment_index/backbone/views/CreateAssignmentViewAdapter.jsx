/* eslint-disable no-fallthrough */
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

import React from 'react'
import CreateEditAssignmentModal from '@canvas/assignments/react/CreateEditAssignmentModal'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import {encodeQueryString} from '@instructure/query-string-encoding'
import axios from '@canvas/axios'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('CreateEditAssignmentModalAdapter')

const CreateAssignmentViewAdapter = ({assignment, assignmentGroup, closeHandler}) => {
  const maxNameLength = ENV.MAX_NAME_LENGTH || 255
  const minNameLength = ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT || 1

  // Different Assignment Types
  const ONLINE_QUIZ = 'online_quiz'
  const DISCUSSION_TOPIC = 'discussion_topic'

  const moreOptionsHandler = (data, isNewAssignment) => {
    const assignmentModel = assignment || generateNewAssignment(assignmentGroup)

    const mappedData = {
      submission_type: [data.type],
      name: data.name,
      due_at: data.dueAt,
      points_possible: data.points,
      post_to_sis: data.syncToSIS,
    }

    assignmentModel.submissionTypes(mappedData.submission_type)

    // Redirect to appropriate "edit" page
    if (data.type === ONLINE_QUIZ) {
      isNewAssignment ? launchQuizNew(mappedData) : launchQuizEdit(assignmentModel, mappedData)
    } else if (data.type === DISCUSSION_TOPIC) {
      launchDiscussionTopicEdit(assignmentModel, assignmentGroup, mappedData, isNewAssignment)
    } else {
      launchAssignmentEdit(assignmentModel, assignmentGroup, mappedData, isNewAssignment)
    }
  }

  const saveHandler = async data => {
    const assignmentModel = assignment || generateNewAssignment(assignmentGroup)

    let mappedData = {
      submission_type: [data.type],
      name: data.name,
      due_at: data.dueAt !== '' ? data.dueAt : null,
      points_possible: data.points,
      post_to_sis: data.syncToSIS,
    }

    if (data.publish) {
      mappedData = {
        published: true,
        ...mappedData,
      }
    }

    assignmentModel.submissionTypes(mappedData.submission_type)

    // Save the assignment model (Should fire backend call)
    try {
      const saveOpts = {wait: true}
      await assignmentModel.save(mappedData, saveOpts)
      assignmentGroup?.get('assignments').add(assignmentModel)
    } catch (e) {
      showFlashAlert({
        message: I18n.t('Unable to save assignment'),
        type: 'error',
      })
    }
  }

  const getAssignmentType = assignment => {
    const submissionTypes = assignment.submissionTypes()
    if (submissionTypes.length === 0) {
      return 'online'
    }
    return submissionTypes[0]
  }

  const adaptAssignment = () => ({
    assignmentGroupId: assignmentGroup ? assignmentGroup.id : null,
    type: getAssignmentType(assignment),
    name: assignment.name(),
    dueAt: assignment.dueAt(),
    lockAt: assignment.lockAt(),
    unlockAt: assignment.unlockAt(),
    allDates: assignment.allDates(),
    points: assignment.pointsPossible(),
    isPublished: assignment.published(),
    multipleDueDates: assignment.multipleDueDates(),
    differentiatedAssignment: assignment.nonBaseDates(),
    frozenFields: getFrozenFields(assignment),
  })

  return (
    <>
      <CreateEditAssignmentModal
        assignment={assignment ? adaptAssignment(assignment) : undefined}
        onCloseHandler={closeHandler}
        onSaveHandler={saveHandler}
        onMoreOptionsHandler={moreOptionsHandler}
        timezone={ENV.TIMEZONE}
        validDueAtRange={ENV.VALID_DATE_RANGE}
        defaultDueTime={ENV.DEFAULT_DUE_TIME}
        dueDateRequired={ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT}
        maxNameLength={maxNameLength}
        minNameLength={minNameLength}
        syncGradesToSISFF={ENV.POST_TO_SIS}
        shouldSyncGradesToSIS={assignment ? assignment.postToSIS() : ENV.POST_TO_SIS_DEFAULT}
        courseHasGradingPeriods={!!ENV.HAS_GRADING_PERIODS}
        activeGradingPeriods={ENV.active_grading_periods}
      />
    </>
  )
}

// helper methods
const newAssignmentUrl = () => {
  return ENV.URLS.new_assignment_url
}

const newQuizUrl = () => {
  return ENV.URLS.new_quiz_url
}

const courseUrl = () => {
  return ENV.current_context.url
}

const redirectTo = url => {
  window.location.href = url
}

const launchQuizNew = async (data) => {
  const response = await axios.post(newQuizUrl(), data)
  redirectTo(response.data.url)
}

const launchQuizEdit = (assignment, data) => {
  const url = assignment.htmlEditUrl()
  redirectTo(url + '?' + encodeQueryString(data))
}

const generateNewAssignment = assignmentGroup => {
  const assignment = new Assignment()
  if (assignmentGroup) {
    assignment.assignmentGroupId(assignmentGroup.id)
  }
  return assignment
}

const launchAssignmentEdit = (assignment, assignmentGroup, data, isNewAssignment) => {
  let url

  if (assignmentGroup) {
    data.assignment_group_id = assignmentGroup.id
  }

  if (isNewAssignment) {
    url = newAssignmentUrl()
  } else {
    url = assignment.htmlEditUrl()
  }
  redirectTo(url + '?' + encodeQueryString(data))
}

const launchDiscussionTopicEdit = (assignment, assignmentGroup, data, isNewAssignment) => {
  let url

  // Need to change "name" to "title" for discussion topics
  data.title = data.name
  delete data.name

  if (isNewAssignment) {
    url = courseUrl() + '/discussion_topics/new?' + assignmentGroup.id + '&'
    redirectTo(url + encodeQueryString(data))
  } else {
    url = assignment.htmlEditUrl()
    redirectTo(url + '?' + encodeQueryString(data))
  }
}

const addFrozenField = (frozenFields, field) => {
  if (!frozenFields.includes(field)) {
    frozenFields.push(field)
  }
}

const getFrozenFields = assignment => {
  const assignmentJSON = assignment.toView()
  const fields = []

  // Check if assignment is a child of blueprint course
  if (assignmentJSON.is_master_course_child_content) {
    const restrictions = assignmentJSON.master_course_restrictions
    Object.keys(restrictions).forEach(r => {
      switch (r) {
        case 'content':
          if (restrictions[r]) addFrozenField(fields, 'name')
        case 'points':
          if (restrictions[r]) addFrozenField(fields, 'points')
        case 'due_dates':
          if (restrictions[r]) addFrozenField(fields, 'due_at')
      }
    })
  }

  // Assignment name
  if (assignmentJSON.frozenAttributes.includes('title')) {
    addFrozenField(fields, 'name')
  }

  // Due Date
  if (
    !assignmentJSON.hasDueDate ||
    assignmentJSON.hasSubAssignments ||
    assignmentJSON.nonBaseDates ||
    assignmentJSON.isOnlyVisibleToOverrides
  ) {
    addFrozenField(fields, 'due_at')
  }

  // Points
  if (assignmentJSON.frozenAttributes.includes('points_possible')) {
    addFrozenField(fields, 'points')
  }

  // Since points for Checkpointed discussion topics are more complex, we will not allow users
  // to adjust points in this modal (they must select "more options")
  if (assignment.isDiscussionTopic() && assignmentJSON.hasSubAssignments) {
    addFrozenField(fields, 'points')
  }

  return fields
}

export default CreateAssignmentViewAdapter
