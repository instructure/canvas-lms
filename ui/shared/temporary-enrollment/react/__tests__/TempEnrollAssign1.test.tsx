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

    it('changes summary when date and time changes', async () => {
      const {findByLabelText, findByTestId} = render(<TempEnrollAssign {...props} />)
      const startDate = await findByLabelText('Begins On *')
      const endDate = await findByLabelText('Until *')

      fireEvent.input(startDate, {target: {value: 'Apr 10 2022'}})
      await waitFor(() => {
        fireEvent.blur(startDate)
      })

      fireEvent.input(endDate, {target: {value: 'Apr 12 2022'}})
      await waitFor(() => {
        fireEvent.blur(endDate)
      })

      // Date.now sets default according to system timezone and cannot be fed a timezone; is midnight in manual testing
      expect((await findByTestId('temp-enroll-summary')).textContent).toBe(
        'Canvas will enroll Melvin as a Teacher in the selected courses of John Smith from Sun, Apr 10, 2022, 12:01 AM - Tue, Apr 12, 2022, 11:59 PM with an ending enrollment state of Deleted',
      )
    })

    it('displays Local and Account datetime in correct timezones', async () => {
      window.ENV = {...window.ENV, TIMEZONE: 'America/Denver'}

      const {findAllByLabelText, findAllByText} = render(<TempEnrollAssign {...props} />)
      const startDate = (await findAllByLabelText('Begins On *'))[0]
      fireEvent.input(startDate, {target: {value: 'Oct 31 2024'}})
      fireEvent.blur(startDate)

      const startTime = (await findAllByLabelText('Time *'))[0]
      fireEvent.input(startTime, {target: {value: '9:00 AM'}})
      fireEvent.blur(startTime)

      const localTime = (await findAllByText(/Local: /))[0]
      const accTime = (await findAllByText(/Account: /))[0]

      expect(localTime.textContent).toContain('9:00 AM')
      expect(accTime.textContent).toContain('11:00 PM')
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
