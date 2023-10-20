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

import {renderHook} from '@testing-library/react-hooks'
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

const defaults = {plannerEnabled: true, isPlannerActive: () => {}}

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))

afterEach(() => {
  plannerExports.initializePlanner.mockClear()
})

describe('usePlanner hook', () => {
  it('Calls initializePlanner when plannerEnabled is true', () => {
    renderHook(() => usePlanner(defaults))
    expect(plannerExports.initializePlanner).toHaveBeenCalled()
  })

  it('Does not call initializePlanner when plannerEnabled is false', () => {
    renderHook(() => usePlanner({...defaults, plannerEnabled: false}))
    expect(plannerExports.initializePlanner).not.toHaveBeenCalled()
  })

  it('returns planner configuration once initialization has completed', async () => {
    const {result, waitForNextUpdate} = renderHook(() => usePlanner(defaults))
    await waitForNextUpdate()
    expect(Object.keys(result.current)).toEqual(PLANNER_CONFIG_KEYS)
  })

  it('returns false if initialization does not happen', () => {
    const {result} = renderHook(() => usePlanner({...defaults, plannerEnabled: false}))
    expect(result.current).toBe(false)
  })

  it('shows a flash error message and returns false if initialization fails', async () => {
    plannerExports.initializePlanner.mockClear()
    plannerExports.initializePlanner.mockImplementationOnce(() =>
      Promise.reject(new Error('something went wrong'))
    )
    const {result} = renderHook(() => usePlanner(defaults))

    // I wish there was a better way to do this, but I didn't see a better way to wait for rejection
    await sleep(1)

    expect(flashAlerts.showFlashError).toHaveBeenCalledWith('Failed to load the schedule tab')
    expect(result.current).toBe(false)
  })

  it('passes the provided focus fallback ref to the planner via initialization options', async () => {
    const dummyRef = 'test'
    const {result, waitForNextUpdate} = renderHook(() =>
      usePlanner({...defaults, focusFallback: dummyRef})
    )
    await waitForNextUpdate()
    expect(result.current).toBeTruthy()
    expect(result.current.externalFallbackFocusable).toBe(dummyRef)
  })
})
