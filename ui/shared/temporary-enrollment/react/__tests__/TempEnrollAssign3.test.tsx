/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {fireEvent, render, waitFor, within} from '@testing-library/react'
import {Props, TempEnrollAssign, tempEnrollAssignData} from '../TempEnrollAssign'
import {MAX_ALLOWED_COURSES_PER_PAGE, PROVIDER, User} from '../types'
import fetchMock from 'fetch-mock'

const backCall = jest.fn()

jest.mock('../api/enrollment', () => ({
  deleteEnrollment: jest.fn(),
  getTemporaryEnrollmentPairing: jest.fn(),
}))

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

function formatDateToLocalString(utcDateStr: string) {
  const date = new Date(utcDateStr)
  return {
    date: new Intl.DateTimeFormat('en-US', {dateStyle: 'long'}).format(date),
    time: new Intl.DateTimeFormat('en-US', {timeStyle: 'short', hour12: true}).format(date),
  }
}

const ENROLLMENTS_URI = encodeURI(
  `/api/v1/users/${props.user.id}/courses?enrollment_state=active&include[]=sections&include[]=term&per_page=${MAX_ALLOWED_COURSES_PER_PAGE}&account_id=${enrollmentsByCourse[0].account_id}`,
)

describe('TempEnrollAssign', () => {
  beforeEach(() => {
    // @ts-expect-error
    window.ENV = {
      ACCOUNT_ID: '1',
      CONTEXT_TIMEZONE: 'Asia/Brunei',
      context_asset_string: 'account_1',
    }
    fetchMock.get(ENROLLMENTS_URI, enrollmentsByCourse)
  })

  afterEach(() => {
    fetchMock.reset()
    fetchMock.restore()
    jest.clearAllMocks()
    // ensure a clean state before each tests
    localStorage.clear()
  })

  afterAll(() => {
    // @ts-expect-error
    window.ENV = {}
  })

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
    expect(input).toHaveValue('Teacher')
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

  it('saves to localStorage on state select', async () => {
    const screen = render(<TempEnrollAssign {...props} />)
    const stateSelect = await screen.findByPlaceholderText('Begin typing to search')
    fireEvent.click(stateSelect)
    const options = await screen.findAllByRole('option')
    fireEvent.click(options[0]) // select the “Deleted” option
    const storedData = localStorage.getItem(tempEnrollAssignData) as string
    const parsedData = JSON.parse(storedData)
    expect(parsedData).toEqual({stateChoice: 'deleted'})
  })

  it('saves to localStorage on START date change', async () => {
    const expectedStartDateDisplay = 'Apr 15 2023'
    const expectedStartDateISO = '2023-04-15'
    const expectedStartTime12Hr = '1:00 PM'

    const {findByLabelText, getByText} = render(<TempEnrollAssign {...props} />)

    // get date input
    const startDate = await findByLabelText('Begins On *')

    // get time input
    const startDateContainer = getByText('Start Date for Melvin').closest('fieldset')
    const {findByLabelText: findByLabelTextWithinStartDate} = within(
      startDateContainer as HTMLElement,
    )
    const startTime = await findByLabelTextWithinStartDate('Time *')

    jest.useFakeTimers()
    fireEvent.input(startDate, {target: {value: expectedStartDateDisplay}})
    fireEvent.blur(startDate)
    jest.runAllTimers() // DateTimeInput has a setTimeout before firing the change event

    fireEvent.input(startTime, {target: {value: expectedStartTime12Hr}})
    fireEvent.blur(startTime)
    jest.runAllTimers() // DateTimeInput has a setTimeout before firing the change event

    const storedDataRaw = localStorage.getItem(tempEnrollAssignData) as string
    expect(storedDataRaw).toBeTruthy()
    const storedData = JSON.parse(storedDataRaw)

    // extract date and time parts
    const [datePart, timeFragment] = storedData.startDate.split('T')

    // check date
    expect(datePart).toBe(expectedStartDateISO)

    // check time
    const localTime = formatDateToLocalString(`${datePart} ${timeFragment}`).time
    expect(localTime).toBe(expectedStartTime12Hr)
  })

  it('saves to localStorage on END date change', async () => {
    const expectedEndDateDisplay = 'Apr 16 2023'
    const expectedEndDateISO = '2023-04-16'
    const expectedEndTime12Hr = '2:00 PM'

    const {findByLabelText, getByText} = render(<TempEnrollAssign {...props} />)

    // get date input
    const endDate = await findByLabelText('Until *')

    // get time input
    const endDateContainer = getByText('End Date for Melvin').closest('fieldset')
    const {findByLabelText: findByLabelTextWithinEndDate} = within(endDateContainer as HTMLElement)
    const endTime = await findByLabelTextWithinEndDate('Time *')

    jest.useFakeTimers()
    fireEvent.input(endDate, {target: {value: expectedEndDateDisplay}})
    fireEvent.blur(endDate)
    jest.runAllTimers() // DateTimeInput has a setTimeout before firing the change event

    fireEvent.input(endTime, {target: {value: expectedEndTime12Hr}})
    fireEvent.blur(endTime)
    jest.runAllTimers() // DateTimeInput has a setTimeout before firing the change event

    const storedDataRaw = localStorage.getItem(tempEnrollAssignData) as string
    expect(storedDataRaw).toBeTruthy()

    const storedData = JSON.parse(storedDataRaw)

    // extract date and time parts
    const [datePart, timeFragment] = storedData.endDate.split('T')

    // check date
    expect(datePart).toBe(expectedEndDateISO)

    // check time
    const localTime = formatDateToLocalString(`${datePart} ${timeFragment}`).time
    expect(localTime).toBe(expectedEndTime12Hr) // 2 p.m.
  })
})
