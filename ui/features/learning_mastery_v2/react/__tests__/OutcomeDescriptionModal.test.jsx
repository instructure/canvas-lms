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
import {render, fireEvent} from '@testing-library/react'
import OutcomeDescriptionModal from '../OutcomeDescriptionModal'
import LMGBContext from '@canvas/outcomes/react/contexts/LMGBContext'
import {pick} from 'lodash'
import {defaultRatings, defaultMasteryPoints} from '@canvas/outcomes/react/hooks/useRatings'

describe('OutcomeDescriptionModal', () => {
  let onCloseHandlerMock

  const setCalculationMethod = (outcome, method, calculationInt = null) => {
    outcome.calculation_method = method
    outcome.calculation_int = calculationInt
    return outcome
  }

  const defaultOutcome = {
    id: '1',
    title: 'Outcome',
    description: '<p>Outcome Description</p>',
    display_name: 'Friendly Outcome Name',
    friendly_description: 'Friendly Description',
    context_type: 'Account',
    context_id: '1',
    calculation_method: 'decaying_average',
    calculation_int: 65,
    mastery_points: defaultMasteryPoints,
    ratings: defaultRatings.map(rating =>
      pick(rating, ['description', 'points', 'color', 'mastery'])
    ),
  }

  const outcomeNoFriendlyDescription = {
    id: '1',
    title: 'Outcome',
    description: '<p>Outcome Description</p>',
    display_name: 'Friendly Outcome Name',
    friendly_description: null,
    context_type: 'Account',
    context_id: '1',
    calculation_method: 'decaying_average',
    calculation_int: 65,
    mastery_points: defaultMasteryPoints,
    ratings: defaultRatings.map(rating =>
      pick(rating, ['description', 'points', 'color', 'mastery'])
    ),
  }

  const outcomeEmpty = {
    id: '1',
    title: 'Outcome',
    description: '',
    display_name: '',
    friendly_description: null,
    context_type: 'Account',
    context_id: '1',
    calculation_method: 'decaying_average',
    calculation_int: 65,
    mastery_points: defaultMasteryPoints,
    ratings: defaultRatings.map(rating =>
      pick(rating, ['description', 'points', 'color', 'mastery'])
    ),
  }

  const defaultProps = outcome => ({
    outcome: outcome,
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
  })

  const renderWithProvider = ({
    outcome = defaultOutcome,
    overrides = {},
    env = {
      contextType: 'Account',
      contextId: '1',
      outcomesFriendlyDescriptionFF: false,
      accountLevelMasteryScalesFF: true,
    },
  } = {}) => {
    return render(
      <LMGBContext.Provider value={{env}}>
        <OutcomeDescriptionModal {...defaultProps(outcome)} {...overrides} />
      </LMGBContext.Provider>
    )
  }

  beforeEach(() => {
    onCloseHandlerMock = jest.fn()
  })

  it('shows modal if isOpen prop is true', () => {
    const {getByTestId} = renderWithProvider()
    expect(getByTestId('outcome-description-modal')).toBeInTheDocument()
  })

  it('does not show modal if isOpen prop is false', () => {
    const {queryByTestId} = renderWithProvider({overrides: {isOpen: false}})
    expect(queryByTestId('outcome-description-modal')).not.toBeInTheDocument()
  })

  it('calls onCloseHandler when closing the modal', () => {
    const {getByRole} = renderWithProvider()
    fireEvent.click(getByRole('button'))
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('correctly renders outcome information in modal', () => {
    const {getByTestId} = renderWithProvider()
    expect(getByTestId('outcome-display-name')).toBeInTheDocument()
    expect(getByTestId('calculation-method')).toBeInTheDocument()
    expect(getByTestId('outcome-description')).toBeInTheDocument()
  })

  it('renders "empty outcome" information when given an outcome with no display name, description, or friendly description', () => {
    const {getByTestId} = renderWithProvider({outcome: outcomeEmpty})
    expect(getByTestId('outcome-empty-title')).toBeInTheDocument()
    expect(getByTestId('outcome-empty-description')).toBeInTheDocument()
  })

  describe('Outcome Calculation Methods', () => {
    it("renders correctly when given an outcome with 'decaying_average' calculation method", () => {
      const {getByText} = renderWithProvider({
        outcome: setCalculationMethod(defaultOutcome, 'decaying_average', 65),
      })
      expect(getByText('65/35 Weighted Average')).toBeInTheDocument()
    })

    it("renders correctly when given an outcome with 'standard_decaying_average' calculation method", () => {
      const {getByText} = renderWithProvider({
        outcome: setCalculationMethod(defaultOutcome, 'standard_decaying_average', 65),
      })
      expect(getByText('65/35 Decaying Average')).toBeInTheDocument()
    })

    it("renders correctly when given an outcome with 'n_mastery' calculation method", () => {
      const {getByText} = renderWithProvider({
        outcome: setCalculationMethod(defaultOutcome, 'n_mastery', 5),
      })
      expect(getByText('Number of Times (5)')).toBeInTheDocument()
    })

    it("renders correctly when given an outcome with 'highest' calculation method", () => {
      const {getByText} = renderWithProvider({
        outcome: setCalculationMethod(defaultOutcome, 'highest'),
      })
      expect(getByText('Highest')).toBeInTheDocument()
    })

    it("renders correctly when given an outcome with 'latest' calculation method", () => {
      const {getByText} = renderWithProvider({
        outcome: setCalculationMethod(defaultOutcome, 'latest'),
      })
      expect(getByText('Most Recent Score')).toBeInTheDocument()
    })

    it("renders correctly when given an outcome with 'average' calculation method", () => {
      const {getByText} = renderWithProvider({
        outcome: setCalculationMethod(defaultOutcome, 'average'),
      })
      expect(getByText('Average')).toBeInTheDocument()
    })

    it("renders 'Average' when given an outcome with invalid calculation method", () => {
      const {getByText} = renderWithProvider({
        outcome: setCalculationMethod(defaultOutcome, 'not_a_calculation_method'),
      })
      expect(getByText('Average')).toBeInTheDocument()
    })
  })

  describe('Outcome Friendly Descriptions', () => {
    const friendlyEnv = {
      contextType: 'Account',
      contextId: '1',
      outcomesFriendlyDescriptionFF: true,
      accountLevelMasteryScalesFF: true,
    }

    it('does not render friendly description if FF is disabled', () => {
      const {queryByTestId} = renderWithProvider()
      expect(queryByTestId('outcome-friendly-description')).not.toBeInTheDocument()
    })

    it('renders friendly description if FF is enabled', () => {
      const {getByTestId} = renderWithProvider({env: friendlyEnv})
      expect(getByTestId('outcome-friendly-description')).toBeInTheDocument()
    })

    it('does not render friendly description if FF is enabled but no friendly description is given', () => {
      const {queryByTestId} = renderWithProvider({
        outcome: outcomeNoFriendlyDescription,
        env: friendlyEnv,
      })
      expect(queryByTestId('outcome-friendly-description')).not.toBeInTheDocument()
    })
  })
})
