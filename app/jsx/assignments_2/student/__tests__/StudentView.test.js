/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import $ from 'jquery'
import {mockAssignment} from '../test-utils'
import {MockedProvider} from 'react-apollo/test-utils'
import StudentView from '../StudentView'
import {STUDENT_VIEW_QUERY} from '../assignmentData'
import wait from 'waait'

const mocks = [
  {
    request: {
      query: STUDENT_VIEW_QUERY,
      variables: {
        assignmentLid: '7'
      }
    },
    result: {
      data: {
        assignment: mockAssignment()
      }
    }
  }
]

beforeAll(() => {
  const found = document.getElementById('fixtures')
  if (!found) {
    const fixtures = document.createElement('div')
    fixtures.setAttribute('id', 'fixtures')
    document.body.appendChild(fixtures)
  }
})

afterEach(() => {
  ReactDOM.unmountComponentAtNode(document.getElementById('fixtures'))
})

it('renders normally', async () => {
  ReactDOM.render(
    <MockedProvider mocks={mocks} removeTypename addTypename>
      <StudentView assignmentLid="7" />
    </MockedProvider>,
    document.getElementById('fixtures')
  )
  await wait(0) // wait for response
  const element = $('[data-test-id="assignments-2-student-view"]')
  expect(element).toHaveLength(1)
})
