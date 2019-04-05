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
import {render, waitForElement} from 'react-testing-library'
import TeacherQuery from '../../TeacherQuery'
import TeacherView from '../../TeacherView'

import {mockAssignment} from '../../../test-utils'

import CanvasValidatedMockedProvider from 'jsx/__tests__/CanvasValidatedMockedProvider'
import {TEACHER_QUERY} from '../../../assignmentData'

export function renderTeacherQuery(assignment, additionalApolloMocks = []) {
  const mocks = [
    {
      request: {
        query: TEACHER_QUERY,
        variables: {
          assignmentLid: assignment.lid
        }
      },
      result: {
        data: {assignment}
      }
    },
    ...additionalApolloMocks
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
  await waitForElement(() => fns.getByText(assignment.name))
  return fns
}

export function renderTeacherView(
  assignment = mockAssignment(),
  additionalApolloMocks = [],
  teacherViewProps = {}
) {
  const fns = render(
    <CanvasValidatedMockedProvider mocks={additionalApolloMocks} addTypename={false}>
      <TeacherView assignment={assignment} {...teacherViewProps} />
    </CanvasValidatedMockedProvider>
  )
  return fns
}
