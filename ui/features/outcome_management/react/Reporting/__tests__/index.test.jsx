// @vitest-environment jsdom
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

import React from 'react'
import {render, screen, waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {useStudentMasteryScores} from '@canvas/outcomes/react/hooks/useStudentMasteryScores'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import Reporting from '../index'
import useRollups from '@canvas/outcomes/react/hooks/useRollups'

jest.mock('@canvas/outcomes/react/hooks/useCanvasContext')
jest.mock('@canvas/outcomes/react/hooks/useStudentMasteryScores')
jest.mock('@canvas/outcomes/react/hooks/useRollups')

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
    },
  },
})

const renderReporting = (props = {}) =>
  render(
    <QueryClientProvider client={queryClient}>
      <Reporting {...props} />
    </QueryClientProvider>,
  )

describe('Reporting', () => {
  const mockStudent = {
    id: '123',
    name: 'Jane Smith',
    login_id: 'jane.smith@example.com',
    avatar_url: 'https://example.com/avatar.jpg',
  }

  const mockScores = {
    grossAverage: 3.5,
    masteryRelativeAverage: 0.5,
    averageText: 'Mastery',
    averageIconURL: '/images/outcomes/mastery.svg',
    buckets: {
      no_evidence: {name: 'No Evidence', iconURL: '/images/outcomes/no_evidence.svg', count: 2},
      remediation: {name: 'Remediation', iconURL: '/images/outcomes/remediation.svg', count: 1},
      near_mastery: {name: 'Near Mastery', iconURL: '/images/outcomes/near_mastery.svg', count: 3},
      mastery: {name: 'Mastery', iconURL: '/images/outcomes/mastery.svg', count: 5},
      exceeds_mastery: {
        name: 'Exceeds Mastery',
        iconURL: '/images/outcomes/exceeds_mastery.svg',
        count: 4,
      },
    },
  }

  let mockSearch = '?student_id=123'
  const originalURLSearchParams = global.URLSearchParams

  beforeAll(() => {
    global.URLSearchParams = class extends originalURLSearchParams {
      constructor(_search) {
        super(mockSearch)
      }
    }
  })

  afterAll(() => {
    global.URLSearchParams = originalURLSearchParams
  })

  beforeEach(() => {
    mockSearch = '?student_id=123'

    useCanvasContext.mockReturnValue({
      contextId: '1',
      accountLevelMasteryScalesFF: true,
    })
  })

  afterEach(() => {
    jest.clearAllMocks()
    queryClient.clear()
  })

  it('renders empty view when no student_id is in URL', () => {
    mockSearch = ''
    useRollups.mockReturnValue({
      outcomes: [],
      rollups: [],
      students: [],
      isLoading: false,
      error: null,
    })
    useStudentMasteryScores.mockReturnValue(null)

    renderReporting()

    expect(screen.getByTestId('outcome-reporting')).toBeInTheDocument()
    expect(screen.queryByTestId('student-mastery-header')).not.toBeInTheDocument()
  })

  it('shows loading spinner while fetching data', () => {
    useRollups.mockReturnValue({
      outcomes: [],
      rollups: [],
      students: [],
      isLoading: true,
      error: null,
    })
    useStudentMasteryScores.mockReturnValue(null)

    renderReporting()

    expect(screen.getByText(/Loading student details/i)).toBeInTheDocument()
  })

  it('renders StudentMasteryHeader with student data when loaded', async () => {
    useRollups.mockReturnValue({
      outcomes: [],
      rollups: [],
      students: [mockStudent],
      isLoading: false,
      error: null,
    })
    useStudentMasteryScores.mockReturnValue(mockScores)

    renderReporting()

    await waitFor(() => {
      expect(screen.getByText('Jane Smith')).toBeInTheDocument()
    })
  })

  it('renders StudentMasteryHeader with correct mastery level', async () => {
    useRollups.mockReturnValue({
      outcomes: [],
      rollups: [],
      students: [mockStudent],
      isLoading: false,
      error: null,
    })
    useStudentMasteryScores.mockReturnValue(mockScores)

    renderReporting()

    await waitFor(() => {
      expect(screen.getByText('3.5')).toBeInTheDocument()
      // Use getAllByText since "Mastery" appears multiple times (screen readers + visible)
      expect(screen.getAllByText('Mastery').length).toBeGreaterThan(0)
    })
  })

  it('renders StudentMasteryHeader with buckets', async () => {
    useRollups.mockReturnValue({
      outcomes: [],
      rollups: [],
      students: [mockStudent],
      isLoading: false,
      error: null,
    })
    useStudentMasteryScores.mockReturnValue(mockScores)

    renderReporting()

    await waitFor(() => {
      expect(screen.getByText('2')).toBeInTheDocument() // No Evidence count
      expect(screen.getByText('5')).toBeInTheDocument() // Mastery count
    })
  })

  it('does not render StudentMasteryHeader when student not found', async () => {
    useRollups.mockReturnValue({
      outcomes: [],
      rollups: [],
      students: [],
      isLoading: false,
      error: null,
    })
    useStudentMasteryScores.mockReturnValue(null)

    renderReporting()

    await waitFor(() => {
      expect(screen.queryByTestId('student-mastery-header')).not.toBeInTheDocument()
    })
  })

  it('does not render StudentMasteryHeader when scores are null', async () => {
    useRollups.mockReturnValue({
      outcomes: [],
      rollups: [],
      students: [mockStudent],
      isLoading: false,
      error: null,
    })
    useStudentMasteryScores.mockReturnValue(null)

    renderReporting()

    await waitFor(() => {
      expect(screen.queryByTestId('student-mastery-header')).not.toBeInTheDocument()
    })
  })

  it('calls useRollups with correct parameters', () => {
    useRollups.mockReturnValue({
      outcomes: [],
      rollups: [],
      students: [],
      isLoading: false,
      error: null,
    })
    useStudentMasteryScores.mockReturnValue(null)

    renderReporting()

    expect(useRollups).toHaveBeenCalledWith({
      courseId: '1',
      accountMasteryScalesEnabled: true,
      enabled: true,
      selectedUserIds: [123],
    })
  })

  it('calls useStudentMasteryScores with correct parameters', async () => {
    useRollups.mockReturnValue({
      outcomes: [{id: '1', title: 'Outcome 1'}],
      rollups: [{studentId: '123', outcomeRollups: []}],
      students: [mockStudent],
      isLoading: false,
      error: null,
    })
    useStudentMasteryScores.mockReturnValue(mockScores)

    renderReporting()

    await waitFor(() => {
      expect(useStudentMasteryScores).toHaveBeenCalledWith({
        student: mockStudent,
        outcomes: [{id: '1', title: 'Outcome 1'}],
        rollups: [{studentId: '123', outcomeRollups: []}],
      })
    })
  })

  it('parses student_id from URL correctly', () => {
    mockSearch = '?student_id=456'
    useRollups.mockReturnValue({
      outcomes: [],
      rollups: [],
      students: [],
      isLoading: false,
      error: null,
    })
    useStudentMasteryScores.mockReturnValue(null)

    renderReporting()

    expect(useRollups).toHaveBeenCalledWith(
      expect.objectContaining({
        selectedUserIds: [456],
      }),
    )
  })

  it('handles missing student gracefully', async () => {
    mockSearch = '?student_id=999'
    useRollups.mockReturnValue({
      outcomes: [],
      rollups: [],
      students: [mockStudent],
      isLoading: false,
      error: null,
    })
    useStudentMasteryScores.mockReturnValue(null)

    renderReporting()

    await waitFor(() => {
      expect(screen.queryByTestId('student-mastery-header')).not.toBeInTheDocument()
    })
  })

  it('renders the "All Students" link with correct href', () => {
    const {getByTestId} = render(<Reporting />)
    const link = getByTestId('all-students-link')
    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute('href', 'gradebook')
  })
})
