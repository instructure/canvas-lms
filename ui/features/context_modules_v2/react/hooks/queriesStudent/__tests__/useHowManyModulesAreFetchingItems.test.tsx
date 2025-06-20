/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import react, {useEffect} from 'react'
import {render} from '@testing-library/react'
import {useHowManyModulesAreFetchingItems} from '../useHowManyModulesAreFetchingItems'
import {renderHook} from '@testing-library/react-hooks'
import * as reactQuery from '@tanstack/react-query'

// Mock the useIsFetching hook from react-query
jest.mock('@tanstack/react-query', () => ({
  ...jest.requireActual('@tanstack/react-query'),
  useIsFetching: jest.fn().mockReturnValue(0),
}))

describe('useHowManyModulesAreFetchingItems', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    // Reset the mock to return 0 by default
    jest.spyOn(reactQuery, 'useIsFetching').mockReturnValue(0)
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('initializes with zero counts', () => {
    const {result} = renderHook(() => useHowManyModulesAreFetchingItems())

    expect(result.current.moduleFetchingCount).toBe(0)
    expect(result.current.maxFetchingCount).toBe(0)
    expect(result.current.fetchComplete).toBe(false)
  })

  it('updates moduleFetchingCount when fetching starts', () => {
    // Start with 0 fetching
    jest.spyOn(reactQuery, 'useIsFetching').mockReturnValue(0)
    const {result, rerender} = renderHook(() => useHowManyModulesAreFetchingItems())

    // Change to 2 fetching
    jest.spyOn(reactQuery, 'useIsFetching').mockReturnValue(2)
    rerender()

    expect(result.current.moduleFetchingCount).toBe(2)
    expect(result.current.maxFetchingCount).toBe(2)
    expect(result.current.fetchComplete).toBe(false)
  })

  it('updates maxFetchingCount to the highest observed value', () => {
    // Start with 0 fetching
    jest.spyOn(reactQuery, 'useIsFetching').mockReturnValue(0)
    const {result, rerender} = renderHook(() => useHowManyModulesAreFetchingItems())

    // Change to 2 fetching
    jest.spyOn(reactQuery, 'useIsFetching').mockReturnValue(2)
    rerender()

    // Change to 5 fetching (higher value)
    jest.spyOn(reactQuery, 'useIsFetching').mockReturnValue(5)
    rerender()

    expect(result.current.moduleFetchingCount).toBe(5)
    expect(result.current.maxFetchingCount).toBe(5)

    // Change to 3 fetching (lower value)
    jest.spyOn(reactQuery, 'useIsFetching').mockReturnValue(3)
    rerender()

    // maxFetchingCount should still be 5
    expect(result.current.moduleFetchingCount).toBe(3)
    expect(result.current.maxFetchingCount).toBe(5)
  })

  // this test emulates what ModuleListStudent does with the useHowManyModulesAreFetchingItems hook
  it('calls callback when fetchComplete is true and maxFetchingCount is greater than 1', () => {
    const callback = jest.fn()
    const TestComponent = ({callback}: any) => {
      const {moduleFetchingCount, maxFetchingCount, fetchComplete} =
        useHowManyModulesAreFetchingItems()
      useEffect(() => {
        if (fetchComplete) {
          if (maxFetchingCount > 1) {
            callback('Module items loaded')
          }
        }
      }, [moduleFetchingCount, maxFetchingCount, fetchComplete, callback])
      return <div />
    }

    // Start with 0 fetching
    jest.spyOn(reactQuery, 'useIsFetching').mockReturnValue(0)
    const {rerender} = render(<TestComponent callback={callback} />)
    expect(callback).not.toHaveBeenCalled()

    // First fetch cycle: 3 fetching
    jest.spyOn(reactQuery, 'useIsFetching').mockReturnValue(3)
    rerender(<TestComponent callback={callback} />)
    expect(callback).not.toHaveBeenCalled()

    // Fetching completes
    jest.spyOn(reactQuery, 'useIsFetching').mockReturnValue(0)
    rerender(<TestComponent callback={callback} />)
    expect(callback).toHaveBeenCalledWith('Module items loaded')
  })

  it('does not call callback when fetchComplete is true and maxFetchingCount is 1', () => {
    const callback = jest.fn()
    const TestComponent = ({callback}: any) => {
      const {moduleFetchingCount, maxFetchingCount, fetchComplete} =
        useHowManyModulesAreFetchingItems()
      useEffect(() => {
        if (fetchComplete) {
          if (maxFetchingCount > 1) {
            callback('Module items loaded')
          }
        }
      }, [moduleFetchingCount, maxFetchingCount, fetchComplete, callback])
      return <div />
    }

    // Start with 0 fetching
    jest.spyOn(reactQuery, 'useIsFetching').mockReturnValue(0)
    const {rerender} = render(<TestComponent callback={callback} />)
    expect(callback).not.toHaveBeenCalled()

    // First fetch cycle: 3 fetching
    jest.spyOn(reactQuery, 'useIsFetching').mockReturnValue(1)
    rerender(<TestComponent callback={callback} />)
    expect(callback).not.toHaveBeenCalled()

    // Fetching completes
    jest.spyOn(reactQuery, 'useIsFetching').mockReturnValue(0)
    rerender(<TestComponent callback={callback} />)
    expect(callback).not.toHaveBeenCalled()
  })

  it('resets maxFetchingCount when a new fetch cycle starts after completion', () => {
    jest.spyOn(reactQuery, 'useIsFetching').mockReturnValue(0)
    const {result, rerender} = renderHook(() => useHowManyModulesAreFetchingItems())

    jest.spyOn(reactQuery, 'useIsFetching').mockReturnValue(3)
    rerender()
    expect(result.current.maxFetchingCount).toBe(3)

    jest.spyOn(reactQuery, 'useIsFetching').mockReturnValue(0)
    rerender()

    jest.spyOn(reactQuery, 'useIsFetching').mockReturnValue(2)
    rerender()

    // maxFetchingCount should be reset to 2
    expect(result.current.moduleFetchingCount).toBe(2)
    expect(result.current.maxFetchingCount).toBe(2)
    expect(result.current.fetchComplete).toBe(false)
  })
})
