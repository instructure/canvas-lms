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
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import {pick} from 'es-toolkit/compat'
import {defaultRatings, defaultMasteryPoints} from '@canvas/outcomes/react/hooks/useRatings'
import {OutcomeDistributionPopover} from '../OutcomeDistributionPopover'
import {Outcome, Student} from '@canvas/outcomes/react/types/rollup'
import {
  OutcomeDistribution,
  RatingDistribution,
} from '@canvas/outcomes/react/types/mastery_distribution'
import LMGBContext from '@canvas/outcomes/react/contexts/LMGBContext'

vi.mock('../../charts/MasteryDistributionChart', () => ({
  MasteryDistributionChart: ({
    onBarClick,
    selectedLabel,
  }: {
    onBarClick?: (label: string, value: number) => void
    selectedLabel?: string
  }) => (
    <div data-testid="mastery-distribution-chart">
      <button data-testid="bar-exceeds-mastery" onClick={() => onBarClick?.('Exceeds Mastery', 2)}>
        Exceeds Mastery {selectedLabel === 'Exceeds Mastery' && '(selected)'}
      </button>
      <button data-testid="bar-mastery" onClick={() => onBarClick?.('Mastery', 3)}>
        Mastery {selectedLabel === 'Mastery' && '(selected)'}
      </button>
      <button data-testid="bar-near-mastery" onClick={() => onBarClick?.('Near Mastery', 1)}>
        Near Mastery {selectedLabel === 'Near Mastery' && '(selected)'}
      </button>
    </div>
  ),
}))

