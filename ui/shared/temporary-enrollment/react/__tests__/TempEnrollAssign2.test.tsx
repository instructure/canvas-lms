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
import {render, within} from '@testing-library/react'
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

function formatDateToLocalString(utcDateStr: string) {
  const date = new Date(utcDateStr)
  return {
    date: new Intl.DateTimeFormat('en-US', {dateStyle: 'long'}).format(date),
    time: new Intl.DateTimeFormat('en-US', {timeStyle: 'short', hour12: true}).format(date),
  }
}

describe('TempEnrollAssign', () => {
  beforeEach(() => {
    // @ts-expect-error
    window.ENV = {
      ACCOUNT_ID: '1',
      CONTEXT_TIMEZONE: 'Asia/Brunei',
      context_asset_string: 'account_1',
    }
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

  describe('getEnrollmentAndUserProps', () => {
    it('should return enrollmentProps and userProps correctly when enrollmentType is RECIPIENT', () => {
      const {enrollmentProps, userProps} = getEnrollmentAndUserProps({
        enrollmentType: RECIPIENT,
        enrollments: props.enrollments,
        user: props.user,
      })

      expect(enrollmentProps).toEqual([props.user])
      expect(userProps).toEqual(props.enrollments[0])
    })

    it('should return enrollmentProps and userProps correctly when enrollmentType is PROVIDER', () => {
      const {enrollmentProps, userProps} = getEnrollmentAndUserProps({
        enrollmentType: PROVIDER,
        enrollments: props.enrollments,
        user: props.user,
      })

      expect(enrollmentProps).toEqual(props.enrollments)
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
        'Begin typing to search',
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
        /^Canvas will enroll Melvin as a ROLE/,
      )
    })

    it('should set the start date and time correctly', async () => {
      const localStartDate = formatDateToLocalString(startAt)
      const {findByLabelText, getByText, debug} = render(<TempEnrollAssign {...tempProps} />)
      const startDate = (await findByLabelText('Begins On *')) as HTMLInputElement
      const startDateContainer = getByText('Start Date for Melvin').closest('fieldset')
      const {findByLabelText: findByLabelTextWithinStartDate} = within(
        startDateContainer as HTMLElement,
      )
      const startTime = (await findByLabelTextWithinStartDate('Time *')) as HTMLInputElement
      expect(startDate.value).toBe(localStartDate.date)
      expect(startTime.value).toBe(localStartDate.time)
    })

    it('should set the end date and time correctly', async () => {
      const localEndDate = formatDateToLocalString(endAt)
      const {findByLabelText, getByText} = render(<TempEnrollAssign {...tempProps} />)
      const endDate = (await findByLabelText('Until *')) as HTMLInputElement
      const endDateContainer = getByText('End Date for Melvin').closest('fieldset')
      const {findByLabelText: findByLabelTextWithinEndDate} = within(
        endDateContainer as HTMLElement,
      )
      const endTime = (await findByLabelTextWithinEndDate('Time *')) as HTMLInputElement
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
      const enrollmentUsers: User[] = [{id: '1', name: 'user1'}]
      const roleId = '20'
      const promises = deleteMultipleEnrollmentsByNoMatch(
        mockTempEnrollments,
        sectionIds,
        enrollmentUsers,
        roleId,
      )
      expect(promises).toHaveLength(1)
      await Promise.all(promises)
      expect(deleteEnrollment).toHaveBeenCalledTimes(1)
    })

    it('should not call deleteEnrollment for non-matching criteria', async () => {
      const sectionIds = ['7', '55', '220', '19']
      const enrollmentUsers: User[] = [{id: '1', name: 'user1'}]
      const roleId = '20'
      const promises = deleteMultipleEnrollmentsByNoMatch(
        mockTempEnrollments,
        sectionIds,
        enrollmentUsers,
        roleId,
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
          storageKey === tempEnrollAssignData ? data : undefined,
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
        role => role.base_role_name !== 'TeacherEnrollment',
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
