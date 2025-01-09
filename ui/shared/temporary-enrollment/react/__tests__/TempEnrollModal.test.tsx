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
  type DuplicateUser,
  type EnrollmentType,
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

// Temporary Enrollment Recipient before GET profile
const recipientUser = {
  user_name: 'Recipient User',
  user_id: '2',
  address: 'recipient@instructure.com',
} as DuplicateUser

// Temporary Enrollment Recipient after GET profile
const recipientProfile = {
  email: 'recipient@instructure.com',
  login_id: 'recipient',
  id: '2',
  name: 'Recipient User',
  sis_user_id: 'recipient_sis',
} as User

const modalProps = {
  enrollmentType: 'provider' as EnrollmentType,
  accountId: '1',
  canReadSIS: true,
  rolePermissions: {
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
  modifyPermissions: {
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
  duplicates: [],
  missing: [],
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
  `/api/v1/users/${modalProps.user.id}/courses?enrollment_state=active&include[]=sections&include[]=term&per_page=${MAX_ALLOWED_COURSES_PER_PAGE}&account_id=${enrollmentsByCourse[0].account_id}`,
)

// user_list did not match the encoded url (hence user_list[])
const userListsData = {
  'user_list[]': '1',
  v2: true,
  search_type: 'cc_path',
}
const userListsParams = Object.entries(userListsData)
  .map(([key, value]) => `${key}=${value}`)
  .join('&')

const USER_LIST_URI = encodeURI(`/accounts/1/user_lists.json?${userListsParams}`)

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
      </TempEnrollModal>,
    )

    expect(screen.queryByText('Find recipients of Temporary Enrollments')).toBeNull()

    // trigger the modal to open and display the search screen (page 1)
    await userEvent.click(screen.getByText('child_element'))

    expect(screen.getByText('Find recipients of Temporary Enrollments')).toBeInTheDocument()
  })

  describe('after opening modal', () => {
    beforeEach(async () => {
      fetchMock.post(USER_LIST_URI, userData)
      userDetailsUriMock(recipientUser.user_id, recipientProfile)
      fetchMock.get(ENROLLMENTS_URI, enrollmentsByCourse)
      const {findByTestId} = render(
        <TempEnrollModal {...modalProps}>
          <p>child_element</p>
        </TempEnrollModal>,
      )

      // trigger the modal to open and display the search screen (page 1)
      await userEvent.click(screen.getByText('child_element'))
      const searchArea = await findByTestId('search_area')
      fireEvent.input(searchArea, {target: {value: '1'}})
    })

    it('hides the modal upon clicking the cancel button', async () => {
      expect(screen.queryByText('Find recipients of Temporary Enrollments')).toBeInTheDocument()

      const cancel = await screen.findByRole('button', {name: 'Cancel'})
      await waitFor(() => {
        expect(cancel).toBeEnabled()
      })

      await userEvent.click(cancel)

      // wait for the modal to close (including animation)
      await waitFor(() => {
        expect(
          screen.queryByText('Find recipients of Temporary Enrollments'),
        ).not.toBeInTheDocument()
      })
    })

    it('closes modal when submission is successful', async () => {
      const next = await screen.findByRole('button', {name: 'Next'})
      await waitFor(() => {
        expect(next).toBeEnabled()
      })

      // click next to go to the search results screen (page 2)
      await userEvent.click(next)
      expect(await screen.findByText(/to be assigned temporary enrollments/)).toBeInTheDocument()
      await waitFor(() => {
        expect(next).toBeEnabled()
      })

      // click next to go to the assign screen (page 3)
      await userEvent.click(next)
      await waitFor(() => {
        expect(screen.queryByText('Back')).toBeInTheDocument()
        expect(screen.queryByText(/to be assigned temporary enrollments/)).toBeNull()
      })

      const submit = await screen.findByText('Submit')
      expect(submit).toBeInTheDocument()
      fireEvent.click(submit)

      expect(fetchMock.calls(USER_LIST_URI)).toHaveLength(1)
      expect(fetchMock.calls('/api/v1/users/2/profile')).toHaveLength(1)
      expect(fetchMock.calls(ENROLLMENTS_URI)).toHaveLength(1)
    })

    it('starts over when start over button is clicked', async () => {
      const next = await screen.findByRole('button', {name: 'Next'})
      await waitFor(() => {
        expect(next).toBeEnabled()
      })

      // click next to go to the search results screen (page 2)
      await userEvent.click(next)
      expect(await screen.findByText(/to be assigned temporary enrollments/)).toBeInTheDocument()

      const reset = await screen.findByText('Start Over')
      expect(reset).toBeInTheDocument()
      fireEvent.click(reset)
      // modal is back on the search screen (page 1)
      await waitFor(() => {
        expect(screen.queryByText('Start Over')).toBeNull()
        expect(screen.queryByText(/to be assigned temporary enrollments/)).toBeNull()
      })

      expect(fetchMock.calls(USER_LIST_URI)).toHaveLength(1)
      expect(fetchMock.calls('/api/v1/users/2/profile')).toHaveLength(1)
    })

    it('goes back when the assign screen (page 3) back button is clicked', async () => {
      const next = await screen.findByRole('button', {name: 'Next'})
      await waitFor(() => {
        expect(next).toBeEnabled()
      })

      // click next to go to the search results screen (page 2)
      await userEvent.click(next)
      expect(
        await screen.findByText(/One user is ready to be assigned temporary enrollments/),
      ).toBeInTheDocument()

      // click next to go to the assign screen (page 3)
      await userEvent.click(next)
      await waitFor(() => {
        expect(screen.queryByText(/to be assigned temporary enrollments/)).toBeNull()
      })

      const back = await screen.findByText('Back')
      expect(back).toBeInTheDocument()
      fireEvent.click(back)

      // modal is back on the search results screen (page 2)
      await waitFor(() => {
        expect(screen.queryByText('Back')).toBeNull()
        expect(screen.queryByText(/to be assigned temporary enrollments/)).toBeInTheDocument()
      })

      expect(fetchMock.calls(USER_LIST_URI)).toHaveLength(1)
      expect(fetchMock.calls('/api/v1/users/2/profile')).toHaveLength(1)
      expect(fetchMock.calls(ENROLLMENTS_URI)).toHaveLength(1)
    })

    it('buttons are enabled', async () => {
      const cancel = await screen.findByRole('button', {name: 'Cancel'})
      const next = await screen.findByRole('button', {name: 'Next'})
      await waitFor(() => expect(next).toBeEnabled())
      await waitFor(() => expect(cancel).toBeEnabled())
    })
  })

  describe('generateModalTitle', () => {
    describe('assign page titles (page >= 2)', () => {
      it('should return assign page title for recipient when page >= 2', () => {
        const title = generateModalTitle(recipientProfile, RECIPIENT, false, 2, [])
        expect(title).toBe(`Assign temporary enrollments to ${recipientUser.user_name}`)
      })

      it('should return assign page title with enrollment name when page >= 2 and enrollment is provided', () => {
        const title = generateModalTitle(providerUser, PROVIDER, false, 2, [recipientProfile])
        expect(title).toBe(`Assign temporary enrollments to ${recipientUser.user_name}`)
      })

      it('should return a fallback title when page >= 2 and no valid recipient is provided', () => {
        const title = generateModalTitle(providerUser, PROVIDER, false, 2, [])
        expect(title).toBe('Assign temporary enrollments')
      })
    })

    describe('edit mode titles', () => {
      it('should return provider’s recipients title when in edit mode and type is provider', () => {
        const title = generateModalTitle(providerUser, PROVIDER, true, 1, [])
        expect(title).toBe(`Temporary Enrollment Recipients for ${providerUser.name}`)
      })

      it('should return recipient’s providers title when in edit mode and type is recipient', () => {
        const title = generateModalTitle(recipientProfile, RECIPIENT, true, 1, [])
        expect(title).toBe(`Temporary Enrollment Providers for ${recipientUser.user_name}`)
      })
    })

    describe('default title', () => {
      it('should return default title when not in edit mode and page < 2', () => {
        const title = generateModalTitle(providerUser, RECIPIENT, false, 1, [])
        expect(title).toBe('Find recipients of Temporary Enrollments')
      })
    })
  })
})
