/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {cleanup, fireEvent, render, screen, waitFor} from '@testing-library/react'
import {generateModalTitle, TempEnrollModal} from '../TempEnrollModal'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'
import {
  type EnrollmentType,
  ITEMS_PER_PAGE,
  MAX_ALLOWED_COURSES_PER_PAGE,
  PROVIDER,
  RECIPIENT,
  type User,
} from '../types'

// Temporary Enrollment Provider
const providerUser = {
  email: 'provider@instructure.com',
  id: '1',
  name: 'Provider User',
  login_id: 'provider',
  sis_user_id: 'provider_sis',
  user_id: '1',
} as User

// Temporary Enrollment Recipient
const recipientUser = {
  email: 'recipient@instructure.com',
  id: '2',
  login_id: 'recipient',
  name: 'Recipient User',
  sis_user_id: 'recipient_sis',
  user_id: '2',
} as User

const modalProps = {
  enrollmentType: 'provider' as EnrollmentType,
  accountId: '1',
  canReadSIS: true,
  permissions: {
    designer: true,
    observer: true,
    student: true,
    ta: true,
    teacher: true,
  },
  roles: [
    {
      base_role_name: 'TeacherEnrollment',
      id: '234',
      name: 'TeacherEnrollment',
      role: 'TeacherEnrollment',
      label: 'Teacher',
    },
  ],
  user: {
    ...providerUser,
  },
  isEditMode: false,
  onToggleEditMode: jest.fn(),
  tempEnrollPermissions: {
    canAdd: true,
    canDelete: true,
    canEdit: true,
  },
}

const userData = {
  users: [
    {
      ...recipientUser,
    },
  ],
}

const enrollmentsByCourse = [
  {
    id: '1',
    name: 'Apple Music',
    workflow_state: 'available',
    account_id: '1',
    enrollments: [
      {
        role_id: '2',
      },
    ],
    sections: [
      {
        id: '1',
        name: 'Section 1',
        enrollment_role: 'StudentEnrollment',
      },
    ],
  },
]

const ENROLLMENTS_URI = encodeURI(
  `/api/v1/users/${modalProps.user.id}/courses?enrollment_state=active&include[]=sections&per_page=${MAX_ALLOWED_COURSES_PER_PAGE}&account_id=${enrollmentsByCourse[0].account_id}`
)

const userListsData = {
  user_list: '',
  v2: true,
  search_type: 'cc_path',
}
const userListsParams = Object.entries(userListsData)
  .map(([key, value]) => `${key}=${value}`)
  .join('&')

const userDetailsUriMock = (userId: string, response: object) =>
  fetchMock.get(`/api/v1/users/${userId}/profile`, response)

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashSuccess: jest.fn(() => jest.fn(() => {})),
}))

