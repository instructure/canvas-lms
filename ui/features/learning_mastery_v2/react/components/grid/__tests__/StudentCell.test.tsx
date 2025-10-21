/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {render} from '@testing-library/react'
import {StudentCell, StudentCellProps} from '../StudentCell'
import {Student} from '../../../types/rollup'
import {SecondaryInfoDisplay, NameDisplayFormat} from '../../../utils/constants'
import {MOCK_STUDENTS} from '../../../__fixtures__/rollups'

describe('StudentCell', () => {
  const defaultProps = (props: Partial<StudentCellProps> = {}): StudentCellProps => ({
    student: {
      status: 'active',
      name: 'Student Test',
      display_name: 'Student Test',
      sortable_name: 'Test, Student',
      avatar_url: '/avatar-url',
      id: '1',
    } as Student,
    courseId: '100',
    ...props,
  })

  it("renders the student's name", () => {
    const {getByText} = render(<StudentCell {...defaultProps()} />)
    expect(getByText('Student Test')).toBeInTheDocument()
  })

  it("renders an image with the student's avatar_url", () => {
    const {getByTestId} = render(<StudentCell {...defaultProps()} />)
    expect(getByTestId('student-avatar')).toBeInTheDocument()
  })

  it('renders a link to the student learning mastery gradebook', () => {
    const props = defaultProps()
    const {getByTestId} = render(<StudentCell {...props} />)
    expect((getByTestId('student-cell-link') as HTMLAnchorElement).href).toMatch(
      `/courses/${props.courseId}/grades/${props.student.id}#tab-outcomes`,
    )
  })

  describe('student status', () => {
    const getTestStudent = (status: string): Student =>
      ({
        status,
        name: 'Student Test',
        display_name: 'Student Test',
        sortable_name: 'Test, Student',
        avatar_url: '/avatar-url',
        id: '1',
      }) as Student

    it('does not render student status label when student active', () => {
      const {queryByTestId} = render(
        <StudentCell {...defaultProps({student: getTestStudent('active')})} />,
      )
      expect(queryByTestId('student-status')).not.toBeInTheDocument()
    })

    it('renders student status label when student is inactive', () => {
      const {getByTestId} = render(
        <StudentCell {...defaultProps({student: getTestStudent('inactive')})} />,
      )
      expect(getByTestId('student-status')).toBeInTheDocument()
    })

    it('renders student status label when student is concluded', () => {
      const {getByTestId} = render(
        <StudentCell {...defaultProps({student: getTestStudent('concluded')})} />,
      )
      expect(getByTestId('student-status')).toBeInTheDocument()
    })
  })

  it('does not render student avatar when showStudentAvatar is false', () => {
    const {queryByTestId} = render(<StudentCell {...defaultProps({showStudentAvatar: false})} />)
    expect(queryByTestId('student-avatar')).not.toBeInTheDocument()
  })

  describe('secondary info display', () => {
    it('does not render secondary info when not specified', () => {
      const {queryByTestId} = render(<StudentCell {...defaultProps()} />)
      expect(queryByTestId('student-secondary-info')).not.toBeInTheDocument()
    })

    it('renders SIS ID when specified', () => {
      const {getByTestId} = render(
        <StudentCell
          {...defaultProps({secondaryInfoDisplay: SecondaryInfoDisplay.SIS_ID})}
          student={{...MOCK_STUDENTS[0], sis_id: 'SIS123'}}
        />,
      )
      expect(getByTestId('student-secondary-info')).toHaveTextContent('SIS123')
    })

    it('renders integration ID when specified', () => {
      const {getByTestId} = render(
        <StudentCell
          {...defaultProps({secondaryInfoDisplay: SecondaryInfoDisplay.INTEGRATION_ID})}
          student={{...MOCK_STUDENTS[0], integration_id: 'INT123'}}
        />,
      )
      expect(getByTestId('student-secondary-info')).toHaveTextContent('INT123')
    })

    it('renders login ID when specified', () => {
      const {getByTestId} = render(
        <StudentCell
          {...defaultProps({secondaryInfoDisplay: SecondaryInfoDisplay.LOGIN_ID})}
          student={{...MOCK_STUDENTS[0], login_id: 'LOGIN123'}}
        />,
      )
      expect(getByTestId('student-secondary-info')).toHaveTextContent('LOGIN123')
    })
  })

  describe('name display format', () => {
    it('renders sortable_name when format is LAST_FIRST', () => {
      const {getByText} = render(
        <StudentCell {...defaultProps({nameDisplayFormat: NameDisplayFormat.LAST_FIRST})} />,
      )
      expect(getByText('Test, Student')).toBeInTheDocument()
    })

    it('renders display_name when format is FIRST_LAST', () => {
      const {getByText} = render(
        <StudentCell {...defaultProps({nameDisplayFormat: NameDisplayFormat.FIRST_LAST})} />,
      )
      expect(getByText('Student Test')).toBeInTheDocument()
    })

    it('renders display_name by default when nameDisplayFormat is not provided', () => {
      const {getByText} = render(<StudentCell {...defaultProps({nameDisplayFormat: undefined})} />)
      expect(getByText('Student Test')).toBeInTheDocument()
    })
  })
})
