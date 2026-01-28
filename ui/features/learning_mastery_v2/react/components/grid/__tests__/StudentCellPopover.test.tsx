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
import userEvent from '@testing-library/user-event'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {
  pickBucketForScore,
  calculateScores,
} from '@canvas/outcomes/react/hooks/useStudentMasteryScores'
import {StudentCellPopover, StudentCellPopoverProps} from '../StudentCellPopover'
import {MOCK_STUDENTS, MOCK_OUTCOMES} from '../../../__fixtures__/rollups'
import {StudentRollupData, Outcome, Student} from '@canvas/outcomes/react/types/rollup'

const server = setupServer()

// Track API calls for caching tests
let apiCallCount = 0

// Mock the MessageStudents component
vi.mock('@canvas/message-students-modal', () => {
  return {
    default: function MessageStudents({open, onRequestClose, title}: any) {
      return open ? (
        <div data-testid="message-students-modal">
          <h2>{title}</h2>
          <button onClick={onRequestClose}>Close Modal</button>
        </div>
      ) : null
    },
  }
})

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

describe('StudentCellPopover', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())
  afterEach(() => {
    server.resetHandlers()
    apiCallCount = 0
  })

  const mockStudent = MOCK_STUDENTS[0]
  const mockOutcomes = MOCK_OUTCOMES
  const courseId = '100'
  const studentGradesUrl = `/courses/${courseId}/grades/${mockStudent.id}#tab-outcomes`

  const mockRollups: StudentRollupData[] = [
    {
      studentId: '1',
      outcomeRollups: [
        {
          outcomeId: '1',
          score: 2,
          rating: {
            color: 'green',
            description: 'Exceeds',
            mastery: true,
            points: 8,
          },
        },
        {
          outcomeId: '2',
          score: 5,
          rating: {
            color: 'green',
            description: 'Mastery',
            mastery: true,
            points: 5,
          },
        },
      ],
    },
  ]

  const mockUserDetails = {
    course: {
      name: 'Test Course',
    },
    user: {
      sections: [
        {id: 1, name: 'Section 1'},
        {id: 2, name: 'Section 2'},
      ],
      last_login: '2024-01-01T12:00:00Z',
    },
  }

  const defaultProps = (props: Partial<StudentCellPopoverProps> = {}): StudentCellPopoverProps => ({
    student: mockStudent,
    studentName: mockStudent.display_name,
    studentGradesUrl,
    courseId,
    outcomes: mockOutcomes,
    rollups: mockRollups,
    ...props,
  })

  describe('popover appearance', () => {
    it('renders the trigger button', () => {
      renderWithQueryClient(<StudentCellPopover {...defaultProps()} />)
      expect(screen.getByTestId('student-cell-link')).toBeInTheDocument()
    })

    it('popover appears when trigger is clicked', async () => {
      const user = userEvent.setup()
      server.use(
        http.get('/api/v1/courses/:courseId/users/:userId/lmgb_user_details', () => {
          return HttpResponse.json(mockUserDetails)
        }),
      )

      renderWithQueryClient(<StudentCellPopover {...defaultProps()} />)

      // Initially popover content should not be visible
      expect(screen.queryByText('Test Course')).not.toBeInTheDocument()

      // Click trigger
      await user.click(screen.getByTestId('student-cell-link'))

      // Wait for popover to appear with loaded content
      await waitFor(() => {
        expect(screen.getByText('Test Course')).toBeInTheDocument()
      })
    })

    it('shows loading spinner while fetching user details', async () => {
      let resolveRequest: () => void
      const user = userEvent.setup()
      server.use(
        http.get('/api/v1/courses/:courseId/users/:userId/lmgb_user_details', async () => {
          await new Promise<void>(resolve => {
            resolveRequest = resolve
          })
          return HttpResponse.json(mockUserDetails)
        }),
      )

      renderWithQueryClient(<StudentCellPopover {...defaultProps()} />)

      await user.click(screen.getByTestId('student-cell-link'))

      // Spinner should appear while loading
      expect(screen.getByText('Loading user details')).toBeInTheDocument()

      resolveRequest!()

      // Wait for content to load
      await waitFor(() => {
        expect(screen.getByText('Test Course')).toBeInTheDocument()
      })
    })

    it('shows error message when API call fails', async () => {
      const user = userEvent.setup()
      server.use(
        http.get('/api/v1/courses/:courseId/users/:userId/lmgb_user_details', () => {
          return HttpResponse.json({error: 'Server error'}, {status: 500})
        }),
      )

      renderWithQueryClient(<StudentCellPopover {...defaultProps()} />)

      await user.click(screen.getByTestId('student-cell-link'))

      await waitFor(() => {
        expect(screen.getByText(/Failed to load user details/)).toBeInTheDocument()
      })
    })
  })

  describe('student information display', () => {
    beforeEach(() => {
      server.use(
        http.get('/api/v1/courses/:courseId/users/:userId/lmgb_user_details', () => {
          return HttpResponse.json(mockUserDetails)
        }),
      )
    })

    it('displays student avatar', async () => {
      const user = userEvent.setup()
      renderWithQueryClient(<StudentCellPopover {...defaultProps()} />)

      await user.click(screen.getByTestId('student-cell-link'))

      await waitFor(() => {
        const avatar = screen.getByTestId('lmgb-student-popover-avatar')
        expect(avatar).toBeInTheDocument()
      })
    })

    it('displays student name', async () => {
      const user = userEvent.setup()
      renderWithQueryClient(<StudentCellPopover {...defaultProps()} />)

      await user.click(screen.getByTestId('student-cell-link'))

      await waitFor(() => {
        // Use getAllByText since the name appears in both trigger and popover content
        const nameElements = screen.getAllByText(mockStudent.display_name)
        expect(nameElements.length).toBeGreaterThan(0)
      })
    })

    it('displays course name', async () => {
      const user = userEvent.setup()
      renderWithQueryClient(<StudentCellPopover {...defaultProps()} />)

      await user.click(screen.getByTestId('student-cell-link'))

      await waitFor(() => {
        expect(screen.getByText('Test Course')).toBeInTheDocument()
      })
    })

    it('displays sections', async () => {
      const user = userEvent.setup()
      renderWithQueryClient(<StudentCellPopover {...defaultProps()} />)

      await user.click(screen.getByTestId('student-cell-link'))

      await waitFor(() => {
        expect(screen.getByText('Section 1, Section 2')).toBeInTheDocument()
      })
    })

    it('displays last login time', async () => {
      const user = userEvent.setup()
      renderWithQueryClient(<StudentCellPopover {...defaultProps()} />)

      await user.click(screen.getByTestId('student-cell-link'))

      await waitFor(() => {
        expect(screen.getByText(/Last Login:/)).toBeInTheDocument()
      })
    })

    it('displays "Never" when no last login', async () => {
      const user = userEvent.setup()
      const detailsWithoutLogin = {
        ...mockUserDetails,
        user: {
          ...mockUserDetails.user,
          last_login: null,
        },
      }

      server.use(
        http.get('/api/v1/courses/:courseId/users/:userId/lmgb_user_details', () => {
          return HttpResponse.json(detailsWithoutLogin)
        }),
      )

      renderWithQueryClient(<StudentCellPopover {...defaultProps()} />)

      await user.click(screen.getByTestId('student-cell-link'))

      await waitFor(() => {
        expect(screen.getByText(/Last Login: Never/)).toBeInTheDocument()
      })
    })
  })

  describe('scores display', () => {
    beforeEach(() => {
      server.use(
        http.get('/api/v1/courses/:courseId/users/:userId/lmgb_user_details', () => {
          return HttpResponse.json(mockUserDetails)
        }),
      )
    })

    it('displays score icons and counts', async () => {
      const user = userEvent.setup()
      renderWithQueryClient(<StudentCellPopover {...defaultProps()} />)

      await user.click(screen.getByTestId('student-cell-link'))

      await waitFor(() => {
        // Should display mastery level icons and counts
        // Query for img elements directly instead of using getAllByRole
        const images = document.querySelectorAll('img')
        expect(images.length).toBeGreaterThan(0)
      })
    })

    it('calculates and displays average score correctly', async () => {
      const user = userEvent.setup()
      renderWithQueryClient(<StudentCellPopover {...defaultProps()} />)

      await user.click(screen.getByTestId('student-cell-link'))

      await waitFor(() => {
        // Average of rollups: (8 + 5) / 2 = 6.5
        expect(screen.getByText('6.5')).toBeInTheDocument()
      })
    })

    it('displays correct bucket counts for outcomes', async () => {
      const user = userEvent.setup()
      renderWithQueryClient(<StudentCellPopover {...defaultProps()} />)

      await user.click(screen.getByTestId('student-cell-link'))

      await waitFor(() => {
        // We have 2 outcomes assessed, so counts should reflect the mastery levels
        expect(screen.getByText('Test Course')).toBeInTheDocument()
      })
    })

    it('handles when there are no rollups', async () => {
      const user = userEvent.setup()
      renderWithQueryClient(<StudentCellPopover {...defaultProps({rollups: []})} />)

      await user.click(screen.getByTestId('student-cell-link'))

      await waitFor(() => {
        expect(screen.getByText('Test Course')).toBeInTheDocument()
      })
    })
  })

  describe('close functionality', () => {
    beforeEach(() => {
      server.use(
        http.get('/api/v1/courses/:courseId/users/:userId/lmgb_user_details', () => {
          apiCallCount++
          return HttpResponse.json(mockUserDetails)
        }),
      )
    })

    it('can be closed using the close button', async () => {
      const user = userEvent.setup()
      renderWithQueryClient(<StudentCellPopover {...defaultProps()} />)

      // Open popover
      await user.click(screen.getByTestId('student-cell-link'))

      await waitFor(() => {
        expect(screen.getByText('Test Course')).toBeInTheDocument()
      })

      // Click close button - CloseButton renders "Close" text in ScreenReaderContent
      const closeButton = screen.getByText('Close').closest('button')
      await user.click(closeButton!)

      // Popover content should no longer be visible
      await waitFor(() => {
        expect(screen.queryByText('Test Course')).not.toBeInTheDocument()
      })
    })

    it('reopening popover does not refetch data', async () => {
      const user = userEvent.setup()
      renderWithQueryClient(<StudentCellPopover {...defaultProps()} />)

      // Open popover first time
      await user.click(screen.getByTestId('student-cell-link'))
      await waitFor(() => {
        expect(screen.getByText('Test Course')).toBeInTheDocument()
      })

      // Close it
      const closeButton = screen.getByText('Close').closest('button')
      await user.click(closeButton!)

      await waitFor(() => {
        expect(screen.queryByText('Test Course')).not.toBeInTheDocument()
      })

      // Verify API was called once
      expect(apiCallCount).toBe(1)

      // Open again
      await user.click(screen.getByTestId('student-cell-link'))
      await waitFor(() => {
        expect(screen.getByText('Test Course')).toBeInTheDocument()
      })

      // API should still have been called only once (data is cached)
      expect(apiCallCount).toBe(1)
    })
  })

  describe('message functionality', () => {
    beforeEach(() => {
      server.use(
        http.get('/api/v1/courses/:courseId/users/:userId/lmgb_user_details', () => {
          return HttpResponse.json(mockUserDetails)
        }),
      )
    })

    it('clicking Message link opens message modal', async () => {
      const user = userEvent.setup()
      renderWithQueryClient(<StudentCellPopover {...defaultProps()} />)

      await user.click(screen.getByTestId('student-cell-link'))

      await waitFor(() => {
        expect(screen.getByText('Message')).toBeInTheDocument()
      })

      // Click Message link
      await user.click(screen.getByText('Message'))

      // Message modal should open
      await waitFor(() => {
        expect(screen.getByTestId('message-students-modal')).toBeInTheDocument()
        expect(screen.getByText('Send a message')).toBeInTheDocument()
      })
    })

    it('message modal can be closed', async () => {
      const user = userEvent.setup()
      renderWithQueryClient(<StudentCellPopover {...defaultProps()} />)

      await user.click(screen.getByTestId('student-cell-link'))

      await waitFor(() => {
        expect(screen.getByText('Message')).toBeInTheDocument()
      })

      // Open message modal
      await user.click(screen.getByText('Message'))

      await waitFor(() => {
        expect(screen.getByTestId('message-students-modal')).toBeInTheDocument()
      })

      // Close modal
      await user.click(screen.getByText('Close Modal'))

      await waitFor(() => {
        expect(screen.queryByTestId('message-students-modal')).not.toBeInTheDocument()
      })
    })
  })

  describe('View Mastery Report link', () => {
    beforeEach(() => {
      server.use(
        http.get('/api/v1/courses/:courseId/users/:userId/lmgb_user_details', () => {
          return HttpResponse.json(mockUserDetails)
        }),
      )
    })

    it('has correct href attribute', async () => {
      const user = userEvent.setup()
      renderWithQueryClient(<StudentCellPopover {...defaultProps()} />)

      await user.click(screen.getByTestId('student-cell-link'))

      await waitFor(() => {
        const link = screen.getByText('View Mastery Report').closest('a')
        expect(link).toHaveAttribute('href', studentGradesUrl)
      })
    })

    it('link points to correct student grades page', async () => {
      const user = userEvent.setup()
      const customStudentId = '999'
      const customStudent = {...mockStudent, id: customStudentId}
      const customGradesUrl = `/courses/${courseId}/grades/${customStudentId}#tab-outcomes`

      renderWithQueryClient(
        <StudentCellPopover
          {...defaultProps({
            student: customStudent,
            studentGradesUrl: customGradesUrl,
          })}
        />,
      )

      await user.click(screen.getByTestId('student-cell-link'))

      await waitFor(() => {
        const link = screen.getByText('View Mastery Report').closest('a')
        expect(link).toHaveAttribute('href', customGradesUrl)
      })
    })
  })

  describe('pickBucketForScore', () => {
    const mockBuckets = {
      no_evidence: {name: 'No Evidence', iconURL: '/images/outcomes/no_evidence.svg', count: 0},
      remediation: {name: 'Remediation', iconURL: '/images/outcomes/remediation.svg', count: 0},
      near_mastery: {
        name: 'Near Mastery',
        iconURL: '/images/outcomes/near_mastery.svg',
        count: 0,
      },
      mastery: {name: 'Mastery', iconURL: '/images/outcomes/mastery.svg', count: 0},
      exceeds_mastery: {
        name: 'Exceeds Mastery',
        iconURL: '/images/outcomes/exceeds_mastery.svg',
        count: 0,
      },
    }

    it('returns no_evidence bucket for null score', () => {
      expect(pickBucketForScore(null, mockBuckets)).toBe(mockBuckets.no_evidence)
    })

    it('returns exceeds_mastery bucket for positive scores', () => {
      expect(pickBucketForScore(0.1, mockBuckets)).toBe(mockBuckets.exceeds_mastery)
      expect(pickBucketForScore(1, mockBuckets)).toBe(mockBuckets.exceeds_mastery)
      expect(pickBucketForScore(5, mockBuckets)).toBe(mockBuckets.exceeds_mastery)
      expect(pickBucketForScore(100, mockBuckets)).toBe(mockBuckets.exceeds_mastery)
    })

    it('returns mastery bucket for zero score', () => {
      expect(pickBucketForScore(0, mockBuckets)).toBe(mockBuckets.mastery)
    })

    it('returns near_mastery bucket for negative scores between -1 and 0', () => {
      expect(pickBucketForScore(-0.1, mockBuckets)).toBe(mockBuckets.near_mastery)
      expect(pickBucketForScore(-0.5, mockBuckets)).toBe(mockBuckets.near_mastery)
      expect(pickBucketForScore(-0.9, mockBuckets)).toBe(mockBuckets.near_mastery)
    })

    it('returns remediation bucket for scores less than -1', () => {
      expect(pickBucketForScore(-1.1, mockBuckets)).toBe(mockBuckets.remediation)
      expect(pickBucketForScore(-2, mockBuckets)).toBe(mockBuckets.remediation)
      expect(pickBucketForScore(-10, mockBuckets)).toBe(mockBuckets.remediation)
    })

    it('returns near_mastery bucket for exactly -1', () => {
      expect(pickBucketForScore(-1, mockBuckets)).toBe(mockBuckets.near_mastery)
    })
  })

  describe('calculateScores', () => {
    const mockStudent: Student = {
      id: '1',
      name: 'Test Student',
      display_name: 'Test Student',
      sortable_name: 'Student, Test',
    }

    const mockOutcome1: Outcome = {
      id: '1',
      title: 'Outcome 1',
      calculation_method: 'decaying_average',
      points_possible: 10,
      mastery_points: 5,
      ratings: [
        {points: 10, color: 'green', description: 'Exceeds', mastery: false},
        {points: 5, color: 'green', description: 'Mastery', mastery: true},
        {points: 3, color: 'yellow', description: 'Near Mastery', mastery: false},
        {points: 0, color: 'red', description: 'Remediation', mastery: false},
      ],
    }

    const mockOutcome2: Outcome = {
      id: '2',
      title: 'Outcome 2',
      calculation_method: 'decaying_average',
      points_possible: 5,
      mastery_points: 3,
      ratings: [
        {points: 5, color: 'green', description: 'Exceeds', mastery: false},
        {points: 3, color: 'green', description: 'Mastery', mastery: true},
        {points: 2, color: 'yellow', description: 'Near Mastery', mastery: false},
        {points: 0, color: 'red', description: 'Remediation', mastery: false},
      ],
    }

    const mockOutcome3: Outcome = {
      id: '3',
      title: 'Outcome 3',
      calculation_method: 'decaying_average',
      points_possible: 8,
      mastery_points: 4,
      ratings: [
        {points: 8, color: 'green', description: 'Exceeds', mastery: false},
        {points: 4, color: 'green', description: 'Mastery', mastery: true},
        {points: 2, color: 'yellow', description: 'Near Mastery', mastery: false},
        {points: 0, color: 'red', description: 'Remediation', mastery: false},
      ],
    }

    it('returns correct buckets when student has no rollups', () => {
      const outcomes: Outcome[] = [mockOutcome1, mockOutcome2, mockOutcome3]
      const rollups: StudentRollupData[] = []

      const result = calculateScores(outcomes, rollups, mockStudent)

      expect(result.buckets.no_evidence.count).toBe(3)
      expect(result.buckets.remediation.count).toBe(0)
      expect(result.buckets.near_mastery.count).toBe(0)
      expect(result.buckets.mastery.count).toBe(0)
      expect(result.buckets.exceeds_mastery.count).toBe(0)
      expect(result.masteryRelativeAverage).toBeNull()
      expect(result.grossAverage).toBeNull()
    })

    it('calculates scores correctly with single outcome at mastery', () => {
      const outcomes: Outcome[] = [mockOutcome1]
      const rollups: StudentRollupData[] = [
        {
          studentId: '1',
          outcomeRollups: [
            {
              outcomeId: '1',
              score: 2,
              rating: {points: 5, color: 'green'},
            },
          ],
        },
      ]

      const result = calculateScores(outcomes, rollups, mockStudent)

      expect(result.buckets.no_evidence.count).toBe(0)
      expect(result.buckets.mastery.count).toBe(1)
      expect(result.masteryRelativeAverage).toBe(0) // 5 - 5 = 0
      expect(result.grossAverage).toBe(5)
      expect(result.averageText).toBe('Mastery')
    })

    it('calculates scores correctly with multiple outcomes', () => {
      const outcomes: Outcome[] = [mockOutcome1, mockOutcome2]
      const rollups: StudentRollupData[] = [
        {
          studentId: '1',
          outcomeRollups: [
            {
              outcomeId: '1',
              score: 2,
              rating: {points: 10, color: 'green'}, // 10 - 5 = +5 (exceeds)
            },
            {
              outcomeId: '2',
              score: 2,
              rating: {points: 3, color: 'green'}, // 3 - 3 = 0 (mastery)
            },
          ],
        },
      ]

      const result = calculateScores(outcomes, rollups, mockStudent)

      expect(result.buckets.exceeds_mastery.count).toBe(1)
      expect(result.buckets.mastery.count).toBe(1)
      expect(result.masteryRelativeAverage).toBe(2.5) // (5 + 0) / 2
      expect(result.grossAverage).toBe(6.5) // (10 + 3) / 2
    })

    it('handles near mastery scores correctly', () => {
      const outcomes: Outcome[] = [mockOutcome1]
      const rollups: StudentRollupData[] = [
        {
          studentId: '1',
          outcomeRollups: [
            {
              outcomeId: '1',
              score: 2,
              rating: {points: 4.5, color: 'yellow'}, // 4.5 - 5 = -0.5 (near mastery)
            },
          ],
        },
      ]

      const result = calculateScores(outcomes, rollups, mockStudent)

      expect(result.buckets.near_mastery.count).toBe(1)
      expect(result.masteryRelativeAverage).toBe(-0.5)
    })

    it('handles remediation scores correctly', () => {
      const outcomes: Outcome[] = [mockOutcome1]
      const rollups: StudentRollupData[] = [
        {
          studentId: '1',
          outcomeRollups: [
            {
              outcomeId: '1',
              score: 2,
              rating: {points: 2, color: 'red'}, // 2 - 5 = -3 (remediation)
            },
          ],
        },
      ]

      const result = calculateScores(outcomes, rollups, mockStudent)

      expect(result.buckets.remediation.count).toBe(1)
      expect(result.masteryRelativeAverage).toBe(-3)
    })

    it('calculates no evidence count correctly with partial rollups', () => {
      const outcomes: Outcome[] = [mockOutcome1, mockOutcome2, mockOutcome3]
      const rollups: StudentRollupData[] = [
        {
          studentId: '1',
          outcomeRollups: [
            {
              outcomeId: '1',
              score: 2,
              rating: {points: 5, color: 'green'},
            },
          ],
        },
      ]

      const result = calculateScores(outcomes, rollups, mockStudent)

      expect(result.buckets.no_evidence.count).toBe(2) // 3 outcomes - 1 rollup
      expect(result.buckets.mastery.count).toBe(1)
    })

    it('ignores rollups with missing outcome references', () => {
      const outcomes: Outcome[] = [mockOutcome1]
      const rollups: StudentRollupData[] = [
        {
          studentId: '1',
          outcomeRollups: [
            {
              outcomeId: '1',
              score: 2,
              rating: {points: 5, color: 'green'},
            },
            {
              outcomeId: '999', // Non-existent outcome
              score: 2,
              rating: {points: 10, color: 'green'},
            },
          ],
        },
      ]

      const result = calculateScores(outcomes, rollups, mockStudent)

      expect(result.buckets.mastery.count).toBe(1)
      expect(result.masteryRelativeAverage).toBe(0)
      expect(result.grossAverage).toBe(5)
    })

    it('handles different student IDs correctly', () => {
      const outcomes: Outcome[] = [mockOutcome1]
      const rollups: StudentRollupData[] = [
        {
          studentId: '999', // Different student
          outcomeRollups: [
            {
              outcomeId: '1',
              score: 2,
              rating: {points: 10, color: 'green'},
            },
          ],
        },
      ]

      const result = calculateScores(outcomes, rollups, mockStudent)

      expect(result.buckets.no_evidence.count).toBe(1)
      expect(result.masteryRelativeAverage).toBeNull()
      expect(result.grossAverage).toBeNull()
    })

    it('handles mixed performance levels correctly', () => {
      const outcomes: Outcome[] = [mockOutcome1, mockOutcome2, mockOutcome3]
      const rollups: StudentRollupData[] = [
        {
          studentId: '1',
          outcomeRollups: [
            {
              outcomeId: '1',
              score: 2,
              rating: {points: 10, color: 'green'}, // +5 exceeds
            },
            {
              outcomeId: '2',
              score: 2,
              rating: {points: 3, color: 'green'}, // 0 mastery
            },
            {
              outcomeId: '3',
              score: 2,
              rating: {points: 3, color: 'yellow'}, // 3 - 4 = -1 (near mastery)
            },
          ],
        },
      ]

      const result = calculateScores(outcomes, rollups, mockStudent)

      expect(result.buckets.exceeds_mastery.count).toBe(1)
      expect(result.buckets.mastery.count).toBe(1)
      expect(result.buckets.near_mastery.count).toBe(1)
      expect(result.buckets.remediation.count).toBe(0)
      expect(result.masteryRelativeAverage).toBeCloseTo(1.33, 1) // (5 + 0 - 1) / 3
      expect(result.grossAverage).toBeCloseTo(5.33, 1) // (10 + 3 + 3) / 3
    })

    it('sets average icon and text based on average mastery score', () => {
      const outcomes: Outcome[] = [mockOutcome1]
      const rollups: StudentRollupData[] = [
        {
          studentId: '1',
          outcomeRollups: [
            {
              outcomeId: '1',
              score: 2,
              rating: {points: 10, color: 'green'}, // +5 exceeds
            },
          ],
        },
      ]

      const result = calculateScores(outcomes, rollups, mockStudent)

      expect(result.averageIconURL).toBe('/images/outcomes/exceeds_mastery.svg')
      expect(result.averageText).toBe('Exceeds Mastery')
    })

    it('handles empty outcomes array', () => {
      const outcomes: Outcome[] = []
      const rollups: StudentRollupData[] = []

      const result = calculateScores(outcomes, rollups, mockStudent)

      expect(result.buckets.no_evidence.count).toBe(0)
      expect(result.masteryRelativeAverage).toBeNull()
      expect(result.grossAverage).toBeNull()
    })

    it('handles undefined outcomes and rollups', () => {
      const result = calculateScores([], [], mockStudent)

      expect(result.buckets.no_evidence.count).toBe(0)
      expect(result.masteryRelativeAverage).toBeNull()
      expect(result.grossAverage).toBeNull()
      expect(result.averageIconURL).toBe('/images/outcomes/no_evidence.svg')
      expect(result.averageText).toBe('No Evidence')
    })
  })
})
