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
import {act, render as rtlRender, waitFor, fireEvent} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {
  ACCOUNT_OUTCOME_CALCULATION_QUERY,
  SET_OUTCOME_CALCULATION_METHOD,
} from '@canvas/outcomes/graphql/MasteryCalculation'
import MasteryCalculation from '../index'
import {masteryCalculationGraphqlMocks} from '@canvas/outcomes/mocks/Outcomes'

jest.useFakeTimers()

describe('MasteryCalculation', () => {
  beforeEach(() => {
    window.ENV = {
      PROFICIENCY_CALCULATION_METHOD_ENABLED_ROLES: [
        {
          id: '1',
          role: 'AccountAdmin',
          label: 'Account Admin',
          base_role_type: 'AccountMembership',
          is_account_role: true,
        },
        {
          id: '2',
          role: 'TeacherEnrollment',
          label: 'Teacher',
          base_role_type: 'TeacherEnrollment',
          is_account_role: false,
        },
      ],
      PERMISSIONS: {
        manage_proficiency_calculations: true,
      },
    }
  })

  afterEach(() => {
    window.ENV = null
  })

  const render = (
    children,
    {contextType = 'Account', contextId = '11', mocks = masteryCalculationGraphqlMocks} = {}
  ) => {
    return rtlRender(
      <OutcomesContext.Provider value={{env: {contextType, contextId}}}>
        <MockedProvider addTypename={false} mocks={mocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>
    )
  }

  it('loads proficiency data for Account', async () => {
    const {getByDisplayValue} = render(<MasteryCalculation />)
    await act(async () => jest.runAllTimers())
    expect(getByDisplayValue(/65/)).not.toEqual(null)
  })

  it('loads calculation data for Course', async () => {
    const {getByDisplayValue} = render(<MasteryCalculation />, {
      contextType: 'Course',
      contextId: '12',
    })
    await act(async () => jest.runAllTimers())
    expect(getByDisplayValue(/65/)).not.toEqual(null)
  })

  it('loads role list', async () => {
    const {getByText, getAllByText} = render(<MasteryCalculation />)
    await act(async () => jest.runAllTimers())
    expect(
      getByText(/Permission to change this mastery calculation at the account level is enabled for/)
    ).not.toEqual(null)
    expect(
      getByText(/Permission to change this mastery calculation at the course level is enabled for/)
    ).not.toEqual(null)
    expect(getAllByText(/Account Admin/).length).not.toBe(0)
    expect(getByText(/Teacher/)).not.toEqual(null)
  })

  it('displays an error on failed request', async () => {
    const {getByText} = render(<MasteryCalculation />, {mocks: []})
    await act(async () => jest.runAllTimers())
    expect(getByText(/An error occurred/)).not.toEqual(null)
  })

  it('loads default data when request returns no ratings/method', async () => {
    const emptyMocks = [
      {
        request: {
          query: ACCOUNT_OUTCOME_CALCULATION_QUERY,
          variables: {
            contextId: '11',
          },
        },
        result: {
          data: {
            context: {
              __typename: 'Account',
              outcomeCalculationMethod: null,
            },
          },
        },
      },
    ]
    const {getByText} = render(<MasteryCalculation />, {mocks: emptyMocks})
    await act(async () => jest.runAllTimers())
    expect(getByText('Mastery Calculation')).not.toBeNull()
  })

  describe('update outcomeCalculationMethod', () => {
    const variables = {
      contextType: 'Account',
      contextId: '11',
      calculationMethod: 'decaying_average',
      calculationInt: 88,
    }
    const updateCall = jest.fn(() => ({
      data: {
        createOutcomeCalculationMethod: {
          outcomeCalculationMethod: {
            _id: '1',
            locked: false,
            ...variables,
          },
          errors: [],
        },
      },
    }))
    const updateMocks = [
      ...masteryCalculationGraphqlMocks,
      {
        request: {
          query: SET_OUTCOME_CALCULATION_METHOD,
          variables,
        },
        result: updateCall,
      },
    ]
    it('submits a request when calculation method is saved', async () => {
      const {getByText, findByLabelText} = render(<MasteryCalculation />, {mocks: updateMocks})
      await act(async () => jest.runAllTimers())
      const parameter = await findByLabelText(/Parameter/)
      fireEvent.input(parameter, {target: {value: '88'}})
      fireEvent.click(getByText('Save Mastery Calculation'))
      fireEvent.click(getByText('Save'))
      await waitFor(() => {
        expect(updateCall).toHaveBeenCalled()
      })
    })
  })
})
