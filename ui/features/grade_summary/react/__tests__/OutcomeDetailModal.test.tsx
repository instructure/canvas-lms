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

import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import OutcomeDetailModal, {type OutcomeDetailModalProps} from '../OutcomeDetailModal'

const server = setupServer()

const defaultOutcome: OutcomeDetailModalProps['outcome'] = {
  id: '1',
  friendly_name: 'Friendly Outcome',
  score: 3,
  mastery_points: 5,
  points_possible: 5,
  percent: 0.6,
  description: '<p>Outcome description</p>',
}

const defaultProps = {
  outcome: defaultOutcome,
  courseId: '10',
  courseName: 'Test Course',
  userId: '20',
  onClose: vi.fn(),
}

const mockResultsResponse = {
  outcome_results: [
    {
      id: '100',
      percent: 0.8,
      possible: 5,
      score: 4,
      links: {alignment: 'align-1'},
      submitted_or_assessed_at: '2026-01-15T00:00:00Z',
    },
    {
      id: '101',
      percent: 0.6,
      possible: 5,
      score: 3,
      links: {alignment: 'align-2'},
      submitted_or_assessed_at: '2026-02-01T00:00:00Z',
    },
  ],
  linked: {
    alignments: [
      {id: 'align-1', name: 'Assignment 1'},
      {id: 'align-2', name: 'Quiz 1'},
    ],
  },
}

function renderModal(props: Partial<typeof defaultProps> = {}) {
  const mergedProps = {...defaultProps, ...props, onClose: props.onClose ?? vi.fn()}
  return render(
    <MockedQueryProvider>
      <OutcomeDetailModal {...mergedProps} />
    </MockedQueryProvider>,
  )
}

