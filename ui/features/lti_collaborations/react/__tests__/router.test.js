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

import $ from 'jquery'
import actions from '../actions'
import router from '../router'

const sleep = async ms => new Promise(resolve => setTimeout(resolve, ms))

describe('router', () => {
  describe('LTI deep linking handlers', () => {
    let oldEnv

    beforeAll(() => {
      oldEnv = ENV
      ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = document.origin

      // this is added before listeners are attached so that this listener comes before.
      // this adds an event.origin to all messages so that isValidDeepLinkingEvent doesn't break,
      // since jsdom doesn't support event.origin, and then retriggers the event.
      window.addEventListener('message', event => {
        if (event.origin === '') {
          event.stopImmediatePropagation()
          const eventWithOrigin = new MessageEvent('message', {
            data: event.data,
            origin: document.origin
          })
          window.dispatchEvent(eventWithOrigin)
        }
      })

      router.attachListeners()
    })

    afterAll(() => {
      ENV = oldEnv
    })

    beforeEach(() => {
      // needs to be two functions to match normal action signature
      jest.spyOn(actions, 'externalContentReady').mockImplementation(() => () => {})
      jest.spyOn(actions, 'externalContentRetrievalFailed').mockImplementation(() => () => {})
    })

    afterEach(() => {
      actions.externalContentReady.mockRestore()
      actions.externalContentRetrievalFailed.mockRestore()
    })

    describe('when LTI 1.3 message is received', () => {
      it('does nothing for non-deep-linking-messages', async () => {
        window.postMessage({messageType: 'lol'}, ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN)
        await sleep(100)
        expect(actions.externalContentReady).not.toHaveBeenCalled()
        expect(actions.externalContentRetrievalFailed).not.toHaveBeenCalled()
      })

      it('sends externalContentReady action for valid message', async () => {
        const item = {service_id: 1, hello: 'world'}
        window.postMessage(
          {
            messageType: 'LtiDeepLinkingResponse',
            content_items: [item]
          },
          ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN
        )
        await sleep(100)

        expect(actions.externalContentReady).toHaveBeenCalledWith({
          service_id: item.service_id,
          contentItems: [item]
        })
        expect(actions.externalContentRetrievalFailed).not.toHaveBeenCalled()
      })
    })

    describe('when LTI 1.1 message is received', () => {
      it('sends externalContentReady action', async () => {
        const item = {service_id: 1, hello: 'world'}
        $(window).trigger('externalContentReady', {
          contentItems: [item],
          service_id: item.service_id
        })
        await sleep(100)

        expect(actions.externalContentReady).toHaveBeenCalledWith({
          service_id: item.service_id,
          contentItems: [item]
        })
        expect(actions.externalContentRetrievalFailed).not.toHaveBeenCalled()
      })
    })
  })
})
