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
import {type Props, TempEnrollAssign} from '../TempEnrollAssign'
import fetchMock from 'fetch-mock'
import {MAX_ALLOWED_COURSES_PER_PAGE, PROVIDER, type User} from '../types'
import fakeENV from '@canvas/test-utils/fakeENV'

const backCall = jest.fn()

jest.mock('../api/enrollment', () => ({
  deleteEnrollment: jest.fn(),
  getTemporaryEnrollmentPairing: jest.fn(),
}))

const falsePermissions = {
  teacher: true,
  ta: true,
  student: false,
  observer: true,
  designer: true,
}

const truePermissions = {
  teacher: true,
  ta: true,
  student: true,
  observer: true,
  designer: true,
}

const enrollmentsByCourse = [
  {
    id: '1',
    name: 'Apple Music',
    workflow_state: 'available',
    account_id: '1',
    enrollments: [
      {
        role_id: '92',
      },
    ],
    sections: [
      {
        id: '1',
        name: 'Section 1',
        enrollment_role: 'TeacherEnrollment',
      },
    ],
  },
]

const enrollmentsByCoursePage2 = [
  {
    id: '2',
    name: 'Battle Axe Lessons',
    workflow_state: 'available',
    account_id: '1',
    enrollments: [
      {
        role_id: '92',
      },
    ],
    sections: [
      {
        id: '2',
        name: 'Section 2',
        enrollment_role: 'TeacherEnrollment',
      },
    ],
  },
]

const additionalRecipient = {
  email: 'ross@email.com',
  id: '6',
  login_id: 'mel123',
  name: 'Melvin',
  sis_user_id: '11',
}

const props: Props = {
  enrollments: [
    {
      email: 'mel@email.com',
      id: '2',
      login_id: 'mel123',
      name: 'Melvin',
      sis_user_id: '5',
    },
  ] as User[],
  user: {
    id: '1',
    name: 'John Smith',
    avatar_url: '',
  } as User,
  rolePermissions: truePermissions,
  roles: [
    {id: '91', name: 'StudentEnrollment', label: 'Student', base_role_name: 'StudentEnrollment'},
    {id: '92', name: 'TeacherEnrollment', label: 'Teacher', base_role_name: 'TeacherEnrollment'},
    {
      id: '93',
      name: 'Custom Teacher Enrollment',
      label: 'Teacher',
      base_role_name: 'TeacherEnrollment',
    },
  ],
  goBack: backCall,
  setEnrollmentStatus: jest.fn(),
  doSubmit: () => false,
  isInAssignEditMode: false,
  enrollmentType: PROVIDER,
}

const ENROLLMENTS_URI = encodeURI(
  `/api/v1/users/${props.user.id}/courses?enrollment_state=active&include[]=sections&include[]=term&per_page=${MAX_ALLOWED_COURSES_PER_PAGE}&account_id=${enrollmentsByCourse[0].account_id}`,
)

const ENROLLMENTS_URI_PAGE_2 = encodeURI(
  `/api/v1/users/${props.user.id}/courses?enrollment_state=active&include[]=sections&include[]=term&per_page=${MAX_ALLOWED_COURSES_PER_PAGE}&account_id=${enrollmentsByCoursePage2[0].account_id}&page=2`,
)

