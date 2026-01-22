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

import {cleanup, render, waitFor, screen} from '@testing-library/react'
import {type MockedFunction} from 'vitest'
import LearningMastery from '../index'
import useRollups from '@canvas/outcomes/react/hooks/useRollups'
import {useGradebookSettings} from '../hooks/useGradebookSettings'
import {useStudents} from '../hooks/useStudents'
import {useContributingScores} from '@canvas/outcomes/react/hooks/useContributingScores'
import fakeENV from '@canvas/test-utils/fakeENV'
import {Rating, Student, Outcome, StudentRollupData} from '@canvas/outcomes/react/types/rollup'
import {SortOrder, SortBy, DEFAULT_GRADEBOOK_SETTINGS} from '@canvas/outcomes/react/utils/constants'
import {MOCK_OUTCOMES, MOCK_RATINGS, MOCK_STUDENTS} from '../__fixtures__/rollups'
import {saveLearningMasteryGradebookSettings} from '../apiClient'
import {useMasteryDistribution} from '../hooks/useMasteryDistribution'

vi.mock('../apiClient')

vi.mock('@canvas/outcomes/react/hooks/useRollups')
vi.mock('../hooks/useGradebookSettings')
vi.mock('../hooks/useStudents')
vi.mock('@canvas/outcomes/react/hooks/useContributingScores')
vi.mock('../hooks/useMasteryDistribution')

vi.mock('@canvas/svg-wrapper', () => ({
  default: ({ariaLabel, ariaHidden}: {ariaLabel?: string; ariaHidden?: boolean}) => (
    <svg aria-label={ariaLabel} aria-hidden={ariaHidden} data-testid="mock-svg" />
  ),
}))

