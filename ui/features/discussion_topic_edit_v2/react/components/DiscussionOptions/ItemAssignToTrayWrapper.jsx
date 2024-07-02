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

import React, {useContext, useEffect, useState} from 'react'
import {DiscussionDueDatesContext} from '../../util/constants'
import DifferentiatedModulesSection from '@canvas/due-dates/react/DifferentiatedModulesSection'
import LoadingIndicator from '@canvas/loading-indicator'

const DEFAULT_SECTION_ID = '0'

export const ItemAssignToTrayWrapper = () => {
  const {
    assignedInfoList,
    setAssignedInfoList,
    title,
    assignmentID,
    importantDates,
    setImportantDates,
    pointsPossible,
    isGraded,
    isCheckpoints,
    postToSis,
  } = useContext(DiscussionDueDatesContext)

  const [overrides, setOverrides] = useState([])
  const [loading, setLoading] = useState(true)

  // Make sure assignedInfoList is updated
  useEffect(() => {
    if (assignedInfoList.length > 0) {
      const newOverrides = assignedInfoList.map(convertToOverrideObject)
      setOverrides(newOverrides)
    }
    setLoading(false)
  }, [assignedInfoList])

  // Convert the assignedInfoList to the expected shape for the DifferentiatedModulesSection
  function convertToOverrideObject(inputObj) {
    const outputObj = {
      due_at: inputObj.dueDate || null,
      lock_at: inputObj.availableUntil || null,
      unlock_at: inputObj.availableFrom || null,
      reply_to_topic_due_at: inputObj.replyToTopicDueDate || null,
      required_replies_due_at: inputObj.requiredRepliesDueDate || null,
      due_at_overridden: true,
      all_day: false,
      all_day_date: null,
      unlock_at_overridden: true,
      reply_to_topic_due_at_overridden: true,
      required_replies_due_at_overridden: true,
      lock_at_overridden: true,
      unassign_item: inputObj.unassignItem || false,
      id: inputObj.dueDateId,
      noop_id: null,
      stagedOverrideId: inputObj.stagedOverrideId || null,
      rowKey: inputObj.rowKey || null,
    }

    // Add context_module_id and context_module_name fields if they exist on inputObj
    if (inputObj.context_module_id) {
      outputObj.context_module_id = inputObj.context_module_id
    }
    if (inputObj.context_module_name) {
      outputObj.context_module_name = inputObj.context_module_name
    }

    let courseSectionId = null
    const studentIds = []
    const groupIds = []

    inputObj.assignedList.forEach(item => {
      if (item === 'everyone') {
        courseSectionId = DEFAULT_SECTION_ID
        return
      }

      if (item === 'mastery_paths') {
        outputObj.noop_id = '1'
        return
      }

      // Find the last underscore in the string and split by it
      const lastUnderscoreIndex = item.lastIndexOf('_')
      const type = item.substring(0, lastUnderscoreIndex)
      const id = item.substring(lastUnderscoreIndex + 1)

      if (type === 'course_section') {
        courseSectionId = id
      } else if (type === 'user') {
        studentIds.push(id)
      } else if (type === 'group') {
        groupIds.push(id)
      } else if (type === 'course') {
        outputObj.course_id = id
      }
    })

    if (courseSectionId) {
      outputObj.course_section_id = courseSectionId
    }
    if (studentIds.length > 0) {
      outputObj.student_ids = studentIds
    }
    if (groupIds.length > 0) {
      outputObj.group_ids = groupIds
    }

    return outputObj
  }

  function convertToAssignedInfoListObject(inputObj) {
    const outputObj = {
      dueDateId: inputObj.rowKey || inputObj.stagedOverrideId || null,
      assignedList: [],
      replyToTopicDueDate: inputObj.reply_to_topic_due_at || null,
      requiredRepliesDueDate: inputObj.required_replies_due_at || null,
      dueDate: inputObj.due_at ? inputObj.due_at : null,
      availableFrom: inputObj.unlock_at || null,
      availableUntil: inputObj.lock_at || null,
      unassignItem: inputObj.unassign_item || false,
      context_module_id: inputObj.context_module_id || null,
      context_module_name: inputObj.context_module_name || null,
      stagedOverrideId: inputObj.stagedOverrideId || null,
      rowKey: inputObj.rowKey || null,
    }

    if (inputObj.noop_id === '1') {
      outputObj.assignedList.push('mastery_paths')
    } else if (inputObj.course_section_id) {
      if (inputObj.course_section_id === '0') {
        outputObj.assignedList.push('everyone')
      } else {
        outputObj.assignedList.push('course_section_' + inputObj.course_section_id)
      }
    } else if (inputObj.student_ids) {
      inputObj.student_ids.forEach(id => {
        outputObj.assignedList.push('user_' + id)
      })
    } else if (inputObj.course_id) {
      outputObj.assignedList.push('course_' + inputObj.course_id)
    }

    if (
      !inputObj.course_section_id &&
      !inputObj.course_id &&
      !inputObj.student_ids &&
      !inputObj.noop_id
    ) {
      outputObj.assignedList.push('everyone')
    }

    return outputObj
  }

  const onSync = (assigneeInfoUpdateOverrides, newImportantDatesValue) => {
    if (assigneeInfoUpdateOverrides) {
      const outputArray = []
      assigneeInfoUpdateOverrides.forEach(inputObj => {
        const outputObj = convertToAssignedInfoListObject(inputObj)
        outputArray.push(outputObj)
      })
      // convert overrides to the expected assignedInfoList shape
      // Then Set the assignedInfoList
      setAssignedInfoList(outputArray)
    }
    setImportantDates(newImportantDatesValue)
  }

  if (loading) {
    return <LoadingIndicator />
  }

  return (
    <DifferentiatedModulesSection
      onSync={onSync}
      overrides={overrides}
      assignmentId={assignmentID}
      getAssignmentName={() => title}
      getPointsPossible={() => pointsPossible}
      type="discussion"
      importantDates={importantDates}
      defaultSectionId={DEFAULT_SECTION_ID}
      supportDueDates={isGraded}
      isCheckpointed={isCheckpoints}
      postToSIS={postToSis}
    />
  )
}

ItemAssignToTrayWrapper.propTypes = {}

ItemAssignToTrayWrapper.defaultProps = {}
