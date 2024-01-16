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
import {
  defaultRoleChoice,
  deleteMultipleEnrollmentsByNoMatch,
  getEnrollmentAndUserProps,
  getStoredData,
  isEnrollmentMatch,
  isMatchFound,
  type Props,
  TempEnrollAssign,
  tempEnrollAssignData,
} from '../TempEnrollAssign'
import fetchMock from 'fetch-mock'
import {
  type Enrollment,
  MAX_ALLOWED_COURSES_PER_PAGE,
  PROVIDER,
  RECIPIENT,
  type Role,
  type User,
} from '../types'
import {deleteEnrollment, getTemporaryEnrollmentPairing} from '../api/enrollment'
import * as localStorageUtils from '../util/helpers'
import {getDayBoundaries} from '../util/helpers'
import MockDate from 'mockdate'

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

const props: Props = {
  enrollment: {
    email: 'mel@email.com',
    id: '2',
    login_id: 'mel123',
    name: 'Melvin',
    sis_user_id: '5',
  } as User,
  user: {
    id: '1',
    name: 'John Smith',
    avatar_url: '',
  } as User,
  permissions: truePermissions,
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
  `/api/v1/users/${props.user.id}/courses?enrollment_state=active&include[]=sections&per_page=${MAX_ALLOWED_COURSES_PER_PAGE}&account_id=${enrollmentsByCourse[0].account_id}`
)

// converts local time to UTC time based on a given date and time
// returns UTC time in 'HH:mm' format
function localToUTCTime(date: string, time: string): string {
  const localDate = new Date(`${date} ${time}`)
  const utcHours = localDate.getUTCHours()
  const utcMinutes = localDate.getUTCMinutes()

  return `${String(utcHours).padStart(2, '0')}:${String(utcMinutes).padStart(2, '0')}`
}

function formatDateToLocalString(utcDateStr: string) {
  const date = new Date(utcDateStr)
  return {
    date: new Intl.DateTimeFormat(undefined, {dateStyle: 'long'}).format(date),
    time: new Intl.DateTimeFormat(undefined, {timeStyle: 'short', hour12: true}).format(date),
  }
}

