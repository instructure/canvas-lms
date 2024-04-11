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
  const {assignedInfoList, title, assignmentID, importantDates, pointsPossible} = useContext(
    GradedDiscussionDueDatesContext
  )

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
  const onSync = overrides => {
    // convert overrides to the expected assignedInfoList shape
    // Then Set the assignedInfoList
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
