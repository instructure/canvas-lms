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

import {act, waitFor} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import React from 'react'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import {useWidgetDashboardEdit, WidgetDashboardEditProvider} from '../useWidgetDashboardEdit'
import type {WidgetConfig} from '../../types'

const server = setupServer()

describe('useWidgetDashboardEdit', () => {
  let queryClient: QueryClient

  beforeAll(() => {
    server.listen({onUnhandledRequest: 'error'})
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {retry: false},
        mutations: {retry: false},
      },
    })
  })

  afterEach(() => {
    server.resetHandlers()
  })

  const createWrapper =
    () =>
    ({children}: {children: React.ReactNode}) => (
      <QueryClientProvider client={queryClient}>
        <WidgetDashboardEditProvider>{children}</WidgetDashboardEditProvider>
      </QueryClientProvider>
    )

  describe('edit mode state management', () => {
    it('initializes with edit mode disabled', () => {
      const {result} = renderHook(() => useWidgetDashboardEdit(), {
        wrapper: createWrapper(),
      })

      expect(result.current.isEditMode).toBe(false)
      expect(result.current.isDirty).toBe(false)
      expect(result.current.isSaving).toBe(false)
      expect(result.current.saveError).toBeNull()
    })

    it('enters edit mode when enterEditMode is called', () => {
      const {result} = renderHook(() => useWidgetDashboardEdit(), {
        wrapper: createWrapper(),
      })

      act(() => {
        result.current.enterEditMode()
      })

      expect(result.current.isEditMode).toBe(true)
      expect(result.current.isDirty).toBe(false)
      expect(result.current.saveError).toBeNull()
    })

    it('exits edit mode when exitEditMode is called', () => {
      const {result} = renderHook(() => useWidgetDashboardEdit(), {
        wrapper: createWrapper(),
      })

      act(() => {
        result.current.enterEditMode()
        result.current.markDirty()
      })

      expect(result.current.isEditMode).toBe(true)
      expect(result.current.isDirty).toBe(true)

      act(() => {
        result.current.exitEditMode()
      })

      expect(result.current.isEditMode).toBe(false)
      expect(result.current.isDirty).toBe(false)
      expect(result.current.saveError).toBeNull()
    })

    it('marks state as dirty when markDirty is called', () => {
      const {result} = renderHook(() => useWidgetDashboardEdit(), {
        wrapper: createWrapper(),
      })

      act(() => {
        result.current.enterEditMode()
      })

      expect(result.current.isDirty).toBe(false)

      act(() => {
        result.current.markDirty()
      })

      expect(result.current.isDirty).toBe(true)
    })
  })

  describe('saveChanges - success path', () => {
    it('successfully saves widget layout and exits edit mode', async () => {
      const mockConfig: WidgetConfig = {
        columns: 2,
        widgets: [
          {
            id: 'widget-1',
            type: 'test-widget',
            position: {col: 1, row: 1, relative: 1},
            title: 'Widget 1',
          },
        ],
      }

      server.use(
        graphql.mutation('UpdateWidgetDashboardLayout', ({variables}) => {
          expect(variables.layout).toBe(JSON.stringify(mockConfig))
          return HttpResponse.json({
            data: {
              updateWidgetDashboardLayout: {
                layout: variables.layout,
                errors: null,
              },
            },
          })
        }),
      )

      const {result} = renderHook(() => useWidgetDashboardEdit(), {
        wrapper: createWrapper(),
      })

      act(() => {
        result.current.enterEditMode()
        result.current.markDirty()
      })

      expect(result.current.isEditMode).toBe(true)
      expect(result.current.isDirty).toBe(true)

      await act(async () => {
        await result.current.saveChanges(mockConfig)
      })

      await waitFor(() => {
        expect(result.current.isEditMode).toBe(false)
        expect(result.current.isDirty).toBe(false)
        expect(result.current.isSaving).toBe(false)
        expect(result.current.saveError).toBeNull()
      })
    })
  })

  describe('saveChanges - error handling', () => {
    it('handles GraphQL validation errors', async () => {
      const mockConfig: WidgetConfig = {
        columns: 2,
        widgets: [],
      }

      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})

      server.use(
        graphql.mutation('UpdateWidgetDashboardLayout', () => {
          return HttpResponse.json({
            data: {
              updateWidgetDashboardLayout: {
                layout: null,
                errors: [{message: 'Invalid widget configuration'}],
              },
            },
          })
        }),
      )

      const {result} = renderHook(() => useWidgetDashboardEdit(), {
        wrapper: createWrapper(),
      })

      act(() => {
        result.current.enterEditMode()
      })

      await act(async () => {
        await result.current.saveChanges(mockConfig)
      })

      await waitFor(() => {
        expect(result.current.saveError).toBe('Invalid widget configuration')
        expect(result.current.isEditMode).toBe(true)
        expect(consoleErrorSpy).toHaveBeenCalledWith(
          'Failed to save widget layout:',
          expect.any(Error),
        )
      })

      consoleErrorSpy.mockRestore()
    })

    it('handles network errors', async () => {
      const mockConfig: WidgetConfig = {
        columns: 2,
        widgets: [],
      }

      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})

      server.use(
        graphql.mutation('UpdateWidgetDashboardLayout', () => {
          return HttpResponse.json({errors: [{message: 'Network error'}]}, {status: 500})
        }),
      )

      const {result} = renderHook(() => useWidgetDashboardEdit(), {
        wrapper: createWrapper(),
      })

      act(() => {
        result.current.enterEditMode()
      })

      await act(async () => {
        await result.current.saveChanges(mockConfig)
      })

      await waitFor(() => {
        expect(result.current.saveError).toBeTruthy()
        expect(result.current.isEditMode).toBe(true)
      })

      consoleErrorSpy.mockRestore()
    })

    it('keeps isDirty true when save fails', async () => {
      const mockConfig: WidgetConfig = {
        columns: 2,
        widgets: [],
      }

      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})

      server.use(
        graphql.mutation('UpdateWidgetDashboardLayout', () => {
          return HttpResponse.json({
            data: {
              updateWidgetDashboardLayout: {
                layout: null,
                errors: [{message: 'Save failed'}],
              },
            },
          })
        }),
      )

      const {result} = renderHook(() => useWidgetDashboardEdit(), {
        wrapper: createWrapper(),
      })

      act(() => {
        result.current.enterEditMode()
        result.current.markDirty()
      })

      expect(result.current.isDirty).toBe(true)

      await act(async () => {
        await result.current.saveChanges(mockConfig)
      })

      await waitFor(() => {
        expect(result.current.isDirty).toBe(true)
      })

      consoleErrorSpy.mockRestore()
    })
  })

  describe('error clearing', () => {
    it('clears error when clearError is called', async () => {
      const mockConfig: WidgetConfig = {
        columns: 2,
        widgets: [],
      }

      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})

      server.use(
        graphql.mutation('UpdateWidgetDashboardLayout', () => {
          return HttpResponse.json({
            data: {
              updateWidgetDashboardLayout: {
                layout: null,
                errors: [{message: 'Test error'}],
              },
            },
          })
        }),
      )

      const {result} = renderHook(() => useWidgetDashboardEdit(), {
        wrapper: createWrapper(),
      })

      act(() => {
        result.current.enterEditMode()
      })

      await act(async () => {
        await result.current.saveChanges(mockConfig)
      })

      await waitFor(() => {
        expect(result.current.saveError).toBe('Test error')
      })

      act(() => {
        result.current.clearError()
      })

      expect(result.current.saveError).toBeNull()

      consoleErrorSpy.mockRestore()
    })

    it('clears error when entering edit mode', () => {
      const {result} = renderHook(() => useWidgetDashboardEdit(), {
        wrapper: createWrapper(),
      })

      act(() => {
        result.current.enterEditMode()
      })

      act(() => {
        result.current.clearError()
      })

      act(() => {
        result.current.exitEditMode()
      })

      act(() => {
        result.current.enterEditMode()
      })

      expect(result.current.saveError).toBeNull()
    })
  })
})
