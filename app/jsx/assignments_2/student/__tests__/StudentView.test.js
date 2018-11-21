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
import {MockedProvider} from 'react-apollo/test-utils'
import StudentView, {STUDENT_VIEW_QUERY} from '../StudentView'
import wait from 'waait'

const mocks = [
  {
    request: {
      query: STUDENT_VIEW_QUERY,
      variables: {
        assignmentLid: '40'
      }
    },
    result: {
      data: {
        assignment: {
          lid: '40',
          gid: 'QXNzaWdubWVudC00MA==',
          name: 'is this still workin',
          description: '<p>sadflkajsdfklajsdfasdf</p>',
          dueAt: '2018-07-11T18:59:59-06:00',
          pointsPossible: 0,
          assignmentGroup: {name: 'Assignments', __typename: 'AssignmentGroup'},
          __typename: 'Assignment'
        }
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
  global.ENV = {}
  global.ENV.context_asset_string = 'course_1'
})

afterEach(() => {
  global.ENV = null
  ReactDOM.unmountComponentAtNode(document.getElementById('fixtures'))
})

jest.mock('timezone')

it('renders normally', async () => {
  ReactDOM.render(
    <MockedProvider mocks={mocks} removeTypename addTypename>
      <StudentView assignmentLid="40" />
    </MockedProvider>,
    document.getElementById('fixtures')
  )
  await wait(0) // wait for response
  const element = $('[data-test-id="assignments-2-student-view"]')
  expect(element).toHaveLength(1)
})
