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

/* global vi */

// Mock modules with inline factory functions that create mocks inside
// This works in both Jest and Vitest since mocks are created in the factory
if (typeof vi !== 'undefined') {
  vi.mock('@canvas/planner', () => ({
    initializePlanner: vi.fn(options => Promise.resolve(options)),
  }))
  vi.mock('@canvas/alerts/react/FlashAlert', () => ({
    showFlashAlert: vi.fn(),
    showFlashError: vi.fn(() => () => {}),
  }))
}
vi.mock('@canvas/planner', () => ({
  initializePlanner: vi.fn(options => Promise.resolve(options)),
}))
vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
  showFlashError: vi.fn(() => () => {}),
}))

import React from 'react'
import PropTypes from 'prop-types'
import {render, waitFor} from '@testing-library/react'
import usePlanner from '../usePlanner'
import {initializePlanner} from '@canvas/planner'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

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
  initializePlanner.mockClear()
})

describe('usePlanner hook', () => {
  it('Calls initializePlanner when plannerEnabled is true', async () => {
    renderHook(defaults)
    await waitFor(() => expect(initializePlanner).toHaveBeenCalled())
  })

  it('Does not call initializePlanner when plannerEnabled is false', () => {
    renderHook({...defaults, plannerEnabled: false})
    expect(initializePlanner).not.toHaveBeenCalled()
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
    initializePlanner.mockClear()
    initializePlanner.mockImplementationOnce(() =>
      Promise.reject(new Error('something went wrong')),
    )
    renderHook(defaults, result => {
      expect(showFlashError).toHaveBeenCalledWith('Failed to load the schedule tab')
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
