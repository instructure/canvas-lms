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
import {GradedDiscussionDueDatesContext} from '../../util/constants'
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
    pointsPossible,
  } = useContext(GradedDiscussionDueDatesContext)

  const [overrides, setOverrides] = useState([])
  const [loading, setLoading] = useState(true)

  // Make sure assignedInfoList is updated
  useEffect(() => {
    if (assignedInfoList.length > 0) {
      const newOverrides = assignedInfoList.map(convertToOverrideObject)
      setOverrides(newOverrides)
      setLoading(false) // Data is loaded and processed
    }
  }, [assignedInfoList])

  // Convert the assignedInfoList to the expected shape for the DifferentiatedModulesSection
  function convertToOverrideObject(inputObj) {
    const outputObj = {
      due_at: inputObj.dueDate || null,
      lock_at: inputObj.availableUntil || null,
      unlock_at: inputObj.availableFrom || null,
      due_at_overridden: true,
      all_day: false,
      all_day_date: null,
      unlock_at_overridden: true,
      lock_at_overridden: true,
      id: inputObj.dueDateId,
      noop_id: null,
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
      dueDateId: inputObj.stagedOverrideId || null,
      assignedList: [],
      dueDate: inputObj.due_at ? inputObj.due_at : null,
      availableFrom: inputObj.unlock_at_overridden ? inputObj.unlock_at : null,
      availableUntil: inputObj.lock_at_overridden ? inputObj.lock_at : null,
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
    }

    if (!inputObj.course_section_id && !inputObj.student_ids && !inputObj.noop_id) {
      outputObj.assignedList.push('everyone')
    }

    return outputObj
  }

  const onSync = assigneeInfoUpdateOverrides => {
    const outputArray = []

    assigneeInfoUpdateOverrides.forEach(inputObj => {
      const outputObj = convertToAssignedInfoListObject(inputObj)
      outputArray.push(outputObj)
    })

    // convert overrides to the expected assignedInfoList shape
    // Then Set the assignedInfoList
    setAssignedInfoList(outputArray)
  }

  if (loading) {
    return <LoadingIndicator />
  }

  return (
    <DifferentiatedModulesSection
      onSync={onSync}
      overrides={overrides}
      assignmentId={assignmentID}
      assignmentName={title}
      pointsPossible={pointsPossible}
      type="discussion"
      importantDates={importantDates}
      defaultSectionId={DEFAULT_SECTION_ID}
    />
  )
}

ItemAssignToTrayWrapper.propTypes = {}

ItemAssignToTrayWrapper.defaultProps = {}
