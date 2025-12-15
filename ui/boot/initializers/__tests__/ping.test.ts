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

const ACTIVITY_THRESHOLD = 5 * 60 * 1000 // 5 minutes
const PING_INTERVAL = 1000 * 180 // 3 minutes
const ACTIVITY_EVENTS = ['mousemove', 'mousedown', 'keydown', 'scroll', 'touchstart'] as const

const mockFail = vi.fn().mockReturnThis()
const mockPost = vi.fn().mockReturnValue({fail: mockFail})

vi.mock('jquery', () => ({
  __esModule: true,
  default: {
    post: mockPost,
  },
}))

// Mock es-toolkit throttle to just call the function immediately
vi.mock('es-toolkit', () => ({
  throttle: (fn: () => void) => fn,
}))

describe('ping initializer', () => {
  let originalEnv: typeof window.ENV
  let intervalCallback: (() => void) | null
  let originalSetInterval: typeof setInterval
  let originalDateNow: typeof Date.now
  let currentTime: number

  beforeEach(() => {
    vi.resetModules()

    mockPost.mockClear()
    mockFail.mockClear()

    originalEnv = window.ENV

    intervalCallback = null
    originalSetInterval = global.setInterval
    global.setInterval = vi.fn((callback: () => void) => {
      intervalCallback = callback
      return 1 as unknown as NodeJS.Timeout
    }) as unknown as typeof setInterval

    currentTime = 1000000
    originalDateNow = Date.now
    Date.now = vi.fn(() => currentTime)

    vi.spyOn(document, 'addEventListener')
    vi.spyOn(document, 'removeEventListener')

    Object.defineProperty(document, 'visibilityState', {
      writable: true,
      configurable: true,
      value: 'visible',
    })
  })

  afterEach(() => {
    window.ENV = originalEnv
    global.setInterval = originalSetInterval
    Date.now = originalDateNow
    vi.restoreAllMocks()
  })

  describe('when ENV.ping_url is set', () => {
    beforeEach(() => {
      // @ts-expect-error - partial ENV for testing
      window.ENV = {ping_url: '/api/v1/courses/123/ping'}
    })

    it('registers activity event listeners', () => {
      require('../ping')

      ACTIVITY_EVENTS.forEach(event => {
        expect(document.addEventListener).toHaveBeenCalledWith(
          event,
          expect.any(Function),
          expect.objectContaining({passive: true, capture: true}),
        )
      })
    })

    it('sets up ping interval at 3 minutes', () => {
      require('../ping')

      expect(global.setInterval).toHaveBeenCalledWith(expect.any(Function), PING_INTERVAL)
    })

    it('sends a ping when the page is visible and user is active', () => {
      require('../ping')

      currentTime += PING_INTERVAL

      intervalCallback!()

      expect(mockPost).toHaveBeenCalledWith('/api/v1/courses/123/ping')
    })

    it('does not send a ping when user has been inactive for more than the threshold', () => {
      require('../ping')

      currentTime += ACTIVITY_THRESHOLD + 1000

      intervalCallback!()

      expect(mockPost).not.toHaveBeenCalled()
    })

    it('sends a ping when user becomes active again after being inactive', () => {
      require('../ping')

      currentTime += ACTIVITY_THRESHOLD + 1000

      const mouseMoveEvent = new MouseEvent('mousemove')
      document.dispatchEvent(mouseMoveEvent)

      intervalCallback!()

      expect(mockPost).toHaveBeenCalledWith('/api/v1/courses/123/ping')
    })

    it('does not send a ping when document is hidden', () => {
      require('../ping')

      Object.defineProperty(document, 'visibilityState', {
        writable: true,
        configurable: true,
        value: 'hidden',
      })

      intervalCallback!()

      expect(mockPost).not.toHaveBeenCalled()
    })

    it('clears interval and removes event listeners on 401 response', () => {
      const clearIntervalSpy = vi.spyOn(global, 'clearInterval')
      require('../ping')

      intervalCallback!()

      expect(mockPost).toHaveBeenCalled()

      const failCallback = mockFail.mock.calls[0][0] as (xhr: {status: number}) => void
      failCallback({status: 401})

      expect(clearIntervalSpy).toHaveBeenCalled()

      ACTIVITY_EVENTS.forEach(event => {
        expect(document.removeEventListener).toHaveBeenCalledWith(
          event,
          expect.any(Function),
          expect.objectContaining({capture: true}),
        )
      })
    })

    it('continues pinging on non-401 failures', () => {
      require('../ping')

      intervalCallback!()

      expect(mockPost).toHaveBeenCalled()

      const failCallback = mockFail.mock.calls[0][0] as (xhr: {status: number}) => void
      failCallback({status: 500})

      mockPost.mockClear()
      intervalCallback!()
      expect(mockPost).toHaveBeenCalledWith('/api/v1/courses/123/ping')
    })

    it.each([
      ['mousemove', MouseEvent],
      ['mousedown', MouseEvent],
      ['keydown', KeyboardEvent],
      ['scroll', Event],
      ['touchstart', TouchEvent],
    ] as const)('reactivates pinging when %s event occurs', (eventType, EventClass) => {
      require('../ping')

      currentTime += ACTIVITY_THRESHOLD + 1000

      document.dispatchEvent(new EventClass(eventType))

      intervalCallback!()
      expect(mockPost).toHaveBeenCalledWith('/api/v1/courses/123/ping')
    })

    it('tracks activity even when another handler calls stopPropagation', () => {
      const blockingHandler = (e: Event) => e.stopPropagation()
      document.addEventListener('mousemove', blockingHandler)

      require('../ping')

      currentTime += ACTIVITY_THRESHOLD + 1000

      document.dispatchEvent(new MouseEvent('mousemove'))

      intervalCallback!()
      expect(mockPost).toHaveBeenCalledWith('/api/v1/courses/123/ping')

      document.removeEventListener('mousemove', blockingHandler)
    })
  })

  describe('when ENV.ping_url is not set', () => {
    it('does not set up any intervals or listeners', () => {
      // @ts-expect-error - partial ENV for testing
      window.ENV = {}
      require('../ping')

      expect(global.setInterval).not.toHaveBeenCalled()
      expect(document.addEventListener).not.toHaveBeenCalled()
    })
  })
})
