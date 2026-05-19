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

import handler from '../lti.enableScrollEvents'
import type {ResponseMessages} from '../../response_messages'

describe('lti.enableScrollEvents handler', () => {
  let responseMessages: ResponseMessages
  const message = {}
  const event = new MessageEvent('message', {origin: 'http://example.com'})

  beforeEach(() => {
    responseMessages = {
      sendResponse: vi.fn(),
      sendSuccess: vi.fn(),
      sendError: vi.fn(),
      sendBadRequestError: vi.fn(),
      sendGenericError: vi.fn(),
      sendUnsupportedSubjectError: vi.fn(),
      sendWrongOriginError: vi.fn(),
      sendUnauthorizedError: vi.fn(),
      isResponse: () => false,
    } as unknown as ResponseMessages
  })

  afterEach(() => {
    vi.restoreAllMocks()
    ENV.FEATURES = {}
  })

  it('returns true', () => {
    ENV.FEATURES = {top_navigation_placement: false}
    expect(handler({message, event, responseMessages})).toBe(true)
  })

  describe('FF on + #drawer-layout-content present → drawer path', () => {
    let drawerContent: HTMLDivElement

    beforeEach(() => {
      ENV.FEATURES = {top_navigation_placement: true}
      drawerContent = document.createElement('div')
      drawerContent.id = 'drawer-layout-content'
      drawerContent.scrollTop = 0
      document.body.appendChild(drawerContent)
    })

    afterEach(() => {
      drawerContent.remove()
    })

    it('attaches scroll listener to #drawer-layout-content', () => {
      const spy = vi.spyOn(drawerContent, 'addEventListener')
      handler({message, event, responseMessages})
      expect(spy).toHaveBeenCalledWith('scroll', expect.any(Function), false)
    })

    it('reports scrollTop of #drawer-layout-content as scrollY', () => {
      vi.useFakeTimers()
      drawerContent.scrollTop = 250

      handler({message, event, responseMessages})
      drawerContent.dispatchEvent(new Event('scroll'))
      vi.runAllTimers()

      expect(responseMessages.sendResponse).toHaveBeenCalledWith(
        expect.objectContaining({subject: 'lti.scroll', scrollY: 250}),
      )
      vi.useRealTimers()
    })
  })

  describe('FF off + #drawer-layout-content present → normal path', () => {
    let drawerContent: HTMLDivElement

    beforeEach(() => {
      ENV.FEATURES = {top_navigation_placement: false}
      drawerContent = document.createElement('div')
      drawerContent.id = 'drawer-layout-content'
      document.body.appendChild(drawerContent)
    })

    afterEach(() => {
      drawerContent.remove()
    })

    it('attaches scroll listener to window', () => {
      const spy = vi.spyOn(window, 'addEventListener')
      handler({message, event, responseMessages})
      expect(spy).toHaveBeenCalledWith('scroll', expect.any(Function), false)
    })

    it('reports window.scrollY in the response', () => {
      vi.useFakeTimers()
      vi.spyOn(window, 'scrollY', 'get').mockReturnValue(123)

      handler({message, event, responseMessages})
      window.dispatchEvent(new Event('scroll'))
      vi.runAllTimers()

      expect(responseMessages.sendResponse).toHaveBeenCalledWith(
        expect.objectContaining({subject: 'lti.scroll', scrollY: 123}),
      )
      vi.useRealTimers()
    })
  })

  describe('FF on + #drawer-layout-content absent → normal path (defensive)', () => {
    beforeEach(() => {
      ENV.FEATURES = {top_navigation_placement: true}
      // No #drawer-layout-content in the DOM
    })

    it('attaches scroll listener to window', () => {
      const spy = vi.spyOn(window, 'addEventListener')
      handler({message, event, responseMessages})
      expect(spy).toHaveBeenCalledWith('scroll', expect.any(Function), false)
    })
  })

  describe('FF absent/undefined → normal path', () => {
    beforeEach(() => {
      ENV.FEATURES = {}
    })

    it('attaches scroll listener to window', () => {
      const spy = vi.spyOn(window, 'addEventListener')
      handler({message, event, responseMessages})
      expect(spy).toHaveBeenCalledWith('scroll', expect.any(Function), false)
    })

    it('reports window.scrollY in the response', () => {
      vi.useFakeTimers()
      vi.spyOn(window, 'scrollY', 'get').mockReturnValue(42)

      handler({message, event, responseMessages})
      window.dispatchEvent(new Event('scroll'))
      vi.runAllTimers()

      expect(responseMessages.sendResponse).toHaveBeenCalledWith(
        expect.objectContaining({subject: 'lti.scroll', scrollY: 42}),
      )
      vi.useRealTimers()
    })
  })
})