describe('TempEnrollModal', () => {
  beforeAll(() => {
    // @ts-expect-error
    window.ENV = {ACCOUNT_ID: '1'}
  })

  beforeEach(() => {
    localStorage.clear()
    fetchMock.reset()
    jest.clearAllMocks()
  })

  afterEach(() => {
    // unmount the React tree after each test
    cleanup()
  })

  afterAll(() => {
    // @ts-expect-error
    window.ENV = {}
    fetchMock.restore()
  })

  it('displays the modal upon clicking the child element', async () => {
    render(
      <TempEnrollModal {...modalProps}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    expect(screen.queryByText('Find a recipient of Temporary Enrollments')).toBeNull()

    // trigger the modal to open and display the search screen (page 1)
    await userEvent.click(screen.getByText('child_element'))

    expect(screen.getByText('Find a recipient of Temporary Enrollments')).toBeInTheDocument()
  })

  it('opens modal if prop is set to true', async () => {
    render(
      <TempEnrollModal {...modalProps} defaultOpen={true}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    expect(screen.getByText('Find a recipient of Temporary Enrollments')).toBeInTheDocument()
  })

  it.skip('hides the modal upon clicking the cancel button', async () => {
    render(
      <TempEnrollModal {...modalProps} defaultOpen={true}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    expect(screen.getByText('Find a recipient of Temporary Enrollments')).toBeInTheDocument()

    const cancel = await screen.findByRole('button', {name: 'Cancel'})
    await waitFor(() => {
      expect(cancel).not.toBeDisabled()
    })

    await userEvent.click(cancel)

    // wait for the modal to close (including animation)
    await waitFor(() => {
      expect(
        screen.queryByText('Find a recipient of Temporary Enrollments')
      ).not.toBeInTheDocument()
    })
  })

  it('closes modal when submission is successful', async () => {
    fetchMock.post(`/accounts/1/user_lists.json?${userListsParams}`, userData)
    userDetailsUriMock(recipientUser.id, userData.users[0])
    fetchMock.get(ENROLLMENTS_URI, enrollmentsByCourse)

    render(
      <TempEnrollModal {...modalProps} defaultOpen={true}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    const next = await screen.findByRole('button', {name: 'Next'})
    await waitFor(() => {
      expect(next).not.toBeDisabled()
    })

    // click next to go to the search results screen (page 2)
    await userEvent.click(next)
    expect(
      await screen.findByText(/is ready to be assigned temporary enrollments/)
    ).toBeInTheDocument()

    // click next to go to the assign screen (page 3)
    await userEvent.click(next)
    await waitFor(() => {
      expect(screen.queryByText('Back')).toBeInTheDocument()
      expect(screen.queryByText(/is ready to be assigned temporary enrollments/)).toBeNull()
    })

    const submit = await screen.findByRole('button', {name: 'Submit'})
    expect(submit).toBeInTheDocument()
    fireEvent.click(submit)

    expect(fetchMock.calls(`/accounts/1/user_lists.json?${userListsParams}`).length).toBe(1)
    expect(fetchMock.calls('/api/v1/users/2/profile').length).toBe(1)
    expect(fetchMock.calls(ENROLLMENTS_URI).length).toBe(1)
  })

  it('starts over when start over button is clicked', async () => {
    fetchMock.post(`/accounts/1/user_lists.json?${userListsParams}`, userData)
    userDetailsUriMock(recipientUser.id, userData.users[0])

    render(
      <TempEnrollModal {...modalProps} defaultOpen={true}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    const next = await screen.findByRole('button', {name: 'Next'})
    await waitFor(() => {
      expect(next).not.toBeDisabled()
    })

    // click next to go to the search results screen (page 2)
    await userEvent.click(next)
    expect(
      await screen.findByText(/is ready to be assigned temporary enrollments/)
    ).toBeInTheDocument()

    await userEvent.click(await screen.findByRole('button', {name: 'Start Over'}))
    // modal is back on the search screen (page 1)
    await waitFor(() => {
      expect(screen.queryByText('Start Over')).toBeNull()
      expect(screen.queryByText(/is ready to be assigned temporary enrollments/)).toBeNull()
    })

    expect(fetchMock.calls(`/accounts/1/user_lists.json?${userListsParams}`).length).toBe(1)
    expect(fetchMock.calls('/api/v1/users/2/profile').length).toBe(1)
  })

  it('goes back when the assign screen (page 3) back button is clicked', async () => {
    fetchMock.post(`/accounts/1/user_lists.json?${userListsParams}`, userData)
    userDetailsUriMock(recipientUser.id, userData.users[0])
    fetchMock.get(ENROLLMENTS_URI, enrollmentsByCourse)

    render(
      <TempEnrollModal {...modalProps} defaultOpen={true}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    const next = await screen.findByRole('button', {name: 'Next'})
    await waitFor(() => {
      expect(next).not.toBeDisabled()
    })

    // click next to go to the search results screen (page 2)
    await userEvent.click(next)
    expect(
      await screen.findByText(/is ready to be assigned temporary enrollments/)
    ).toBeInTheDocument()

    // click next to go to the assign screen (page 3)
    await userEvent.click(next)
    await waitFor(() => {
      expect(screen.queryByText('Back')).toBeInTheDocument()
      expect(screen.queryByText(/is ready to be assigned temporary enrollments/)).toBeNull()
    })

    await userEvent.click(await screen.findByRole('button', {name: 'Back'}))
    // modal is back on the search results screen (page 2)
    await waitFor(() => {
      expect(screen.queryByText('Back')).toBeNull()
      expect(
        screen.queryByText(/is ready to be assigned temporary enrollments/)
      ).toBeInTheDocument()
    })

    expect(fetchMock.calls(`/accounts/1/user_lists.json?${userListsParams}`).length).toBe(1)
    expect(fetchMock.calls('/api/v1/users/2/profile').length).toBe(1)
    expect(fetchMock.calls(ENROLLMENTS_URI).length).toBe(1)
  })

  it('displays error message when fetch fails in edit mode', async () => {
    const spiedConsoleError = jest.spyOn(console, 'error')
    spiedConsoleError.mockImplementation(() => {})

    fetchMock.get(
      encodeURI(
        `/api/v1/users/${modalProps.user.id}/enrollments?state[]=current_and_future&per_page=${ITEMS_PER_PAGE}&temporary_enrollment_recipients_for_provider=true`
      ),
      {
        status: 500,
        body: {
          errors: [
            {
              message: 'An error occurred.',
              error_code: 'internal_server_error',
            },
          ],
          error_report_id: '1234',
        },
      }
    )

    render(
      <TempEnrollModal {...modalProps} defaultOpen={true} isEditMode={true}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    const errorMessage = await screen.findByText(
      'An unexpected error occurred, please try again later.'
    )
    expect(errorMessage).toBeInTheDocument()

    expect(spiedConsoleError).toHaveBeenCalled()
    spiedConsoleError.mockRestore()
  })

  describe('disabled buttons', () => {
    it('confirms cancel and next buttons are disabled on open', async () => {
      render(
        <TempEnrollModal {...modalProps} defaultOpen={true}>
          <p>child_element</p>
        </TempEnrollModal>
      )
      const cancel = await screen.findByRole('button', {name: 'Cancel'})
      const next = await screen.findByRole('button', {name: 'Next'})
      expect(cancel).toBeDisabled()
      expect(next).toBeDisabled()
    })

    it('confirms cancel and next buttons are disabled on close', async () => {
      render(
        <TempEnrollModal {...modalProps} defaultOpen={true}>
          <p>child_element</p>
        </TempEnrollModal>
      )
      expect(screen.getByText('Find a recipient of Temporary Enrollments')).toBeInTheDocument()
      const cancel = await screen.findByRole('button', {name: 'Cancel'})
      const next = await screen.findByRole('button', {name: 'Next'})
      await waitFor(() => {
        expect(cancel).toBeDisabled()
        expect(next).toBeDisabled()
      })
    })
  })

  describe('generateModalTitle', () => {
    describe('assign page titles (page >= 2)', () => {
      it('should return assign page title for recipient when page >= 2', () => {
        const title = generateModalTitle(recipientUser, RECIPIENT, false, 2, null)
        expect(title).toBe(`Assign temporary enrollments to ${recipientUser.name}`)
      })

      it('should return assign page title with enrollment name when page >= 2 and enrollment is provided', () => {
        const title = generateModalTitle(providerUser, PROVIDER, false, 2, recipientUser)
        expect(title).toBe(`Assign temporary enrollments to ${recipientUser.name}`)
      })

      it('should return a fallback title when page >= 2 and no valid recipient is provided', () => {
        const title = generateModalTitle(providerUser, PROVIDER, false, 2, null)
        expect(title).toBe('Assign temporary enrollments')
      })
    })

    describe('edit mode titles', () => {
      it('should return provider’s recipients title when in edit mode and type is provider', () => {
        const title = generateModalTitle(providerUser, PROVIDER, true, 1, null)
        expect(title).toBe(`Temporary Enrollment Recipients for ${providerUser.name}`)
      })

      it('should return recipient’s providers title when in edit mode and type is recipient', () => {
        const title = generateModalTitle(recipientUser, RECIPIENT, true, 1, null)
        expect(title).toBe(`Temporary Enrollment Providers for ${recipientUser.name}`)
      })
    })

    describe('default title', () => {
      it('should return default title when not in edit mode and page < 2', () => {
        const title = generateModalTitle(providerUser, RECIPIENT, false, 1, null)
        expect(title).toBe('Find a recipient of Temporary Enrollments')
      })
    })
  })
})
