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
import TeacherView from '../../TeacherView'

// api module should be mocked by the test file
import {queryAssignment} from '../../../api'
import {mockAssignment} from '../../../test-utils'

export async function renderTeacherView(assignment = mockAssignment()) {
  queryAssignment.mockReturnValueOnce({data: {assignment}})
  const result = render(<TeacherView assignmentLid={assignment.lid} />)
  // wait for the queryAssignment promise to resolve and the view to render in response
  await waitForElement(() => result.getByText(assignment.name))
  return result
}
