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
import {render, fireEvent, act} from '@testing-library/react'
import {MockedProvider} from '@apollo/client/testing'
import {OutcomeManagementWithoutGraphql as OutcomeManagement} from '../OutcomeManagement'
import {
  masteryCalculationGraphqlMocks,
  masteryScalesGraphqlMocks,
} from '@canvas/outcomes/mocks/Outcomes'
import {createCache} from '@canvas/apollo-v3'
import {windowConfirm} from '@canvas/util/globalUtils'
import {useAllPages} from '@canvas/query'

vi.mock('@canvas/query', () => ({
  useAllPages: vi.fn(),
}))

vi.mock('@canvas/outcomes/react/OutcomesImporter', () => ({
  showOutcomesImporter: vi.fn(() => vi.fn(() => {})),
  showOutcomesImporterIfInProgress: vi.fn(() => vi.fn(() => {})),
}))

vi.mock('@canvas/util/globalUtils', async () => ({
  ...(await vi.importActual('@canvas/util/globalUtils')),
  windowConfirm: vi.fn(() => true),
}))

describe('OutcomeManagement Changes confirmation', () => {
  let cache
  let originalAddEventListener, unloadEventListener

  beforeAll(() => {
    originalAddEventListener = window.addEventListener
    window.addEventListener = (eventName, callback) => {
      if (eventName === 'beforeunload') {
        unloadEventListener = callback
      }
    }
  })

  beforeEach(() => {
    cache = createCache()
    vi.useFakeTimers()
    vi.clearAllMocks()
    window.ENV = {
      context_asset_string: 'account_11',
      CONTEXT_URL_ROOT: '/account/11',
      PERMISSIONS: {
        manage_proficiency_calculations: true,
      },
      current_user: {id: '1'},
      ACCOUNT_LEVEL_MASTERY_SCALES: true,
      IMPROVED_OUTCOMES_MANAGEMENT: true,
    }
  })

  afterEach(() => {
    vi.clearAllMocks()
    vi.useRealTimers()
    window.ENV = null
  })

  afterAll(() => {
    window.addEventListener = originalAddEventListener
    unloadEventListener = null
  })

  it("Doesn't ask to confirm tab change when there is not change", () => {
    useAllPages.mockReturnValue({
      data: {pages: [masteryScalesGraphqlMocks[0].result.data]},
      isError: false,
      isLoading: false,
    })
    const {getByText} = render(
      <MockedProvider
        cache={cache}
        mocks={[...masteryCalculationGraphqlMocks, ...masteryScalesGraphqlMocks]}
      >
        <OutcomeManagement />
      </MockedProvider>,
    )

    fireEvent.click(getByText('Mastery'))
    fireEvent.click(getByText('Calculation'))

    expect(windowConfirm).not.toHaveBeenCalled()
  })

  it('Asks to confirm tab change when there is changes', async () => {
    useAllPages.mockReturnValue({
      data: {pages: [masteryScalesGraphqlMocks[0].result.data]},
      isError: false,
      isLoading: false,
    })
    const {getByText, getByLabelText, getByTestId} = render(
      <MockedProvider
        cache={cache}
        mocks={[...masteryCalculationGraphqlMocks, ...masteryScalesGraphqlMocks]}
      >
        <OutcomeManagement />
      </MockedProvider>,
    )

    fireEvent.click(getByText('Calculation'))
    await act(async () => vi.runAllTimers())
    fireEvent.input(getByLabelText('Parameter'), {target: {value: ''}})
    fireEvent.click(getByText('Mastery'))
    await act(async () => vi.runAllTimers())
    expect(windowConfirm).toHaveBeenCalledWith(
      'Are you sure you want to proceed? Changes you made will not be saved.',
    )
    expect(getByTestId('masteryScales')).toBeInTheDocument()
  })

  it("Doesn't change tabs when doesn't confirm", async () => {
    // mock decline from user
    windowConfirm.mockImplementationOnce(() => false)

    const {getByText, getByLabelText, queryByTestId} = render(
      <MockedProvider
        cache={cache}
        mocks={[...masteryCalculationGraphqlMocks, ...masteryScalesGraphqlMocks]}
      >
        <OutcomeManagement />
      </MockedProvider>,
    )

    fireEvent.click(getByText('Calculation'))
    await act(async () => vi.runAllTimers())
    fireEvent.input(getByLabelText('Parameter'), {target: {value: ''}})
    fireEvent.click(getByText('Mastery'))
    expect(queryByTestId('masteryScales')).not.toBeInTheDocument()
  })

  it("Allows to leave page when doesn't have changes", async () => {
    const {getByText} = render(
      <MockedProvider
        cache={cache}
        mocks={[...masteryCalculationGraphqlMocks, ...masteryScalesGraphqlMocks]}
      >
        <OutcomeManagement />
      </MockedProvider>,
    )

    const calculationButton = getByText('Calculation')
    fireEvent.click(calculationButton)

    await act(async () => vi.runAllTimers())

    const e = vi.fn()
    e.preventDefault = vi.fn()
    unloadEventListener(e)
    expect(e.preventDefault).not.toHaveBeenCalled()
  })

  it("Doesn't Allow to leave page when has changes", async () => {
    const {getByText, getByLabelText} = render(
      <MockedProvider
        cache={cache}
        mocks={[...masteryCalculationGraphqlMocks, ...masteryScalesGraphqlMocks]}
      >
        <OutcomeManagement />
      </MockedProvider>,
    )

    const calculationButton = getByText('Calculation')
    fireEvent.click(calculationButton)

    await act(async () => vi.runAllTimers())

    const parameter = getByLabelText(/Parameter/)
    fireEvent.input(parameter, {target: {value: '88'}})

    const e = vi.fn()
    e.preventDefault = vi.fn()
    unloadEventListener(e)
    expect(e.preventDefault).toHaveBeenCalled()
  })
})
