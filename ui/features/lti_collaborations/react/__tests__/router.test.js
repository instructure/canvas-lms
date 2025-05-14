// @vitest-environment jsdom
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
import {fireEvent} from '@testing-library/react'
import fakeENV from '@canvas/test-utils/fakeENV'

const sleep = async ms => new Promise(resolve => setTimeout(resolve, ms))

describe('router', () => {
  describe('LTI deep linking handlers', () => {
    // Define testOrigin at a higher scope so it's accessible in all tests
    const testOrigin = 'http://localhost'

    beforeAll(() => {
      fakeENV.setup({
        DEEP_LINKING_POST_MESSAGE_ORIGIN: testOrigin,
      })

      // this is added before listeners are attached so that this listener comes before.
      // this adds an event.origin to all messages so that isValidDeepLinkingEvent doesn't break,
      // since jsdom doesn't support event.origin, and then retriggers the event.
      window.addEventListener('message', event => {
        if (event.origin === '') {
          event.stopImmediatePropagation()
          const eventWithOrigin = new MessageEvent('message', {
            data: event.data,
            origin: testOrigin,
          })
          window.dispatchEvent(eventWithOrigin)
        }
      })

      router.attachListeners()
    })

    afterAll(() => {
      fakeENV.teardown()
    })

    beforeEach(() => {
      // Clear all mocks before each test
      jest.clearAllMocks()

      // Mock the action creators to return action objects
      // This follows the Redux pattern where action creators return action objects
      jest.spyOn(actions, 'externalContentReady').mockImplementation(data => ({
        type: 'EXTERNAL_CONTENT_READY',
        payload: data,
      }))

      jest.spyOn(actions, 'externalContentRetrievalFailed').mockImplementation(() => ({
        type: 'EXTERNAL_CONTENT_RETRIEVAL_FAILED',
      }))
    })

    afterEach(() => {
      // Restore the original implementations
      jest.restoreAllMocks()
    })

    describe('when LTI 1.3 message is received', () => {
      it('does nothing for non-deep-linking-messages', async () => {
        window.postMessage({subject: 'lol'}, testOrigin)
        await sleep(100)
        expect(actions.externalContentReady).not.toHaveBeenCalled()
        expect(actions.externalContentRetrievalFailed).not.toHaveBeenCalled()
      })

      it('sends externalContentReady action for valid message', async () => {
        const item = {hello: 'world'}
        window.postMessage(
          {
            subject: 'LtiDeepLinkingResponse',
            content_items: [item],
            service_id: 123,
            tool_id: 1234,
          },
          testOrigin,
        )
        await sleep(100)

        expect(actions.externalContentReady).toHaveBeenCalledWith({
          service_id: 123,
          tool_id: 1234,
          contentItems: [item],
        })
        expect(actions.externalContentRetrievalFailed).not.toHaveBeenCalled()
      })
    })

    describe('when LTI 1.1 message is received', () => {
      const origin = 'http://example.com'

      beforeAll(() => {
        // Setup fakeENV with the new origin before attaching listeners
        fakeENV.setup({
          DEEP_LINKING_POST_MESSAGE_ORIGIN: origin,
        })

        // Re-attach listeners with the new origin
        router.attachListeners()
      })

      afterAll(() => {
        fakeENV.teardown()
      })

      const sendPostMessage = data => fireEvent(window, new MessageEvent('message', {data, origin}))

      it('sends externalContentReady action', async () => {
        const item = {service_id: 1, hello: 'world'}
        sendPostMessage({
          subject: 'externalContentReady',
          contentItems: [item],
          service_id: item.service_id,
        })

        expect(actions.externalContentReady).toHaveBeenCalledWith({
          // subject not required to be passed in, but comes from the event and doesn't hurt
          subject: 'externalContentReady',
          service_id: item.service_id,
          contentItems: [item],
        })
        expect(actions.externalContentRetrievalFailed).not.toHaveBeenCalled()
      })
    })
  })
})
