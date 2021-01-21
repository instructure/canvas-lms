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
import {MockedProvider} from '@apollo/react-testing'
import {
  OutcomePanel,
  OutcomeManagementWithoutGraphql as OutcomeManagement
} from '../OutcomeManagement'
import {
  masteryCalculationGraphqlMocks,
  masteryScalesGraphqlMocks,
  outcomeGroupsMocks
} from './mocks'
import {createCache} from '../../canvas-apollo'

jest.useFakeTimers()

describe('OutcomeManagement', () => {
  let cache

  beforeEach(() => {
    cache = createCache()
  })

  const sharedExamples = () => {
    it('renders the OutcomeManagement and shows the "outcomes" div', () => {
      document.body.innerHTML = '<div id="outcomes" style="display:none">Outcomes Tab</div>'
      render(<OutcomeManagement />)
      expect(document.getElementById('outcomes').style.display).toBe('block')
    })

    it('does not render ManagementHeader', () => {
      const {queryByTestId} = render(<OutcomeManagement />)
      expect(queryByTestId('managementHeader')).not.toBeInTheDocument()
    })

    it('renders ManagementHeader when improved outcomes enabled', async () => {
      window.ENV.IMPROVED_OUTCOMES_MANAGEMENT = true
      const {getByText, getByTestId} = render(
        <MockedProvider cache={cache} mocks={[...outcomeGroupsMocks]}>
          <OutcomeManagement />
        </MockedProvider>
      )
      expect(getByText(/Loading/)).toBeInTheDocument()
      await act(async () => jest.runAllTimers())
      expect(getByTestId('managementHeader')).toBeInTheDocument()
      delete window.ENV.IMPROVED_OUTCOMES_MANAGEMENT
    })

    it('does not render OutcomeManagementPanel', () => {
      const {queryByTestId} = render(<OutcomeManagement />)
      expect(queryByTestId('outcomeManagementPanel')).not.toBeInTheDocument()
    })

    it('renders OutcomeManagementPanel when improved outcomes enabled', async () => {
      window.ENV.IMPROVED_OUTCOMES_MANAGEMENT = true
      const {getByText, getByTestId} = render(
        <MockedProvider cache={cache} mocks={[...outcomeGroupsMocks]}>
          <OutcomeManagement />
        </MockedProvider>
      )
      expect(getByText(/Loading/)).toBeInTheDocument()
      await act(async () => jest.runAllTimers())
      expect(getByTestId('outcomeManagementPanel')).toBeInTheDocument()
      delete window.ENV.IMPROVED_OUTCOMES_MANAGEMENT
    })

    describe('Changes confirmation', () => {
      let originalConfirm, originalAddEventListener, unloadEventListener

      beforeAll(() => {
        originalConfirm = window.confirm
        originalAddEventListener = window.addEventListener
        window.confirm = jest.fn(() => true)
        window.addEventListener = (eventName, callback) => {
          if (eventName === 'beforeunload') {
            unloadEventListener = callback
          }
        }
      })

      afterAll(() => {
        window.confirm = originalConfirm
        window.addEventListener = originalAddEventListener
        unloadEventListener = null
      })

      it("Doesn't ask to confirm tab change when there is not change", () => {
        const {getByText} = render(
          <MockedProvider
            cache={cache}
            mocks={[...masteryCalculationGraphqlMocks, ...masteryScalesGraphqlMocks]}
          >
            <OutcomeManagement />
          </MockedProvider>
        )

        fireEvent.click(getByText('Mastery'))
        fireEvent.click(getByText('Calculation'))

        expect(window.confirm).not.toHaveBeenCalled()
      })

      it('Asks to confirm tab change when there is changes', async () => {
        const {getByText, getByLabelText, getByTestId} = render(
          <MockedProvider
            cache={cache}
            mocks={[...masteryCalculationGraphqlMocks, ...masteryScalesGraphqlMocks]}
          >
            <OutcomeManagement />
          </MockedProvider>
        )

        fireEvent.click(getByText('Calculation'))
        await act(async () => jest.runAllTimers())
        fireEvent.input(getByLabelText('Parameter'), {target: {value: ''}})
        fireEvent.click(getByText('Mastery'))
        await act(async () => jest.runAllTimers())
        expect(window.confirm).toHaveBeenCalled()
        expect(getByTestId('masteryScales')).toBeInTheDocument()
      })

      it("Doesn't change tabs when doesn't confirm", async () => {
        // mock decline from user
        window.confirm = () => false

        const {getByText, getByLabelText, queryByTestId} = render(
          <MockedProvider
            cache={cache}
            mocks={[...masteryCalculationGraphqlMocks, ...masteryScalesGraphqlMocks]}
          >
            <OutcomeManagement />
          </MockedProvider>
        )

        fireEvent.click(getByText('Calculation'))
        await act(async () => jest.runAllTimers())
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
          </MockedProvider>
        )

        const calculationButton = getByText('Calculation')
        fireEvent.click(calculationButton)

        await act(async () => jest.runAllTimers())

        const e = jest.mock()
        e.preventDefault = jest.fn()
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
          </MockedProvider>
        )

        const calculationButton = getByText('Calculation')
        fireEvent.click(calculationButton)

        await act(async () => jest.runAllTimers())

        const parameter = getByLabelText(/Parameter/)
        fireEvent.input(parameter, {target: {value: '88'}})

        const e = jest.mock()
        e.preventDefault = jest.fn()
        unloadEventListener(e)
        expect(e.preventDefault).toHaveBeenCalled()
      })
    })
  }

  describe('account', () => {
    beforeEach(() => {
      window.ENV = {
        context_asset_string: 'account_11',
        PERMISSIONS: {
          manage_proficiency_calculations: true
        }
      }
    })

    afterEach(() => {
      window.ENV = null
    })

    sharedExamples()
  })

  describe('course', () => {
    beforeEach(() => {
      window.ENV = {
        context_asset_string: 'course_12',
        PERMISSIONS: {
          manage_proficiency_calculations: true
        }
      }
    })

    afterEach(() => {
      window.ENV = null
    })

    sharedExamples()
  })
})

describe('OutcomePanel', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="outcomes" style="display:none">Outcomes Tab</div>'
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('sets style on mount', () => {
    render(<OutcomePanel />)
    expect(document.getElementById('outcomes').style.display).toBe('block')
  })

  it('sets style on unmount', () => {
    const {unmount} = render(<OutcomePanel />)
    unmount()
    expect(document.getElementById('outcomes').style.display).toBe('none')
  })
})
