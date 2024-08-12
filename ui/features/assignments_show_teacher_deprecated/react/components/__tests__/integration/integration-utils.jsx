/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render, waitFor, fireEvent} from '@testing-library/react'
import TeacherQuery from '../../TeacherQuery'
import TeacherView from '../../TeacherView'

import {mockAssignment, initialTeacherViewGQLMocks} from '../../../test-utils'

import CanvasValidatedMockedProvider from '@canvas/validated-apollo-mocked-provider'
import {TEACHER_QUERY} from '../../../assignmentData'

export function renderTeacherQuery(assignment, additionalApolloMocks = []) {
  const mocks = [
    ...initialTeacherViewGQLMocks(assignment.course.lid),
    {
      request: {
        query: TEACHER_QUERY,
        variables: {
          assignmentLid: assignment.lid,
        },
      },
      result: {
        data: {assignment},
      },
    },
    ...additionalApolloMocks,
  ]
  const fns = render(
    <CanvasValidatedMockedProvider mocks={mocks} addTypename={false}>
      <TeacherQuery assignmentLid={assignment.lid} />
    </CanvasValidatedMockedProvider>
  )
  return fns
}

export async function renderTeacherQueryAndWaitForResult(assignment, additionalApolloMocks) {
  const fns = renderTeacherQuery(assignment, additionalApolloMocks)
  await waitFor(() => fns.getAllByText(assignment.name)[0])
  return fns
}

export function renderTeacherView(
  assignment = mockAssignment(),
  additionalApolloMocks = [],
  teacherViewProps = {},
  activeTabName = null
) {
  const mocks = [...initialTeacherViewGQLMocks(assignment.course.lid), ...additionalApolloMocks]
  const fns = render(
    <CanvasValidatedMockedProvider mocks={mocks} addTypename={false}>
      <TeacherView assignment={assignment} {...teacherViewProps} />
    </CanvasValidatedMockedProvider>
  )
  if (activeTabName) {
    fireEvent.click(fns.getAllByText(new RegExp(activeTabName, 'i'))[0])
  }
  return fns
}
