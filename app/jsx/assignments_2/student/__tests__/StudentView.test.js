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
import {mockAssignment} from '../test-utils'
import {MockedProvider} from 'react-apollo/test-utils'
import StudentView from '../StudentView'
import {GetAssignmentEnvVariables, STUDENT_VIEW_QUERY} from '../assignmentData'
import {render, waitForElement} from 'react-testing-library'

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

describe('StudentView', () => {
  it('renders normally', async () => {
    const {getByTestId} = render(
      <MockedProvider mocks={mocks} removeTypename addTypename>
        <StudentView assignmentLid="7" />
      </MockedProvider>
    )
    expect(
      await waitForElement(() => getByTestId('assignments-2-student-view'))
    ).toBeInTheDocument()
  })

  it('renders default env correctly', async () => {
    const defaultEnv = GetAssignmentEnvVariables()

    expect(defaultEnv).toEqual({
      assignmentUrl: '',
      currentUserId: null,
      modulePrereq: null,
      moduleUrl: ''
    })
  })

  it('renders with env params set', async () => {
    window.ENV = {
      context_asset_string: 'test_1',
      current_user_id: '1',
      PREREQS: {}
    }

    const env = GetAssignmentEnvVariables()

    expect(env).toEqual({
      assignmentUrl: 'http://localhost/tests/1/assignments',
      currentUserId: '1',
      modulePrereq: null,
      moduleUrl: 'http://localhost/tests/1/modules'
    })
  })

  it('renders loading', async () => {
    const {getByTitle} = render(
      <MockedProvider mocks={mocks} removeTypename addTypename>
        <StudentView assignmentLid="7" />
      </MockedProvider>
    )

    expect(getByTitle('Loading')).toBeInTheDocument()
  })
})

it('renders error', async () => {
  const errorMock = [
    {
      request: {
        query: STUDENT_VIEW_QUERY,
        variables: {
          assignmentLid: '7'
        }
      },
      error: new Error('aw shucks')
    }
  ]
  const {getByText} = render(
    <MockedProvider mocks={errorMock} removeTypename addTypename>
      <StudentView assignmentLid="7" />
    </MockedProvider>
  )

  expect(await waitForElement(() => getByText('Something broke unexpectedly.'))).toBeInTheDocument()
})
