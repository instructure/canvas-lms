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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {Provider} from 'react-redux'
import fakeENV from '@canvas/test-utils/fakeENV'

import Header from '../Header'
import configureStore from '../../configureStore'

describe('GradeSummary Header "Post to Students" button', () => {
  let store
  let storeEnv

  beforeEach(() => {
    fakeENV.setup({
      GRADERS: [
        {
          grader_name: 'Charlie Xi',
          id: '4502',
          user_id: '1103',
          grader_selectable: true,
          graderId: '4502',
        },
      ],
    })

    storeEnv = {
      assignment: {
        courseId: '1201',
        gradesPublished: true,
        id: '2301',
        muted: true,
        title: 'Example Assignment',
      },
      currentUser: {
        graderId: 'teach',
        id: '1105',
      },
      graders: [
        {
          grader_name: 'Charlie Xi',
          id: '4502',
          user_id: '1103',
          grader_selectable: true,
          graderId: '4502',
        },
      ],
    }

    window.confirm = jest.fn(() => true)

    jest.mock('../../assignment/AssignmentActions', () => ({
      releaseGrades: jest.fn().mockImplementation(() => ({
        type: 'SET_RELEASE_GRADES_STATUS',
        payload: {status: 'STARTED'},
      })),
      setReleaseGradesStatus: jest.fn(),
      setUnmuteAssignmentStatus: jest.fn(),
      unmuteAssignment: jest.fn().mockImplementation(() => ({
        type: 'SET_UNMUTE_ASSIGNMENT_STATUS',
        payload: {status: 'STARTED'},
      })),
      STARTED: 'STARTED',
      SUCCESS: 'SUCCESS',
      FAILURE: 'FAILURE',
    }))
  })

  afterEach(() => {
    jest.resetAllMocks()
    fakeENV.teardown()
    document.body.innerHTML = ''
  })

  function mountComponent() {
    store = configureStore(storeEnv)
    render(
      <Provider store={store}>
        <Header />
      </Provider>,
    )
  }

  it('displays a confirmation dialog when clicked', async () => {
    const user = userEvent.setup({delay: null})
    mountComponent()
    await user.click(screen.getByRole('button', {name: /post to students/i}))
    await waitFor(() => {
      expect(window.confirm).toHaveBeenCalledTimes(1)
    })
  })
})
