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

import React from 'react'
import fetchMock from 'fetch-mock'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import {render, waitFor, cleanup, fireEvent} from '@testing-library/react'

import {CreateCourseModal} from '../CreateCourseModal'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import fakeENV from '@canvas/test-utils/fakeENV'

injectGlobalAlertContainers()

const MANAGEABLE_COURSES = [
  {
    id: '4',
    name: 'CPMS',
    adminable: true,
  },
  {
    id: '5',
    name: 'CS',
    adminable: false,
  },
  {
    id: '6',
    name: 'Elementary',
    adminable: false,
  },
]

const ENROLLMENTS = [
  {
    id: '72',
    name: 'Algebra Honors',
    account: {
      id: '6',
      name: 'Orange Elementary',
    },
  },
  {
    id: '74',
    name: 'Math',
    account: {
      id: '6',
      name: 'Orange Elementary',
    },
  },
  {
    id: '105',
    name: 'English 11',
    account: {
      id: '13',
      name: 'Clark HS',
    },
  },
]

const MCC_ACCOUNT = {
  id: '3',
  name: 'Manually-Created Courses',
  workflow_state: 'active',
}

const COURSE_CREATION_COURSES_URL = '/api/v1/course_creation_accounts?per_page=100'

const USER_EVENT_OPTIONS = {pointerEventsCheck: PointerEventsCheckLevel.Never}

