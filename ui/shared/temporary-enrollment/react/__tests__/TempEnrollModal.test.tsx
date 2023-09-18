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
import {fireEvent, render, waitFor} from '@testing-library/react'
import {TempEnrollModal} from '../TempEnrollModal'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
// import {prettyDOM} from '@testing-library/dom'

type DateRange = {
  startDate: string
  nextDayDate: string
}

// returns ISO strings for a date and its next day, both at local timezone start
function getLocalStartAndNextDayDates(year: number, month: number, day: number): DateRange {
  const startDate = new Date(year, month, day)
  startDate.setHours(0, 0, 0, 0)

  const nextDayDate = new Date(startDate)
  nextDayDate.setDate(startDate.getDate() + 1)

  return {
    startDate: startDate.toISOString(),
    nextDayDate: nextDayDate.toISOString(),
  }
}
const {startDate, nextDayDate}: DateRange = getLocalStartAndNextDayDates(2022, 0, 1) // for January 1, 2022

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
      label: 'Teacher',
    },
  ],
  user: {
    ...providerUser,
  },
}

const userData = {
  users: [
    {
      ...recipientUser,
    },
  ],
}

// teacher enrollment; checked by default
const enrollmentsData = [
  {
    course_id: '11',
    course_section_id: '111',
    id: '1',
    role_id: '234',
  },
]

const enrollmentStatesData = ['active', 'completed', 'invited']
const enrollmentStatesParams = new URLSearchParams(
  enrollmentStatesData.map(param => ['state[]', param])
).toString()

const enrollmentData = {
  user_id: recipientUser.user_id,
  temporary_enrollment_source_user_id: providerUser.user_id,
  start_at: startDate,
  end_at: nextDayDate,
  role_id: '234',
}
const enrollmentParams = new URLSearchParams(
  Object.entries(enrollmentData).map(([key, value]) => [`enrollment[${key}]`, value])
)

const courseData = {
  name: 'course1',
  workflow_state: 'available',
}

