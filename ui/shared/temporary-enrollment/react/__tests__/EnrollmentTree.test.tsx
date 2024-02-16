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
import {render, screen, waitFor} from '@testing-library/react'
import {EnrollmentTree, type Props} from '../EnrollmentTree'
import type {Enrollment} from '../types'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'

const mockEnrollment = {
  enrollment_state: 'active',
  course_id: '',
  course_section_id: '',
  limit_privileges_to_course_section: false,
  end_at: '',
  id: '',
  start_at: '',
  temporary_enrollment_pairing_id: 0,
  temporary_enrollment_provider: {
    id: '',
    name: '',
  },
  temporary_enrollment_source_user_id: 0,
  type: '',
  user: {
    id: '',
    name: '',
  },
  user_id: '',
}

const props: Props = {
  roles: [
    {
      id: '1',
      label: 'StudentRole',
      name: 'StudentEnrollment',
      base_role_name: 'StudentEnrollment',
    },
    {
      id: '2',
      label: 'SubTeacherRole',
      name: 'TeacherEnrollment',
      base_role_name: 'TeacherEnrollment',
    },
    {
      id: '3',
      label: 'DesignRole',
      name: 'DesignerEnrollment',
      base_role_name: 'DesignerEnrollment',
    },
    {
      id: '4',
      label: 'TeacherRole',
      name: 'TeacherEnrollment',
      base_role_name: 'TeacherEnrollment',
    },
  ],
  selectedRole: {
    id: '',
    name: '',
  },
  enrollmentsByCourse: [
    {
      id: '1',
      name: 'Apple Music',
      workflow_state: 'available',
      enrollments: [
        {
          role_id: '1',
          ...mockEnrollment,
        },
      ],
      sections: [
        {
          id: '1',
          name: 'Section 1',
          enrollment_role: 'StudentEnrollment',
          course_id: '',
          course_section_id: '',
        },
      ],
    },
    {
      id: '1',
      name: 'Apple Music',
      workflow_state: 'available',
      enrollments: [
        {
          role_id: '2',
          ...mockEnrollment,
        },
      ],
      sections: [
        {
          id: '1',
          name: 'Section 1',
          enrollment_role: 'TeacherEnrollment',
          course_id: '',
          course_section_id: '',
        },
      ],
    },
    {
      id: '1',
      name: 'Apple Music',
      workflow_state: 'available',
      enrollments: [
        {
          role_id: '3',
          ...mockEnrollment,
        },
      ],
      sections: [
        {
          id: '2',
          name: 'Section 2',
          enrollment_role: 'DesignerEnrollment',
          course_id: '',
          course_section_id: '',
        },
      ],
    },
    {
      id: '2',
      name: 'Studio Beats',
      workflow_state: 'unpublished',
      enrollments: [
        {
          role_id: '4',
          ...mockEnrollment,
        },
      ],
      sections: [
        {
          id: '3',
          name: 'Default Section',
          enrollment_role: 'TeacherEnrollment',
          course_id: '',
          course_section_id: '',
        },
      ],
    },
  ],
  createEnroll: jest.fn(),
}

const USER_EVENT_OPTIONS = {pointerEventsCheck: PointerEventsCheckLevel.Never}

