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
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import {render, waitFor, cleanup} from '@testing-library/react'

import {CreateCourseModal} from '../CreateCourseModal'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import fakeENV from '@canvas/test-utils/fakeENV'

injectGlobalAlertContainers()

const server = setupServer()

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

const USER_EVENT_OPTIONS = {pointerEventsCheck: PointerEventsCheckLevel.Never}

describe('CreateCourseModal (1)', () => {
  const setModalOpen = vi.fn()

  const getProps = (overrides = {}) => ({
    isModalOpen: true,
    setModalOpen,
    permissions: 'admin',
    restrictToMCCAccount: false,
    isK5User: true,
    ...overrides,
  })

  beforeAll(() => {
    server.listen({onUnhandledRequest: 'bypass'})
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    fakeENV.setup()
    setModalOpen.mockClear()

    // Default handlers for common requests
    server.use(
      http.get('/api/v1/users/self/courses', ({request}) => {
        const url = new URL(request.url)
        if (url.searchParams.get('homeroom') === 'true') {
          return HttpResponse.json([])
        }
        return HttpResponse.json([])
      }),
      http.get('/api/v1/accounts/:accountId/courses', () => HttpResponse.json([])),
      http.post('/api/v1/accounts/:accountId/courses', () =>
        HttpResponse.json({id: '123', name: 'New Course'}),
      ),
    )
  })

  afterEach(() => {
    cleanup()
    server.resetHandlers()
    fakeENV.teardown()
  })

  it('shows a spinner with correct title while loading accounts', async () => {
    server.use(
      http.get('/api/v1/manageable_accounts', async () => {
        // Delay to ensure we can see the loading state
        await new Promise(resolve => setTimeout(resolve, 50))
        return HttpResponse.json(MANAGEABLE_COURSES)
      }),
    )
    const {getByText} = render(<CreateCourseModal {...getProps()} />)
    await waitFor(() => expect(getByText('Loading accounts...')).toBeInTheDocument())
  })

  it('shows form fields for account and subject name and homeroom sync after loading accounts', async () => {
    server.use(http.get('/api/v1/manageable_accounts', () => HttpResponse.json(MANAGEABLE_COURSES)))
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

  it('closes the modal when clicking cancel', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    server.use(http.get('/api/v1/manageable_accounts', () => HttpResponse.json(MANAGEABLE_COURSES)))
    const {getByText, getByRole} = render(<CreateCourseModal {...getProps()} />)
    await waitFor(() => expect(getByRole('button', {name: 'Cancel'})).not.toBeDisabled())
    await user.click(getByText('Cancel'))
    expect(setModalOpen).toHaveBeenCalledWith(false)
  })

  it('disables the create button without a subject name and account', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    server.use(http.get('/api/v1/manageable_accounts', () => HttpResponse.json(MANAGEABLE_COURSES)))
    const {getByText, getByLabelText, getByRole} = render(<CreateCourseModal {...getProps()} />)
    await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
    const createButton = getByRole('button', {name: 'Create'})
    expect(createButton).toBeDisabled()
    await user.type(getByLabelText('Subject Name'), 'New course')
    expect(createButton).toBeDisabled()
    await user.click(getByLabelText('Which account will this subject be associated with?'))
    await user.click(getByText('Elementary'))
    // Wait for the button to be enabled after account selection completes
    await waitFor(() => expect(createButton).not.toBeDisabled())
  })

  it('includes all received accounts in the select, handling pagination correctly', async () => {
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

    server.use(
      http.get('/api/v1/manageable_accounts', ({request}) => {
        const url = new URL(request.url)
        const page = url.searchParams.get('page')
        if (page === '2') {
          return HttpResponse.json(accountsPage2)
        }
        return HttpResponse.json(accountsPage1, {
          headers: {Link: '</api/v1/manageable_accounts?page=2&per_page=100>; rel="next"'},
        })
      }),
    )

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

  // TODO: Test fails with "Cannot read properties of undefined (reading 'homeroom_course')" error
  it.skip('creates new subject and enrolls user in that subject', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    server.use(http.get('/api/v1/manageable_accounts', () => HttpResponse.json(MANAGEABLE_COURSES)))
    const {getByText, getByLabelText} = render(<CreateCourseModal {...getProps()} />)
    await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
    await user.click(getByLabelText('Which account will this subject be associated with?'))
    await user.click(getByText('Elementary'))
    await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
    await user.type(getByLabelText('Subject Name'), 'Science')
    await user.click(getByText('Create'))
    expect(getByText('Creating new subject...')).toBeInTheDocument()
  })

  it('shows an error message if subject creation fails', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    server.use(
      http.get('/api/v1/manageable_accounts', () => HttpResponse.json(MANAGEABLE_COURSES)),
      http.post('/api/v1/accounts/:accountId/courses', () =>
        HttpResponse.json({error: 'Server error'}, {status: 500}),
      ),
    )
    const {getByText, getByLabelText, getAllByText, getByRole} = render(
      <CreateCourseModal {...getProps()} />,
    )
    await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
    await user.click(getByLabelText('Which account will this subject be associated with?'))
    await user.click(getByText('CS'))
    await user.type(getByLabelText('Subject Name'), 'Math')
    // Wait for the button to be enabled after both account selection and name entry
    await waitFor(() => expect(getByRole('button', {name: 'Create'})).not.toBeDisabled())
    await user.click(getByText('Create'))
    await waitFor(() => expect(getAllByText('Error creating new subject')[0]).toBeInTheDocument())
    expect(getByRole('button', {name: 'Cancel'})).not.toBeDisabled()
  })

  describe('with teacher permission', () => {
    it('fetches accounts from enrollments api', async () => {
      server.use(
        http.get('/api/v1/users/self/courses', ({request}) => {
          const url = new URL(request.url)
          if (url.searchParams.get('enrollment_type') === 'teacher') {
            return HttpResponse.json(ENROLLMENTS)
          }
          if (url.searchParams.get('homeroom') === 'true') {
            return HttpResponse.json([])
          }
          return HttpResponse.json([])
        }),
      )
      const {getByText, getByLabelText} = render(
        <CreateCourseModal {...getProps({permissions: 'teacher'})} />,
      )
      await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
      await getByLabelText('Which account will this subject be associated with?').click()
      expect(getByText('Orange Elementary')).toBeInTheDocument()
      expect(getByText('Clark HS')).toBeInTheDocument()
    })

    it('hides the account select if there is only one enrollment', async () => {
      server.use(
        http.get('/api/v1/users/self/courses', ({request}) => {
          const url = new URL(request.url)
          if (url.searchParams.get('enrollment_type') === 'teacher') {
            return HttpResponse.json([ENROLLMENTS[0]])
          }
          if (url.searchParams.get('homeroom') === 'true') {
            return HttpResponse.json([])
          }
          return HttpResponse.json([])
        }),
      )
      const {queryByText, getByLabelText} = render(
        <CreateCourseModal {...getProps({permissions: 'teacher'})} />,
      )
      await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
      expect(
        queryByText('Which account will this subject be associated with?'),
      ).not.toBeInTheDocument()
    })

    it("doesn't break if the user has restricted enrollments", async () => {
      server.use(
        http.get('/api/v1/users/self/courses', ({request}) => {
          const url = new URL(request.url)
          if (url.searchParams.get('enrollment_type') === 'teacher') {
            return HttpResponse.json([
              ...ENROLLMENTS,
              {
                id: 1033,
                access_restricted_by_date: true,
              },
            ])
          }
          if (url.searchParams.get('homeroom') === 'true') {
            return HttpResponse.json([])
          }
          return HttpResponse.json([])
        }),
      )
      const {getByLabelText, queryByText, getByText} = render(
        <CreateCourseModal {...getProps({permissions: 'teacher'})} />,
      )
      await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
      expect(queryByText('Unable to get accounts')).not.toBeInTheDocument()
      await getByLabelText('Which account will this subject be associated with?').click()
      expect(getByText('Orange Elementary')).toBeInTheDocument()
      expect(getByText('Clark HS')).toBeInTheDocument()
    })

    it('fetches accounts from the manually_created_courses_account api if restrictToMCCAccount is true', async () => {
      server.use(
        http.get('/api/v1/manually_created_courses_account', () => HttpResponse.json(MCC_ACCOUNT)),
      )
      const {getByLabelText, queryByText} = render(
        <CreateCourseModal {...getProps({permissions: 'teacher', restrictToMCCAccount: true})} />,
      )
      await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
      expect(
        queryByText('Which account will this subject be associated with?'),
      ).not.toBeInTheDocument()
    })
  })

  describe('with student permission', () => {
    beforeEach(() => {
      server.use(
        http.get('/api/v1/users/self/courses', ({request}) => {
          const url = new URL(request.url)
          if (url.searchParams.get('homeroom') === 'true') {
            return HttpResponse.json([])
          }
          return HttpResponse.json(ENROLLMENTS)
        }),
      )
    })

    it('fetches accounts from enrollments api', async () => {
      const {findByLabelText, getByLabelText, getByText} = render(
        <CreateCourseModal {...getProps({permissions: 'student'})} />,
      )
      expect(await findByLabelText('Subject Name')).toBeInTheDocument()
      await getByLabelText('Which account will this subject be associated with?').click()
      expect(getByText('Orange Elementary')).toBeInTheDocument()
    })

    it("doesn't show the homeroom sync options", async () => {
      const {findByLabelText, queryByText} = render(
        <CreateCourseModal {...getProps({permissions: 'student'})} />,
      )
      expect(await findByLabelText('Subject Name')).toBeInTheDocument()
      expect(
        queryByText('Sync enrollments and subject start/end dates from homeroom'),
      ).not.toBeInTheDocument()
      expect(queryByText('Select a homeroom')).not.toBeInTheDocument()
    })

    it('fetches accounts from the manually_created_courses_account api if restrictToMCCAccount is true', async () => {
      server.use(
        http.get('/api/v1/manually_created_courses_account', () => HttpResponse.json(MCC_ACCOUNT)),
      )
      const {getByLabelText, queryByText} = render(
        <CreateCourseModal {...getProps({permissions: 'student', restrictToMCCAccount: true})} />,
      )
      await waitFor(() => expect(getByLabelText('Subject Name')).toBeInTheDocument())
      expect(
        queryByText('Which account will this subject be associated with?'),
      ).not.toBeInTheDocument()
    })
  })

  describe('with no_enrollments permission', () => {
    beforeEach(() => {
      server.use(
        http.get('/api/v1/manually_created_courses_account', () => HttpResponse.json(MCC_ACCOUNT)),
      )
    })

    it('uses the manually_created_courses_account api to get the right account', async () => {
      const {findByLabelText} = render(
        <CreateCourseModal {...getProps({permissions: 'no_enrollments'})} />,
      )
      expect(await findByLabelText('Subject Name')).toBeInTheDocument()
    })

    it("doesn't show the homeroom sync options or account dropdown", async () => {
      const {findByLabelText, queryByText} = render(
        <CreateCourseModal {...getProps({permissions: 'no_enrollments'})} />,
      )
      expect(await findByLabelText('Subject Name')).toBeInTheDocument()
      expect(
        queryByText('Sync enrollments and subject start/end dates from homeroom'),
      ).not.toBeInTheDocument()
      expect(
        queryByText('Which account will this subject be associated with?'),
      ).not.toBeInTheDocument()
    })
  })

  describe('with isK5User set to false', () => {
    beforeEach(() => {
      server.use(
        http.get('/api/v1/manageable_accounts', () => HttpResponse.json(MANAGEABLE_COURSES)),
      )
    })

    it('does not show the homeroom sync options', async () => {
      const {findByLabelText, queryByText} = render(
        <CreateCourseModal {...getProps({isK5User: false})} />,
      )
      expect(await findByLabelText('Course Name')).toBeInTheDocument()
      expect(
        queryByText('Sync enrollments and subject start/end dates from homeroom'),
      ).not.toBeInTheDocument()
      expect(queryByText('Select a homeroom')).not.toBeInTheDocument()
    })

    it('uses classic canvas vocabulary', async () => {
      const {findByLabelText, getByLabelText, getByText} = render(
        <CreateCourseModal {...getProps({isK5User: false})} />,
      )
      expect(await findByLabelText('Course Name')).toBeInTheDocument()
      expect(getByLabelText('Create Course')).toBeInTheDocument()
      expect(
        getByLabelText('Which account will this course be associated with?'),
      ).toBeInTheDocument()
      expect(getByText('Course Details')).toBeInTheDocument()
    })
  })
})
