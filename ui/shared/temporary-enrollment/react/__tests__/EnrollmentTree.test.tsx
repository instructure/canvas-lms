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
import {render, screen} from '@testing-library/react'
import {EnrollmentTree, type Props} from '../EnrollmentTree'
import type {Enrollment} from '../types'
import userEvent from '@testing-library/user-event'

const mockEnrollment = {
  enrollment_state: 'active',
  course_id: '',
  course_section_id: '',
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
      role: 'StudentEnrollment',
      label: 'StudentRole',
      base_role_name: 'StudentEnrollment',
    },
    {
      id: '2',
      role: 'TeacherEnrollment',
      label: 'SubTeacherRole',
      base_role_name: 'TeacherEnrollment',
    },
    {
      id: '3',
      role: 'DesignerEnrollment',
      label: 'DesignRole',
      base_role_name: 'DesignerEnrollment',
    },
    {
      id: '4',
      role: 'CustomTeacherEnrollment',
      label: 'TeacherRole',
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
    render(<EnrollmentTree {...props} />)
    expect(await screen.findByText('Toggle group SubTeacherRole')).toBeInTheDocument()
    userEvent.click(await screen.findByText('Toggle group StudentRole'))
    expect(await screen.findByText('Apple Music - Section 1')).toBeInTheDocument()
  })

  it('hides children after clicking toggle', async () => {
    render(<EnrollmentTree {...props} />)
    expect(await screen.findByText('Toggle group SubTeacherRole')).toBeInTheDocument()
    userEvent.click(screen.getByText('Toggle group StudentRole'))
    expect(await screen.findByText('Apple Music - Section 1')).toBeInTheDocument()
    userEvent.click(screen.getByText('Toggle group StudentRole'))
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
    expect(checkedBox.getAttribute('data-testid')).toMatch('check r2')
  })

  it('does not select unpublished course enrollments by default', async () => {
    render(<EnrollmentTree {...props} />)
    expect(screen.queryByText('TeacherRole')).toBeInTheDocument()
    expect(screen.queryByText('SubTeacherRole')).toBeInTheDocument()
    expect((screen.getByTestId('check r2') as HTMLInputElement).checked).toBe(true)
    expect((screen.getByTestId('check r4') as HTMLInputElement).checked).toBe(false)
    expect(screen.queryByText('Toggle group TeacherRole')).toBeInTheDocument()
    expect(screen.queryByText('Toggle group SubTeacherRole')).toBeInTheDocument()
  })

  it('shows enrollments in one section with different roles under respective role groups', async () => {
    render(<EnrollmentTree {...props} />)
    await screen.findByText('Toggle group StudentRole')
    userEvent.click(screen.getByText('Toggle group StudentRole'))
    expect(screen.queryByText('Apple Music - Section 1')).toBeInTheDocument()
    userEvent.click(screen.getByText('Toggle group DesignRole'))
    expect(screen.queryByText('Apple Music - Section 2')).toBeInTheDocument()
  })

  it('checks children when group is checked', async () => {
    render(<EnrollmentTree {...props} />)
    expect(screen.queryByText('SubTeacherRole')).toBeInTheDocument()
    userEvent.click(screen.getByTestId('check r1'))
    // includes default teacher check
    expect(screen.getAllByRole('checkbox', {checked: true}).length).toBe(2)
    userEvent.click(screen.getByText('Toggle group StudentRole'))
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
      const studentCheckbox = screen.getByTestId('check r1') as HTMLInputElement
      expect(studentCheckbox.checked).toBe(true)
      const teacherCheckbox = screen.getByTestId('check r2') as HTMLInputElement
      expect(teacherCheckbox.checked).toBe(true)
      const designCheckbox = screen.getByTestId('check r3') as HTMLInputElement
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

    it('renders multiple courses with the same label', () => {
      render(<EnrollmentTree {...tempProps} />)
      userEvent.click(screen.getByText('Toggle group SubTeacherRole'))
      expect(screen.getAllByText('Second Grade Math - Second Grade Math')).toHaveLength(3)
    })
  })
})
