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

import React, {useEffect} from 'react'
import {render, waitFor} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {useHowManyModulesAreFetchingItems} from '../useHowManyModulesAreFetchingItems'

const setup = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  })

  const wrapper = ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )

  return {queryClient, wrapper}
}

const createDefaultProps = () => ({
  teacherMode: false,
})

describe('useHowManyModulesAreFetchingItems', () => {
  it('initializes with zero counts', () => {
    const {wrapper} = setup()
    const props = createDefaultProps()
    const {result} = renderHook(() => useHowManyModulesAreFetchingItems(props.teacherMode), {
      wrapper,
    })

    expect(result.current.moduleFetchingCount).toBe(0)
    expect(result.current.maxFetchingCount).toBe(0)
    expect(result.current.fetchComplete).toBe(false)
  })

  it('tracks fetching state changes correctly', async () => {
    const {queryClient, wrapper} = setup()
    const props = createDefaultProps()
    const {result} = renderHook(() => useHowManyModulesAreFetchingItems(props.teacherMode), {
      wrapper,
    })

    // Initial state
    expect(result.current.moduleFetchingCount).toBe(0)
    expect(result.current.maxFetchingCount).toBe(0)
    expect(result.current.fetchComplete).toBe(false)

    // Simulate queries being added
    queryClient.setQueryData(['moduleItemsStudent', 'module1'], {data: 'pending'})
    queryClient.fetchQuery({
      queryKey: ['moduleItemsStudent', 'module1'],
      queryFn: () => new Promise(resolve => setTimeout(() => resolve({data: 'loaded'}), 100)),
    })

    await waitFor(() => {
      expect(result.current.moduleFetchingCount).toBeGreaterThan(0)
    })

    // Wait for query to complete
    await waitFor(() => {
      expect(result.current.moduleFetchingCount).toBe(0)
      expect(result.current.fetchComplete).toBe(true)
    })
  })

  it('correctly handles teacherMode parameter', async () => {
    const {queryClient, wrapper} = setup()
    const {result} = renderHook(() => useHowManyModulesAreFetchingItems(true), {
      wrapper,
    })

    expect(result.current.moduleFetchingCount).toBe(0)
    expect(result.current.fetchComplete).toBe(false)

    // Simulate teacher mode queries
    queryClient.fetchQuery({
      queryKey: ['moduleItems', 'module1'],
      queryFn: () => new Promise(resolve => setTimeout(() => resolve({data: 'loaded'}), 100)),
    })

    await waitFor(() => {
      expect(result.current.moduleFetchingCount).toBeGreaterThan(0)
    })

    await waitFor(() => {
      expect(result.current.moduleFetchingCount).toBe(0)
      expect(result.current.fetchComplete).toBe(true)
    })
  })

  it('component integration with callback when fetchComplete', async () => {
    const callback = jest.fn()
    const {queryClient, wrapper} = setup()

    const TestComponent = ({callback}: any) => {
      const {moduleFetchingCount, maxFetchingCount, fetchComplete} =
        useHowManyModulesAreFetchingItems()
      useEffect(() => {
        if (fetchComplete && maxFetchingCount > 1) {
          callback('Module items loaded')
        }
      }, [moduleFetchingCount, maxFetchingCount, fetchComplete, callback])
      return <div />
    }

    render(<TestComponent callback={callback} />, {wrapper})
    expect(callback).not.toHaveBeenCalled()

    // Simulate multiple queries
    const queries = [
      queryClient.fetchQuery({
        queryKey: ['moduleItemsStudent', 'module1'],
        queryFn: () => new Promise(resolve => setTimeout(() => resolve({data: '1'}), 50)),
      }),
      queryClient.fetchQuery({
        queryKey: ['moduleItemsStudent', 'module2'],
        queryFn: () => new Promise(resolve => setTimeout(() => resolve({data: '2'}), 100)),
      }),
    ]

    await Promise.all(queries)

    await waitFor(() => {
      expect(callback).toHaveBeenCalledWith('Module items loaded')
    })
  })

  it('tracks maxFetchingCount correctly across fetch cycles', async () => {
    const {queryClient, wrapper} = setup()
    const props = createDefaultProps()
    const {result} = renderHook(() => useHowManyModulesAreFetchingItems(props.teacherMode), {
      wrapper,
    })

    // First fetch cycle with 3 queries - use longer delays to ensure detection
    const firstCycle = [
      queryClient.fetchQuery({
        queryKey: ['moduleItemsStudent', 'module1'],
        queryFn: () => new Promise(resolve => setTimeout(() => resolve({data: '1'}), 100)),
      }),
      queryClient.fetchQuery({
        queryKey: ['moduleItemsStudent', 'module2'],
        queryFn: () => new Promise(resolve => setTimeout(() => resolve({data: '2'}), 100)),
      }),
      queryClient.fetchQuery({
        queryKey: ['moduleItemsStudent', 'module3'],
        queryFn: () => new Promise(resolve => setTimeout(() => resolve({data: '3'}), 100)),
      }),
    ]

    // Wait for all queries to be detected as fetching
    await waitFor(() => {
      expect(result.current.moduleFetchingCount).toBeGreaterThan(0)
    })

    // Wait for the maximum count to be reached
    await waitFor(() => {
      expect(result.current.maxFetchingCount).toBeGreaterThanOrEqual(3)
    })

    await Promise.all(firstCycle)

    // Wait for first cycle to complete
    await waitFor(() => {
      expect(result.current.moduleFetchingCount).toBe(0)
      expect(result.current.fetchComplete).toBe(true)
    })

    const firstCycleMaxCount = result.current.maxFetchingCount

    // Second fetch cycle with 2 queries
    const secondCycle = [
      queryClient.fetchQuery({
        queryKey: ['moduleItemsStudent', 'module4'],
        queryFn: () => new Promise(resolve => setTimeout(() => resolve({data: '4'}), 100)),
      }),
      queryClient.fetchQuery({
        queryKey: ['moduleItemsStudent', 'module5'],
        queryFn: () => new Promise(resolve => setTimeout(() => resolve({data: '5'}), 100)),
      }),
    ]

    // Wait for second cycle to be detected as fetching
    await waitFor(() => {
      expect(result.current.moduleFetchingCount).toBeGreaterThan(0)
      expect(result.current.fetchComplete).toBe(false)
    })

    await Promise.all(secondCycle)

    // Wait for second cycle to complete
    await waitFor(() => {
      expect(result.current.moduleFetchingCount).toBe(0)
      expect(result.current.fetchComplete).toBe(true)
    })

    // The hook should have tracked both cycles appropriately
    expect(firstCycleMaxCount).toBeGreaterThanOrEqual(1)
    expect(result.current.maxFetchingCount).toBeGreaterThanOrEqual(1)
  })

  it.skip('differentiates between student and teacher mode queries', async () => {
    const {queryClient, wrapper} = setup()

    const {result: studentResult} = renderHook(() => useHowManyModulesAreFetchingItems(false), {
      wrapper,
    })

    const {result: teacherResult} = renderHook(() => useHowManyModulesAreFetchingItems(true), {
      wrapper,
    })

    // Add a student query
    queryClient.fetchQuery({
      queryKey: ['moduleItemsStudent', 'module1'],
      queryFn: () => new Promise(resolve => setTimeout(() => resolve({data: 'student'}), 50)),
    })

    // Add a teacher query
    queryClient.fetchQuery({
      queryKey: ['moduleItems', 'module1'],
      queryFn: () => new Promise(resolve => setTimeout(() => resolve({data: 'teacher'}), 50)),
    })

    await waitFor(() => {
      expect(studentResult.current.moduleFetchingCount).toBe(1)
      expect(teacherResult.current.moduleFetchingCount).toBe(1)
    })

    await waitFor(() => {
      expect(studentResult.current.fetchComplete).toBe(true)
      expect(teacherResult.current.fetchComplete).toBe(true)
    })
  })
})
