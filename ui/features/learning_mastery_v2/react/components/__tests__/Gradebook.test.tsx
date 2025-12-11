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
import {render} from '@testing-library/react'
import {QueryClient} from '@tanstack/react-query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {Gradebook, GradebookProps} from '../Gradebook'
import {SortOrder, SortBy} from '../../utils/constants'
import {MOCK_OUTCOMES, MOCK_STUDENTS} from '../../__fixtures__/rollups'
import {ContributingScoresManager} from '../../hooks/useContributingScores'

// Helper to render with MockedQueryClientProvider
const renderWithQueryClient = (ui: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })
  return render(<MockedQueryClientProvider client={queryClient}>{ui}</MockedQueryClientProvider>)
}

describe('Gradebook', () => {
  const MOCK_ALIGNMENTS_TWO = [
    {
      alignment_id: 'D_5',
      associated_asset_id: '2',
      associated_asset_name: 'Test Assignment 1',
      associated_asset_type: 'Assignment',
      html_url: 'http://test.com/assignments/2',
    },
    {
      alignment_id: 'D_6',
      associated_asset_id: '3',
      associated_asset_name: 'Test Assignment 2',
      associated_asset_type: 'Assignment',
      html_url: 'http://test.com/assignments/3',
    },
  ]

  const MOCK_ALIGNMENTS_THREE = [
    {
      alignment_id: 'D_5',
      associated_asset_id: '2',
      associated_asset_name: 'Assignment 1',
      associated_asset_type: 'Assignment',
      html_url: 'http://test.com/assignments/2',
    },
    {
      alignment_id: 'D_6',
      associated_asset_id: '3',
      associated_asset_name: 'Assignment 2',
      associated_asset_type: 'Assignment',
      html_url: 'http://test.com/assignments/3',
    },
    {
      alignment_id: 'D_7',
      associated_asset_id: '4',
      associated_asset_name: 'Assignment 3',
      associated_asset_type: 'Assignment',
      html_url: 'http://test.com/assignments/4',
    },
  ]

  const mockContributingScores: ContributingScoresManager = {
    forOutcome: jest.fn(() => ({
      isVisible: () => false,
      toggleVisibility: jest.fn(),
      data: undefined,
      alignments: undefined,
      scoresForUser: jest.fn(() => []),
      isLoading: false,
      error: undefined,
    })),
  }

  const defaultProps = (props = {}): GradebookProps => {
    return {
      students: MOCK_STUDENTS,
      outcomes: MOCK_OUTCOMES,
      rollups: [
        {
          studentId: '1',
          outcomeRollups: [],
        },
        {
          studentId: '2',
          outcomeRollups: [],
        },
      ],
      courseId: '100',
      setCurrentPage: jest.fn(),
      sorting: {
        sortOrder: SortOrder.ASC,
        setSortOrder: jest.fn(),
        sortBy: SortBy.SortableName,
        setSortBy: jest.fn(),
        sortOutcomeId: null,
        setSortOutcomeId: jest.fn(),
        sortAlignmentId: null,
        setSortAlignmentId: jest.fn(),
      },
      onChangeNameDisplayFormat: jest.fn(),
      contributingScores: mockContributingScores,
      ...props,
    }
  }

  beforeEach(() => {
    window.ENV = window.ENV || {}
    window.ENV.GRADEBOOK_OPTIONS = {ACCOUNT_LEVEL_MASTERY_SCALES: true}
  })

  it('renders each student', () => {
    const props = defaultProps()
    const {getByText} = renderWithQueryClient(<Gradebook {...props} />)
    props.students.forEach(student => {
      expect(getByText(student.display_name)).toBeInTheDocument()
    })
  })

  it('renders each outcome', () => {
    const props = defaultProps()
    const {getByText} = renderWithQueryClient(<Gradebook {...props} />)
    props.outcomes.forEach(outcome => {
      expect(getByText(outcome.title)).toBeInTheDocument()
    })
  })

  it('renders outcomes in the order they are provided', () => {
    const customOutcomes = [
      {...MOCK_OUTCOMES[0], id: '1', title: 'First Outcome'},
      {...MOCK_OUTCOMES[0], id: '2', title: 'Second Outcome'},
      {...MOCK_OUTCOMES[0], id: '4', title: 'Fourth Outcome'},
      {...MOCK_OUTCOMES[0], id: '3', title: 'Third Outcome'},
    ]
    const props = defaultProps({outcomes: customOutcomes})
    const {container} = renderWithQueryClient(<Gradebook {...props} />)
    const outcomeHeaders = container.querySelectorAll(
      '#outcomes-header [data-testid="column-header"]',
    )

    expect(outcomeHeaders).toHaveLength(4)
    expect(outcomeHeaders[0]).toHaveTextContent('First Outcome')
    expect(outcomeHeaders[1]).toHaveTextContent('Second Outcome')
    expect(outcomeHeaders[2]).toHaveTextContent('Fourth Outcome')
    expect(outcomeHeaders[3]).toHaveTextContent('Third Outcome')
  })

  describe('pagination', () => {
    it('does not render pagination controls when there is only one page', () => {
      const props = defaultProps({pagination: {currentPage: 1, perPage: 10, totalPages: 1}})
      const {queryByTestId} = renderWithQueryClient(<Gradebook {...props} />)
      expect(queryByTestId('gradebook-pagination')).not.toBeInTheDocument()
    })

    it('does not render pagination controls when pagination is not provided', () => {
      const props = defaultProps({pagination: undefined})
      const {queryByTestId} = renderWithQueryClient(<Gradebook {...props} />)
      expect(queryByTestId('gradebook-pagination')).not.toBeInTheDocument()
    })

    it('renders pagination controls when there are multiple pages', () => {
      const props = defaultProps({pagination: {currentPage: 1, perPage: 10, totalPages: 2}})
      const {queryByTestId} = renderWithQueryClient(<Gradebook {...props} />)
      expect(queryByTestId('gradebook-pagination')).toBeInTheDocument()
    })

    it('calls setCurrentPage when page number button is clicked', () => {
      const props = defaultProps({pagination: {currentPage: 1, perPage: 10, totalPages: 3}})
      const {getByText} = renderWithQueryClient(<Gradebook {...props} />)
      const page2Button = getByText('2')
      page2Button.click()
      expect(props.setCurrentPage).toHaveBeenCalledWith(2)
    })
  })

  describe('contributing scores headers', () => {
    it('does not render contributing score headers when outcome is not visible', () => {
      const mockContributingScoresNotVisible: ContributingScoresManager = {
        forOutcome: jest.fn(() => ({
          isVisible: () => false,
          toggleVisibility: jest.fn(),
          data: undefined,
          alignments: [
            {
              alignment_id: 'D_5',
              associated_asset_id: '2',
              associated_asset_name: 'Test Assignment',
              associated_asset_type: 'Assignment',
              html_url: 'http://test.com/assignments/2',
            },
          ],
          scoresForUser: jest.fn(() => []),
          isLoading: false,
          error: undefined,
        })),
      }

      const props = defaultProps({contributingScores: mockContributingScoresNotVisible})
      const {queryByText} = renderWithQueryClient(<Gradebook {...props} />)
      expect(queryByText('Test Assignment')).not.toBeInTheDocument()
    })

    it('renders contributing score headers when outcome is visible', () => {
      const mockContributingScoresVisible: ContributingScoresManager = {
        forOutcome: jest.fn(outcomeId => {
          if (outcomeId === '1') {
            return {
              isVisible: () => true,
              toggleVisibility: jest.fn(),
              data: {
                outcome: {id: '1', title: 'Test Outcome'},
                alignments: MOCK_ALIGNMENTS_TWO,
                scores: [],
              },
              alignments: MOCK_ALIGNMENTS_TWO,
              scoresForUser: jest.fn(() => []),
              isLoading: false,
              error: undefined,
            }
          }
          return {
            isVisible: () => false,
            toggleVisibility: jest.fn(),
            data: undefined,
            alignments: undefined,
            scoresForUser: jest.fn(() => []),
            isLoading: false,
            error: undefined,
          }
        }),
      }

      const props = defaultProps({
        contributingScores: mockContributingScoresVisible,
        outcomes: [{...MOCK_OUTCOMES[0], id: '1'}],
      })
      const {getByText} = renderWithQueryClient(<Gradebook {...props} />)

      expect(getByText('Test Assignment 1')).toBeInTheDocument()
      expect(getByText('Test Assignment 2')).toBeInTheDocument()
    })

    it('renders correct number of contributing score headers based on alignments', () => {
      const mockContributingScoresMultiple: ContributingScoresManager = {
        forOutcome: jest.fn(outcomeId => {
          if (outcomeId === '1') {
            return {
              isVisible: () => true,
              toggleVisibility: jest.fn(),
              data: {
                outcome: {id: '1', title: 'Test Outcome'},
                alignments: MOCK_ALIGNMENTS_THREE,
                scores: [],
              },
              alignments: MOCK_ALIGNMENTS_THREE,
              scoresForUser: jest.fn(() => []),
              isLoading: false,
              error: undefined,
            }
          }
          return {
            isVisible: () => false,
            toggleVisibility: jest.fn(),
            data: undefined,
            alignments: undefined,
            scoresForUser: jest.fn(() => []),
            isLoading: false,
            error: undefined,
          }
        }),
      }

      const props = defaultProps({
        contributingScores: mockContributingScoresMultiple,
        outcomes: [{...MOCK_OUTCOMES[0], id: '1'}],
      })
      const {getByText} = renderWithQueryClient(<Gradebook {...props} />)

      expect(getByText('Assignment 1')).toBeInTheDocument()
      expect(getByText('Assignment 2')).toBeInTheDocument()
      expect(getByText('Assignment 3')).toBeInTheDocument()
    })

    it('does not render contributing score headers when alignments is undefined', () => {
      const mockContributingScoresNoAlignments: ContributingScoresManager = {
        forOutcome: jest.fn(() => ({
          isVisible: () => true,
          toggleVisibility: jest.fn(),
          data: undefined,
          alignments: undefined,
          scoresForUser: jest.fn(() => []),
          isLoading: false,
          error: undefined,
        })),
      }

      const props = defaultProps({contributingScores: mockContributingScoresNoAlignments})
      const {container} = renderWithQueryClient(<Gradebook {...props} />)

      const allHeaders = container.querySelectorAll(
        '#outcomes-header [data-testid="column-header"]',
      )
      expect(allHeaders).toHaveLength(2)
    })

    it('does not render contributing score headers when alignments is empty array', () => {
      const mockContributingScoresEmptyAlignments: ContributingScoresManager = {
        forOutcome: jest.fn(() => ({
          isVisible: () => true,
          toggleVisibility: jest.fn(),
          data: {
            outcome: {id: '1', title: 'Test Outcome'},
            alignments: [],
            scores: [],
          },
          alignments: [],
          scoresForUser: jest.fn(() => []),
          isLoading: false,
          error: undefined,
        })),
      }

      const props = defaultProps({contributingScores: mockContributingScoresEmptyAlignments})
      const {container} = renderWithQueryClient(<Gradebook {...props} />)

      const allHeaders = container.querySelectorAll(
        '#outcomes-header [data-testid="column-header"]',
      )
      expect(allHeaders).toHaveLength(2)
    })

    it('renders contributing score headers for multiple visible outcomes', () => {
      const mockContributingScoresMultipleOutcomes: ContributingScoresManager = {
        forOutcome: jest.fn(outcomeId => ({
          isVisible: () => true,
          toggleVisibility: jest.fn(),
          data: {
            outcome: {id: outcomeId.toString(), title: `Outcome ${outcomeId}`},
            alignments: [
              {
                alignment_id: `D_${outcomeId}`,
                associated_asset_id: outcomeId.toString(),
                associated_asset_name: `Assignment for Outcome ${outcomeId}`,
                associated_asset_type: 'Assignment',
                html_url: `http://test.com/assignments/${outcomeId}`,
              },
            ],
            scores: [],
          },
          alignments: [
            {
              alignment_id: `D_${outcomeId}`,
              associated_asset_id: outcomeId.toString(),
              associated_asset_name: `Assignment for Outcome ${outcomeId}`,
              associated_asset_type: 'Assignment',
              html_url: `http://test.com/assignments/${outcomeId}`,
            },
          ],
          scoresForUser: jest.fn(() => []),
          isLoading: false,
          error: undefined,
        })),
      }

      const props = defaultProps({contributingScores: mockContributingScoresMultipleOutcomes})
      const {getByText} = renderWithQueryClient(<Gradebook {...props} />)

      // Should render headers for both outcomes (MOCK_OUTCOMES has 2 outcomes)
      props.outcomes.forEach(outcome => {
        expect(getByText(`Assignment for Outcome ${outcome.id}`)).toBeInTheDocument()
      })
    })
  })
})
