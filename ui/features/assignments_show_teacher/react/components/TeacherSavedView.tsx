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
import type {TeacherAssignmentType} from '@canvas/assignments/graphql/teacher/AssignmentTeacherTypes'
import AssignmentHeader from '@canvas/assignments/react/AssignmentHeader'
import WithBreakpoints, {type Breakpoints} from '@canvas/with-breakpoints'
import {ASSIGNMENT_VIEW_TYPES} from '@canvas/assignments/react/AssignmentTypes'
import {queryClient} from '@canvas/query'
import {QueryClientProvider} from '@tanstack/react-query'

interface TeacherViewProps {
  assignment: TeacherAssignmentType
  breakpoints?: Breakpoints
}

const TeacherSavedView: React.FC<TeacherViewProps> = ({assignment, breakpoints = {}}) => {
  return (
    <QueryClientProvider client={queryClient}>
      <AssignmentHeader
        type={ASSIGNMENT_VIEW_TYPES.SAVED}
        assignment={assignment}
        breakpoints={breakpoints}
      />
    </QueryClientProvider>
  )
}

export default WithBreakpoints(TeacherSavedView)
