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

import $ from 'jquery'
import handler from '../lti.scrollToTop'
import * as forwardedMsgSourceModule from '../../forwarded_msg_source'
import type {ResponseMessages} from '../../response_messages'

vi.mock('../../forwarded_msg_source', () => ({
  forwardedMsgSource: vi.fn(),
}))

describe('lti.scrollToTop handler', () => {
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
    vi.mocked(forwardedMsgSourceModule.forwardedMsgSource).mockReturnValue(undefined)
  })

  afterEach(() => {
    vi.restoreAllMocks()
    ENV.FEATURES = {}
  })

  it('returns false', () => {
    ENV.FEATURES = {top_navigation_placement: false}
    expect(handler({message, event, responseMessages})).toBe(false)
  })

  describe('FF on + #drawer-layout-content present → drawer path', () => {
    let drawerContent: HTMLDivElement

    beforeEach(() => {
      ENV.FEATURES = {top_navigation_placement: true}
      drawerContent = document.createElement('div')
      drawerContent.id = 'drawer-layout-content'
      document.body.appendChild(drawerContent)
    })

    afterEach(() => {
      drawerContent.remove()
    })

    it('animates #drawer-layout-content scrollTop', () => {
      const toolWrapper = document.createElement('div')
      toolWrapper.className = 'tool_content_wrapper'
      drawerContent.appendChild(toolWrapper)

      let animatedTarget: JQuery | undefined
      vi.spyOn($.fn, 'animate').mockImplementation(function (this: JQuery) {
        animatedTarget = this
        return this
      })
      handler({message, event, responseMessages})
      expect(animatedTarget?.is('#drawer-layout-content')).toBe(true)
      toolWrapper.remove()
    })

    it('animates to .tool_content_wrapper offset when it exists', () => {
      const toolWrapper = document.createElement('div')
      toolWrapper.className = 'tool_content_wrapper'
      drawerContent.appendChild(toolWrapper)

      const animateSpy = vi.spyOn($.fn, 'animate')
      handler({message, event, responseMessages})

      expect(animateSpy).toHaveBeenCalledWith(
        expect.objectContaining({scrollTop: $(toolWrapper).offset()?.top}),
        'fast',
      )
      toolWrapper.remove()
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

    it('animates html,body scrollTop', () => {
      const toolWrapper = document.createElement('div')
      toolWrapper.className = 'tool_content_wrapper'
      document.body.appendChild(toolWrapper)

      let animatedTarget: JQuery | undefined
      vi.spyOn($.fn, 'animate').mockImplementation(function (this: JQuery) {
        animatedTarget = this
        return this
      })
      handler({message, event, responseMessages})
      expect(animatedTarget?.is('html, body')).toBe(true)
      toolWrapper.remove()
    })

    it('does not modify #drawer-layout-content scrollTop', () => {
      drawerContent.scrollTop = 500
      vi.spyOn($.fn, 'animate').mockImplementation(function (this: JQuery) {
        return this
      })
      handler({message, event, responseMessages})
      expect(drawerContent.scrollTop).toBe(500)
    })
  })

  describe('FF on + #drawer-layout-content absent → normal path (defensive)', () => {
    beforeEach(() => {
      ENV.FEATURES = {top_navigation_placement: true}
    })

    it('animates html,body scrollTop', () => {
      const toolWrapper = document.createElement('div')
      toolWrapper.className = 'tool_content_wrapper'
      document.body.appendChild(toolWrapper)

      let animatedTarget: JQuery | undefined
      vi.spyOn($.fn, 'animate').mockImplementation(function (this: JQuery) {
        animatedTarget = this
        return this
      })
      handler({message, event, responseMessages})
      expect(animatedTarget?.is('html, body')).toBe(true)
      toolWrapper.remove()
    })
  })

  describe('FF absent/undefined → normal path', () => {
    beforeEach(() => {
      ENV.FEATURES = {}
    })

    it('does not animate when no tool wrapper is found', () => {
      const animateSpy = vi.spyOn($.fn, 'animate')
      handler({message, event, responseMessages})
      expect(animateSpy).not.toHaveBeenCalled()
    })
  })

  describe('iframe fallback when no .tool_content_wrapper', () => {
    let iframe: HTMLIFrameElement
    const fakeWindow = {} as Window

    beforeEach(() => {
      ENV.FEATURES = {top_navigation_placement: false}
      iframe = document.createElement('iframe')
      document.body.appendChild(iframe)
      vi.mocked(forwardedMsgSourceModule.forwardedMsgSource).mockReturnValue(fakeWindow)
      // Make iframe's contentWindow match the forwarded source
      Object.defineProperty(iframe, 'contentWindow', {value: fakeWindow, configurable: true})
    })

    afterEach(() => {
      iframe.remove()
    })

    it('animates to the matching iframe offset when no .tool_content_wrapper', () => {
      const animateSpy = vi.spyOn($.fn, 'animate')
      handler({message, event, responseMessages})
      expect(animateSpy).toHaveBeenCalledWith(
        expect.objectContaining({scrollTop: $(iframe).offset()?.top}),
        'fast',
      )
    })
  })
})
