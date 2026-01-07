/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {vi} from 'vitest'
import {TAB_IDS} from '@canvas/k5/react/utils'
import {MOCK_OBSERVED_USERS_LIST} from '@canvas/observer-picker/react/__tests__/fixtures'
import {act, render, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import React from 'react'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {K5Course} from '../K5Course'
import {
  MOCK_GRADING_PERIODS_EMPTY,
  MOCK_ASSIGNMENT_GROUPS_WITH_OBSERVED_USERS,
  MOCK_ENROLLMENTS_WITH_OBSERVED_USERS,
  MOCK_GROUPS,
} from './mocks'
import fakeENV from '@canvas/test-utils/fakeENV'
import {
  defaultProps,
  defaultEnv,
  createModulesPartial,
  setupBasicFetchMocks,
  cleanupModulesContainer,
  observedUserCookieName,
  dateFormatter,
  OBSERVER_GRADING_PERIODS_URL,
  OBSERVER_ASSIGNMENT_GROUPS_URL,
  OBSERVER_ENROLLMENTS_URL,
} from './K5CourseTestHelpers'

vi.mock('@canvas/util/globalUtils', () => ({
  reloadWindow: vi.fn(),
}))

const server = setupServer()

beforeAll(() => {
  server.listen()
})

afterAll(() => {
  server.close()
})

beforeEach(() => {
  setupBasicFetchMocks()
  server.use(
    http.get('/api/v1/courses/30/groups', () => {
      return HttpResponse.json(MOCK_GROUPS)
    }),
  )
  fakeENV.setup(defaultEnv)
  document.body.appendChild(createModulesPartial())
})

afterEach(() => {
  fakeENV.teardown()
  cleanupModulesContainer()
  localStorage.clear()
  fetchMock.restore()
  server.resetHandlers()
  window.location.hash = ''
})

describe('K-5 Subject Course', () => {
  describe('Grades tab', () => {
    it('fetches and displays grade information', async () => {
      const {getByText} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.GRADES} />)
      await waitFor(() => expect(getByText('WWII Report')).toBeInTheDocument())
      ;['Reports', '9.5 pts', 'Out of 10 pts'].forEach(t => {
        expect(getByText(t)).toBeInTheDocument()
      })
      expect(getByText('Submitted', {exact: false})).toBeInTheDocument()
    })

    it('shows course total', async () => {
      const {findByText} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.GRADES} />)
      expect(await findByText('Total: 89.39%')).toBeInTheDocument()
    })

    it('shows tab for LMGB if enabled', () => {
      const {getByRole} = render(
        <K5Course
          {...defaultProps}
          showLearningMasteryGradebook={true}
          defaultTab={TAB_IDS.GRADES}
        />,
      )
      expect(getByRole('tab', {name: 'Learning Mastery'})).toBeInTheDocument()
    })
  })

  describe('Observer Support', () => {
    beforeEach(() => {
      fetchMock.get(OBSERVER_GRADING_PERIODS_URL, MOCK_GRADING_PERIODS_EMPTY)
      fetchMock.get(OBSERVER_ASSIGNMENT_GROUPS_URL, MOCK_ASSIGNMENT_GROUPS_WITH_OBSERVED_USERS)
      fetchMock.get(OBSERVER_ENROLLMENTS_URL, MOCK_ENROLLMENTS_WITH_OBSERVED_USERS)
    })

    afterEach(() => {
      document.cookie = `${observedUserCookieName}=`
    })

    it('shows picker when user is an observer', () => {
      const {getByRole} = render(
        <K5Course {...defaultProps} observedUsersList={MOCK_OBSERVED_USERS_LIST} />,
      )
      const select = getByRole('combobox', {name: 'Select a student to view'})
      expect(select).toBeInTheDocument()
      expect(select.value).toBe('Zelda')
    })

    it('shows the observee grades on the Grades Tab', async () => {
      const {getByRole, getByText} = render(
        <K5Course
          {...defaultProps}
          observedUsersList={MOCK_OBSERVED_USERS_LIST}
          defaultTab={TAB_IDS.GRADES}
        />,
      )
      const formattedSubmittedDate = `Submitted ${dateFormatter('2021-09-20T23:55:08Z')}`
      const select = getByRole('combobox', {name: 'Select a student to view'})
      act(() => select.click())
      act(() => getByText('Student 5').click())
      await waitFor(() => {
        ;['Assignment 3', formattedSubmittedDate, 'Assignments', '6 pts', 'Out of 10 pts'].forEach(
          label => {
            expect(getByText(label)).toBeInTheDocument()
          },
        )
      })
    })
  })
})
