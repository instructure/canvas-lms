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
import {cleanup, render, screen, waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import fetchMock from 'fetch-mock'
import {OutcomeResultSection, OutcomeResultSectionProps} from '../OutcomeResultSection'
import {Outcome, StudentRollupData} from '@canvas/outcomes/react/types/rollup'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

describe('OutcomeResultSection', () => {
  const courseId = '123'
  const studentId = '456'
  const assignmentId = '789'

  const mockOutcomes: Outcome[] = [
    {
      id: 10,
      title: 'Outcome 1',
      display_name: 'Display Name 1',
      calculation_method: 'highest',
      points_possible: 5,
      mastery_points: 3,
      ratings: [
        {points: 5, color: 'green', mastery: true},
        {points: 3, color: 'yellow', mastery: false},
      ],
    },
    {
      id: 20,
      title: 'Outcome 2',
      display_name: 'Display Name 2',
      calculation_method: 'highest',
      points_possible: 10,
      mastery_points: 7,
      ratings: [
        {points: 10, color: 'green', mastery: true},
        {points: 7, color: 'yellow', mastery: false},
      ],
    },
  ]

  const mockRollups: StudentRollupData[] = [
    {
      studentId: '456',
      outcomeRollups: [
        {
          outcomeId: 10,
          score: 4.5,
          rating: {points: 5, color: 'green', mastery: true},
        },
        {
          outcomeId: 20,
          score: 8.0,
          rating: {points: 10, color: 'green', mastery: true},
        },
      ],
    },
  ]

  const mockAlignments = [
    {
      id: 1,
      learning_outcome_id: 10,
      assignment_id: 789,
      submission_types: 'online_text_entry',
      url: '/courses/123/assignments/789',
      title: 'Assignment 1',
    },
    {
      id: 2,
      learning_outcome_id: 20,
      assignment_id: 789,
      submission_types: 'online_upload',
      url: '/courses/123/assignments/789',
      title: 'Assignment 1',
    },
  ]

  const defaultProps: OutcomeResultSectionProps = {
    courseId,
    studentId,
    assignmentId,
    rollups: mockRollups,
    outcomes: mockOutcomes,
  }

  const createWrapper = () => {
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })

    const Wrapper: React.FC<any> = ({children}) => (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    )
    return Wrapper
  }

  beforeEach(() => {
    fetchMock.restore()
    vi.clearAllMocks()
  })

  afterEach(() => {
    cleanup()
    fetchMock.restore()
  })

  describe('successful rendering', () => {
    it('renders aligned outcomes section', async () => {
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}&assignment_id=${assignmentId}`,
        mockAlignments,
      )

      render(<OutcomeResultSection {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText('Aligned Outcomes')).toBeInTheDocument()
      })
    })

    it('displays outcome titles', async () => {
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}&assignment_id=${assignmentId}`,
        mockAlignments,
      )

      render(<OutcomeResultSection {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText('Outcome 1')).toBeInTheDocument()
        expect(screen.getByText('Outcome 2')).toBeInTheDocument()
      })
    })

    it('displays outcome display names', async () => {
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}&assignment_id=${assignmentId}`,
        mockAlignments,
      )

      render(<OutcomeResultSection {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText('Display Name 1')).toBeInTheDocument()
        expect(screen.getByText('Display Name 2')).toBeInTheDocument()
      })
    })

    it('displays outcome scores', async () => {
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}&assignment_id=${assignmentId}`,
        mockAlignments,
      )

      render(<OutcomeResultSection {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText('4.5')).toBeInTheDocument()
        expect(screen.getByText('8.0')).toBeInTheDocument()
      })
    })

    it('renders StudentOutcomeScore components for each outcome', async () => {
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}&assignment_id=${assignmentId}`,
        mockAlignments,
      )

      render(<OutcomeResultSection {...defaultProps} />, {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(screen.getByText('Outcome 1')).toBeInTheDocument()
      })

      // Both outcomes should be rendered with their scores
      expect(screen.getByText('Outcome 1')).toBeInTheDocument()
      expect(screen.getByText('Outcome 2')).toBeInTheDocument()
    })

    it('only displays outcomes that are aligned to the assignment', async () => {
      const alignmentsWithOnlyOne = [mockAlignments[0]]

      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}&assignment_id=${assignmentId}`,
        alignmentsWithOnlyOne,
      )

      render(<OutcomeResultSection {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText('Outcome 1')).toBeInTheDocument()
      })

      expect(screen.queryByText('Outcome 2')).not.toBeInTheDocument()
    })

    it('handles outcomes without scores', async () => {
      const rollupsWithoutScore: StudentRollupData[] = [
        {
          studentId: '456',
          outcomeRollups: [
            {
              outcomeId: 10,
              score: 4.5,
              rating: {points: 5, color: 'green', mastery: true},
            },
            // Outcome 20 has no score
          ],
        },
      ]

      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}&assignment_id=${assignmentId}`,
        mockAlignments,
      )

      render(<OutcomeResultSection {...defaultProps} rollups={rollupsWithoutScore} />, {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(screen.getByText('Outcome 1')).toBeInTheDocument()
        expect(screen.getByText('Outcome 2')).toBeInTheDocument()
      })

      // Outcome 1 should have a score
      expect(screen.getByText('4.5')).toBeInTheDocument()
      // Outcome 2 should not have a score displayed
      expect(screen.queryByText('8.0')).not.toBeInTheDocument()
    })
  })

  describe('loading state', () => {
    it('displays loading spinner while fetching alignments', () => {
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}&assignment_id=${assignmentId}`,
        new Promise(() => {}), // Never resolves
      )

      render(<OutcomeResultSection {...defaultProps} />, {wrapper: createWrapper()})

      expect(screen.getByText('Loading outcome alignments')).toBeInTheDocument()
    })
  })

  describe('error handling', () => {
    it('renders nothing on 500 error', async () => {
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}&assignment_id=${assignmentId}`,
        {status: 500, body: {error: 'Server error'}},
      )

      const {container} = render(<OutcomeResultSection {...defaultProps} />, {
        wrapper: createWrapper(),
      })

      // Wait for the error to be processed
      await waitFor(
        () => {
          expect(container.firstChild).toBeNull()
        },
        {timeout: 3000},
      )

      // Verify no content is rendered
      expect(screen.queryByText('Aligned Outcomes')).not.toBeInTheDocument()
      expect(showFlashAlert).toHaveBeenCalled()
    })

    it('renders nothing on 404 error', async () => {
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}&assignment_id=${assignmentId}`,
        {status: 404},
      )

      const {container} = render(<OutcomeResultSection {...defaultProps} />, {
        wrapper: createWrapper(),
      })

      await waitFor(
        () => {
          expect(container.firstChild).toBeNull()
        },
        {timeout: 3000},
      )

      expect(screen.queryByText('Aligned Outcomes')).not.toBeInTheDocument()
      expect(showFlashAlert).toHaveBeenCalled()
    })

    it('renders nothing on network error', async () => {
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}&assignment_id=${assignmentId}`,
        {throws: new Error('Network error')},
      )

      const {container} = render(<OutcomeResultSection {...defaultProps} />, {
        wrapper: createWrapper(),
      })

      await waitFor(
        () => {
          expect(container.firstChild).toBeNull()
        },
        {timeout: 3000},
      )

      expect(screen.queryByText('Aligned Outcomes')).not.toBeInTheDocument()
      expect(showFlashAlert).toHaveBeenCalled()
    })
  })

  describe('edge cases', () => {
    it('handles empty alignments array', async () => {
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}&assignment_id=${assignmentId}`,
        [],
      )

      render(<OutcomeResultSection {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText('Aligned Outcomes')).toBeInTheDocument()
      })

      // Should not display any outcomes
      expect(screen.queryByText('Outcome 1')).not.toBeInTheDocument()
      expect(screen.queryByText('Outcome 2')).not.toBeInTheDocument()
    })

    it('handles student with no rollup data', async () => {
      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}&assignment_id=${assignmentId}`,
        mockAlignments,
      )

      render(<OutcomeResultSection {...defaultProps} rollups={[]} />, {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(screen.getByText('Outcome 1')).toBeInTheDocument()
      })

      // Outcomes should be displayed but without scores
      expect(screen.queryByText('4.5')).not.toBeInTheDocument()
      expect(screen.queryByText('8.0')).not.toBeInTheDocument()
    })

    it('handles mismatched outcome IDs between alignments and outcomes', async () => {
      const alignmentsWithDifferentId = [
        {
          ...mockAlignments[0],
          learning_outcome_id: 999, // ID that doesn't exist in mockOutcomes
        },
      ]

      fetchMock.get(
        `/api/v1/courses/${courseId}/outcome_alignments?student_id=${studentId}&assignment_id=${assignmentId}`,
        alignmentsWithDifferentId,
      )

      render(<OutcomeResultSection {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText('Aligned Outcomes')).toBeInTheDocument()
      })

      // Should not display any outcomes since no IDs match
      expect(screen.queryByText('Outcome 1')).not.toBeInTheDocument()
      expect(screen.queryByText('Outcome 2')).not.toBeInTheDocument()
    })
  })
})