describe('EnrollmentTree', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders role groups', async () => {
    render(<EnrollmentTree {...props} />)
    expect(await screen.findByText('StudentRole')).toBeInTheDocument()
    expect(await screen.findByText('TeacherRole')).toBeInTheDocument()
    expect(await screen.findByText('DesignRole')).toBeInTheDocument()
  })

  it('renders children after clicking toggle', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    render(<EnrollmentTree {...props} />)
    expect(await screen.findByText('Toggle group SubTeacherRole')).toBeInTheDocument()
    await user.click(await screen.findByText('Toggle group StudentRole'))
    expect(await screen.findByText('Apple Music - Section 1')).toBeInTheDocument()
  })

  it('hides children after clicking toggle', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    render(<EnrollmentTree {...props} />)
    expect(await screen.findByText('Toggle group SubTeacherRole')).toBeInTheDocument()
    await user.click(screen.getByText('Toggle group StudentRole'))
    expect(await screen.findByText('Apple Music - Section 1')).toBeInTheDocument()
    await user.click(screen.getByText('Toggle group StudentRole'))
    expect(screen.queryByText('Apple Music - Section 1')).not.toBeInTheDocument()
  })

  it('renders enrollments in order of base role', async () => {
    render(<EnrollmentTree {...props} />)
    await screen.findByText('SubTeacherRole')
    const sub = screen.getByText('SubTeacherRole')
    const student = screen.getByText('StudentRole')
    const designer = screen.getByText('DesignRole')
    // SubTeacher is above Designer in list
    expect(sub.compareDocumentPosition(designer)).toBe(4)
    // Designer is above Student in List
    expect(designer.compareDocumentPosition(student)).toBe(4)
  })

  it('selects teacher base roles by default', async () => {
    render(<EnrollmentTree {...props} />)
    await screen.findByText('SubTeacherRole')
    const checkedBox = screen.getByRole('checkbox', {checked: true})
    expect(checkedBox.getAttribute('data-testid')).toMatch('check-r2')
  })

  it('does not select unpublished course enrollments by default', async () => {
    render(<EnrollmentTree {...props} />)
    expect(screen.queryByText('TeacherRole')).toBeInTheDocument()
    expect(screen.queryByText('SubTeacherRole')).toBeInTheDocument()
    expect((screen.getByTestId('check-r2') as HTMLInputElement).checked).toBe(true)
    expect((screen.getByTestId('check-r4') as HTMLInputElement).checked).toBe(false)
    expect(screen.queryByText('Toggle group TeacherRole')).toBeInTheDocument()
    expect(screen.queryByText('Toggle group SubTeacherRole')).toBeInTheDocument()
  })

  it('shows enrollments in one section with different roles under respective role groups', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    render(<EnrollmentTree {...props} />)
    await screen.findByText('Toggle group StudentRole')
    await user.click(screen.getByText('Toggle group StudentRole'))
    expect(screen.queryByText('Apple Music - Section 1')).toBeInTheDocument()
    await user.click(screen.getByText('Toggle group DesignRole'))
    expect(screen.queryByText('Apple Music - Section 2')).toBeInTheDocument()
  })

  it('checks children when group is checked', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    render(<EnrollmentTree {...props} />)
    expect(screen.queryByText('SubTeacherRole')).toBeInTheDocument()
    await user.click(screen.getByTestId('check-r1'))
    // includes default teacher check
    expect(screen.getAllByRole('checkbox', {checked: true}).length).toBe(2)
    await user.click(screen.getByText('Toggle group StudentRole'))
    // parent + child + default
    expect(screen.getAllByRole('checkbox', {checked: true}).length).toBe(3)
  })

  it('calls createEnroll when available', async () => {
    render(<EnrollmentTree {...props} />)
    await screen.findByText('SubTeacherRole')
    expect(props.createEnroll).toHaveBeenCalledTimes(1)
  })

  describe('props.tempEnrollmentsPairing', () => {
    let tempProps: Props
    const tempEnrollmentsPairingMock: Enrollment[] = [
      {
        course_id: '1',
        course_section_id: '1',
        role_id: '1', // student
      },
      {
        course_id: '1',
        course_section_id: '1',
        role_id: '2', // teacher
      },
    ] as Enrollment[]

    beforeEach(() => {
      tempProps = {
        ...props,
        tempEnrollmentsPairing: tempEnrollmentsPairingMock,
      }
    })

    it('renders role groups based on tempEnrollmentsPairing', async () => {
      render(<EnrollmentTree {...tempProps} />)
      expect(screen.queryByText('StudentRole')).toBeInTheDocument()
      expect(screen.queryByText('SubTeacherRole')).toBeInTheDocument()
      expect(screen.queryByText('DesignRole')).toBeInTheDocument()
      const studentCheckbox = screen.getByTestId('check-r1') as HTMLInputElement
      expect(studentCheckbox.checked).toBe(true)
      const teacherCheckbox = screen.getByTestId('check-r2') as HTMLInputElement
      expect(teacherCheckbox.checked).toBe(true)
      const designCheckbox = screen.getByTestId('check-r3') as HTMLInputElement
      expect(designCheckbox.checked).toBe(false)
      expect(screen.queryByText('Toggle group StudentRole')).toBeInTheDocument()
      expect(screen.queryByText('Toggle group SubTeacherRole')).toBeInTheDocument()
      expect(screen.queryByText('Toggle group DesignRole')).toBeInTheDocument()
    })
  })

  describe('findOrAppendNewNode', () => {
    let tempProps: Props
    const enrollmentsByCourseMock = [
      {
        id: '3',
        name: 'Second Grade Math',
        workflow_state: 'available',
        enrollments: [
          {
            role_id: '2',
            ...mockEnrollment,
          },
        ],
        sections: [
          {
            id: '16',
            name: 'Second Grade Math',
            enrollment_role: 'TeacherEnrollment',
            course_id: '',
            course_section_id: '',
          },
        ],
      },
      {
        id: '4',
        name: 'Second Grade Math',
        workflow_state: 'available',
        enrollments: [
          {
            role_id: '2',
            ...mockEnrollment,
          },
        ],
        sections: [
          {
            id: '17',
            name: 'Second Grade Math',
            enrollment_role: 'TeacherEnrollment',
            course_id: '',
            course_section_id: '',
          },
        ],
      },
      {
        id: '5',
        name: 'Second Grade Math',
        workflow_state: 'available',
        enrollments: [
          {
            role_id: '2',
            ...mockEnrollment,
          },
        ],
        sections: [
          {
            id: '18',
            name: 'Second Grade Math',
            enrollment_role: 'TeacherEnrollment',
            course_id: '',
            course_section_id: '',
          },
        ],
      },
    ]

    beforeEach(() => {
      tempProps = {
        ...props,
        enrollmentsByCourse: [...props.enrollmentsByCourse, ...enrollmentsByCourseMock],
      }
    })

    it('renders multiple courses with the same label', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      render(<EnrollmentTree {...tempProps} />)
      await user.click(screen.getByText('Toggle group SubTeacherRole'))
      expect(screen.getAllByText('Second Grade Math - Second Grade Math')).toHaveLength(3)
    })
  })

  describe('isMismatch', () => {
    let tempProps: Props
    const enrollmentsByCourseMock = [
      {
        id: '1',
        name: 'History of Art Period 1',
        workflow_state: 'available',
        enrollments: [
          {
            role_id: '4',
            ...mockEnrollment,
          },
        ],
        sections: [
          {
            id: '1',
            name: 'Test Section',
            enrollment_role: 'TeacherEnrollment',
            course_id: '1',
            course_section_id: '1',
          },
          {
            id: '2',
            name: 'Another Section',
            enrollment_role: 'TeacherEnrollment',
            course_id: '1',
            course_section_id: '2',
          },
        ],
      },
    ]

    beforeEach(() => {
      tempProps = {
        ...props,
        enrollmentsByCourse: enrollmentsByCourseMock,
        selectedRole: {
          id: '1',
          name: 'StudentEnrollment',
        },
      }
    })

    it('verifies initial state of checkboxes and presence of tooltips', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      render(<EnrollmentTree {...tempProps} />)
      await user.click(screen.getByText('Toggle group TeacherRole'))
      await user.click(screen.getByText('Toggle group History of Art Period 1'))
      // teacher roles/enrollments are checked by default if not in edit mode
      expect(screen.getByTestId('check-c1')).toBeChecked()
      expect(screen.getByTestId('tip-c1')).toBeInTheDocument()
      expect(screen.getByTestId('check-s1')).toBeChecked()
      expect(screen.getByTestId('tip-s1')).toBeInTheDocument()
      expect(screen.getByTestId('check-s2')).toBeChecked()
      expect(screen.getByTestId('tip-s2')).toBeInTheDocument()
    })

    it('updates isMismatch property and indeterminate state based on section check status', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      render(<EnrollmentTree {...tempProps} />)
      await user.click(screen.getByText('Toggle group TeacherRole'))
      await user.click(screen.getByText('Toggle group History of Art Period 1'))
      await user.click(screen.getByTestId('check-s1'))
      expect(screen.getByTestId('check-s1')).not.toBeChecked()
      expect(screen.queryByTestId('tip-s1')).not.toBeInTheDocument()
      const courseCheckbox = screen.getByTestId('check-c1') as HTMLInputElement
      expect(courseCheckbox.indeterminate).toBe(true)
      expect(screen.getByTestId('tip-c1')).toBeInTheDocument()
      expect(screen.getByTestId('check-s2')).toBeChecked()
      expect(screen.getByTestId('tip-s2')).toBeInTheDocument()
    })

    it('toggles the parent checkbox to control all children and verifies tooltips', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      render(<EnrollmentTree {...tempProps} />)
      await user.click(screen.getByText('Toggle group TeacherRole'))
      await user.click(screen.getByText('Toggle group History of Art Period 1'))
      // check initial state of parent and children
      expect(screen.getByTestId('check-c1')).toBeChecked()
      expect(screen.getByTestId('check-s1')).toBeChecked()
      expect(screen.getByTestId('check-s2')).toBeChecked()
      expect(screen.getByTestId('tip-c1')).toBeInTheDocument()
      expect(screen.getByTestId('tip-s1')).toBeInTheDocument()
      expect(screen.getByTestId('tip-s2')).toBeInTheDocument()
      // uncheck all children
      await user.click(screen.getByTestId('check-c1'))
      await waitFor(() => {
        expect(screen.getByTestId('check-c1')).not.toBeChecked()
        expect(screen.getByTestId('check-s1')).not.toBeChecked()
        expect(screen.getByTestId('check-s2')).not.toBeChecked()
        expect(screen.queryByTestId('tip-c1')).not.toBeInTheDocument()
        expect(screen.queryByTestId('tip-s1')).not.toBeInTheDocument()
        expect(screen.queryByTestId('tip-s2')).not.toBeInTheDocument()
      })
      // check all children
      await user.click(screen.getByTestId('check-c1'))
      await waitFor(() => {
        expect(screen.getByTestId('check-c1')).toBeChecked()
        expect(screen.getByTestId('check-s1')).toBeChecked()
        expect(screen.getByTestId('check-s2')).toBeChecked()
        expect(screen.getByTestId('tip-c1')).toBeInTheDocument()
        expect(screen.getByTestId('tip-s1')).toBeInTheDocument()
        expect(screen.getByTestId('tip-s2')).toBeInTheDocument()
      })
    })

    it('removes tooltips when role changes to TeacherRole', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {rerender} = render(<EnrollmentTree {...tempProps} />)
      await user.click(screen.getByText('Toggle group TeacherRole'))
      await user.click(screen.getByText('Toggle group History of Art Period 1'))
      expect(screen.getByTestId('tip-c1')).toBeInTheDocument()
      expect(screen.getByTestId('tip-s1')).toBeInTheDocument()
      expect(screen.getByTestId('tip-s2')).toBeInTheDocument()
      // simulate changing role so it’s not a mismatch
      tempProps.selectedRole = {
        id: '4',
        name: 'TeacherEnrollment',
      }
      // using key forces component re-mount to simulate prop updates
      rerender(<EnrollmentTree {...tempProps} key={tempProps.selectedRole.id} />)
      // tooltips should be removed after role change
      await waitFor(() => {
        expect(screen.queryByTestId('tip-c1')).not.toBeInTheDocument()
        expect(screen.queryByTestId('tip-s1')).not.toBeInTheDocument()
        expect(screen.queryByTestId('tip-s2')).not.toBeInTheDocument()
      })
    })
  })
})
