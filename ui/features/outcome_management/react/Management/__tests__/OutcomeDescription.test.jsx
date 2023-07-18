/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render as rtlRender} from '@testing-library/react'
import OutcomeDescription from '../OutcomeDescription'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {defaultRatingsAndCalculationMethod} from './helpers'

describe('OutcomeDescription', () => {
  let setShouldExpandMock
  const empty = ''
  const truncatedTestId = 'description-truncated'
  const ratingsTestId = 'outcome-management-ratings'
  const expandedTestId = 'description-expanded'
  const friendlyExpandedTestId = 'friendly-description-expanded'
  const {calculationMethod, calculationInt, masteryPoints, pointsPossible, ratings} =
    defaultRatingsAndCalculationMethod
  const defaultProps = (props = {}) => ({
    truncated: true,
    description: 'Description',
    friendlyDescription: '',
    calculationMethod,
    calculationInt,
    masteryPoints,
    pointsPossible,
    ratings,
    setShouldExpand: setShouldExpandMock,
    ...props,
  })

  beforeEach(() => {
    setShouldExpandMock = jest.fn()
  })

  const render = (
    children,
    {friendlyDescriptionFF = false, accountLevelMasteryScalesFF = true, isStudent = false} = {}
  ) => {
    return rtlRender(
      <OutcomesContext.Provider
        value={{env: {friendlyDescriptionFF, accountLevelMasteryScalesFF, isStudent}}}
      >
        {children}
      </OutcomesContext.Provider>
    )
  }

  it('renders truncated Description when description prop provided and truncated prop true', () => {
    const {queryByTestId} = render(<OutcomeDescription {...defaultProps()} />)
    expect(queryByTestId(truncatedTestId)).toBeInTheDocument()
  })

  it('renders expanded Description when description prop provided and truncated prop false', () => {
    const {queryByTestId} = render(<OutcomeDescription {...defaultProps({truncated: false})} />)
    expect(queryByTestId(expandedTestId)).toBeInTheDocument()
  })

  it('does not render Description when description prop not provided/null', () => {
    const {queryByTestId} = render(<OutcomeDescription {...defaultProps({description: null})} />)
    expect(queryByTestId(truncatedTestId)).not.toBeInTheDocument()
  })

  it('does not render Description when description prop is empty', () => {
    const {queryByTestId} = render(<OutcomeDescription {...defaultProps({description: empty})} />)
    expect(queryByTestId(truncatedTestId)).not.toBeInTheDocument()
  })

  it('renders non-expandable description when description is provided in text format and truncate prop true', () => {
    const {queryByTestId} = render(
      <OutcomeDescription {...defaultProps({description: 'Text description'})} />
    )
    expect(queryByTestId(truncatedTestId)).toBeInTheDocument()
  })

  describe('with friendly description', () => {
    describe('feature flag enabled', () => {
      it('displays the friendly description when expanded', () => {
        const {queryByTestId} = render(
          <OutcomeDescription
            {...defaultProps({
              truncated: false,
              friendlyDescription: 'Friendly Description',
            })}
          />,
          {
            friendlyDescriptionFF: true,
          }
        )
        expect(queryByTestId(friendlyExpandedTestId)).toBeInTheDocument()
      })

      it('displays the friendly description as the description if the user is a student', () => {
        const {queryByTestId, getByText} = render(
          <OutcomeDescription
            {...defaultProps({
              truncated: false,
              friendlyDescription: 'Friendly Description',
            })}
          />,
          {
            friendlyDescriptionFF: true,
            isStudent: true,
          }
        )
        expect(queryByTestId(friendlyExpandedTestId)).not.toBeInTheDocument()
        expect(getByText('Friendly Description')).toBeInTheDocument()
      })

      it('displays the friendly description as the description if there is no description', () => {
        const {queryByTestId, getByText} = render(
          <OutcomeDescription
            {...defaultProps({
              truncated: false,
              friendlyDescription: 'Very Friendly Text',
              description: '',
            })}
          />,
          {
            friendlyDescriptionFF: true,
          }
        )
        expect(queryByTestId(friendlyExpandedTestId)).not.toBeInTheDocument()
        expect(queryByTestId('Description')).not.toBeInTheDocument()
        expect(getByText('Very Friendly Text')).toBeInTheDocument()
      })
    })

    describe('feature flag disabled', () => {
      it('does not display the friendly description', () => {
        const {queryByTestId} = render(
          <OutcomeDescription
            {...defaultProps({
              truncated: false,
              friendlyDescription: 'Friendly Description',
            })}
          />
        )
        expect(queryByTestId(friendlyExpandedTestId)).not.toBeInTheDocument()
      })

      it('does not display the friendly description as the description if the user is a student', () => {
        const {getByTestId, queryByTestId, queryByText} = render(
          <OutcomeDescription
            {...defaultProps({
              truncated: false,
              friendlyDescription: 'Friendly Description',
            })}
          />,
          {
            isStudent: true,
          }
        )
        expect(getByTestId(expandedTestId)).toBeInTheDocument()
        expect(queryByTestId(friendlyExpandedTestId)).not.toBeInTheDocument()
        expect(queryByText('Friendly Description')).not.toBeInTheDocument()
      })
    })
  })

  describe('account level mastery scales FF', () => {
    describe('when feature flag disabled', () => {
      it('renders ratings when description prop not provided/null and expanded', () => {
        const {queryByTestId} = render(
          <OutcomeDescription {...defaultProps({description: null, truncated: false})} />,
          {
            accountLevelMasteryScalesFF: false,
          }
        )
        expect(queryByTestId(ratingsTestId)).toBeInTheDocument()
      })

      it('displays calculation method if description expanded', () => {
        const {getByText} = render(<OutcomeDescription {...defaultProps({truncated: false})} />, {
          accountLevelMasteryScalesFF: false,
        })
        expect(getByText('Proficiency Calculation:')).toBeInTheDocument()
      })

      it('hides calculation method if description truncated', () => {
        const {queryByText} = render(<OutcomeDescription {...defaultProps()} />, {
          accountLevelMasteryScalesFF: false,
        })
        expect(queryByText('Proficiency Calculation:')).not.toBeInTheDocument()
      })
    })

    describe('when feature flag enabled', () => {
      it('hides calculation method', () => {
        const {queryByText} = render(<OutcomeDescription {...defaultProps({truncated: false})} />)
        expect(queryByText('Proficiency Calculation:')).not.toBeInTheDocument()
      })
    })
  })
})
