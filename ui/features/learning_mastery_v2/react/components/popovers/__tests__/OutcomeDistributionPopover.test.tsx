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
import {Outcome} from '@canvas/outcomes/react/types/rollup'
import LMGBContext from '@canvas/outcomes/react/contexts/LMGBContext'

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
})