describe('LearningMastery', () => {
  const ratings: Rating[] = MOCK_RATINGS
  const students: Student[] = MOCK_STUDENTS
  const outcomes: Outcome[] = MOCK_OUTCOMES
  const mockSaveLearningMasteryGradebookSettings =
    saveLearningMasteryGradebookSettings as MockedFunction<
      typeof saveLearningMasteryGradebookSettings
    >

  const rollups: StudentRollupData[] = [
    {
      studentId: '1',
      outcomeRollups: [
        {
          outcomeId: '1',
          score: 2,
          rating: {
            points: 3,
            color: 'green',
            description: 'rating description!',
            mastery: false,
          },
        },
      ],
    },
  ]

  interface DefaultProps {
    courseId?: string
  }

  const defaultProps = (props: DefaultProps = {}): {courseId: string} => {
    return {
      courseId: '1',
      ...props,
    }
  }

  const createMockUseRollupsReturnValue = (
    overrides: Partial<ReturnType<typeof useRollups>> = {},
  ): ReturnType<typeof useRollups> => ({
    isLoading: false,
    error: null,
    students: [],
    outcomes: [],
    rollups: [],
    setCurrentPage: vi.fn(),
    sorting: {
      sortBy: SortBy.SortableName,
      sortOrder: SortOrder.ASC,
      setSortOrder: vi.fn(),
      setSortBy: vi.fn(),
      sortOutcomeId: null,
      setSortOutcomeId: vi.fn(),
      sortAlignmentId: null,
      setSortAlignmentId: vi.fn(),
    },
    filter: {
      selectedOutcomeIds: [],
      setSelectedOutcomeIds: vi.fn(),
    },
    ...overrides,
  })

  beforeEach(() => {
    vi.useFakeTimers()
    fakeENV.setup({
      GRADEBOOK_OPTIONS: {
        outcome_proficiency: {ratings},
        ACCOUNT_LEVEL_MASTERY_SCALES: true,
        context_url: '/courses/1',
      },
      FEATURES: {instui_nav: true},
    })

    const mockUseRollups = useRollups as MockedFunction<typeof useRollups>
    mockUseRollups.mockReturnValue(
      createMockUseRollupsReturnValue({
        students,
        outcomes,
        rollups,
      }),
    )

    const mockUseGradebookSettings = useGradebookSettings as MockedFunction<
      typeof useGradebookSettings
    >
    mockUseGradebookSettings.mockReturnValue({
      settings: DEFAULT_GRADEBOOK_SETTINGS,
      isLoading: false,
      error: null,
      updateSettings: vi.fn(),
    })

    const mockUseStudents = useStudents as MockedFunction<typeof useStudents>
    mockUseStudents.mockReturnValue({
      students,
      isLoading: false,
      error: null,
    })

    const mockUseContributingScores = useContributingScores as MockedFunction<
      typeof useContributingScores
    >
    mockUseContributingScores.mockReturnValue({
      isLoading: false,
      error: null,
      contributingScores: {
        forOutcome: vi.fn(() => ({
          isVisible: () => false,
          toggleVisibility: vi.fn(),
          data: undefined,
          alignments: undefined,
          scoresForUser: vi.fn(() => []),
          isLoading: false,
          error: undefined,
        })),
      },
    })

    const mockUseMasteryDistribution = useMasteryDistribution as MockedFunction<
      typeof useMasteryDistribution
    >
    mockUseMasteryDistribution.mockReturnValue({
      data: {
        outcome_distributions: {
          '1': {
            outcome_id: '1',
            ratings: [
              {description: 'Exceeds', points: 3, color: '#127A1B', count: 5, student_ids: []},
              {description: 'Meets', points: 2, color: '#0B874B', count: 10, student_ids: []},
            ],
            total_students: 15,
          },
        },
        students: [],
      },
      isLoading: false,
      error: null,
      refetch: vi.fn(),
    } as any)
  })

  afterEach(() => {
    cleanup()
    const mockUseRollups = useRollups as MockedFunction<typeof useRollups>
    mockUseRollups.mockClear()
    mockSaveLearningMasteryGradebookSettings.mockClear()
    vi.clearAllMocks()
    vi.clearAllTimers()
    vi.useRealTimers()
    fakeENV.teardown()
  })

  it('renders a loading spinner when useRollups.isLoading is true', async () => {
    const mockUseRollups = useRollups as MockedFunction<typeof useRollups>
    mockUseRollups.mockReturnValue(createMockUseRollupsReturnValue({isLoading: true}))
    render(<LearningMastery {...defaultProps()} />)
    expect(screen.getByText('Loading')).toBeInTheDocument()
  })

  it('renders the gradebook menu on the page', async () => {
    render(<LearningMastery {...defaultProps()} />)
    expect(screen.getByTestId('lmgb-gradebook-menu')).toBeInTheDocument()
  })

  it('renders the export button on the page', async () => {
    render(<LearningMastery {...defaultProps()} />)
    expect(screen.getByText('Export')).toBeInTheDocument()
  })

  it('does not render the export button on load error', async () => {
    const mockUseRollups = useRollups as MockedFunction<typeof useRollups>
    mockUseRollups.mockReturnValue(createMockUseRollupsReturnValue({error: ''}))
    render(<LearningMastery {...defaultProps()} />)
    expect(screen.queryByText('Export')).not.toBeInTheDocument()
  })

  it('does not render the gradebook body on the page if loading failed', async () => {
    const mockUseRollups = useRollups as MockedFunction<typeof useRollups>
    mockUseRollups.mockReturnValue(createMockUseRollupsReturnValue({error: ''}))
    render(<LearningMastery {...defaultProps()} />)
    expect(screen.queryByTestId('gradebook-body')).not.toBeInTheDocument()
  })

  it('renders generic error page if loading failed, while still rendering the gradebook menu', async () => {
    const mockUseRollups = useRollups as MockedFunction<typeof useRollups>
    mockUseRollups.mockReturnValue(createMockUseRollupsReturnValue({error: 'Banana Error'}))
    render(<LearningMastery {...defaultProps()} />)
    expect(screen.getByTestId('lmgb-gradebook-menu')).toBeInTheDocument()
    expect(screen.getByText('Sorry, Something Broke')).toBeInTheDocument()
  })

  it('renders each student, outcome, rollup from the response', async () => {
    render(<LearningMastery {...defaultProps()} />)

    await waitFor(() => {
      expect(screen.getByText(students[0].name)).toBeInTheDocument()
    })

    expect(screen.getAllByText(outcomes[0].title)[0]).toBeInTheDocument()
    expect(await screen.findByLabelText('rating description!')).toBeInTheDocument()
  })

  it('calls useRollups with the provided courseId', () => {
    const mockUseRollups = useRollups as MockedFunction<typeof useRollups>
    const props = defaultProps()
    render(<LearningMastery {...props} />)
    expect(mockUseRollups).toHaveBeenCalledWith({
      courseId: props.courseId,
      accountMasteryScalesEnabled: true,
      enabled: true,
      settings: DEFAULT_GRADEBOOK_SETTINGS,
      selectedUserIds: [],
    })
  })
})
