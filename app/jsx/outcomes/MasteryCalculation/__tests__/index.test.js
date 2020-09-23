/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {render, wait, fireEvent} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import {OUTCOME_PROFICIENCY_QUERY, SET_OUTCOME_CALCULATION_METHOD} from '../api'
import MasteryCalculation from '../index'

describe('MasteryCalculation', () => {
  const mocks = [
    {
      request: {
        query: OUTCOME_PROFICIENCY_QUERY,
        variables: {
          contextId: '11'
        }
      },
      result: {
        data: {
          account: {
            __typename: 'Account',
            outcomeCalculationMethod: {
              __typename: 'OutcomeCalculationMethod',
              _id: '1',
              contextType: 'Account',
              contextId: 1,
              calculationMethod: 'decaying_average',
              calculationInt: 65,
              locked: false
            }
          }
        }
      }
    }
  ]

  it('loads proficiency data', async () => {
    const {getByText, getByDisplayValue} = render(
      <MockedProvider mocks={mocks}>
        <MasteryCalculation contextType="Account" contextId="11" />
      </MockedProvider>
    )
    expect(getByText('Loading')).not.toEqual(null)
    await wait()
    expect(getByDisplayValue(/65/)).not.toEqual(null)
  })

  it('displays an error on failed request', async () => {
    const {getByText} = render(
      <MockedProvider mocks={[]}>
        <MasteryCalculation contextType="Account" contextId="11" />
      </MockedProvider>
    )
    await wait()
    expect(getByText(/An error occurred/)).not.toEqual(null)
  })

  it('loads default data when request returns no ratings/method', async () => {
    const emptyMocks = [
      {
        request: {
          query: OUTCOME_PROFICIENCY_QUERY,
          variables: {
            contextId: '11'
          }
        },
        result: {
          data: {
            account: {
              __typename: 'Account',
              outcomeCalculationMethod: null
            }
          }
        }
      }
    ]
    const {getByText} = render(
      <MockedProvider mocks={emptyMocks}>
        <MasteryCalculation contextType="Account" contextId="11" />
      </MockedProvider>
    )
    await wait()
    expect(getByText('Proficiency Calculation')).not.toBeNull()
  })

  describe('update outcomeCalculationMethod', () => {
    const variables = {
      contextType: 'Account',
      contextId: '11',
      calculationMethod: 'decaying_average',
      calculationInt: 88
    }
    const updateCall = jest.fn(() => ({
      data: {
        createOutcomeCalculationMethod: {
          outcomeCalculationMethod: {
            _id: '1',
            locked: false,
            ...variables
          },
          errors: []
        }
      }
    }))
    const updateMocks = [
      ...mocks,
      {
        request: {
          query: SET_OUTCOME_CALCULATION_METHOD,
          variables
        },
        result: updateCall
      }
    ]
    it('submits a request when calculation method is updated', async () => {
      const {findByLabelText} = render(
        <MockedProvider mocks={updateMocks} addTypename={false}>
          <MasteryCalculation contextType="Account" contextId="11" />
        </MockedProvider>
      )
      const parameter = await findByLabelText(/Parameter/)
      fireEvent.input(parameter, {target: {value: '88'}})

      await wait(() => expect(updateCall).toHaveBeenCalled())
    })
  })
})