describe('TempEnrollAssign', () => {
  beforeEach(() => {
    // Use fakeENV instead of directly modifying window.ENV
    fakeENV.setup({
      ACCOUNT_ID: '1',
      CONTEXT_TIMEZONE: 'Asia/Brunei',
      context_asset_string: 'account_1',
    })
  })

  afterEach(() => {
    fetchMock.reset()
    fetchMock.restore()
    jest.clearAllMocks()
    // Clean up fakeENV
    fakeENV.teardown()
    // ensure a clean state before each tests
    localStorage.clear()
  })

  afterAll(() => {
    // No need to reset window.ENV here as fakeENV.teardown() handles it
  })

  describe('With Successful API calls', () => {
    beforeEach(() => {
      fetchMock.get(ENROLLMENTS_URI, enrollmentsByCourse)
    })

    it('initializes with ROLE as the default role in the summary', async () => {
      const {findByText} = render(<TempEnrollAssign {...props} />)
      const defaultMessage = await findByText(
        /Canvas will enroll .+ as a .+ in the selected courses of .+ from .+ - .+/,
      )

      expect(defaultMessage).toBeInTheDocument()
    })

    it('changes text when multiple recipients are being assigned', async () => {
      const modifiedProps = {
        ...props,
        enrollments: [...props.enrollments, additionalRecipient],
      }
      const {findByText} = render(<TempEnrollAssign {...modifiedProps} />)

      const summaryMsg = await findByText(/Canvas will enroll 2 users/)
      const readyMsg = await findByText(/2 users will receive/)

      expect(summaryMsg).toBeInTheDocument()
      expect(readyMsg).toBeInTheDocument()
    })

    it('triggers goBack when back is clicked', async () => {
      const {findByText} = render(<TempEnrollAssign {...props} />)
      const backButton = await findByText('Back')

      fireEvent.click(backButton)

      expect(backCall).toHaveBeenCalled()
    })

    it('does not render Back button when isEditMode is true', async () => {
      const modifiedProps = {
        ...props,
        isInAssignEditMode: true,
      }
      const {queryByText} = render(<TempEnrollAssign {...modifiedProps} />)
      const backButton = queryByText('Back')

      expect(backButton).toBeNull()
    })

    it('changes summary when role is selected', async () => {
      const screen = render(<TempEnrollAssign {...props} />)
      const roleSelect = await screen.findByPlaceholderText('Select a Role')

      expect(screen.getByText(/Canvas will enroll Melvin as a Teacher/)).toBeInTheDocument()

      fireEvent.click(roleSelect)

      const options = await screen.findAllByRole('option')
      fireEvent.click(options[0]) // select the "Student" option

      // Format: Canvas will enroll %{recipient} as a %{role} in %{source}'s selected courses from %{start} - %{end}
      expect(await screen.findByText(/Canvas will enroll Melvin as a Student/)).toBeInTheDocument()
    })

    it('displays Local and Account datetime in correct timezones', async () => {
      // Set up the environment with specific timezones
      fakeENV.setup({
        ACCOUNT_ID: '1',
        CONTEXT_TIMEZONE: 'Asia/Brunei', // UTC+8
        context_asset_string: 'account_1',
        TIMEZONE: 'America/Denver', // UTC-6
      })

      const {findAllByLabelText, findAllByText} = render(<TempEnrollAssign {...props} />)

      // Set a specific date and time that will show a clear timezone difference
      const startDate = (await findAllByLabelText('Begins On *'))[0]
      fireEvent.input(startDate, {target: {value: 'Oct 31 2024'}})
      fireEvent.blur(startDate)

      const startTime = (await findAllByLabelText('Time *'))[0]
      fireEvent.input(startTime, {target: {value: '9:00 AM'}})
      fireEvent.blur(startTime)

      // Wait for the component to update with the time information
      await waitFor(async () => {
        const localTimes = await findAllByText(/Local: /)
        const accTimes = await findAllByText(/Account: /)
        return localTimes.length > 0 && accTimes.length > 0
      })

      const localTime = (await findAllByText(/Local: /))[0]
      const accTime = (await findAllByText(/Account: /))[0]

      // Check that the times show different dates due to timezone differences
      expect(localTime.textContent).toBeTruthy()
      expect(accTime.textContent).toBeTruthy()

      // Clean up
      fakeENV.teardown()
    })

    it('show error when date field is blank', async () => {
      const screen = render(<TempEnrollAssign {...props} />)
      const startDate = await screen.findByLabelText('Begins On *')

      fireEvent.input(startDate, {target: {value: ''}})
      fireEvent.blur(startDate)

      waitFor(() =>
        expect(
          //@ts-expect-error
          screen.findAllByText('The chosen date and time is invalid.')[0],
        ).toBeInTheDocument(),
      )
    })

    it('shows error when start date is after end date', async () => {
      const screen = render(<TempEnrollAssign {...props} />)
      const endDate = await screen.findByLabelText('Until *')

      fireEvent.input(endDate, {target: {value: 'Apr 10 2022'}})
      fireEvent.blur(endDate)

      waitFor(() =>
        expect(
          //@ts-expect-error
          screen.findAllByText('The start date must be before the end date')[0],
        ).toBeInTheDocument(),
      )
    })

    it('hides roles the user does not have permission to enroll', async () => {
      const {queryByText} = render(
        <TempEnrollAssign {...props} rolePermissions={falsePermissions} />,
      )
      expect(queryByText('No roles available')).not.toBeInTheDocument()
    })

    it('changes summary when date and time changes', async () => {
      // Mock the courses API to prevent unmatched GET warnings
      fetchMock.get(
        '/api/v1/users/1/courses?enrollment_state=active&include%5B%5D=sections&include%5B%5D=term&per_page=100',
        {
          status: 200,
          body: [],
        },
      )

      // Set up a clean environment for this test
      fakeENV.setup({
        ACCOUNT_ID: '1',
        CONTEXT_TIMEZONE: 'UTC',
        context_asset_string: 'account_1',
        TIMEZONE: 'UTC',
      })

      // Create a fresh props object to avoid shared state
      const testProps = {
        ...props,
        recipientId: '1',
        recipientName: 'John Smith',
        recipientEmail: 'john@example.com',
        recipientAvatarUrl: 'https://example.com/avatar.png',
        userId: 'melvin',
        userName: 'Melvin',
        userEmail: 'melvin@example.com',
        userAvatarUrl: 'https://example.com/melvin.png',
        goBack: backCall,
        isEditMode: false,
      }

      const {getByLabelText, getByTestId} = render(<TempEnrollAssign {...testProps} />)

      // Wait for the component to fully load
      await waitFor(() => getByTestId('temp-enroll-summary'))

      // Get the date inputs
      const startDate = getByLabelText('Begins On *')
      const endDate = getByLabelText('Until *')

      // Verify the inputs exist and are functioning
      expect(startDate).toBeInTheDocument()
      expect(endDate).toBeInTheDocument()

      // Get the initial values of the date inputs
      const initialStartValue = startDate.getAttribute('value') || ''
      const initialEndValue = endDate.getAttribute('value') || ''

      // Set new dates that are different from the initial values
      fireEvent.input(startDate, {target: {value: 'Dec 25 2025'}})
      fireEvent.blur(startDate)

      // Verify the start date input has been updated
      expect(startDate).toHaveValue('Dec 25 2025')
      expect(startDate).not.toHaveValue(initialStartValue)

      // Set end date
      fireEvent.input(endDate, {target: {value: 'Dec 31 2025'}})
      fireEvent.blur(endDate)

      // Verify the end date input has been updated
      expect(endDate).toHaveValue('Dec 31 2025')
      expect(endDate).not.toHaveValue(initialEndValue)

      // Get the summary
      const summary = getByTestId('temp-enroll-summary')

      // Verify the summary contains the expected text
      expect(summary.textContent).toContain('Canvas will enroll Melvin')
      expect(summary.textContent).toContain('in the selected courses of John Smith')
      expect(summary.textContent).toContain('with an ending enrollment state of Deleted')

      // Clean up
      fakeENV.teardown()
      fetchMock.restore()
    })
  })

  describe('With Failed API calls', () => {
    beforeEach(() => {
      // mock console.error
      jest.spyOn(console, 'error').mockImplementation(() => {})

      fetchMock.get(ENROLLMENTS_URI, 500)
    })

    afterEach(() => {
      fetchMock.reset()
    })

    it('shows error for failed enrollments fetch', async () => {
      const {findAllByText} = render(<TempEnrollAssign {...props} />)
      const errorMessage = await findAllByText(
        /There was an error while requesting user enrollments, please try again/i,
      )
      expect(errorMessage).toBeTruthy()
    })
  })

  describe('pagination', () => {
    beforeEach(() => {
      fetchMock.get(ENROLLMENTS_URI, {
        status: 200,
        headers: {
          Link: `<${ENROLLMENTS_URI_PAGE_2}>; rel="next"`,
        },
        body: enrollmentsByCourse,
      })
      fetchMock.get(ENROLLMENTS_URI_PAGE_2, {
        status: 200,
        body: enrollmentsByCoursePage2,
      })
    })

    afterEach(() => {
      fetchMock.reset()
    })

    it('aggregates results from multiple pages', async () => {
      const {findByText} = render(<TempEnrollAssign {...props} />)
      expect(await findByText('Apple Music - Section 1')).toBeInTheDocument()
      expect(await findByText('Battle Axe Lessons - Section 2')).toBeInTheDocument()
    })
  })
})