const sectionData = {
  name: 'section1',
}

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
  })

  afterEach(() => {
    fetchMock.reset()
    jest.clearAllMocks()
  })

  afterAll(() => {
    fetchMock.restore()
  })

  it('displays the modal upon clicking the child element', () => {
    // render the modal with a child element
    const screen = render(
      <TempEnrollModal {...modalProps}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    // modal heading should not be displayed initially
    expect(screen.queryByText('Create a temporary enrollment')).toBeNull()

    // trigger the modal to open
    userEvent.click(screen.getByText('child_element'))

    // modal heading should be displayed after the click
    expect(screen.getByText('Create a temporary enrollment')).toBeInTheDocument()
  })

  it('opens modal if prop is set to true', async () => {
    // render the modal with a child element
    const screen = render(
      <TempEnrollModal {...modalProps} defaultOpen={true}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    // modal heading should be displayed
    expect(screen.getByText('Create a temporary enrollment')).toBeInTheDocument()
  })

  it('hides the modal upon clicking the cancel button', async () => {
    // render the modal with a child element
    const screen = render(
      <TempEnrollModal {...modalProps}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    // trigger the modal to open
    userEvent.click(screen.getByText('child_element'))

    // modal heading should be displayed after the click
    expect(screen.getByText('Create a temporary enrollment')).toBeInTheDocument()

    // close the modal
    userEvent.click(await screen.findByText('Cancel'))

    // ensure the modal is closed
    await screen.findByText('Cancel')
    await screen.findByText('Create a temporary enrollment')
  })

  // submit can (almost) only be tested in modal; submit button updates props for TempEnrollAssign
  it.skip('closes modal when submission is successful', async () => {
    // simulating API responses using mocked data to replicate the UI flow
    // without manual data input or interacting with real UI elements
    fetchMock.post(`/accounts/1/user_lists.json?${userListsParams}`, userData)
    fetchMock.get('/api/v1/users/2', userData.users[0])
    fetchMock.get(`/api/v1/users/1/enrollments?${enrollmentStatesParams}`, enrollmentsData)
    fetchMock.get(`/api/v1/courses/11`, courseData)
    fetchMock.get('/api/v1/courses/11/sections/111', sectionData)
    fetchMock.post(`/api/v1/sections/111/enrollments?${enrollmentParams}`, 200)

    // render the modal with a child element
    const screen = render(
      <TempEnrollModal {...modalProps}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    // trigger the modal to open
    userEvent.click(screen.getByText('child_element'))

    // cache the next button
    const next = screen.getByText('Next')

    // click next to go to the search results screen (page 2)
    userEvent.click(next)

    // assertions for search results screen
    expect(
      await screen.findByText(/is ready to be assigned temporary enrollments/)
    ).toBeInTheDocument()

    // click next to go to the assign screen (page 3)
    userEvent.click(next)

    // select a role from the dropdown
    const roleInput = await screen.findByPlaceholderText('Select a Role')
    fireEvent.focus(roleInput)
    fireEvent.click(roleInput)

    const options = await screen.findAllByRole('option')
    const option = options[0] as HTMLOptionElement
    fireEvent.focus(option)
    fireEvent.click(option) // select the first option
    fireEvent.blur(option)

    fireEvent.blur(roleInput)

    // start date and time input
    const startDateInput = await screen.findByLabelText('Begins On')
    userEvent.clear(startDateInput)
    userEvent.type(startDateInput, '2022-01-01') // Jan 01, 2022

    // end date and time input
    const endDateInput = await screen.findByLabelText('Until')
    userEvent.clear(endDateInput)
    userEvent.type(endDateInput, '2022-01-02') // Jan 02, 2022

    // simulate clicking the submit button
    fireEvent.click(await screen.findByText('Submit'.trim()))
    // console.log(prettyDOM(screen.baseElement as Element, 10000000))

    await waitFor(() =>
      expect(showFlashSuccess).toHaveBeenCalledWith(
        'Temporary enrollment was successfully created.'
      )
    )

    // ensure the modal is closed
    await screen.findByText('Cancel')
    await screen.findByText('Create a temporary enrollment')

    // confirm mocks were called the expected number of times
    expect(fetchMock.calls(`/accounts/1/user_lists.json?${userListsParams}`).length).toBe(1)
    expect(fetchMock.calls('/api/v1/users/2').length).toBe(1)
    expect(fetchMock.calls(`/api/v1/users/1/enrollments?${enrollmentStatesParams}`).length).toBe(1)
    expect(fetchMock.calls(`/api/v1/courses/11`).length).toBe(1)
    expect(fetchMock.calls('/api/v1/courses/11/sections/111').length).toBe(1)
    expect(fetchMock.calls(`/api/v1/sections/111/enrollments?${enrollmentParams}`).length).toBe(1)
  })

  it('shows error and stays open if data is missing', async () => {
    // setup API mocks
    fetchMock.post(`/accounts/1/user_lists.json?${userListsParams}`, userData)
    fetchMock.get('/api/v1/users/2', userData.users[0])
    fetchMock.get(`/api/v1/users/1/enrollments?${enrollmentStatesParams}`, enrollmentsData)
    fetchMock.get(`/api/v1/courses/11`, courseData)
    fetchMock.get('/api/v1/courses/11/sections/111', sectionData)
    fetchMock.post(`/api/v1/sections/111/enrollments?${enrollmentParams}`, 200) // NOT CALLED!

    // render the modal with a child element
    const screen = render(
      <TempEnrollModal {...modalProps}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    // trigger the modal to open
    userEvent.click(screen.getByText('child_element'))

    // cache the next button
    const next = screen.getByText('Next')

    // click next to go to the search results screen (page 2)
    userEvent.click(next)

    // assertions for search results screen
    expect(
      await screen.findByText(/is ready to be assigned temporary enrollments/)
    ).toBeInTheDocument()

    // click next to go to the assign screen (page 3)
    userEvent.click(next)

    // NO ROLE SELECTED!

    // simulate clicking the submit button
    fireEvent.click(await screen.findByText('Submit'))

    // error message should be displayed
    await waitFor(() =>
      expect(screen.getByText('Please select a role before submitting')).toBeInTheDocument()
    )

    // confirm mocks were called the expected number of times
    expect(fetchMock.calls(`/accounts/1/user_lists.json?${userListsParams}`).length).toBe(1)
    expect(fetchMock.calls('/api/v1/users/2').length).toBe(1)
    expect(fetchMock.calls(`/api/v1/users/1/enrollments?${enrollmentStatesParams}`).length).toBe(1)
    expect(fetchMock.calls(`/api/v1/courses/11`).length).toBe(1)
    expect(fetchMock.calls('/api/v1/courses/11/sections/111').length).toBe(1)
    expect(fetchMock.calls(`/api/v1/sections/111/enrollments?${enrollmentParams}`).length).toBe(0) // NOT CALLED!
  })

  it('starts over when start over button is clicked', async () => {
    // setup API mocks
    fetchMock.post(`/accounts/1/user_lists.json?${userListsParams}`, userData)
    fetchMock.get('/api/v1/users/2', userData.users[0])

    // render the modal with a child element
    const screen = render(
      <TempEnrollModal {...modalProps}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    // trigger the modal to open
    userEvent.click(screen.getByText('child_element'))

    // cache the next button
    const next = screen.getByText('Next')

    // click next to go to the search results screen (page 2)
    userEvent.click(next)

    // assertions for search results screen
    expect(
      await screen.findByText(/is ready to be assigned temporary enrollments/)
    ).toBeInTheDocument()

    // simulate clicking the start over button
    userEvent.click(await screen.findByText('Start Over'))

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
    fetchMock.get(`/api/v1/users/1/enrollments?${enrollmentStatesParams}`, enrollmentsData)
    fetchMock.get(`/api/v1/courses/11`, courseData)
    fetchMock.get('/api/v1/courses/11/sections/111', sectionData)

    // render the modal with a child element
    const screen = render(
      <TempEnrollModal {...modalProps}>
        <p>child_element</p>
      </TempEnrollModal>
    )

    // trigger the modal to open
    userEvent.click(screen.getByText('child_element'))

    // cache the next button
    const next = screen.getByText('Next')

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
    userEvent.click(await screen.findByText('Back'))

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
    expect(fetchMock.calls(`/api/v1/users/1/enrollments?${enrollmentStatesParams}`).length).toBe(1)
    expect(fetchMock.calls(`/api/v1/courses/11`).length).toBe(1)
    expect(fetchMock.calls('/api/v1/courses/11/sections/111').length).toBe(1)
  })
})
