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

import {renderHook, act} from '@testing-library/react-hooks'
import {cleanup} from '@testing-library/react'
import {useObservedTranslations} from '../useObservedTranslations'
import {useTranslationStore} from '../useTranslationStore'
import {useTranslation} from '../useTranslation'

vi.mock('../useTranslationStore')
vi.mock('../useTranslation')

const useTranslationStoreMock = useTranslationStore as unknown as ReturnType<typeof vi.fn> & {
  getState: ReturnType<typeof vi.fn>
}
const useTranslationMock = useTranslation as ReturnType<typeof vi.fn>

describe('useObservedTranslations', () => {
  let setTranslationStartMock: ReturnType<typeof vi.fn>
  let enqueueTranslationMock: ReturnType<typeof vi.fn>
  let translateEntryMock: ReturnType<typeof vi.fn>
  let observerInstance: IntersectionObserver
  let observerCallback: IntersectionObserverCallback

  beforeEach(() => {
    vi.clearAllMocks()
    vi.useFakeTimers()

    setTranslationStartMock = vi.fn()
    enqueueTranslationMock = vi.fn()
    translateEntryMock = vi.fn()

    useTranslationStoreMock.mockImplementation((selector: any) => {
      if (typeof selector === 'function') {
        return selector({setTranslationStart: setTranslationStartMock})
      }
      return {setTranslationStart: setTranslationStartMock}
    })

    useTranslationStoreMock.getState = vi.fn(() => ({
      entries: {},
      activeLanguage: 'en',
      translateAll: true,
    }))

    useTranslationMock.mockReturnValue({
      translateEntry: translateEntryMock,
    })

    // Mock IntersectionObserver
    global.IntersectionObserver = vi.fn(callback => {
      observerCallback = callback
      observerInstance = {
        observe: vi.fn(),
        unobserve: vi.fn(),
        disconnect: vi.fn(),
        root: null,
        rootMargin: '',
        thresholds: [0.1],
        takeRecords: vi.fn(),
      }
      return observerInstance
    }) as any
  })

  afterEach(() => {
    cleanup()
    vi.useRealTimers()
  })

  describe('startObserving', () => {
    it('should create an IntersectionObserver with threshold 0.1', () => {
      const {result} = renderHook(() => useObservedTranslations(enqueueTranslationMock))

      act(() => {
        result.current.startObserving('es')
      })

      expect(global.IntersectionObserver).toHaveBeenCalledWith(expect.any(Function), {
        threshold: 0.1,
      })
    })

    it('should observe all nodes in nodesRef', () => {
      const {result} = renderHook(() => useObservedTranslations(enqueueTranslationMock))

      const node1 = document.createElement('div')
      const node2 = document.createElement('div')

      result.current.nodesRef.current.set('1', node1)
      result.current.nodesRef.current.set('2', node2)

      act(() => {
        result.current.startObserving('es')
      })

      expect(result.current.observerRef.current?.observe).toHaveBeenCalledTimes(2)
      expect(result.current.observerRef.current?.observe).toHaveBeenCalledWith(node1)
      expect(result.current.observerRef.current?.observe).toHaveBeenCalledWith(node2)
    })

    it('should enqueue translation when entry is intersecting', () => {
      const {result} = renderHook(() => useObservedTranslations(enqueueTranslationMock))

      const mockElement = document.createElement('div')
      mockElement.dataset.id = 'entry-1'

      useTranslationStoreMock.getState = vi.fn(() => ({
        entries: {
          'entry-1': {
            message: 'Hello world',
            title: 'Test title',
            language: 'es',
            loading: false,
          },
        },
        activeLanguage: 'en',
        translateAll: true,
      }))

      act(() => {
        result.current.startObserving('en')
      })

      act(() => {
        observerCallback(
          [
            {
              isIntersecting: true,
              target: mockElement,
              boundingClientRect: {} as DOMRectReadOnly,
              intersectionRatio: 0.5,
              intersectionRect: {} as DOMRectReadOnly,
              rootBounds: null,
              time: 0,
            },
          ],
          observerInstance,
        )
      })

      act(() => {
        vi.advanceTimersByTime(200)
      })

      expect(setTranslationStartMock).toHaveBeenCalledWith('entry-1')
      expect(enqueueTranslationMock).toHaveBeenCalledWith(expect.any(Function))
    })

    it('should not enqueue translation if entry is already loading', () => {
      const {result} = renderHook(() => useObservedTranslations(enqueueTranslationMock))

      const mockElement = document.createElement('div')
      mockElement.dataset.id = 'entry-1'

      useTranslationStoreMock.getState = vi.fn(() => ({
        entries: {
          'entry-1': {
            message: 'Hello world',
            title: 'Test title',
            language: 'es',
            loading: true,
          },
        },
        activeLanguage: 'en',
        translateAll: true,
      }))

      act(() => {
        result.current.startObserving('en')
      })

      act(() => {
        observerCallback(
          [
            {
              isIntersecting: true,
              target: mockElement,
              boundingClientRect: {} as DOMRectReadOnly,
              intersectionRatio: 0.5,
              intersectionRect: {} as DOMRectReadOnly,
              rootBounds: null,
              time: 0,
            },
          ],
          observerInstance,
        )
      })

      act(() => {
        vi.advanceTimersByTime(200)
      })

      expect(setTranslationStartMock).not.toHaveBeenCalled()
      expect(enqueueTranslationMock).not.toHaveBeenCalled()
    })

    it('should not enqueue translation if entry language matches active language', () => {
      const {result} = renderHook(() => useObservedTranslations(enqueueTranslationMock))

      const mockElement = document.createElement('div')
      mockElement.dataset.id = 'entry-1'

      useTranslationStoreMock.getState = vi.fn(() => ({
        entries: {
          'entry-1': {
            message: 'Hello world',
            title: 'Test title',
            language: 'en',
            loading: false,
          },
        },
        activeLanguage: 'en',
        translateAll: true,
      }))

      act(() => {
        result.current.startObserving('en')
      })

      act(() => {
        observerCallback(
          [
            {
              isIntersecting: true,
              target: mockElement,
              boundingClientRect: {} as DOMRectReadOnly,
              intersectionRatio: 0.5,
              intersectionRect: {} as DOMRectReadOnly,
              rootBounds: null,
              time: 0,
            },
          ],
          observerInstance,
        )
      })

      act(() => {
        vi.advanceTimersByTime(200)
      })

      expect(setTranslationStartMock).not.toHaveBeenCalled()
      expect(enqueueTranslationMock).not.toHaveBeenCalled()
    })

    it('should not enqueue translation if entry does not exist', () => {
      const {result} = renderHook(() => useObservedTranslations(enqueueTranslationMock))

      const mockElement = document.createElement('div')
      mockElement.dataset.id = 'entry-1'

      useTranslationStoreMock.getState = vi.fn(() => ({
        entries: {},
        activeLanguage: 'en',
        translateAll: true,
      }))

      act(() => {
        result.current.startObserving('en')
      })

      act(() => {
        observerCallback(
          [
            {
              isIntersecting: true,
              target: mockElement,
              boundingClientRect: {} as DOMRectReadOnly,
              intersectionRatio: 0.5,
              intersectionRect: {} as DOMRectReadOnly,
              rootBounds: null,
              time: 0,
            },
          ],
          observerInstance,
        )
      })

      act(() => {
        vi.advanceTimersByTime(200)
      })

      expect(setTranslationStartMock).not.toHaveBeenCalled()
      expect(enqueueTranslationMock).not.toHaveBeenCalled()
    })

    it('should not enqueue translation if element does not have data-id', () => {
      const {result} = renderHook(() => useObservedTranslations(enqueueTranslationMock))

      const mockElement = document.createElement('div')

      act(() => {
        result.current.startObserving('en')
      })

      act(() => {
        observerCallback(
          [
            {
              isIntersecting: true,
              target: mockElement,
              boundingClientRect: {} as DOMRectReadOnly,
              intersectionRatio: 0.5,
              intersectionRect: {} as DOMRectReadOnly,
              rootBounds: null,
              time: 0,
            },
          ],
          observerInstance,
        )
      })

      act(() => {
        vi.advanceTimersByTime(200)
      })

      expect(setTranslationStartMock).not.toHaveBeenCalled()
      expect(enqueueTranslationMock).not.toHaveBeenCalled()
    })

    it('should clear timeout when entry stops intersecting', () => {
      const {result} = renderHook(() => useObservedTranslations(enqueueTranslationMock))

      const mockElement = document.createElement('div')
      mockElement.dataset.id = 'entry-1'

      useTranslationStoreMock.getState = vi.fn(() => ({
        entries: {
          'entry-1': {
            message: 'Hello world',
            title: 'Test title',
            language: 'es',
            loading: false,
          },
        },
        activeLanguage: 'en',
        translateAll: true,
      }))

      act(() => {
        result.current.startObserving('en')
      })

      // Entry intersects
      act(() => {
        observerCallback(
          [
            {
              isIntersecting: true,
              target: mockElement,
              boundingClientRect: {} as DOMRectReadOnly,
              intersectionRatio: 0.5,
              intersectionRect: {} as DOMRectReadOnly,
              rootBounds: null,
              time: 0,
            },
          ],
          observerInstance,
        )
      })

      // Entry stops intersecting before timeout
      act(() => {
        observerCallback(
          [
            {
              isIntersecting: false,
              target: mockElement,
              boundingClientRect: {} as DOMRectReadOnly,
              intersectionRatio: 0,
              intersectionRect: {} as DOMRectReadOnly,
              rootBounds: null,
              time: 100,
            },
          ],
          observerInstance,
        )
      })

      act(() => {
        vi.advanceTimersByTime(200)
      })

      expect(setTranslationStartMock).not.toHaveBeenCalled()
      expect(enqueueTranslationMock).not.toHaveBeenCalled()
    })

    it('should call translateEntry with correct parameters when translation is enqueued', async () => {
      const {result} = renderHook(() => useObservedTranslations(enqueueTranslationMock))

      const mockElement = document.createElement('div')
      mockElement.dataset.id = 'entry-1'

      const mockEntry = {
        message: 'Hello world',
        title: 'Test title',
        language: 'es',
        loading: false,
      }

      useTranslationStoreMock.getState = vi.fn(() => ({
        entries: {
          'entry-1': mockEntry,
        },
        activeLanguage: 'en',
        translateAll: true,
      }))

      act(() => {
        result.current.startObserving('en')
      })

      act(() => {
        observerCallback(
          [
            {
              isIntersecting: true,
              target: mockElement,
              boundingClientRect: {} as DOMRectReadOnly,
              intersectionRatio: 0.5,
              intersectionRect: {} as DOMRectReadOnly,
              rootBounds: null,
              time: 0,
            },
          ],
          observerInstance,
        )
      })

      act(() => {
        vi.advanceTimersByTime(200)
      })

      expect(enqueueTranslationMock).toHaveBeenCalledWith(expect.any(Function))

      // Execute the enqueued job
      const translateJob = enqueueTranslationMock.mock.calls[0][0]
      const mockSignal = new AbortController().signal
      await translateJob(mockSignal)

      expect(translateEntryMock).toHaveBeenCalledWith(
        {
          language: 'en',
          entryId: 'entry-1',
          message: mockEntry.message,
          title: mockEntry.title,
        },
        mockSignal,
      )
    })

    it('should handle multiple intersecting entries', () => {
      const {result} = renderHook(() => useObservedTranslations(enqueueTranslationMock))

      const mockElement1 = document.createElement('div')
      mockElement1.dataset.id = 'entry-1'
      const mockElement2 = document.createElement('div')
      mockElement2.dataset.id = 'entry-2'

      useTranslationStoreMock.getState = vi.fn(() => ({
        entries: {
          'entry-1': {
            message: 'Hello world',
            title: 'Test title 1',
            language: 'es',
            loading: false,
          },
          'entry-2': {
            message: 'Goodbye world',
            title: 'Test title 2',
            language: 'es',
            loading: false,
          },
        },
        activeLanguage: 'en',
        translateAll: true,
      }))

      act(() => {
        result.current.startObserving('en')
      })

      act(() => {
        observerCallback(
          [
            {
              isIntersecting: true,
              target: mockElement1,
              boundingClientRect: {} as DOMRectReadOnly,
              intersectionRatio: 0.5,
              intersectionRect: {} as DOMRectReadOnly,
              rootBounds: null,
              time: 0,
            },
            {
              isIntersecting: true,
              target: mockElement2,
              boundingClientRect: {} as DOMRectReadOnly,
              intersectionRatio: 0.5,
              intersectionRect: {} as DOMRectReadOnly,
              rootBounds: null,
              time: 0,
            },
          ],
          observerInstance,
        )
      })

      act(() => {
        vi.advanceTimersByTime(200)
      })

      expect(setTranslationStartMock).toHaveBeenCalledTimes(2)
      expect(setTranslationStartMock).toHaveBeenCalledWith('entry-1')
      expect(setTranslationStartMock).toHaveBeenCalledWith('entry-2')
      expect(enqueueTranslationMock).toHaveBeenCalledTimes(2)
    })
  })

  describe('stopObserving', () => {
    it('should disconnect the observer', () => {
      const {result} = renderHook(() => useObservedTranslations(enqueueTranslationMock))

      act(() => {
        result.current.startObserving('es')
      })

      const observer = result.current.observerRef.current

      act(() => {
        result.current.stopObserving()
      })

      expect(observer?.disconnect).toHaveBeenCalled()
      expect(result.current.observerRef.current).toBeUndefined()
    })

    it('should handle calling stopObserving when observer does not exist', () => {
      const {result} = renderHook(() => useObservedTranslations(enqueueTranslationMock))

      expect(() => {
        act(() => {
          result.current.stopObserving()
        })
      }).not.toThrow()

      expect(result.current.observerRef.current).toBeUndefined()
    })
  })

  describe('refs', () => {
    it('should return observerRef and nodesRef', () => {
      const {result} = renderHook(() => useObservedTranslations(enqueueTranslationMock))

      expect(result.current.observerRef).toBeDefined()
      expect(result.current.nodesRef).toBeDefined()
      expect(result.current.nodesRef.current).toBeInstanceOf(Map)
    })

    it('should maintain nodesRef across re-renders', () => {
      const {result, rerender} = renderHook(() => useObservedTranslations(enqueueTranslationMock))

      const node = document.createElement('div')
      result.current.nodesRef.current.set('1', node)

      rerender()

      expect(result.current.nodesRef.current.get('1')).toBe(node)
    })
  })

  describe('timeout behavior', () => {
    it('should use 200ms delay before triggering translation', () => {
      const {result} = renderHook(() => useObservedTranslations(enqueueTranslationMock))

      const mockElement = document.createElement('div')
      mockElement.dataset.id = 'entry-1'

      useTranslationStoreMock.getState = vi.fn(() => ({
        entries: {
          'entry-1': {
            message: 'Hello world',
            title: 'Test title',
            language: 'es',
            loading: false,
          },
        },
        activeLanguage: 'en',
        translateAll: true,
      }))

      act(() => {
        result.current.startObserving('en')
      })

      act(() => {
        observerCallback(
          [
            {
              isIntersecting: true,
              target: mockElement,
              boundingClientRect: {} as DOMRectReadOnly,
              intersectionRatio: 0.5,
              intersectionRect: {} as DOMRectReadOnly,
              rootBounds: null,
              time: 0,
            },
          ],
          observerInstance,
        )
      })

      // Not triggered yet
      act(() => {
        vi.advanceTimersByTime(100)
      })
      expect(setTranslationStartMock).not.toHaveBeenCalled()

      // Triggered after 200ms
      act(() => {
        vi.advanceTimersByTime(100)
      })
      expect(setTranslationStartMock).toHaveBeenCalled()
    })
  })
})
