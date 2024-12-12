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
import AssignmentHeader from '@canvas/assignments/react/AssignmentHeader'
import WithBreakpoints, {type Breakpoints} from '@canvas/with-breakpoints/src'
import type {TeacherAssignmentType} from '@canvas/assignments/graphql/teacher/AssignmentTeacherTypes'
import {ASSIGNMENT_VIEW_TYPES} from '@canvas/assignments/react/AssignmentTypes'

interface TeacherCreateEditViewProps {
  edit: boolean
  assignment: TeacherAssignmentType
  breakpoints?: Breakpoints
}

const TeacherCreateEditView: React.FC<TeacherCreateEditViewProps> = ({
  edit,
  assignment,
  breakpoints = {},
}) => {
  return (
    <AssignmentHeader
      type={edit ? ASSIGNMENT_VIEW_TYPES.EDIT : ASSIGNMENT_VIEW_TYPES.CREATE}
      assignment={assignment}
      breakpoints={breakpoints}
    />
  )
}

export default WithBreakpoints(TeacherCreateEditView)