describe('OutcomeDistributionPopover', () => {
  const outcome: Outcome = {
    id: '1',
    title: 'outcome 1',
    description: 'Outcome description',
    display_name: 'Friendly outcome name',
    calculation_method: 'decaying_average',
    calculation_int: 65,
    points_possible: 5,
    mastery_points: defaultMasteryPoints,
    ratings: defaultRatings.map(rating =>
      pick(rating, ['description', 'points', 'color', 'mastery']),
    ),
    context_type: 'Course',
    context_id: '5',
  }

  const renderWithContext = (component: React.ReactElement) => {
    return render(
      <LMGBContext.Provider value={{env: {accountLevelMasteryScalesFF: false}}}>
        {component}
      </LMGBContext.Provider>,
    )
  }

  it('renders the popover with outcome title', () => {
    renderWithContext(
      <OutcomeDistributionPopover
        outcome={outcome}
        isOpen={true}
        onCloseHandler={vi.fn()}
        renderTrigger={<button>Trigger</button>}
      />,
    )
    expect(screen.getByTestId('outcome-distribution-popover')).toBeInTheDocument()
    expect(screen.getByText('outcome 1')).toBeInTheDocument()
  })

  it('calls onCloseHandler when close button is clicked', async () => {
    const onCloseHandler = vi.fn()
    renderWithContext(
      <OutcomeDistributionPopover
        outcome={outcome}
        isOpen={true}
        onCloseHandler={onCloseHandler}
        renderTrigger={<button>Trigger</button>}
      />,
    )

    const closeButtonWrapper = screen.getByTestId('outcome-distribution-popover-close-button')
    const closeButton = closeButtonWrapper.querySelector('button')

    closeButton?.click()

    expect(onCloseHandler).toHaveBeenCalledTimes(1)
  })

  it('toggles outcome info section when info button is clicked', async () => {
    render(
      <OutcomeDistributionPopover
        outcome={outcome}
        isOpen={true}
        onCloseHandler={vi.fn()}
        renderTrigger={<button>Trigger</button>}
      />,
    )

    expect(screen.queryByTestId('outcome-info-section')).not.toBeInTheDocument()

    const infoButton = screen.getByTestId('outcome-distribution-popover-info-button')
    fireEvent.click(infoButton)

    await waitFor(() => {
      expect(screen.queryByTestId('outcome-info-section')).toBeInTheDocument()
    })

    fireEvent.click(infoButton)

    await waitFor(() => {
      expect(screen.queryByTestId('outcome-info-section')).not.toBeInTheDocument()
    })
  })

  it('displays configure mastery link when info is shown', async () => {
    render(
      <OutcomeDistributionPopover
        outcome={outcome}
        isOpen={true}
        onCloseHandler={vi.fn()}
        renderTrigger={<button>Trigger</button>}
      />,
    )

    expect(screen.queryByTestId('configure-mastery-link')).not.toBeInTheDocument()

    const infoButton = screen.getByTestId('outcome-distribution-popover-info-button')
    fireEvent.click(infoButton)

    await waitFor(() => {
      expect(screen.queryByTestId('configure-mastery-link')).toBeInTheDocument()
    })
  })

  it('displays the calculation method correctly', async () => {
    render(
      <OutcomeDistributionPopover
        outcome={outcome}
        isOpen={true}
        onCloseHandler={vi.fn()}
        renderTrigger={<button>Trigger</button>}
      />,
    )

    const infoButton = screen.getByTestId('outcome-distribution-popover-info-button')
    fireEvent.click(infoButton)

    await waitFor(() => {
      expect(screen.getByText('Weighted Average')).toBeInTheDocument()
    })
  })

  it('displays mastery scale points', async () => {
    render(
      <OutcomeDistributionPopover
        outcome={outcome}
        isOpen={true}
        onCloseHandler={vi.fn()}
        renderTrigger={<button>Trigger</button>}
      />,
    )

    const infoButton = screen.getByTestId('outcome-distribution-popover-info-button')
    fireEvent.click(infoButton)

    await waitFor(() => {
      expect(screen.getByText('5 Point')).toBeInTheDocument()
    })
  })

  describe('student list', () => {
    const mockStudents: Student[] = [
      {
        id: '1',
        name: 'Alice Johnson',
        display_name: 'Alice Johnson',
        sortable_name: 'Johnson, Alice',
        avatar_url: 'https://example.com/alice.jpg',
      },
      {
        id: '2',
        name: 'Bob Smith',
        display_name: 'Bob Smith',
        sortable_name: 'Smith, Bob',
        avatar_url: 'https://example.com/bob.jpg',
      },
      {
        id: '3',
        name: 'Charlie Brown',
        display_name: 'Charlie Brown',
        sortable_name: 'Brown, Charlie',
        avatar_url: 'https://example.com/charlie.jpg',
      },
      {
        id: '4',
        name: 'Diana Prince',
        display_name: 'Diana Prince',
        sortable_name: 'Prince, Diana',
        avatar_url: 'https://example.com/diana.jpg',
      },
      {
        id: '5',
        name: 'Eve Davis',
        display_name: 'Eve Davis',
        sortable_name: 'Davis, Eve',
        avatar_url: 'https://example.com/eve.jpg',
      },
    ]

    const mockRatings: RatingDistribution[] = [
      {
        description: 'Exceeds Mastery',
        points: 5,
        color: '#00AC18',
        count: 2,
        student_ids: ['1', '5'],
      },
      {
        description: 'Mastery',
        points: 3,
        color: '#127A1B',
        count: 3,
        student_ids: ['2', '3', '4'],
      },
      {
        description: 'Near Mastery',
        points: 2,
        color: '#FAB901',
        count: 0,
        student_ids: [],
      },
    ]

    const mockOutcomeDistribution: OutcomeDistribution = {
      outcome_id: '1',
      ratings: mockRatings,
      total_students: 5,
    }

    it('shows student list when a bar is clicked', async () => {
      renderWithContext(
        <OutcomeDistributionPopover
          outcome={outcome}
          outcomeDistribution={mockOutcomeDistribution}
          distributionStudents={mockStudents}
          isOpen={true}
          onCloseHandler={vi.fn()}
          renderTrigger={<button>Trigger</button>}
        />,
      )

      expect(screen.queryByTestId('student-list-section')).not.toBeInTheDocument()

      const exceedsBar = screen.getByTestId('bar-exceeds-mastery')
      fireEvent.click(exceedsBar)

      await waitFor(() => {
        expect(screen.getByTestId('student-list-section')).toBeInTheDocument()
      })
    })

    it('filters students correctly by mastery level when bar is clicked', async () => {
      renderWithContext(
        <OutcomeDistributionPopover
          outcome={outcome}
          outcomeDistribution={mockOutcomeDistribution}
          distributionStudents={mockStudents}
          isOpen={true}
          onCloseHandler={vi.fn()}
          renderTrigger={<button>Trigger</button>}
        />,
      )

      const exceedsBar = screen.getByTestId('bar-exceeds-mastery')
      fireEvent.click(exceedsBar)

      await waitFor(() => {
        expect(screen.getByTestId('student-list-section')).toBeInTheDocument()
        expect(screen.getByText('Alice Johnson')).toBeInTheDocument()
        expect(screen.getByText('Eve Davis')).toBeInTheDocument()
        expect(screen.queryByText('Bob Smith')).not.toBeInTheDocument()
        expect(screen.queryByText('Charlie Brown')).not.toBeInTheDocument()
        expect(screen.queryByText('Diana Prince')).not.toBeInTheDocument()
      })
    })

    it('clicking the same bar twice toggles the student list', async () => {
      renderWithContext(
        <OutcomeDistributionPopover
          outcome={outcome}
          outcomeDistribution={mockOutcomeDistribution}
          distributionStudents={mockStudents}
          isOpen={true}
          onCloseHandler={vi.fn()}
          renderTrigger={<button>Trigger</button>}
        />,
      )

      const masteryBar = screen.getByTestId('bar-mastery')

      fireEvent.click(masteryBar)

      await waitFor(() => {
        expect(screen.getByTestId('student-list-section')).toBeInTheDocument()
        expect(screen.getByText('Bob Smith')).toBeInTheDocument()
        expect(screen.getByText('Charlie Brown')).toBeInTheDocument()
        expect(screen.getByText('Diana Prince')).toBeInTheDocument()
      })

      fireEvent.click(masteryBar)

      await waitFor(() => {
        expect(screen.queryByTestId('student-list-section')).not.toBeInTheDocument()
      })
    })

    it('clicking different bars shows different students', async () => {
      renderWithContext(
        <OutcomeDistributionPopover
          outcome={outcome}
          outcomeDistribution={mockOutcomeDistribution}
          distributionStudents={mockStudents}
          isOpen={true}
          onCloseHandler={vi.fn()}
          renderTrigger={<button>Trigger</button>}
        />,
      )

      const exceedsBar = screen.getByTestId('bar-exceeds-mastery')
      fireEvent.click(exceedsBar)

      await waitFor(() => {
        expect(screen.getByText('Alice Johnson')).toBeInTheDocument()
        expect(screen.getByText('Eve Davis')).toBeInTheDocument()
        expect(screen.queryByText('Bob Smith')).not.toBeInTheDocument()
      })

      const masteryBar = screen.getByTestId('bar-mastery')
      fireEvent.click(masteryBar)

      await waitFor(() => {
        expect(screen.queryByText('Alice Johnson')).not.toBeInTheDocument()
        expect(screen.queryByText('Eve Davis')).not.toBeInTheDocument()
        expect(screen.getByText('Bob Smith')).toBeInTheDocument()
        expect(screen.getByText('Charlie Brown')).toBeInTheDocument()
        expect(screen.getByText('Diana Prince')).toBeInTheDocument()
      })
    })

    it('shows "No students" message when clicking a bar with no students', async () => {
      renderWithContext(
        <OutcomeDistributionPopover
          outcome={outcome}
          outcomeDistribution={mockOutcomeDistribution}
          distributionStudents={mockStudents}
          isOpen={true}
          onCloseHandler={vi.fn()}
          renderTrigger={<button>Trigger</button>}
        />,
      )

      const nearMasteryBar = screen.getByTestId('bar-near-mastery')
      fireEvent.click(nearMasteryBar)

      await waitFor(() => {
        expect(screen.getByTestId('student-list-section')).toBeInTheDocument()
        expect(screen.getByText('No students')).toBeInTheDocument()
      })
    })

    it('displays student avatars in the filtered list', async () => {
      renderWithContext(
        <OutcomeDistributionPopover
          outcome={outcome}
          outcomeDistribution={mockOutcomeDistribution}
          distributionStudents={mockStudents}
          isOpen={true}
          onCloseHandler={vi.fn()}
          renderTrigger={<button>Trigger</button>}
        />,
      )

      const exceedsBar = screen.getByTestId('bar-exceeds-mastery')
      fireEvent.click(exceedsBar)

      await waitFor(() => {
        const avatars = screen.getAllByTestId('student-avatar')
        expect(avatars).toHaveLength(2)
      })
    })
  })
})
