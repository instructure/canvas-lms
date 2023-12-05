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
import {EnrollmentTree, type Props} from '../EnrollmentTree'
import type {Enrollment} from '../types'

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
    const {getByText} = render(<EnrollmentTree {...props} />)
    await waitFor(() => expect(getByText('StudentRole')).toBeInTheDocument())
    await waitFor(() => expect(getByText('SubTeacherRole')).toBeInTheDocument())
  })

  it('renders children after clicking toggle', async () => {
    const screen = render(<EnrollmentTree {...props} />)
    await waitFor(() => {
      expect(screen.getByText('Toggle group SubTeacherRole')).toBeInTheDocument()
    })
    const roleGroup = await screen.findByText('Toggle group StudentRole')
    fireEvent.click(roleGroup)
    await waitFor(() => {
      expect(screen.getByText('Apple Music - Section 1')).toBeInTheDocument()
    })
  })

  it('hides children after clicking toggle', async () => {
    const screen = render(<EnrollmentTree {...props} />)
    await waitFor(() => {
      expect(screen.getByText('Toggle group SubTeacherRole')).toBeInTheDocument()
    })
    const roleGroup = screen.getByText('Toggle group StudentRole')
    fireEvent.click(roleGroup)
    expect(await screen.findByText('Apple Music - Section 1')).toBeInTheDocument()

    fireEvent.click(roleGroup)
    expect(screen.queryByText('Apple Music - Section 1')).not.toBeInTheDocument()
  })

  it('renders enrollments in order of base role', async () => {
    const {getByText} = render(<EnrollmentTree {...props} />)
    await waitFor(() => expect(getByText('SubTeacherRole')).toBeInTheDocument())
    const student = getByText('StudentRole')
    const sub = getByText('SubTeacherRole')
    const designer = getByText('DesignRole')
    // SubTeacher is above Designer in list
    expect(sub.compareDocumentPosition(designer)).toBe(4)
    // Designer is above Student in List
    expect(designer.compareDocumentPosition(student)).toBe(4)
  })

  it('selects teacher base roles by default', async () => {
    const {getByText, getByRole} = render(<EnrollmentTree {...props} />)
    await waitFor(() => expect(getByText('SubTeacherRole')).toBeInTheDocument())

    const checkedBox = getByRole('checkbox', {checked: true})
    expect(checkedBox.getAttribute('data-testid')).toMatch('check r2')
  })

  it('does not select unpublished course enrollments by default', async () => {
    const {queryByText, getByTestId} = render(<EnrollmentTree {...props} />)

    expect(queryByText('TeacherRole')).toBeInTheDocument()
    expect(queryByText('SubTeacherRole')).toBeInTheDocument()

    const subTeacherCheckbox = getByTestId('check r2') as HTMLInputElement
    expect(subTeacherCheckbox.checked).toBe(true)
    const teacherCheckbox = getByTestId('check r4') as HTMLInputElement
    expect(teacherCheckbox.checked).toBe(false)

    expect(queryByText('Toggle group TeacherRole')).toBeInTheDocument()
    expect(queryByText('Toggle group SubTeacherRole')).toBeInTheDocument()
  })

  it('shows enrollments in one section with different roles under respective role groups', async () => {
    const screen = render(<EnrollmentTree {...props} />)
    await waitFor(() => {
      expect(screen.getByText('Toggle group StudentRole')).toBeInTheDocument()
    })
    const studentGroup = screen.getByText('Toggle group StudentRole')
    fireEvent.click(studentGroup)
    await waitFor(() => {
      expect(screen.getByText('Apple Music - Section 1')).toBeInTheDocument()
    })
    const designerGroup = screen.getByText('Toggle group DesignRole')
    fireEvent.click(designerGroup)
    await waitFor(() => {
      expect(screen.getByText('Apple Music - Section 2')).toBeInTheDocument()
    })
  })

  it('checks children when group is checked', async () => {
    const {getByText, getAllByRole, getByTestId} = render(<EnrollmentTree {...props} />)
    await waitFor(() => expect(getByText('SubTeacherRole')).toBeInTheDocument())
    const parentBox = getByTestId('check r1')
    fireEvent.click(parentBox)

    // includes default teacher check
    await waitFor(() => expect(getAllByRole('checkbox', {checked: true}).length).toBe(2))
    fireEvent.click(getByText('Toggle group StudentRole'))
    const allChecked = getAllByRole('checkbox', {checked: true})
    // parent + child + default
    expect(allChecked.length).toBe(3)
  })

  it('calls createEnroll when available', async () => {
    const {getByText} = render(<EnrollmentTree {...props} />)
    await waitFor(() => expect(getByText('SubTeacherRole')).toBeInTheDocument())
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
      const {queryByText, getByTestId} = render(<EnrollmentTree {...tempProps} />)

      expect(queryByText('StudentRole')).toBeInTheDocument()
      expect(queryByText('SubTeacherRole')).toBeInTheDocument()
      expect(queryByText('DesignRole')).toBeInTheDocument()

      const studentCheckbox = getByTestId('check r1') as HTMLInputElement
      expect(studentCheckbox.checked).toBe(true)
      const teacherCheckbox = getByTestId('check r2') as HTMLInputElement
      expect(teacherCheckbox.checked).toBe(true)
      const designCheckbox = getByTestId('check r3') as HTMLInputElement
      expect(designCheckbox.checked).toBe(false)

      expect(queryByText('Toggle group StudentRole')).toBeInTheDocument()
      expect(queryByText('Toggle group SubTeacherRole')).toBeInTheDocument()
      expect(queryByText('Toggle group DesignRole')).toBeInTheDocument()
    })
  })
})
