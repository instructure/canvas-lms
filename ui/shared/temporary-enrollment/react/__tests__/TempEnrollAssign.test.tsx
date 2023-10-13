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
import {fireEvent, render, waitFor, within} from '@testing-library/react'
import {TempEnrollAssign, tempEnrollAssignData} from '../TempEnrollAssign'
import fetchMock from 'fetch-mock'

const backCall = jest.fn()

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
    enrollments: [
      {
        role_id: '1',
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

const props = {
  enrollment: {login_id: 'mel123', email: 'mel@email.com', name: 'Melvin', sis_user_id: '5'},
  user: {
    name: 'John Smith',
    avatar_url: '',
    id: '1',
  },
  permissions: truePermissions,
  roles: [
    {id: '91', label: 'Student', base_role_name: 'StudentEnrollment'},
    {id: '92', label: 'Custom Teacher Role', base_role_name: 'TeacherEnrollment'},
  ],
  goBack: backCall,
  setEnrollmentStatus: jest.fn(),
  doSubmit: () => false,
  isInAssignEditMode: false,
}

const ENROLLMENTS_URI = encodeURI(
  `/api/v1/users/${props.user.id}/courses?enrollment_state=active&include[]=sections`
)

// converts local time to UTC time based on a given date and time
// returns UTC time in 'HH:mm' format
function localToUTCTime(date: string, time: string): string {
  const localDate = new Date(`${date} ${time}`)
  const utcHours = localDate.getUTCHours()
  const utcMinutes = localDate.getUTCMinutes()

  return `${String(utcHours).padStart(2, '0')}:${String(utcMinutes).padStart(2, '0')}`
}

describe('TempEnrollAssign', () => {
  afterEach(() => {
    fetchMock.reset()
    fetchMock.restore()
    jest.clearAllMocks()
    // ensure a clean state before each tests
    localStorage.clear()
  })

  describe('With Successful API calls', () => {
    beforeEach(() => {
      fetchMock.get(ENROLLMENTS_URI, enrollmentsByCourse)
    })

    it('initializes with ROLE as the default role in the summary', async () => {
      const {findByText} = render(<TempEnrollAssign {...props} />)
      const defaultMessage = await findByText(
        /Canvas will enroll .+ as a .+ in .+’s selected courses from .+ - .+/
      )

      expect(defaultMessage).toBeInTheDocument()
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

      expect(screen.getByText(/Canvas will enroll Melvin as a ROLE/)).toBeInTheDocument()

      fireEvent.click(roleSelect)

      const options = await screen.findAllByRole('option')
      fireEvent.click(options[0]) // select the "Student" option

      // Format: Canvas will enroll %{recipient} as a %{role} in %{source}'s selected courses from %{start} - %{end}
      expect(await screen.findByText(/Canvas will enroll Melvin as a Student/)).toBeInTheDocument()
    })

    it('changes summary when date and time changes', async () => {
      const {findByLabelText, findByTestId} = render(<TempEnrollAssign {...props} />)
      const startDate = await findByLabelText('Begins On')
      const endDate = await findByLabelText('Until')

      fireEvent.input(startDate, {target: {value: 'Apr 10 2022'}})
      fireEvent.blur(startDate)

      fireEvent.input(endDate, {target: {value: 'Apr 12 2022'}})
      fireEvent.blur(endDate)

      expect((await findByTestId('temp-enroll-summary')).textContent).toBe(
        'Canvas will enroll Melvin as a ROLE in John Smith’s selected courses from Sun, Apr 10, 2022, 12:00 AM - Tue, Apr 12, 2022, 11:59 PM'
      )
    })

    it('shows error when start date is after end date', async () => {
      const screen = render(<TempEnrollAssign {...props} />)
      const endDate = await screen.findByLabelText('Until')

      fireEvent.input(endDate, {target: {value: 'Apr 10 2022'}})
      fireEvent.blur(endDate)

      expect(
        await screen.findByText('The start date must be before the end date')
      ).toBeInTheDocument()
    })

    it('hides roles the user does not have permission to enroll', async () => {
      const {queryByText} = render(<TempEnrollAssign {...props} permissions={falsePermissions} />)
      expect(queryByText('No roles available')).not.toBeInTheDocument()
    })

    describe('localStorage interactions', () => {
      it('sets state from localStorage on mount', async () => {
        const mockData = {
          roleChoice: {id: '92', name: 'TeacherEnrollment'},
        }
        localStorage.setItem(tempEnrollAssignData, JSON.stringify(mockData))

        const screen = render(<TempEnrollAssign {...props} />)

        // wait for the component to load
        await waitFor(() => {
          const loadingElement = screen.queryByText(/Retrieving user enrollments/)
          expect(loadingElement).not.toBeInTheDocument()
        })

        const input = screen.getByPlaceholderText('Select a Role')
        expect(input).toHaveValue('Custom Teacher Role')
      })

      it('saves to localStorage on role select', async () => {
        const screen = render(<TempEnrollAssign {...props} />)
        const roleSelect = await screen.findByPlaceholderText('Select a Role')
        fireEvent.click(roleSelect)

        const options = await screen.findAllByRole('option')
        fireEvent.click(options[1]) // select the "Custom Teacher Role" option

        const storedData = localStorage.getItem(tempEnrollAssignData) as string
        const parsedData = JSON.parse(storedData)
        expect(parsedData).toEqual({roleChoice: {id: '92', name: 'Teacher'}})
      })

      it('saves to localStorage on START date change', async () => {
        const expectedStartDateDisplay = 'Apr 15 2023'
        const expectedStartDateISO = '2023-04-15'
        const expectedStartTime12Hr = '1:00 PM'

        const {findByLabelText, getByText} = render(<TempEnrollAssign {...props} />)

        const startDate = await findByLabelText('Begins On')
        fireEvent.input(startDate, {target: {value: expectedStartDateDisplay}})
        fireEvent.blur(startDate)

        const startDateContainer = getByText('Start Date for Melvin').closest('fieldset')

        const {findByLabelText: findByLabelTextWithinStartDate} = within(
          startDateContainer as HTMLElement
        )
        const startTime = await findByLabelTextWithinStartDate('Time')

        fireEvent.input(startTime, {target: {value: expectedStartTime12Hr}})
        fireEvent.blur(startTime)

        await waitFor(() => {
          const storedDataRaw = localStorage.getItem(tempEnrollAssignData) as string
          expect(storedDataRaw).toBeTruthy()

          const storedData = JSON.parse(storedDataRaw)

          // extract date and time parts
          const [datePart, timeFragment] = storedData.startDate.split('T')
          const timePart = timeFragment.slice(0, 5)

          // check date
          expect(datePart).toBe(expectedStartDateISO)

          // check time
          const expectedUTCTime = localToUTCTime(expectedStartDateISO, expectedStartTime12Hr)
          expect(timePart).toBe(expectedUTCTime)
        })
      })

      it('saves to localStorage on END date change', async () => {
        const expectedEndDateDisplay = 'Apr 16 2023'
        const expectedEndDateISO = '2023-04-16'
        const expectedEndTime12Hr = '2:00 PM'

        const {findByLabelText, getByText} = render(<TempEnrollAssign {...props} />)

        const endDate = await findByLabelText('Until')
        fireEvent.input(endDate, {target: {value: expectedEndDateDisplay}})
        fireEvent.blur(endDate)

        const endDateContainer = getByText('End Date for Melvin').closest('fieldset')

        const {findByLabelText: findByLabelTextWithinEndDate} = within(
          endDateContainer as HTMLElement
        )
        const endTime = await findByLabelTextWithinEndDate('Time')

        fireEvent.input(endTime, {target: {value: expectedEndTime12Hr}})
        fireEvent.blur(endTime)

        await waitFor(() => {
          const storedDataRaw = localStorage.getItem(tempEnrollAssignData) as string
          expect(storedDataRaw).toBeTruthy()

          const storedData = JSON.parse(storedDataRaw)

          // extract date and time parts
          const [datePart, timeFragment] = storedData.endDate.split('T')
          const timePart = timeFragment.slice(0, 5)

          // check date
          expect(datePart).toBe(expectedEndDateISO)

          // check time
          const expectedUTCTime = localToUTCTime(expectedEndDateISO, expectedEndTime12Hr)
          expect(timePart).toBe(expectedUTCTime) // 2 p.m.
        })
      })
    })
  })

  describe('With Failed API calls', () => {
    beforeEach(() => {
      // mock console.error
      jest.spyOn(console, 'error').mockImplementation(() => {})

      fetchMock.get(ENROLLMENTS_URI, 500)
    })

    it('shows error for failed enrollments fetch', async () => {
      const {findAllByText} = render(<TempEnrollAssign {...props} />)
      const errorMessage = await findAllByText(
        /There was an error while requesting user enrollments, please try again/i
      )
      expect(errorMessage).toBeTruthy()
    })
  })
})
