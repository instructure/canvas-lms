// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {handler, init} from '../../../../public/javascripts/lti_post_message_forwarding'

describe('lti_post_message_forwarding', () => {
  describe('handler', () => {
    let message: string | object
    let origin: string
    let parentDomain: string
    let windowReferences: Array<Window | undefined>
    // eslint-disable-next-line no-undef
    let source: MessageEventSource
    let parentWindow: Window
    let includeRCESignal: boolean

    const subject = () =>
      handler(
        parentDomain,
        windowReferences,
        parentWindow,
        includeRCESignal
      )({data: message, origin, source} as MessageEvent)

    describe('when message is not JSON string or JS object', () => {
      beforeEach(() => {
        message = 'abcdefghi'
      })

      it('returns false', () => {
        expect(subject()).toBe(false)
      })
    })

    describe('incoming message', () => {
      beforeEach(() => {
        message = {subject: 'hello_world', key: 'value'}
        origin = 'https://test.tool.com'
        parentDomain = 'https://parent.domain.com'
        windowReferences = []
        includeRCESignal = false
        source = {
          postMessage: jest.fn(),
        } as unknown as Window
        parentWindow = {
          postMessage: jest.fn(),
        } as unknown as Window
      })

      it('posts message to top parent', () => {
        subject()
        expect(parentWindow.postMessage).toHaveBeenCalled()
      })

      it('attaches origin and windowId to message', () => {
        subject()
        expect(parentWindow.postMessage).toHaveBeenCalledWith(
          {...(message as object), sourceToolInfo: {origin, windowId: 0}},
          expect.anything()
        )
      })

      it('stores source window in an array', () => {
        subject()
        expect(windowReferences.length).toBe(1)
        expect(windowReferences[0]).toBe(source)
      })

      it('reuses existing windowId for previously-seen source windows', () => {
        subject()
        const source2 = {postMessage: jest.fn()}
        handler(
          parentDomain,
          windowReferences,
          parentWindow
        )({data: message, origin, source: source2} as MessageEvent)
        subject()
        expect(parentWindow.postMessage.mock.calls[0][0].sourceToolInfo.windowId).toBe(0)
        expect(parentWindow.postMessage.mock.calls[1][0].sourceToolInfo.windowId).toBe(1)
        expect(parentWindow.postMessage.mock.calls[2][0].sourceToolInfo.windowId).toBe(0)
        expect(windowReferences.length).toBe(2)
        expect(windowReferences[0]).toBe(source)
        expect(windowReferences[1]).toBe(source2)
      })

      it('addresses message to parent domain', () => {
        subject()
        expect(parentWindow.postMessage).toHaveBeenCalledWith(expect.anything(), parentDomain)
      })

      describe('when includeRCESignal is true', () => {
        beforeEach(() => {
          includeRCESignal = true
        })

        it('adds in_rce=true to message', () => {
          subject()
          expect(parentWindow.postMessage.mock.calls[0][0].in_rce).toBe(true)
        })
      })
    })

    describe('outgoing message', () => {
      beforeEach(() => {
        message = {
          subject: 'hello_world',
          key: 'value',
          sourceToolInfo: {origin: 'https://test.tool.com', windowId: 1},
        }
        origin = 'https://parent.domain.com'
        parentDomain = 'https://parent.domain.com'
        source = {
          postMessage: jest.fn(),
        } as unknown as Window
        // source is index 1 (above we're using windowId=1):
        windowReferences = [undefined, source]
      })

      describe('when message has no sourceToolInfo', () => {
        beforeEach(() => {
          message = {subject: 'hello_world', key: 'value'}
        })

        it('returns false', () => {
          expect(subject()).toBe(false)
        })
      })

      it('posts message to source window', () => {
        subject()
        expect(source.postMessage).toHaveBeenCalled()
      })

      it('addresses message to correct origin and source (from sourceToolInfo)', () => {
        subject()
        expect(source.postMessage).toHaveBeenCalledWith(expect.anything(), 'https://test.tool.com')
      })

      it('removes sourceToolInfo from message', () => {
        subject()
        expect(source.postMessage).toHaveBeenCalledWith(
          {subject: 'hello_world', key: 'value'},
          expect.anything()
        )
      })
    })
  })

  describe('init', () => {
    afterEach(() => jest.restoreAllMocks())

    it('sets up an event handler for postMessage when the DOM loads', () => {
      jest.spyOn(document, 'readyState', 'get').mockReturnValue('loading')
      jest.spyOn(document, 'addEventListener').mockImplementation(() => {})
      init()
      expect(document.addEventListener).toHaveBeenCalledWith('DOMContentLoaded', expect.anything())
      const cb = document.addEventListener.mock.calls[0][1]

      jest.spyOn(window, 'addEventListener').mockImplementation(() => {})
      cb()
      expect(window.addEventListener).toHaveBeenCalledWith('message', expect.anything())
    })
  })
})