describe('TempEnrollAssign', () => {
  beforeAll(() => {
    // @ts-expect-error
    window.ENV = {ACCOUNT_ID: '1'}
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

  describe('With Successful API calls', () => {
    beforeEach(() => {
      fetchMock.get(ENROLLMENTS_URI, enrollmentsByCourse)
    })

    it('initializes with ROLE as the default role in the summary', async () => {
      const {findByText} = render(<TempEnrollAssign {...props} />)
      const defaultMessage = await findByText(
        /Canvas will enroll .+ as a .+ in the selected courses of .+ from .+ - .+/
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

      expect(screen.getByText(/Canvas will enroll Melvin as a Teacher/)).toBeInTheDocument()

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
        'Canvas will enroll Melvin as a Teacher in the selected courses of John Smith from Sun, Apr 10, 2022, 12:01 AM - Tue, Apr 12, 2022, 11:59 PM with an ending enrollment state of Deleted'
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

  describe('getEnrollmentAndUserProps', () => {
    it('should return enrollmentProps and userProps correctly when enrollmentType is RECIPIENT', () => {
      const {enrollmentProps, userProps} = getEnrollmentAndUserProps({
        enrollmentType: RECIPIENT,
        enrollment: props.enrollment,
        user: props.user,
      })

      // Assert
      expect(enrollmentProps).toEqual(props.user)
      expect(userProps).toEqual(props.enrollment)
    })

    it('should return enrollmentProps and userProps correctly when enrollmentType is PROVIDER', () => {
      const {enrollmentProps, userProps} = getEnrollmentAndUserProps({
        enrollmentType: PROVIDER,
        enrollment: props.enrollment,
        user: props.user,
      })

      expect(enrollmentProps).toEqual(props.enrollment)
      expect(userProps).toEqual(props.user)
    })
  })

  describe('props.tempEnrollmentsPairing', () => {
    let tempProps: Props
    const startAt = '2022-11-09T05:30:00Z'
    const endAt = '2022-12-31T07:30:00Z'
    const tempEnrollmentsPairingMock: Enrollment[] = [
      {
        course_id: '1',
        course_section_id: '1',
        role_id: '92',
        start_at: startAt,
        end_at: endAt,
        temporary_enrollment_pairing_id: 143,
      },
    ] as Enrollment[]

    beforeEach(() => {
      fetchMock.get(ENROLLMENTS_URI, enrollmentsByCourse)
      tempProps = {
        ...props,
        tempEnrollmentsPairing: tempEnrollmentsPairingMock,
      }
      ;(getTemporaryEnrollmentPairing as jest.Mock).mockResolvedValue({
        response: {status: 204, ok: true},
        json: {
          temporary_enrollment_pairing: {
            id: '143',
            root_account_id: '2',
            workflow_state: 'active',
            created_at: '2024-01-12T20:02:47Z',
            updated_at: '2024-01-12T20:02:47Z',
            created_by_id: '1',
            deleted_by_id: null,
            ending_enrollment_state: null,
          },
        },
      })
    })

    it('should set the role correctly when a matching role is found', async () => {
      const {findByPlaceholderText} = render(<TempEnrollAssign {...tempProps} />)
      const roleSelect = (await findByPlaceholderText('Select a Role')) as HTMLInputElement
      expect(roleSelect.value).toBe('Teacher')
    })

    it('should set the state correctly when a matching state is found', async () => {
      const {findByPlaceholderText} = render(<TempEnrollAssign {...tempProps} />)
      const stateSelect = (await findByPlaceholderText(
        'Begin typing to search'
      )) as HTMLInputElement
      expect(stateSelect.value).toBe('Deleted')
    })

    it('should choose the default if no role is found', async () => {
      const doNotFindThisRoleId: Role = {
        id: '999',
        base_role_name: 'SomeEnrollment',
        name: 'SomeEnrollment',
        label: 'Test',
      }
      tempProps.roles = [doNotFindThisRoleId]
      const {findByPlaceholderText, findByTestId} = render(<TempEnrollAssign {...tempProps} />)
      const roleSelect = (await findByPlaceholderText('Select a Role')) as HTMLInputElement
      expect(roleSelect.value).toBe('')
      expect((await findByTestId('temp-enroll-summary')).textContent).toMatch(
        /^Canvas will enroll Melvin as a ROLE/
      )
    })

    it('should set the start date and time correctly', async () => {
      const localStartDate = formatDateToLocalString(startAt)
      const {findByLabelText, getByText} = render(<TempEnrollAssign {...tempProps} />)
      const startDate = (await findByLabelText('Begins On')) as HTMLInputElement
      const startDateContainer = getByText('Start Date for Melvin').closest('fieldset')
      const {findByLabelText: findByLabelTextWithinStartDate} = within(
        startDateContainer as HTMLElement
      )
      const startTime = (await findByLabelTextWithinStartDate('Time')) as HTMLInputElement
      expect(startDate.value).toBe(localStartDate.date)
      expect(startTime.value).toBe(localStartDate.time)
    })

    it('should set the end date and time correctly', async () => {
      const localEndDate = formatDateToLocalString(endAt)
      const {findByLabelText, getByText} = render(<TempEnrollAssign {...tempProps} />)
      const endDate = (await findByLabelText('Until')) as HTMLInputElement
      const endDateContainer = getByText('End Date for Melvin').closest('fieldset')
      const {findByLabelText: findByLabelTextWithinEndDate} = within(
        endDateContainer as HTMLElement
      )
      const endTime = (await findByLabelTextWithinEndDate('Time')) as HTMLInputElement
      expect(endDate.value).toBe(localEndDate.date)
      expect(endTime.value).toBe(localEndDate.time)
    })
  })

  describe('isEnrollmentMatch', () => {
    let mockTempEnrollment: Enrollment

    beforeEach(() => {
      mockTempEnrollment = {
        course_id: '',
        end_at: '',
        id: '',
        start_at: '',
        user_id: '',
        enrollment_state: '',
        temporary_enrollment_pairing_id: 0,
        temporary_enrollment_source_user_id: 0,
        type: '',
        course_section_id: '7',
        limit_privileges_to_course_section: false,
        user: {
          id: '1',
        } as User,
        role_id: '20',
      }
    })

    it('should return true when enrollment matches', () => {
      const result = isEnrollmentMatch(mockTempEnrollment, '7', '1', '20')
      expect(result).toBe(true)
    })

    it('should return false when course_section_id does not match', () => {
      const result = isEnrollmentMatch(mockTempEnrollment, '8', '1', '20')
      expect(result).toBe(false)
    })

    it('should return false when user ID does not match', () => {
      const result = isEnrollmentMatch(mockTempEnrollment, '7', '2', '20')
      expect(result).toBe(false)
    })

    it('should return false when role ID does not match', () => {
      const result = isEnrollmentMatch(mockTempEnrollment, '7', '1', '21')
      expect(result).toBe(false)
    })
  })

  describe('isMatchFound', () => {
    let mockTempEnrollment: Enrollment

    beforeEach(() => {
      mockTempEnrollment = {
        course_id: '8',
        end_at: '',
        id: '92',
        start_at: '',
        user_id: '1',
        enrollment_state: 'active',
        temporary_enrollment_pairing_id: 0,
        temporary_enrollment_source_user_id: 0,
        type: '',
        course_section_id: '7',
        limit_privileges_to_course_section: false,
        user: {
          id: '1',
        } as User,
        role_id: '20',
      }
    })

    it('should return false if a match is found', () => {
      const sectionIds = ['7', '8', '9']
      const userId = '1'
      const roleId = '20'
      expect(isMatchFound(sectionIds, mockTempEnrollment, userId, roleId)).toBe(true)
    })

    it('should return true if no match is found', () => {
      const sectionIds = ['22', '55', '100']
      const userId = '1'
      const roleId = '20'
      expect(isMatchFound(sectionIds, mockTempEnrollment, userId, roleId)).toBe(false)
    })

    it('should return true if user ID does not match', () => {
      const sectionIds = ['7', '8', '9']
      const nonMatchingUserId = '2'
      const roleId = '20'
      expect(isMatchFound(sectionIds, mockTempEnrollment, nonMatchingUserId, roleId)).toBe(false)
    })

    it('should return true if role ID does not match', () => {
      const sectionIds = ['7', '8', '9']
      const userId = '1'
      const nonMatchingRoleId = '30'
      expect(isMatchFound(sectionIds, mockTempEnrollment, userId, nonMatchingRoleId)).toBe(false)
    })

    it('should return true if sectionIds array is empty', () => {
      const sectionIds: string[] = []
      const userId = '1'
      const roleId = '20'
      expect(isMatchFound(sectionIds, mockTempEnrollment, userId, roleId)).toBe(false)
    })
  })

  describe('processEnrollmentDeletions', () => {
    let mockTempEnrollments: Enrollment[]

    beforeEach(() => {
      mockTempEnrollments = [
        {
          course_id: '8',
          end_at: '',
          id: '92',
          start_at: '',
          user_id: '1',
          enrollment_state: 'active',
          temporary_enrollment_pairing_id: 0,
          temporary_enrollment_source_user_id: 0,
          type: '',
          course_section_id: '7',
          limit_privileges_to_course_section: false,
          user: {
            id: '1',
          } as User,
          role_id: '20',
        },
      ]
      ;(deleteEnrollment as jest.Mock).mockResolvedValue({
        response: {status: 204, ok: true},
        json: [],
      })
    })

    it('should call deleteEnrollment for matching criteria', async () => {
      const sectionIds = ['55', '220', '19']
      const userId = '1'
      const roleId = '20'
      const promises = deleteMultipleEnrollmentsByNoMatch(
        mockTempEnrollments,
        sectionIds,
        userId,
        roleId
      )
      expect(promises).toHaveLength(1)
      await Promise.all(promises)
      expect(deleteEnrollment).toHaveBeenCalledTimes(1)
    })

    it('should not call deleteEnrollment for non-matching criteria', async () => {
      const sectionIds = ['7', '55', '220', '19']
      const userId = '1'
      const roleId = '20'
      const promises = deleteMultipleEnrollmentsByNoMatch(
        mockTempEnrollments,
        sectionIds,
        userId,
        roleId
      )
      expect(promises).toHaveLength(0)
      await Promise.all(promises)
      expect(deleteEnrollment).toHaveBeenCalledTimes(0)
    })
  })

  // FOO-4218 - remove or rewrite to remove spies on imports
  describe.skip('getStoredData', () => {
    let mockRoles: Role[]

    function mockGetFromLocalStorage<T extends object>(data: T | undefined) {
      jest
        .spyOn(localStorageUtils, 'getFromLocalStorage')
        .mockImplementation((storageKey: string) =>
          storageKey === tempEnrollAssignData ? data : undefined
        )
    }

    beforeEach(() => {
      mockRoles = [
        {
          id: '19',
          name: 'StudentEnrollment',
          label: 'Student',
          base_role_name: 'StudentEnrollment',
        },
        {
          id: '20',
          name: 'TeacherEnrollment',
          label: 'Teacher',
          base_role_name: 'TeacherEnrollment',
        },
        {
          id: '21',
          name: 'TaEnrollment',
          label: 'TA',
          base_role_name: 'TaEnrollment',
        },
        {
          id: '22',
          name: 'DesignerEnrollment',
          label: 'Designer',
          base_role_name: 'DesignerEnrollment',
        },
        {
          id: '23',
          name: 'ObserverEnrollment',
          label: 'Observer',
          base_role_name: 'ObserverEnrollment',
        },
      ]
      MockDate.set('2022-01-01T00:00:00.000Z')
    })

    afterEach(() => {
      MockDate.reset()
    })

    it('should return default values when no data is in local storage', () => {
      mockGetFromLocalStorage({})
      const result = getStoredData(mockRoles)
      const [expectedDefaultStartDate, expectedDefaultEndDate] = getDayBoundaries()
      const expectedTeacherRoleChoice = {id: '20', name: 'Teacher'}
      expect(result.roleChoice).toEqual(expectedTeacherRoleChoice)
      expect(result.startDate).toEqual(expectedDefaultStartDate)
      expect(result.endDate).toEqual(expectedDefaultEndDate)
    })

    it('should correctly use local storage data when available', () => {
      const mockLocalStorageData = {
        roleChoice: {id: '20', name: 'Teacher'},
        startDate: '2022-01-01T00:00:00.000Z',
        endDate: '2022-01-31T00:00:00.000Z',
      }
      mockGetFromLocalStorage(mockLocalStorageData)
      const result = getStoredData(mockRoles)
      expect(result.roleChoice).toEqual(mockLocalStorageData.roleChoice)
      expect(result.startDate).toEqual(new Date(mockLocalStorageData.startDate))
      expect(result.endDate).toEqual(new Date(mockLocalStorageData.endDate))
    })

    it('should handle date conversions correctly', () => {
      const mockLocalStorageData = {
        startDate: '2022-01-01T00:00:00.000Z',
        endDate: '2022-01-31T00:00:00.000Z',
      }
      mockGetFromLocalStorage(mockLocalStorageData)
      const result = getStoredData(mockRoles)
      expect(result.startDate).toEqual(new Date(mockLocalStorageData.startDate))
      expect(result.endDate).toEqual(new Date(mockLocalStorageData.endDate))
    })

    it('should set the roleChoice to defaultRoleChoice when no teacher role is present', () => {
      const rolesWithoutTeacher = mockRoles.filter(
        role => role.base_role_name !== 'TeacherEnrollment'
      )
      mockGetFromLocalStorage({}) // Mock with empty object
      const result = getStoredData(rolesWithoutTeacher)
      const [expectedDefaultStartDate, expectedDefaultEndDate] = getDayBoundaries()
      expect(result.roleChoice).toEqual(defaultRoleChoice)
      expect(result.startDate).toEqual(expectedDefaultStartDate)
      expect(result.endDate).toEqual(expectedDefaultEndDate)
    })
  })
})