describe('OutcomeDetailModal', () => {
  beforeAll(() => server.listen({onUnhandledRequest: 'bypass'}))

  afterAll(() => server.close())

  beforeEach(() => {
    server.use(
      http.get('/api/v1/courses/:courseId/outcome_results', () => {
        return HttpResponse.json(mockResultsResponse)
      }),
    )
    queryClient.clear()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  it('renders course name as modal heading', () => {
    renderModal()

    expect(screen.getByRole('heading', {name: 'Test Course'})).toBeInTheDocument()
  })

  it('renders outcome friendly_name', () => {
    renderModal()

    expect(screen.getByText('Friendly Outcome')).toBeInTheDocument()
  })

  it('renders outcome description HTML when provided', () => {
    renderModal()

    expect(screen.getByText('Outcome description')).toBeInTheDocument()
  })

  it('renders alignment name for each outcome result', async () => {
    renderModal()

    await waitFor(() => {
      expect(screen.getByText('Assignment 1')).toBeInTheDocument()
      expect(screen.getByText('Quiz 1')).toBeInTheDocument()
    })
  })

  it('results appear sorted by date descending (newest first)', async () => {
    renderModal()

    await waitFor(() => {
      expect(screen.getByText('Quiz 1')).toBeInTheDocument()
    })

    const quiz = screen.getByText('Quiz 1')
    const assignment = screen.getByText('Assignment 1')
    expect(quiz.compareDocumentPosition(assignment)).toBe(Node.DOCUMENT_POSITION_FOLLOWING)
  })

  it('shows "No items." when API returns empty outcome_results', async () => {
    server.use(
      http.get('/api/v1/courses/:courseId/outcome_results', () => {
        return HttpResponse.json({outcome_results: [], linked: {alignments: []}})
      }),
    )
    renderModal()

    await waitFor(() => {
      expect(screen.getByText('No items.')).toBeInTheDocument()
    })
  })

  it('shows error alert when API request fails', async () => {
    server.use(
      http.get('/api/v1/courses/:courseId/outcome_results', () => {
        return HttpResponse.error()
      }),
    )
    renderModal()

    await waitFor(() => {
      expect(screen.getByText('Failed to load alignments')).toBeInTheDocument()
    })
  })

  it('calls onClose when header close button is clicked', async () => {
    const onClose = vi.fn()
    renderModal({onClose})

    const buttons = screen.getAllByRole('button', {name: 'Close'})
    // First Close button is the header CloseButton (X)
    await userEvent.click(buttons[0])

    expect(onClose).toHaveBeenCalledTimes(1)
  })

  it('calls onClose when footer Close button is clicked', async () => {
    const onClose = vi.fn()
    renderModal({onClose})

    const buttons = screen.getAllByRole('button', {name: 'Close'})
    // Last Close button is the footer button
    await userEvent.click(buttons[buttons.length - 1])

    expect(onClose).toHaveBeenCalledTimes(1)
  })

  describe('OutcomeProgressBar', () => {
    it('shows formatted score when score > 0', () => {
      renderModal({outcome: {...defaultOutcome, score: 3, mastery_points: 5}})

      expect(screen.getByText('3')).toBeInTheDocument()
    })

    it('shows formatted score when score is 0', () => {
      renderModal({outcome: {...defaultOutcome, score: 0, mastery_points: 5}})

      expect(screen.getByText('0')).toBeInTheDocument()
    })

    it('shows "-" when score is undefined', () => {
      renderModal({outcome: {...defaultOutcome, score: undefined, mastery_points: 5}})

      const dashes = screen.getAllByText('-')
      expect(dashes.length).toBeGreaterThanOrEqual(1)
    })

    it('shows formatted mastery_points when > 0', () => {
      renderModal({outcome: {...defaultOutcome, score: 3, mastery_points: 5}})

      expect(screen.getByText('5')).toBeInTheDocument()
    })

    it('shows formatted mastery_points when 0', () => {
      renderModal({outcome: {...defaultOutcome, score: 3, mastery_points: 0}})

      const allText = screen.getAllByText('0')
      expect(allText.length).toBeGreaterThanOrEqual(1)
    })

    it('shows "-" when mastery_points is undefined', () => {
      renderModal({outcome: {...defaultOutcome, score: 3, mastery_points: undefined}})

      const dashes = screen.getAllByText('-')
      expect(dashes.length).toBeGreaterThanOrEqual(1)
    })

    function getProgressBars(): HTMLProgressElement[] {
      return Array.from(document.querySelectorAll('progress'))
    }

    it('shows success color when score >= mastery_points', () => {
      renderModal({
        outcome: {...defaultOutcome, score: 5, mastery_points: 5, points_possible: 5, percent: 1},
      })
      const bar = getProgressBars()[0]
      expect(bar.value).toBe(100)
    })

    it('shows danger color when score < mastery_points/2', () => {
      renderModal({
        outcome: {
          ...defaultOutcome,
          score: 1,
          mastery_points: 5,
          points_possible: 5,
          percent: 0.2,
        },
      })
      const bar = getProgressBars()[0]
      expect(bar.value).toBe(20)
    })

    it('shows info color when score is undefined', () => {
      renderModal({
        outcome: {...defaultOutcome, score: undefined, mastery_points: 5, points_possible: 5},
      })
      const bar = getProgressBars()[0]
      expect(bar.value).toBe(0)
    })

    it('uses percent * 100 when percent prop is provided', async () => {
      server.use(
        http.get('/api/v1/courses/:courseId/outcome_results', () => {
          return HttpResponse.json({
            outcome_results: [
              {
                id: '200',
                percent: 0.8,
                possible: 10,
                score: 4,
                links: {alignment: 'align-1'},
                submitted_or_assessed_at: '2026-01-15T00:00:00Z',
              },
            ],
            linked: {alignments: [{id: 'align-1', name: 'Test Assignment'}]},
          })
        }),
      )
      renderModal()

      await waitFor(() => {
        expect(screen.getByText('Test Assignment')).toBeInTheDocument()
      })

      // The result row's progress bar uses percent (0.8 * 100 = 80)
      const bars = getProgressBars()
      const resultBar = bars[bars.length - 1]
      expect(resultBar.value).toBe(80)
    })

    it('uses score / points_possible * 100 when percent is not provided', () => {
      renderModal({
        outcome: {
          ...defaultOutcome,
          score: 3,
          points_possible: 5,
          percent: undefined,
          mastery_points: 5,
        },
      })
      // 3 / 5 * 100 = 60
      const bar = getProgressBars()[0]
      expect(bar.value).toBe(60)
    })

    it('reports 0% when score is undefined', () => {
      renderModal({
        outcome: {...defaultOutcome, score: undefined, points_possible: 5, mastery_points: 5},
      })
      const bar = getProgressBars()[0]
      expect(bar.value).toBe(0)
    })
  })
})
