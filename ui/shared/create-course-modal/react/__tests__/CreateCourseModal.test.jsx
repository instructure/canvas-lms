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
import {render, waitFor, act, cleanup} from '@testing-library/react'

import {CreateCourseModal} from '../CreateCourseModal'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

const MANAGEABLE_COURSES = [
  {
    id: '4',
    name: 'CPMS',
  },
  {
    id: '5',
    name: 'CS',
  },
  {
    id: '6',
    name: 'Elementary',
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
const MANAGEABLE_COURSES_URL = '/api/v1/manageable_accounts?per_page=100'
const TEACHER_ENROLLMENTS_URL = encodeURI(
  '/api/v1/users/self/courses?per_page=100&include[]=account&enrollment_type=teacher'
)
const STUDENT_ENROLLMENTS_URL = encodeURI(
  '/api/v1/users/self/courses?per_page=100&include[]=account'
)
const MCC_ACCOUNT_URL = 'api/v1/manually_created_courses_account'

const USER_EVENT_OPTIONS = {pointerEventsCheck: PointerEventsCheckLevel.Never}

describe('CreateCourseModal (1)', () => {
  const setModalOpen = jest.fn()
  let originalEnv

  const getProps = (overrides = {}) => ({
    isModalOpen: true,
    setModalOpen,
    permissions: 'admin',
    restrictToMCCAccount: false,
    isK5User: true,
    ...overrides,
  })

  beforeEach(() => {
    originalEnv = JSON.parse(JSON.stringify(window.ENV))

    // mock requests that are made, but not explicitly tested, to clean up console warnings
    fetchMock.get('/api/v1/users/self/courses?homeroom=true&per_page=100', 200)
    fetchMock.get('begin:/api/v1/accounts/', 200)
    fetchMock.post('begin:/api/v1/accounts/', 200)
  })

  afterEach(() => {
    cleanup()
    window.ENV = originalEnv
    fetchMock.reset()
    fetchMock.restore()
  })

  it('shows a spinner with correct title while loading accounts', async () => {
    fetchMock.get(MANAGEABLE_COURSES_URL, MANAGEABLE_COURSES)
    const {getByText} = render(<CreateCourseModal {...getProps()} />)
    await waitFor(() => expect(getByText('Loading accounts...')).toBeInTheDocument())
  })

  it('shows form fields for account and subject name and homeroom sync after loading accounts', async () => {
    fetchMock.get(MANAGEABLE_COURSES_URL, MANAGEABLE_COURSES)
    const {getByLabelText} = render(<CreateCourseModal {...getProps()} />)
    await waitFor(() => {
      expect(
        getByLabelText('Which account will this subject be associated with?')
      ).toBeInTheDocument()
      expect(getByLabelText('Subject Name')).toBeInTheDocument()
      expect(
        getByLabelText('Sync enrollments and subject start/end dates from homeroom')
      ).toBeInTheDocument()
    })
  })

  it('closes the modal when clicking cancel', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    fetchMock.get(MANAGEABLE_COURSES_URL, MANAGEABLE_COURSES)
    const {getByText, getByRole} = render(<CreateCourseModal {...getProps()} />)
    await waitFor(() => expect(getByRole('button', {name: 'Cancel'})).not.toBeDisabled())
    await user.click(getByText('Cancel'))
    expect(setModalOpen).toHaveBeenCalledWith(false)
  })

  it('disables the create button without a subject name and account', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    fetchMock.get(MANAGEABLE_COURSES_URL, MANAGEABLE_COURSES)
    const {getByText, getByLabelText, getByRole} = render(<CreateCourseModal {...getProps()} />)
    await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
    const createButton = getByRole('button', {name: 'Create'})
    expect(createButton).toBeDisabled()
    await user.type(getByLabelText('Subject Name'), 'New course')
    expect(createButton).toBeDisabled()
    await user.click(getByLabelText('Which account will this subject be associated with?'))
    await user.click(getByText('Elementary'))
    await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
    expect(createButton).not.toBeDisabled()
  })

  it.skip('includes all received accounts in the select, handling pagination correctly', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const accountsPage1 = []
    for (let i = 0; i < 50; i++) {
      accountsPage1.push({
        id: String(i),
        name: String(i),
      })
    }
    const accountsPage2 = [
      {
        id: '51',
        name: '51',
      },
      {
        id: '52',
        name: '52',
      },
    ]
    const response1 = {
      headers: {Link: '</api/v1/manageable_accounts?page=2&per_page=100>; rel="next"'},
      body: accountsPage1,
    }
    fetchMock.mock(MANAGEABLE_COURSES_URL, response1)
    fetchMock.get('/api/v1/manageable_accounts?per_page=100&page=2', accountsPage2)
    const {getByText, getByLabelText} = render(<CreateCourseModal {...getProps()} />)
    await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
    await user.click(getByLabelText('Which account will this subject be associated with?'))
    accountsPage1.forEach(a => {
      expect(getByText(a.name)).toBeInTheDocument()
    })
    accountsPage2.forEach(a => {
      expect(getByText(a.name)).toBeInTheDocument()
    })
  })

  it.skip('creates new subject and enrolls user in that subject', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    fetchMock.get(MANAGEABLE_COURSES_URL, MANAGEABLE_COURSES)
    fetchMock.post(encodeURI('/api/v1/accounts/6/courses?course[name]=Science&enroll_me=true'), {
      id: '14',
    })
    const {getByText, getByLabelText} = render(<CreateCourseModal {...getProps()} />)
    await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
    await user.click(getByLabelText('Which account will this subject be associated with?'))
    await user.click(getByText('Elementary'))
    await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
    await user.type(getByLabelText('Subject Name'), 'Science')
    await user.click(getByText('Create'))
    expect(getByText('Creating new subject...')).toBeInTheDocument()
  })

  it.skip('shows an error message if subject creation fails', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    fetchMock.get(MANAGEABLE_COURSES_URL, MANAGEABLE_COURSES)
    fetchMock.post(encodeURI('/api/v1/accounts/5/courses?course[name]=Math&enroll_me=true'), 500)
    const {getByText, getByLabelText, getAllByText, getByRole} = render(
      <CreateCourseModal {...getProps()} />
    )
    await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
    await user.click(getByLabelText('Which account will this subject be associated with?'))
    await user.click(getByText('CS'))
    await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
    await user.type(getByLabelText('Subject Name'), 'Math')
    await user.click(getByText('Create'))
    await waitFor(() => expect(getAllByText('Error creating new subject')[0]).toBeInTheDocument())
    expect(getByRole('button', {name: 'Cancel'})).not.toBeDisabled()
  })

  describe('with teacher permission', () => {
    it('fetches accounts from enrollments api', async () => {
      fetchMock.get(TEACHER_ENROLLMENTS_URL, ENROLLMENTS)
      const {getByText, getByLabelText} = render(
        <CreateCourseModal {...getProps({permissions: 'teacher'})} />
      )
      await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
      act(() => getByLabelText('Which account will this subject be associated with?').click())
      expect(getByText('Orange Elementary')).toBeInTheDocument()
      expect(getByText('Clark HS')).toBeInTheDocument()
    })

    it('hides the account select if there is only one enrollment', async () => {
      fetchMock.get(TEACHER_ENROLLMENTS_URL, [ENROLLMENTS[0]])
      const {queryByText, getByLabelText} = render(
        <CreateCourseModal {...getProps({permissions: 'teacher'})} />
      )
      await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
      expect(
        queryByText('Which account will this subject be associated with?')
      ).not.toBeInTheDocument()
    })

    it("doesn't break if the user has restricted enrollments", async () => {
      fetchMock.get(TEACHER_ENROLLMENTS_URL, [
        ...ENROLLMENTS,
        {
          id: 1033,
          access_restricted_by_date: true,
        },
      ])
      const {getByLabelText, queryByText, getByText} = render(
        <CreateCourseModal {...getProps({permissions: 'teacher'})} />
      )
      await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
      expect(queryByText('Unable to get accounts')).not.toBeInTheDocument()
      act(() => getByLabelText('Which account will this subject be associated with?').click())
      expect(getByText('Orange Elementary')).toBeInTheDocument()
      expect(getByText('Clark HS')).toBeInTheDocument()
    })

    it('fetches accounts from the manually_created_courses_account api if restrictToMCCAccount is true', async () => {
      fetchMock.get(MCC_ACCOUNT_URL, MCC_ACCOUNT)
      const {getByLabelText, queryByText} = render(
        <CreateCourseModal {...getProps({permissions: 'teacher', restrictToMCCAccount: true})} />
      )
      await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
      expect(
        queryByText('Which account will this subject be associated with?')
      ).not.toBeInTheDocument()
    })
  })

  describe('with student permission', () => {
    beforeEach(() => {
      fetchMock.get(STUDENT_ENROLLMENTS_URL, ENROLLMENTS)
    })

    it('fetches accounts from enrollments api', async () => {
      const {findByLabelText, getByLabelText, getByText} = render(
        <CreateCourseModal {...getProps({permissions: 'student'})} />
      )
      expect(await findByLabelText('Subject Name')).toBeInTheDocument()
      act(() => getByLabelText('Which account will this subject be associated with?').click())
      expect(getByText('Orange Elementary')).toBeInTheDocument()
    })

    it("doesn't show the homeroom sync options", async () => {
      const {findByLabelText, queryByText} = render(
        <CreateCourseModal {...getProps({permissions: 'student'})} />
      )
      expect(await findByLabelText('Subject Name')).toBeInTheDocument()
      expect(
        queryByText('Sync enrollments and subject start/end dates from homeroom')
      ).not.toBeInTheDocument()
      expect(queryByText('Select a homeroom')).not.toBeInTheDocument()
    })

    it('fetches accounts from the manually_created_courses_account api if restrictToMCCAccount is true', async () => {
      fetchMock.get(MCC_ACCOUNT_URL, MCC_ACCOUNT)
      const {getByLabelText, queryByText} = render(
        <CreateCourseModal {...getProps({permissions: 'student', restrictToMCCAccount: true})} />
      )
      await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
      expect(
        queryByText('Which account will this subject be associated with?')
      ).not.toBeInTheDocument()
    })
  })

  describe('with no_enrollments permission', () => {
    beforeEach(() => {
      fetchMock.get(MCC_ACCOUNT_URL, MCC_ACCOUNT)
    })

    it('uses the manually_created_courses_account api to get the right account', async () => {
      const {findByLabelText} = render(
        <CreateCourseModal {...getProps({permissions: 'no_enrollments'})} />
      )
      expect(await findByLabelText('Subject Name')).toBeInTheDocument()
    })

    it("doesn't show the homeroom sync options or account dropdown", async () => {
      const {findByLabelText, queryByText} = render(
        <CreateCourseModal {...getProps({permissions: 'no_enrollments'})} />
      )
      expect(await findByLabelText('Subject Name')).toBeInTheDocument()
      expect(
        queryByText('Sync enrollments and subject start/end dates from homeroom')
      ).not.toBeInTheDocument()
      expect(
        queryByText('Which account will this subject be associated with?')
      ).not.toBeInTheDocument()
    })
  })

  describe('with isK5User set to false', () => {
    beforeEach(() => {
      fetchMock.get(MANAGEABLE_COURSES_URL, MANAGEABLE_COURSES)
    })

    it('does not show the homeroom sync options', async () => {
      const {findByLabelText, queryByText} = render(
        <CreateCourseModal {...getProps({isK5User: false})} />
      )
      expect(await findByLabelText('Course Name')).toBeInTheDocument()
      expect(
        queryByText('Sync enrollments and subject start/end dates from homeroom')
      ).not.toBeInTheDocument()
      expect(queryByText('Select a homeroom')).not.toBeInTheDocument()
    })

    it('uses classic canvas vocabulary', async () => {
      const {findByLabelText, getByLabelText, getByText} = render(
        <CreateCourseModal {...getProps({isK5User: false})} />
      )
      expect(await findByLabelText('Course Name')).toBeInTheDocument()
      expect(getByLabelText('Create Course')).toBeInTheDocument()
      expect(
        getByLabelText('Which account will this course be associated with?')
      ).toBeInTheDocument()
      expect(getByText('Course Details')).toBeInTheDocument()
    })
  })

  describe('with enhanced_course_creation_picker FF ON', () => {
    beforeEach(() => {
      window.ENV.FEATURES.enhanced_course_creation_account_fetching = true
      fetchMock.get(COURSE_CREATION_COURSES_URL, MANAGEABLE_COURSES)
    })

    afterEach(() => {
      window.ENV.FEATURES.enhanced_course_creation_account_fetching = false
      fetchMock.restore()
    })

    it('fetches accounts from enrollments api', async () => {
      render(<CreateCourseModal {...getProps()} />)
      expect(fetchMock.calls()[0][0]).toEqual('/api/v1/course_creation_accounts?per_page=100')
      render(<CreateCourseModal {...getProps({permissions: 'teacher'})} />)
      expect(fetchMock.calls()[0][0]).toEqual('/api/v1/course_creation_accounts?per_page=100')
      render(<CreateCourseModal {...getProps({permissions: 'student'})} />)
      expect(fetchMock.calls()[0][0]).toEqual('/api/v1/course_creation_accounts?per_page=100')
      render(<CreateCourseModal {...getProps({permissions: 'no_enrollments'})} />)
      expect(fetchMock.calls()[0][0]).toEqual('/api/v1/course_creation_accounts?per_page=100')
    })
  })
})
