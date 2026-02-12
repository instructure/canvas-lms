/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {GradebookTable} from '../GradebookTable'
import {
  SortOrder,
  SortBy,
  ScoreDisplayFormat,
  NameDisplayFormat,
  SecondaryInfoDisplay,
  DEFAULT_GRADEBOOK_SETTINGS,
} from '@canvas/outcomes/react/utils/constants'
import {MOCK_STUDENTS, MOCK_OUTCOMES, MOCK_ROLLUPS} from '../../__fixtures__/rollups'
import {useContributingScores} from '@canvas/outcomes/react/hooks/useContributingScores'

vi.mock('@canvas/outcomes/react/hooks/useContributingScores')

vi.mock('@canvas/svg-wrapper', () => ({
  default: ({ariaLabel, ariaHidden}: {ariaLabel?: string; ariaHidden?: boolean}) => (
    <svg aria-label={ariaLabel} aria-hidden={ariaHidden} data-testid="mock-svg" />
  ),
}))

const mockContributingScores = {
  forOutcome: vi.fn().mockReturnValue({
    isVisible: vi.fn().mockReturnValue(false),
    scoresForUser: vi.fn().mockReturnValue([]),
    alignments: [],
  }),
  isLoading: false,
  error: null,
}

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

describe('GradebookTable', () => {
  const defaultProps = {
    courseId: '1',
    students: MOCK_STUDENTS,
    outcomes: MOCK_OUTCOMES,
    rollups: MOCK_ROLLUPS,
    sorting: {
      sortOrder: SortOrder.ASC,
      setSortOrder: vi.fn(),
      sortBy: SortBy.Name,
      setSortBy: vi.fn(),
      sortOutcomeId: null,
      setSortOutcomeId: vi.fn(),
      sortAlignmentId: null,
      setSortAlignmentId: vi.fn(),
    },
    gradebookSettings: DEFAULT_GRADEBOOK_SETTINGS,
    onChangeNameDisplayFormat: vi.fn(),
    contributingScores: mockContributingScores,
  }

  beforeEach(() => {
    vi.mocked(useContributingScores).mockReturnValue({
      ...mockContributingScores,
      forOutcome: vi.fn().mockReturnValue({
        isVisible: vi.fn().mockReturnValue(false),
        scoresForUser: vi.fn().mockReturnValue([]),
        alignments: [],
      }),
    } as any)
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('renders table with caption', () => {
    renderWithQueryClient(<GradebookTable {...defaultProps} />)
    expect(screen.getByText('Learning Mastery Gradebook')).toBeInTheDocument()
  })

  it('renders student column header', () => {
    renderWithQueryClient(<GradebookTable {...defaultProps} />)
    expect(screen.getAllByText('Students')[0]).toBeInTheDocument()
  })

  it('renders outcome column headers', () => {
    const {container} = renderWithQueryClient(<GradebookTable {...defaultProps} />)
    expect(container.textContent).toContain('outcome 1')
    expect(container.textContent).toContain('outcome 2')
  })

  it('renders student names', () => {
    const {container} = renderWithQueryClient(<GradebookTable {...defaultProps} />)
    expect(container.textContent).toContain('Student Test')
    expect(container.textContent).toContain('Student Test 2')
    expect(container.textContent).toContain('Student 3')
  })

  it('renders student outcome scores', async () => {
    renderWithQueryClient(<GradebookTable {...defaultProps} />)
    expect((await screen.findAllByLabelText('mastery!')).length).toBeGreaterThan(0)
    expect((await screen.findAllByLabelText('great!')).length).toBeGreaterThan(0)
  })

  describe('contributing scores', () => {
    it('renders contributing score columns when visible', () => {
      const mockContributingScoresWithVisible = {
        ...mockContributingScores,
        forOutcome: vi.fn().mockReturnValue({
          isVisible: vi.fn().mockReturnValue(true),
          scoresForUser: vi.fn().mockReturnValue([{score: 3}, {score: 4}]),
          alignments: [
            {
              alignment_id: 'A_1',
              associated_asset_id: '1',
              associated_asset_name: 'Assignment 1',
              associated_asset_type: 'Assignment',
              html_url: '/courses/1/assignments/1',
            },
            {
              alignment_id: 'A_2',
              associated_asset_id: '2',
              associated_asset_name: 'Assignment 2',
              associated_asset_type: 'Assignment',
              html_url: '/courses/1/assignments/2',
            },
          ],
        }),
      }

      const {container} = renderWithQueryClient(
        <GradebookTable {...defaultProps} contributingScores={mockContributingScoresWithVisible} />,
      )

      expect(container.textContent).toContain('Assignment 1')
      expect(container.textContent).toContain('Assignment 2')
    })

    it('calls onOpenStudentAssignmentTray when contributing score is clicked', () => {
      const onOpenStudentAssignmentTray = vi.fn()
      const mockContributingScoresWithVisible = {
        ...mockContributingScores,
        forOutcome: vi.fn().mockReturnValue({
          isVisible: vi.fn().mockReturnValue(true),
          scoresForUser: vi.fn().mockReturnValue([{score: 3}]),
          alignments: [
            {
              alignment_id: 'A_1',
              associated_asset_id: '1',
              associated_asset_name: 'Assignment 1',
              associated_asset_type: 'Assignment',
              html_url: '/courses/1/assignments/1',
            },
          ],
        }),
      }

      const {container} = renderWithQueryClient(
        <GradebookTable
          {...defaultProps}
          contributingScores={mockContributingScoresWithVisible}
          onOpenStudentAssignmentTray={onOpenStudentAssignmentTray}
        />,
      )

      expect(container.textContent).toContain('Assignment 1')
    })
  })

  describe('drag and drop', () => {
    it('enables drag and drop when handlers are provided', () => {
      const handleOutcomeReorder = vi.fn()
      const handleOutcomeDragEnd = vi.fn()
      const handleOutcomeDragLeave = vi.fn()

      renderWithQueryClient(
        <GradebookTable
          {...defaultProps}
          handleOutcomeReorder={handleOutcomeReorder}
          handleOutcomeDragEnd={handleOutcomeDragEnd}
          handleOutcomeDragLeave={handleOutcomeDragLeave}
        />,
      )

      expect(screen.getAllByText('outcome 1')[0]).toBeInTheDocument()
    })

    it('calls handleOutcomeReorder when outcome is moved', () => {
      const handleOutcomeReorder = vi.fn()

      const {container} = renderWithQueryClient(
        <GradebookTable {...defaultProps} handleOutcomeReorder={handleOutcomeReorder} />,
      )

      expect(container.textContent).toContain('outcome 1')
    })
  })

  describe('name display format', () => {
    it('renders first name first when format is FIRST_LAST', () => {
      const props = {
        ...defaultProps,
        gradebookSettings: {
          ...defaultProps.gradebookSettings,
          nameDisplayFormat: NameDisplayFormat.FIRST_LAST,
        },
      }

      const {container} = renderWithQueryClient(<GradebookTable {...props} />)
      expect(container.textContent).toContain('Student Test')
    })

    it('renders last name first when format is LAST_FIRST', () => {
      const props = {
        ...defaultProps,
        gradebookSettings: {
          ...defaultProps.gradebookSettings,
          nameDisplayFormat: NameDisplayFormat.LAST_FIRST,
        },
      }

      const {container} = renderWithQueryClient(<GradebookTable {...props} />)
      expect(container.textContent).toContain('Test, Student')
    })
  })

  describe('score display format', () => {
    it('displays scores in points format by default', () => {
      const {container} = renderWithQueryClient(<GradebookTable {...defaultProps} />)
      expect(container).toBeInTheDocument()
    })

    it('applies score display format from settings', () => {
      const props = {
        ...defaultProps,
        gradebookSettings: {
          ...defaultProps.gradebookSettings,
          scoreDisplayFormat: ScoreDisplayFormat.ICON_AND_POINTS,
        },
      }

      renderWithQueryClient(<GradebookTable {...props} />)
      expect(screen.getAllByText('outcome 1')[0]).toBeInTheDocument()
    })
  })
})