describe('CreateCourseModal (2)', () => {
  const setModalOpen = jest.fn()

  const getProps = (overrides = {}) => ({
    isModalOpen: true,
    setModalOpen,
    permissions: 'admin',
    restrictToMCCAccount: false,
    isK5User: true,
    ...overrides,
  })

  beforeEach(() => {
    // Set up fakeENV
    fakeENV.setup()

    // mock requests that are made, but not explicitly tested, to clean up console warnings
    fetchMock.get('/api/v1/users/self/courses?homeroom=true&per_page=100', [])
    fetchMock.get('begin:/api/v1/accounts/', [])
    fetchMock.post('begin:/api/v1/accounts/', {id: '123', name: 'New Course'})
  })

  afterEach(() => {
    cleanup()
    // Tear down fakeENV
    fakeENV.teardown()
    fetchMock.reset()
    fetchMock.restore()
  })

  describe('with enhanced_course_creation_picker FF ON', () => {
    beforeEach(() => {
      fakeENV.setup({
        FEATURES: {
          enhanced_course_creation_account_fetching: true,
        },
      })
    })

    afterEach(() => {
      fakeENV.teardown()
      fetchMock.restore()
    })

    it('fetches accounts from enrollments api', async () => {
      fetchMock.get(COURSE_CREATION_COURSES_URL, MANAGEABLE_COURSES)
      render(<CreateCourseModal {...getProps()} />)
      expect(fetchMock.calls()[0][0]).toEqual('/api/v1/course_creation_accounts?per_page=100')
      render(<CreateCourseModal {...getProps({permissions: 'teacher'})} />)
      expect(fetchMock.calls()[0][0]).toEqual('/api/v1/course_creation_accounts?per_page=100')
      render(<CreateCourseModal {...getProps({permissions: 'student'})} />)
      expect(fetchMock.calls()[0][0]).toEqual('/api/v1/course_creation_accounts?per_page=100')
      render(<CreateCourseModal {...getProps({permissions: 'no_enrollments'})} />)
      expect(fetchMock.calls()[0][0]).toEqual('/api/v1/course_creation_accounts?per_page=100')
    })

    it('account selection dropdown is shown', async () => {
      fetchMock.get(COURSE_CREATION_COURSES_URL, ENROLLMENTS)
      const {getByLabelText, queryByText} = render(
        <CreateCourseModal {...getProps({permissions: 'teacher'})} />,
      )
      await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
      expect(queryByText('Which account will this subject be associated with?')).toBeInTheDocument()
    })

    it('account selection dropdown is not shown when only MCC Account', async () => {
      fetchMock.get(COURSE_CREATION_COURSES_URL, MCC_ACCOUNT)
      const {getByLabelText, queryByText} = render(
        <CreateCourseModal {...getProps({permissions: 'teacher'})} />,
      )
      await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
      expect(
        queryByText('Which account will this subject be associated with?'),
      ).not.toBeInTheDocument()
    })

    it('Create button is enabled when Course name is added', async () => {
      fetchMock.get(COURSE_CREATION_COURSES_URL, MCC_ACCOUNT)
      const {getByLabelText, queryByText, getByRole} = render(
        <CreateCourseModal {...getProps({permissions: 'teacher'})} />,
      )
      await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())

      const input = getByLabelText('Subject Name')
      const createButton = getByRole('button', {name: 'Create'})
      expect(createButton).toBeDisabled()
      fireEvent.change(input, {target: {value: 'New Course'}})

      expect(
        queryByText('Which account will this subject be associated with?'),
      ).not.toBeInTheDocument()

      expect(createButton).not.toBeDisabled()
    })

    it('Create button is enabled when Course name is added and account is selected', async () => {
      fetchMock.reset()
      fetchMock.config.overwriteRoutes = true

      fetchMock.get(COURSE_CREATION_COURSES_URL, MANAGEABLE_COURSES)
      fetchMock.get('/api/v1/users/self/courses?homeroom=true&per_page=100', [])
      fetchMock.get('/api/v1/accounts/6/courses?homeroom=true&per_page=100', [])

      const CreateCourseModalWithMockedState = props => {
        const Component = CreateCourseModal
        return <Component {...props} />
      }

      const {getByLabelText, getByRole} = render(
        <CreateCourseModalWithMockedState {...getProps()} />,
      )

      await waitFor(() => {
        expect(getByLabelText('Subject Name')).toBeInTheDocument()
      })

      const createButton = getByRole('button', {name: 'Create'})
      expect(createButton).toBeDisabled()

      fireEvent.change(getByLabelText('Subject Name'), {target: {value: 'New course'}})

      const accountDropdown = getByLabelText('Which account will this subject be associated with?')
      expect(accountDropdown).toBeInTheDocument()

      fireEvent.click(accountDropdown)

      fireEvent.change(accountDropdown, {target: {value: 'Elementary'}})
    })

    it('shows form fields for account and subject name and homeroom sync after loading accounts', async () => {
      fetchMock.get(COURSE_CREATION_COURSES_URL, MANAGEABLE_COURSES)
      const {getByLabelText} = render(<CreateCourseModal {...getProps()} />)
      await waitFor(() => {
        expect(
          getByLabelText('Which account will this subject be associated with?'),
        ).toBeInTheDocument()
        expect(getByLabelText('Subject Name')).toBeInTheDocument()
        expect(
          getByLabelText('Sync enrollments and subject start/end dates from homeroom'),
        ).toBeInTheDocument()
      })
    })

    it('homeroom endpoint is called when user is not administrator of the selected account', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      fetchMock.get(COURSE_CREATION_COURSES_URL, MANAGEABLE_COURSES)
      const {getByText, getByLabelText, getByRole} = render(<CreateCourseModal {...getProps()} />)
      await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
      const createButton = getByRole('button', {name: 'Create'})
      expect(createButton).toBeDisabled()
      await user.type(getByLabelText('Subject Name'), 'New course')
      expect(createButton).toBeDisabled()
      await user.click(getByLabelText('Which account will this subject be associated with?'))
      await user.click(getByText('Elementary'))
      await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
      await user.click(getByLabelText('Sync enrollments and subject start/end dates from homeroom'))
      expect(fetchMock.calls()[1][0]).toEqual(
        '/api/v1/users/self/courses?homeroom=true&per_page=100',
      )
    })

    it('homeroom endpoint is called when user is administrator of the selected account', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      fetchMock.get(COURSE_CREATION_COURSES_URL, MANAGEABLE_COURSES)
      const {getByText, getByLabelText, getByRole} = render(<CreateCourseModal {...getProps()} />)
      await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
      const createButton = getByRole('button', {name: 'Create'})
      expect(createButton).toBeDisabled()
      await user.type(getByLabelText('Subject Name'), 'New course')
      expect(createButton).toBeDisabled()
      await user.click(getByLabelText('Which account will this subject be associated with?'))
      await user.click(getByText('CPMS'))
      await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
      await user.click(getByLabelText('Sync enrollments and subject start/end dates from homeroom'))
      expect(fetchMock.calls()[2][0]).toEqual(
        '/api/v1/accounts/4/courses?homeroom=true&per_page=100',
      )
    })
  })
})
