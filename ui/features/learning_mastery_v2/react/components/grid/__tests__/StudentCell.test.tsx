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

import React from 'react'
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {StudentCell, StudentCellProps} from '../StudentCell'
import {Student} from '@canvas/outcomes/react/types/rollup'
import {SecondaryInfoDisplay, NameDisplayFormat} from '@canvas/outcomes/react/utils/constants'
import {MOCK_STUDENTS} from '../../../__fixtures__/rollups'

const server = setupServer()

// Helper to render with QueryClientProvider
const renderWithQueryClient = (ui: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })
  return render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>)
}

describe('StudentCell', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())
  afterEach(() => server.resetHandlers())

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
    const {getByText} = renderWithQueryClient(<StudentCell {...defaultProps()} />)
    expect(getByText('Student Test')).toBeInTheDocument()
  })

  it("renders an image with the student's avatar_url", () => {
    const {getByTestId} = renderWithQueryClient(<StudentCell {...defaultProps()} />)
    expect(getByTestId('student-avatar')).toBeInTheDocument()
  })

  it('renders a clickable link that opens a popover', async () => {
    const user = userEvent.setup()
    const props = defaultProps()

    // Mock the API call for user details
    server.use(
      http.get('/api/v1/courses/:courseId/users/:userId/lmgb_user_details', () => {
        return HttpResponse.json({
          course: {
            name: 'Test Course',
          },
          user: {
            sections: [{id: 1, name: 'Section 1'}],
            last_login: '2024-01-01T12:00:00Z',
          },
        })
      }),
    )

    const {getByTestId} = renderWithQueryClient(<StudentCell {...props} />)
    const link = getByTestId('student-cell-link')

    // Link should be clickable but not navigate away
    expect(link).toBeInTheDocument()

    // Click the link to open popover
    await user.click(link)

    // Wait for the popover content to load
    await waitFor(() => {
      expect(screen.getByText('Message')).toBeInTheDocument()
    })

    expect(screen.getByText('View Mastery Report')).toBeInTheDocument()
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
      const {queryByTestId} = renderWithQueryClient(
        <StudentCell {...defaultProps({student: getTestStudent('active')})} />,
      )
      expect(queryByTestId('student-status')).not.toBeInTheDocument()
    })

    it('renders student status label when student is inactive', () => {
      const {getByTestId} = renderWithQueryClient(
        <StudentCell {...defaultProps({student: getTestStudent('inactive')})} />,
      )
      expect(getByTestId('student-status')).toBeInTheDocument()
    })

    it('renders student status label when student is concluded', () => {
      const {getByTestId} = renderWithQueryClient(
        <StudentCell {...defaultProps({student: getTestStudent('concluded')})} />,
      )
      expect(getByTestId('student-status')).toBeInTheDocument()
    })
  })

  it('does not render student avatar when showStudentAvatar is false', () => {
    const {queryByTestId} = renderWithQueryClient(
      <StudentCell {...defaultProps({showStudentAvatar: false})} />,
    )
    expect(queryByTestId('student-avatar')).not.toBeInTheDocument()
  })

  describe('secondary info display', () => {
    it('does not render secondary info when not specified', () => {
      const {queryByTestId} = renderWithQueryClient(<StudentCell {...defaultProps()} />)
      expect(queryByTestId('student-secondary-info')).not.toBeInTheDocument()
    })

    it('renders SIS ID when specified', () => {
      const {getByTestId} = renderWithQueryClient(
        <StudentCell
          {...defaultProps({secondaryInfoDisplay: SecondaryInfoDisplay.SIS_ID})}
          student={{...MOCK_STUDENTS[0], sis_id: 'SIS123'}}
        />,
      )
      expect(getByTestId('student-secondary-info')).toHaveTextContent('SIS123')
    })

    it('renders integration ID when specified', () => {
      const {getByTestId} = renderWithQueryClient(
        <StudentCell
          {...defaultProps({secondaryInfoDisplay: SecondaryInfoDisplay.INTEGRATION_ID})}
          student={{...MOCK_STUDENTS[0], integration_id: 'INT123'}}
        />,
      )
      expect(getByTestId('student-secondary-info')).toHaveTextContent('INT123')
    })

    it('renders login ID when specified', () => {
      const {getByTestId} = renderWithQueryClient(
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
      const {getByText} = renderWithQueryClient(
        <StudentCell {...defaultProps({nameDisplayFormat: NameDisplayFormat.LAST_FIRST})} />,
      )
      expect(getByText('Test, Student')).toBeInTheDocument()
    })

    it('renders display_name when format is FIRST_LAST', () => {
      const {getByText} = renderWithQueryClient(
        <StudentCell {...defaultProps({nameDisplayFormat: NameDisplayFormat.FIRST_LAST})} />,
      )
      expect(getByText('Student Test')).toBeInTheDocument()
    })

    it('renders display_name by default when nameDisplayFormat is not provided', () => {
      const {getByText} = renderWithQueryClient(
        <StudentCell {...defaultProps({nameDisplayFormat: undefined})} />,
      )
      expect(getByText('Student Test')).toBeInTheDocument()
    })
  })
})
