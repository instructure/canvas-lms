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

import {render, screen, fireEvent} from '@testing-library/react'
import StudentOutcomesTable from '../StudentOutcomesTable'
import {Outcome} from '../types'

vi.mock('@canvas/outcomes/react/hooks/useCanvasContext', () => ({
  __esModule: true,
  default: () => ({
    contextId: '1',
    accountLevelMasteryScalesFF: false,
  }),
}))

vi.mock('@canvas/outcomes/react/hooks/useContributingScores', () => ({
  useContributingScores: () => ({
    isLoading: false,
    error: null,
    contributingScores: {
      forOutcome: () => ({
        isVisible: () => false,
        toggleVisibility: vi.fn(),
        data: undefined,
        alignments: [],
        scoresForUser: () => [],
        isLoading: false,
        error: undefined,
      }),
    },
  }),
}))

describe('StudentOutcomesTable', () => {
  const testOutcomes: Outcome[] = [
    {
      id: 1,
      code: 'N-CN.1',
      name: 'Test Outcome 1',
      description: 'Test description 1',
      assessedAlignmentsCount: 3,
      totalAlignmentsCount: 5,
      masteryScore: 2.5,
      masteryLevel: 'near_mastery' as const,
      masteryPoints: 1,
    },
    {
      id: 2,
      code: 'A-SSE.2',
      name: 'Test Outcome 2',
      description: 'Test description 2',
      assessedAlignmentsCount: 0,
      totalAlignmentsCount: 3,
      masteryScore: null,
      masteryLevel: 'unassessed' as const,
      masteryPoints: 2,
    },
  ]

  it('renders the component', () => {
    render(<StudentOutcomesTable outcomes={testOutcomes} studentId="1" />)
    expect(screen.getByText('Student Outcomes')).toBeInTheDocument()
  })

  it('renders without errors', () => {
    expect(() =>
      render(<StudentOutcomesTable outcomes={testOutcomes} studentId="1" />),
    ).not.toThrow()
  })

  it('renders outcomes in the table', () => {
    render(<StudentOutcomesTable outcomes={testOutcomes} studentId="1" />)
    expect(screen.getByText('N-CN.1')).toBeInTheDocument()
    expect(screen.getByText('Test Outcome 1')).toBeInTheDocument()
    expect(screen.getByText('A-SSE.2')).toBeInTheDocument()
    expect(screen.getByText('Test Outcome 2')).toBeInTheDocument()
  })

  it('displays assessment counts correctly', () => {
    render(<StudentOutcomesTable outcomes={testOutcomes} studentId="1" />)
    expect(screen.getByText('3 of 5 alignments')).toBeInTheDocument()
    expect(screen.getByText('0 of 3 alignments')).toBeInTheDocument()
  })

  it('displays mastery scores correctly', () => {
    render(<StudentOutcomesTable outcomes={testOutcomes} studentId="1" />)
    expect(screen.getByText('2.5')).toBeInTheDocument()
    expect(screen.getByText('--')).toBeInTheDocument()
  })

  it('expands and collapses rows when clicking expand button', () => {
    render(<StudentOutcomesTable outcomes={testOutcomes} studentId="1" />)

    const expandButton = screen.getByTestId('outcome-expand-button-1')

    // Check button is not expanded initially
    expect(expandButton).toHaveAttribute('aria-expanded', 'false')

    // Click expand button
    fireEvent.click(expandButton)

    // Button should now show expanded state
    expect(expandButton).toHaveAttribute('aria-expanded', 'true')

    // Click collapse button
    fireEvent.click(expandButton)

    // Button should return to collapsed state
    expect(expandButton).toHaveAttribute('aria-expanded', 'false')
  })

  it('sorts by code by default in ascending order', () => {
    const unsortedOutcomes = [{...testOutcomes[1]}, {...testOutcomes[0]}]
    const {container} = render(<StudentOutcomesTable outcomes={unsortedOutcomes} studentId="1" />)

    const rows = container.querySelectorAll('tbody tr')
    expect(rows[0].textContent).toContain('A-SSE.2')
    expect(rows[1].textContent).toContain('N-CN.1')
  })

  it('sorts by assessed count when clicking the Times Assessed header', () => {
    const {container} = render(<StudentOutcomesTable outcomes={testOutcomes} studentId="1" />)

    const assessedHeader = screen.getByText('Times Assessed').closest('th')
    const sortButton = assessedHeader?.querySelector('button')
    fireEvent.click(sortButton!)

    const rows = container.querySelectorAll('tbody tr')
    // Outcome with 0 assessed should come first in ascending order
    expect(rows[0].textContent).toContain('0 of 3 alignments')
    expect(rows[1].textContent).toContain('3 of 5 alignments')
  })

  it('sorts by mastery score when clicking the Mastery header', () => {
    const {container} = render(<StudentOutcomesTable outcomes={testOutcomes} studentId="1" />)

    const masteryHeader = screen.getByText('Mastery').closest('th')
    const sortButton = masteryHeader?.querySelector('button')
    fireEvent.click(sortButton!)

    const rows = container.querySelectorAll('tbody tr')
    // Unassessed (null) should come first, then scored outcomes
    expect(rows[0].textContent).toContain('--')
    expect(rows[1].textContent).toContain('2.5')
  })

  it('toggles sort direction when clicking the same column header twice', () => {
    const {container} = render(<StudentOutcomesTable outcomes={testOutcomes} studentId="1" />)

    // Initially sorted by code ascending (A-SSE.2 comes first)
    let rows = container.querySelectorAll('tbody tr')
    expect(rows[0].textContent).toContain('A-SSE.2')
    expect(rows[1].textContent).toContain('N-CN.1')

    // Find the sort button within the Outcome column header
    const outcomeHeader = screen.getByText('Outcome').closest('th')
    const sortButton = outcomeHeader?.querySelector('button')

    // Click once - should toggle to descending (N-CN.1 comes first)
    fireEvent.click(sortButton!)
    rows = container.querySelectorAll('tbody tr')
    expect(rows[0].textContent).toContain('N-CN.1')
    expect(rows[1].textContent).toContain('A-SSE.2')

    // Click again - should toggle back to ascending (A-SSE.2 comes first)
    fireEvent.click(sortButton!)

    rows = container.querySelectorAll('tbody tr')
    expect(rows[0].textContent).toContain('A-SSE.2')
    expect(rows[1].textContent).toContain('N-CN.1')
  })

  it('displays outcome information tooltip button', () => {
    render(<StudentOutcomesTable outcomes={testOutcomes} studentId="1" />)
    expect(screen.getByTestId('outcome-info-button-1')).toBeInTheDocument()
    expect(screen.getByTestId('outcome-info-button-2')).toBeInTheDocument()
  })

  it('displays zero alignments text when totalAlignmentsCount is 0', () => {
    const zeroAlignmentOutcome: Outcome[] = [
      {
        id: 3,
        code: 'TEST.1',
        name: 'Zero Alignment Test',
        description: 'Test',
        assessedAlignmentsCount: 0,
        totalAlignmentsCount: 0,
        masteryScore: null,
        masteryLevel: 'unassessed' as const,
        masteryPoints: 0,
      },
    ]
    render(<StudentOutcomesTable outcomes={zeroAlignmentOutcome} studentId="1" />)
    expect(screen.getByText('0 alignments')).toBeInTheDocument()
  })

  it('renders mastery icons with correct alt text', () => {
    render(<StudentOutcomesTable outcomes={testOutcomes} studentId="1" />)
    expect(screen.getByAltText('Near Mastery')).toBeInTheDocument()
    expect(screen.getByAltText('Unassessed')).toBeInTheDocument()
  })
})
