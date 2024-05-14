/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import {render, waitFor} from '@testing-library/react'
import usePlanner from '../usePlanner'

jest.mock('@canvas/planner')
// eslint-disable-next-line import/no-commonjs
const plannerExports = require('@canvas/planner')

plannerExports.initializePlanner = jest.fn(options => Promise.resolve(options))

jest.mock('@canvas/alerts/react/FlashAlert')
// eslint-disable-next-line import/no-commonjs
const flashAlerts = require('@canvas/alerts/react/FlashAlert')

flashAlerts.showFlashError = jest.fn(() => () => {})

const PLANNER_CONFIG_KEYS = [
  'getActiveApp',
  'flashError',
  'flashMessage',
  'srFlashMessage',
  'convertApiUserContent',
  'dateTimeFormatters',
  'externalFallbackFocusable',
  'env',
  'singleCourse',
  'observedUserId',
]

const TestComponent = ({defaults, getResult = () => {}}) => {
  const plannerInitialized = usePlanner(defaults)
  getResult(plannerInitialized)
  return <div className="test-wrapper">Test</div>
}

TestComponent.propTypes = {
  defaults: PropTypes.object.isRequired,
  getResult: PropTypes.func,
}

const renderHook = defaults => {
  const {container} = render(<TestComponent defaults={defaults} />)
  return container.querySelector('.test-wrapper').innerHTML
}

const defaults = {plannerEnabled: true, isPlannerActive: () => {}}

afterEach(() => {
  plannerExports.initializePlanner.mockClear()
})

describe('usePlanner hook', () => {
  it('Calls initializePlanner when plannerEnabled is true', async () => {
    renderHook(defaults)
    await waitFor(() => expect(plannerExports.initializePlanner).toHaveBeenCalled())
  })

  it('Does not call initializePlanner when plannerEnabled is false', () => {
    renderHook({...defaults, plannerEnabled: false})
    expect(plannerExports.initializePlanner).not.toHaveBeenCalled()
  })

  it('returns planner configuration once initialization has completed', async () => {
    renderHook(defaults, result => {
      expect(result).toEqual(PLANNER_CONFIG_KEYS)
    })
  })

  it('returns false if initialization does not happen', () => {
    renderHook({...defaults, plannerEnabled: false}, result => {
      expect(result).toBe(false)
    })
  })

  it('shows a flash error message and returns false if initialization fails', async () => {
    plannerExports.initializePlanner.mockClear()
    plannerExports.initializePlanner.mockImplementationOnce(() =>
      Promise.reject(new Error('something went wrong'))
    )
    renderHook(defaults, result => {
      expect(flashAlerts.showFlashError).toHaveBeenCalledWith('Failed to load the schedule tab')
      expect(result).toBe(false)
    })
  })

  it('passes the provided focus fallback ref to the planner via initialization options', async () => {
    const dummyRef = 'test'
    renderHook({...defaults, focusFallback: dummyRef}, result => {
      expect(result).toBeTruthy()
      expect(result.externalFallbackFocusable).toBe(dummyRef)
    })
  })
})
