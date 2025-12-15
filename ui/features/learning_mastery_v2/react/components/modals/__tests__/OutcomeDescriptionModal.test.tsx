/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import {OutcomeDescriptionModal} from '../OutcomeDescriptionModal'
import {Outcome} from '../../../types/rollup'
import LMGBContext from '@canvas/outcomes/react/contexts/LMGBContext'
import {pick} from 'es-toolkit/compat'
import {defaultRatings, defaultMasteryPoints} from '@canvas/outcomes/react/hooks/useRatings'

describe('OutcomeDescriptionModal', () => {
  let onCloseHandlerMock: any

  const setCalculationMethod = (
    outcome: Outcome,
    method: string,
    calculationInt: number | null = null,
  ): Outcome => {
    return {
      ...outcome,
      calculation_method: method,
      calculation_int: calculationInt ?? outcome.calculation_int,
    }
  }

  const defaultOutcome: Outcome = {
    id: '1',
    title: 'Outcome',
    context_type: 'Course',
    context_id: '1',
    description: '<p>Outcome Description</p>',
    display_name: 'Friendly Outcome Name',
    friendly_description: 'Friendly Description',
    calculation_method: 'decaying_average',
    calculation_int: 65,
    points_possible: 5,
    mastery_points: defaultMasteryPoints,
    ratings: defaultRatings.map(rating =>
      pick(rating, ['description', 'points', 'color', 'mastery']),
    ),
  }

  const outcomeNoFriendlyDescription: Outcome = {
    id: '1',
    title: 'Outcome',
    context_type: 'Course',
    context_id: '1',
    description: '<p>Outcome Description</p>',
    display_name: 'Friendly Outcome Name',
    calculation_method: 'decaying_average',
    calculation_int: 65,
    points_possible: 5,
    mastery_points: defaultMasteryPoints,
    ratings: defaultRatings.map(rating =>
      pick(rating, ['description', 'points', 'color', 'mastery']),
    ),
  }

  const outcomeEmpty: Outcome = {
    id: '1',
    title: 'Outcome',
    context_type: 'Course',
    context_id: '1',
    description: '',
    display_name: '',
    calculation_method: 'decaying_average',
    calculation_int: 65,
    points_possible: 5,
    mastery_points: defaultMasteryPoints,
    ratings: defaultRatings.map(rating =>
      pick(rating, ['description', 'points', 'color', 'mastery']),
    ),
  }

  const defaultProps = (outcome: Outcome) => ({
    outcome,
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
  })

  interface RenderWithProviderOptions {
    outcome?: Outcome
    overrides?: Record<string, any>
    env?: {
      contextType: string
      contextId: string
      outcomesFriendlyDescriptionFF: boolean
      accountLevelMasteryScalesFF: boolean
      contextURL?: string
    }
  }

  const renderWithProvider = ({
    outcome = defaultOutcome,
    overrides = {},
    env = {
      contextType: 'Account',
      contextId: '1',
      outcomesFriendlyDescriptionFF: false,
      accountLevelMasteryScalesFF: true,
      contextURL: '',
    },
  }: RenderWithProviderOptions = {}) => {
    return render(
      <LMGBContext.Provider value={{env}}>
        <OutcomeDescriptionModal {...defaultProps(outcome)} {...overrides} />
      </LMGBContext.Provider>,
    )
  }

  beforeEach(() => {
    onCloseHandlerMock = vi.fn()
  })

  it('shows modal if isOpen prop is true', () => {
    renderWithProvider()
    expect(screen.getByTestId('outcome-description-modal')).toBeInTheDocument()
  })

  it('does not show modal if isOpen prop is false', () => {
    renderWithProvider({overrides: {isOpen: false}})
    expect(screen.queryByTestId('outcome-description-modal')).not.toBeInTheDocument()
  })

  it('calls onCloseHandler when closing the modal', async () => {
    const user = userEvent.setup()
    renderWithProvider()
    await user.click(screen.getByRole('button'))
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('correctly renders outcome information in modal', () => {
    renderWithProvider()
    expect(screen.getByTestId('outcome-display-name')).toBeInTheDocument()
    expect(screen.getByText('Calculation Method')).toBeInTheDocument()
    expect(screen.getByText('Mastery Scale')).toBeInTheDocument()
    expect(screen.getByTestId('outcome-description')).toBeInTheDocument()
  })

  it('renders "empty outcome" information when given an outcome with no display name, description, or friendly description', () => {
    renderWithProvider({outcome: outcomeEmpty})
    expect(screen.getByTestId('outcome-empty-title')).toBeInTheDocument()
    expect(screen.getByTestId('outcome-empty-description')).toBeInTheDocument()
  })

  describe('Outcome Calculation Methods', () => {
    it("renders correctly when given an outcome with 'decaying_average' calculation method", () => {
      renderWithProvider({
        outcome: setCalculationMethod(defaultOutcome, 'decaying_average', 65),
      })
      expect(screen.getByText('Weighted Average')).toBeInTheDocument()
    })

    it("renders correctly when given an outcome with 'standard_decaying_average' calculation method", () => {
      renderWithProvider({
        outcome: setCalculationMethod(defaultOutcome, 'standard_decaying_average', 65),
      })
      expect(screen.getByText('Decaying Average')).toBeInTheDocument()
    })

    it("renders correctly when given an outcome with 'n_mastery' calculation method", () => {
      renderWithProvider({
        outcome: setCalculationMethod(defaultOutcome, 'n_mastery', 5),
      })
      expect(screen.getByText('Number of Times')).toBeInTheDocument()
    })

    it("renders correctly when given an outcome with 'highest' calculation method", () => {
      renderWithProvider({
        outcome: setCalculationMethod(defaultOutcome, 'highest'),
      })
      expect(screen.getByText('Highest')).toBeInTheDocument()
    })

    it("renders correctly when given an outcome with 'latest' calculation method", () => {
      renderWithProvider({
        outcome: setCalculationMethod(defaultOutcome, 'latest'),
      })
      expect(screen.getByText('Most Recent Score')).toBeInTheDocument()
    })

    it("renders correctly when given an outcome with 'average' calculation method", () => {
      renderWithProvider({
        outcome: setCalculationMethod(defaultOutcome, 'average'),
      })
      expect(screen.getByText('Average')).toBeInTheDocument()
    })

    it("renders 'Average' when given an outcome with invalid calculation method", () => {
      renderWithProvider({
        outcome: setCalculationMethod(defaultOutcome, 'not_a_calculation_method'),
      })
      expect(screen.getByText('Average')).toBeInTheDocument()
    })
  })

  describe('Outcome Friendly Descriptions', () => {
    const friendlyEnv = {
      contextType: 'Account',
      contextId: '1',
      outcomesFriendlyDescriptionFF: true,
      accountLevelMasteryScalesFF: true,
      contextURL: '',
    }

    it('does not render friendly description if FF is disabled', () => {
      renderWithProvider()
      expect(screen.queryByTestId('outcome-friendly-description')).not.toBeInTheDocument()
    })

    it('renders friendly description if FF is enabled', () => {
      renderWithProvider({env: friendlyEnv})
      expect(screen.getByTestId('outcome-friendly-description')).toBeInTheDocument()
    })

    it('does not render friendly description if FF is enabled but no friendly description is given', () => {
      renderWithProvider({
        outcome: outcomeNoFriendlyDescription,
        env: friendlyEnv,
      })
      expect(screen.queryByTestId('outcome-friendly-description')).not.toBeInTheDocument()
    })
  })

  describe('Mastery Scale', () => {
    it('renders mastery scale with points_possible', () => {
      renderWithProvider()
      expect(screen.getByText('5 Point')).toBeInTheDocument()
    })

    it('renders mastery scale with different points_possible value', () => {
      const outcomeWithDifferentPoints = {...defaultOutcome, points_possible: 10}
      renderWithProvider({outcome: outcomeWithDifferentPoints})
      expect(screen.getByText('10 Point')).toBeInTheDocument()
    })
  })

  describe('Conditional Rendering', () => {
    it('does not render display_name when it is missing', () => {
      const outcomeNoDisplayName = {...defaultOutcome, display_name: undefined}
      renderWithProvider({outcome: outcomeNoDisplayName})
      expect(screen.queryByTestId('outcome-display-name')).not.toBeInTheDocument()
    })

    it('does not render description when it is missing', () => {
      const outcomeNoDescription = {...defaultOutcome, description: undefined}
      renderWithProvider({outcome: outcomeNoDescription})
      expect(screen.queryByTestId('outcome-description')).not.toBeInTheDocument()
    })

    it('renders display_name when it exists', () => {
      renderWithProvider()
      expect(screen.getByTestId('outcome-display-name')).toBeInTheDocument()
    })

    it('renders description when it exists', () => {
      renderWithProvider()
      expect(screen.getByTestId('outcome-description')).toBeInTheDocument()
    })
  })
})
