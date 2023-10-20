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

import {AssigneeOption} from '../react/AssigneeSelector'
import {AssignmentOverridePayload, AssignmentOverridesPayload} from '../react/types'

export const setContainScrollBehavior = (element: HTMLElement | null) => {
  if (element !== null) {
    let parent = element.parentElement
    while (parent) {
      const {overflowY} = window.getComputedStyle(parent)
      if (['scroll', 'auto'].includes(overflowY)) {
        parent.style.overscrollBehaviorY = 'contain'
        return
      }
      parent = parent.parentElement
    }
  }
}

export const generateAssignmentOverridesPayload = (
  selectedAssignees: AssigneeOption[]
): AssignmentOverridesPayload => {
  const studentsOverrideId = selectedAssignees.find(
    assignee => assignee.id.includes('student') && assignee.overrideId
  )?.overrideId
  const sectionOverrides = selectedAssignees
    .filter(assignee => assignee.id.includes('section'))
    ?.map(section => ({
      course_section_id: section.id.split('-')[1],
      id: section.overrideId,
    }))
  const studentIds = selectedAssignees
    .filter(assignee => assignee.id.includes('student'))
    ?.map(({id}) => id.split('-')[1])
  const overrides: AssignmentOverridePayload[] = [...sectionOverrides]
  if (studentIds.length > 0) {
    overrides.push({
      id: studentsOverrideId,
      student_ids: studentIds,
    })
  }

  return {overrides}
}
