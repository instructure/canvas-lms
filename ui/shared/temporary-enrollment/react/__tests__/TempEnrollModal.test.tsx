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
import {TempEnrollModal} from '../TempEnrollModal'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'
import {EnrollmentType} from '@canvas/temporary-enrollment/react/types'

// Temporary Enrollment Provider
const providerUser = {
  email: 'provider@instructure.com',
  id: '1',
  name: 'Provider User',
  login_id: 'provider',
  sis_user_id: 'provider_sis',
  user_id: '1',
}

// Temporary Enrollment Recipient
const recipientUser = {
  email: 'recipient@instructure.com',
  id: '2',
  login_id: 'recipient',
  name: 'Recipient User',
  sis_user_id: 'recipient_sis',
  user_id: '2',
}

const modalProps = {
  title: 'Create a temporary enrollment',
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
  `/api/v1/users/${modalProps.user.id}/courses?enrollment_state=active&include[]=sections`
)

const userListsData = {
  user_list: '',
  v2: true,
  search_type: 'cc_path',
}
const userListsParams = Object.entries(userListsData)
  .map(([key, value]) => `${key}=${value}`)
  .join('&')

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashSuccess: jest.fn(() => jest.fn(() => {})),
}))

describe('TempEnrollModal', () => {
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
    fetchMock.restore()
  })

  it('displays the modal upon clicking the child element', () => {
    // render the modal with a child element
    render(
      <TempEnrollModal {...modalProps}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    // modal heading should not be displayed initially
    expect(screen.queryByText('Create a temporary enrollment')).toBeNull()

    // trigger the modal to open and display the search screen (page 1)
    userEvent.click(screen.getByText('child_element'))

    // modal heading should be displayed after the click
    expect(screen.getByText('Create a temporary enrollment')).toBeInTheDocument()
  })

  it('opens modal if prop is set to true', async () => {
    // render the modal with a child element
    render(
      <TempEnrollModal {...modalProps} defaultOpen={true}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    // modal heading should be displayed
    expect(screen.getByText('Create a temporary enrollment')).toBeInTheDocument()
  })

  it('hides the modal upon clicking the cancel button', async () => {
    // render the modal with a child element
    render(
      <TempEnrollModal {...modalProps} defaultOpen={true}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    // modal heading should be displayed after the click
    expect(screen.getByText('Create a temporary enrollment')).toBeInTheDocument()

    // close the modal
    userEvent.click(await screen.findByRole('button', {name: 'Cancel'}))

    // wait for the modal to close (including animation)
    await waitFor(() => {
      expect(screen.queryByText('Create a temporary enrollment')).not.toBeInTheDocument()
    })
  })

  // submit can (almost) only be tested in modal; submit button updates props for TempEnrollAssign
  it('closes modal when submission is successful', async () => {
    // simulating API responses using mocked data to replicate the UI flow
    // without manual data input or interacting with real UI elements
    fetchMock.post(`/accounts/1/user_lists.json?${userListsParams}`, userData)
    fetchMock.get('/api/v1/users/2', userData.users[0])
    fetchMock.get(ENROLLMENTS_URI, enrollmentsByCourse)

    // render the modal with a child element
    render(
      <TempEnrollModal {...modalProps} defaultOpen={true}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    // cache the next button
    const next = await screen.findByRole('button', {name: 'Next'})

    // click next to go to the search results screen (page 2)
    userEvent.click(next)

    // assertions for search results screen
    expect(
      await screen.findByText(/is ready to be assigned temporary enrollments/)
    ).toBeInTheDocument()

    // click next to go to the assign screen (page 3)
    userEvent.click(next)

    // confirm the modal is on the assign screen (page 3)
    await waitFor(() => {
      expect(screen.queryByText('Back')).toBeInTheDocument()
      expect(screen.queryByText(/is ready to be assigned temporary enrollments/)).toBeNull()
    })

    // select a role
    const role = screen.getByLabelText(/select role/i)
    userEvent.click(role)
    await waitFor(() => {
      const option = document.getElementById('234')
      if (!option) throw new Error('Option not yet available')
    })
    const option = document.getElementById('234')
    userEvent.click(option!)

    // simulate clicking the submit button
    const submit = await screen.findByRole('button', {name: 'Submit'})
    expect(submit).toBeInTheDocument()
    fireEvent.click(submit)

    // ensure the modal is closed
    await waitFor(() => {
      expect(screen.queryByText('Create a temporary enrollment')).toBeNull()
    })

    // confirm mocks were called the expected number of times
    expect(fetchMock.calls(`/accounts/1/user_lists.json?${userListsParams}`).length).toBe(1)
    expect(fetchMock.calls('/api/v1/users/2').length).toBe(1)
    expect(fetchMock.calls(ENROLLMENTS_URI).length).toBe(1)
  })

  it('shows error and stays open if data is missing', async () => {
    // setup API mocks
    fetchMock.post(`/accounts/1/user_lists.json?${userListsParams}`, userData)
    fetchMock.get('/api/v1/users/2', userData.users[0])
    fetchMock.get(ENROLLMENTS_URI, enrollmentsByCourse)

    // render the modal with a child element
    render(
      <TempEnrollModal {...modalProps} defaultOpen={true}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    // cache the next button
    const next = await screen.findByRole('button', {name: 'Next'})

    // click next to go to the search results screen (page 2)
    userEvent.click(next)

    // assertions for search results screen
    expect(
      await screen.findByText(/is ready to be assigned temporary enrollments/)
    ).toBeInTheDocument()

    // click next to go to the assign screen (page 3)
    userEvent.click(next)

    //
    // NO PROVIDER BASE ROLE SELECTED!
    //

    // confirm the modal is on the assign screen (page 3)
    await waitFor(() => {
      expect(screen.queryByText('Back')).toBeInTheDocument()
      expect(screen.queryByText(/is ready to be assigned temporary enrollments/)).toBeNull()
    })

    userEvent.click(await screen.findByRole('button', {name: 'Submit'}))

    expect(await screen.findByText(/please select a role before submitting/i)).toBeInTheDocument()

    // confirm mocks were called the expected number of times
    expect(fetchMock.calls(`/accounts/1/user_lists.json?${userListsParams}`).length).toBe(1)
    expect(fetchMock.calls('/api/v1/users/2').length).toBe(1)
    expect(fetchMock.calls(ENROLLMENTS_URI).length).toBe(1)
  })

  it('starts over when start over button is clicked', async () => {
    // setup API mocks
    fetchMock.post(`/accounts/1/user_lists.json?${userListsParams}`, userData)
    fetchMock.get('/api/v1/users/2', userData.users[0])

    // render the modal with a child element
    render(
      <TempEnrollModal {...modalProps} defaultOpen={true}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    // cache the next button
    const next = await screen.findByRole('button', {name: 'Next'})

    // click next to go to the search results screen (page 2)
    userEvent.click(next)

    // assertions for search results screen
    expect(
      await screen.findByText(/is ready to be assigned temporary enrollments/)
    ).toBeInTheDocument()

    // simulate clicking the start over button
    userEvent.click(await screen.findByRole('button', {name: 'Start Over'}))

    // modal is back on the search screen (page 1)
    await waitFor(() => {
      expect(screen.queryByText('Start Over')).toBeNull()
      expect(screen.queryByText(/is ready to be assigned temporary enrollments/)).toBeNull()
    })

    // confirm mocks were called the expected number of times
    expect(fetchMock.calls(`/accounts/1/user_lists.json?${userListsParams}`).length).toBe(1)
    expect(fetchMock.calls('/api/v1/users/2').length).toBe(1)
  })

  it('goes back when the assign screen (page 3) back button is clicked', async () => {
    // setup API mocks
    fetchMock.post(`/accounts/1/user_lists.json?${userListsParams}`, userData)
    fetchMock.get('/api/v1/users/2', userData.users[0])
    fetchMock.get(ENROLLMENTS_URI, enrollmentsByCourse)

    // render the modal with a child element
    render(
      <TempEnrollModal {...modalProps} defaultOpen={true}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    // cache the next button
    const next = await screen.findByRole('button', {name: 'Next'})

    // click next to go to the search results screen (page 2)
    userEvent.click(next)

    // assertions for search results screen
    expect(
      await screen.findByText(/is ready to be assigned temporary enrollments/)
    ).toBeInTheDocument()

    // click next to go to the assign screen (page 3)
    userEvent.click(next)

    // confirm the modal is on the assign screen (page 3)
    await waitFor(() => {
      expect(screen.queryByText('Back')).toBeInTheDocument()
      expect(screen.queryByText(/is ready to be assigned temporary enrollments/)).toBeNull()
    })

    // simulate clicking the back button
    userEvent.click(await screen.findByRole('button', {name: 'Back'}))

    // modal is back on the search results screen (page 2)
    await waitFor(() => {
      expect(screen.queryByText('Back')).toBeNull()
      expect(
        screen.queryByText(/is ready to be assigned temporary enrollments/)
      ).toBeInTheDocument()
    })

    // confirm mocks were called the expected number of times
    expect(fetchMock.calls(`/accounts/1/user_lists.json?${userListsParams}`).length).toBe(1)
    expect(fetchMock.calls('/api/v1/users/2').length).toBe(1)
    expect(fetchMock.calls(ENROLLMENTS_URI).length).toBe(1)
  })
})
