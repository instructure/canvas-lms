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

import {handler} from '../index'

describe('post_message_forwarding', () => {
  describe('handler', () => {
    let message: string | object
    let origin: string
    let parentDomain: string
    let windowReferences: object
    // eslint-disable-next-line no-undef
    let source: MessageEventSource
    let parentWindow: Window

    const subject = () =>
      handler(
        parentDomain,
        windowReferences,
        parentWindow
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
        windowReferences = {}
        source = {
          postMessage: jest.fn(),
        } as unknown as Window
        parentWindow = {
          postMessage: jest.fn(),
        } as unknown as Window
      })

      it('stores source window keyed by origin', () => {
        subject()
        expect(windowReferences[origin]).toBe(source)
      })

      it('posts message to top parent', () => {
        subject()
        expect(parentWindow.postMessage).toHaveBeenCalled()
      })

      it('attaches origin to message', () => {
        subject()
        expect(parentWindow.postMessage).toHaveBeenCalledWith(
          {...(message as object), toolOrigin: origin},
          expect.anything()
        )
      })

      it('addresses message to parent domain', () => {
        subject()
        expect(parentWindow.postMessage).toHaveBeenCalledWith(expect.anything(), parentDomain)
      })
    })

    describe('outgoing message', () => {
      beforeEach(() => {
        message = {subject: 'hello_world', key: 'value', toolOrigin: 'https://test.tool.com'}
        origin = 'https://parent.domain.com'
        parentDomain = 'https://parent.domain.com'
        source = {
          postMessage: jest.fn(),
        } as unknown as Window
        windowReferences = {
          'https://test.tool.com': source,
        }
      })

      describe('when message has no toolOrigin', () => {
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

      it('addresses message to toolOrigin', () => {
        subject()
        expect(source.postMessage).toHaveBeenCalledWith(expect.anything(), 'https://test.tool.com')
      })

      it('removes toolOrigin from message', () => {
        subject()
        expect(source.postMessage).toHaveBeenCalledWith(
          {subject: 'hello_world', key: 'value'},
          expect.anything()
        )
      })
    })
  })
})
