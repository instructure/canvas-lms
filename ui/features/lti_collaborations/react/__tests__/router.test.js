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

// Import the modules we want to mock
import * as DeepLinking from '@canvas/deep-linking/DeepLinking'
import processSingleContentItem from '@canvas/deep-linking/processors/processSingleContentItem'

// Mock the modules - we'll control their behavior in individual tests
jest.mock('@canvas/deep-linking/DeepLinking')
jest.mock('@canvas/deep-linking/processors/processSingleContentItem')

const sleep = async ms => new Promise(resolve => setTimeout(resolve, ms))

describe('router', () => {
  describe('LTI deep linking handlers', () => {
    // Define testOrigin at a higher scope so it's accessible in all tests
    const testOrigin = 'http://localhost'

    beforeAll(() => {
      // Setup ENV for all tests
      fakeENV.setup({
        DEEP_LINKING_POST_MESSAGE_ORIGIN: testOrigin,
      })

      // Add the message event handler to handle events with empty origin
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
    })

    beforeEach(() => {
      // Attach listeners before each test to ensure clean state
      router.attachListeners()
    })

    afterEach(() => {
      // Clean up after each test
      window.removeEventListener('message', router.attachListeners)
    })

    afterAll(() => {
      fakeENV.teardown()
    })

    beforeEach(() => {
      // Reset all mocks before each test
      jest.resetAllMocks()

      // Mock the action creators to return action objects
      jest.spyOn(actions, 'externalContentReady').mockImplementation(data => ({
        type: 'EXTERNAL_CONTENT_READY',
        payload: data,
      }))

      jest.spyOn(actions, 'externalContentRetrievalFailed').mockImplementation(() => ({
        type: 'EXTERNAL_CONTENT_RETRIEVAL_FAILED',
      }))

      // Default behavior for DeepLinking.isValidDeepLinkingEvent
      // We'll override this in specific tests as needed
      DeepLinking.isValidDeepLinkingEvent.mockImplementation(event => {
        return event.data?.subject === 'LtiDeepLinkingResponse'
      })

      // Default behavior for processSingleContentItem
      // We'll override this in specific tests as needed
      processSingleContentItem.mockImplementation(event => event.data.content_items?.[0])
    })

    afterEach(() => {
      // Restore the original implementations
      jest.restoreAllMocks()
    })

    describe('when LTI 1.3 message is received', () => {
      it('does nothing for non-deep-linking-messages', async () => {
        // Override the validation to reject all messages
        DeepLinking.isValidDeepLinkingEvent.mockImplementation(() => false)

        // Send a message that would normally be processed
        const messageEvent = new MessageEvent('message', {
          data: {subject: 'LtiDeepLinkingResponse'},
          origin: testOrigin,
        })
        window.dispatchEvent(messageEvent)
        await sleep(100)

        // Verify no actions were called
        expect(actions.externalContentReady).not.toHaveBeenCalled()
        expect(actions.externalContentRetrievalFailed).not.toHaveBeenCalled()
      })

      it('sends externalContentReady action for valid message', async () => {
        // Setup mocks for this specific test
        DeepLinking.isValidDeepLinkingEvent.mockImplementation(() => true)

        // Create test data
        const item = {hello: 'world'}
        const messageData = {
          subject: 'LtiDeepLinkingResponse',
          content_items: [item],
          service_id: 123,
          tool_id: 1234,
        }

        // Create and dispatch the event
        const messageEvent = new MessageEvent('message', {
          data: messageData,
          origin: testOrigin,
        })

        // Dispatch the event and wait for processing
        window.dispatchEvent(messageEvent)
        await sleep(200)

        // Verify the action was called with the expected data
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

      beforeEach(() => {
        // Setup fakeENV with the new origin for each test
        fakeENV.setup({
          DEEP_LINKING_POST_MESSAGE_ORIGIN: origin,
        })

        // Reset the mocks for this test group
        jest.resetAllMocks()

        // Mock the action creators again after reset
        jest.spyOn(actions, 'externalContentReady').mockImplementation(data => ({
          type: 'EXTERNAL_CONTENT_READY',
          payload: data,
        }))

        jest.spyOn(actions, 'externalContentRetrievalFailed').mockImplementation(() => ({
          type: 'EXTERNAL_CONTENT_RETRIEVAL_FAILED',
        }))

        // Re-attach listeners with the new origin
        router.attachListeners()
      })

      afterEach(() => {
        fakeENV.teardown()
      })

      const sendPostMessage = data => fireEvent(window, new MessageEvent('message', {data, origin}))

      it('sends externalContentReady action', async () => {
        // Create test data
        const item = {service_id: 1, hello: 'world'}
        const messageData = {
          subject: 'externalContentReady',
          contentItems: [item],
          service_id: item.service_id,
        }

        // Send the message
        sendPostMessage(messageData)
        await sleep(100)

        // Verify the action was called with the expected data
        expect(actions.externalContentReady).toHaveBeenCalledWith({
          subject: 'externalContentReady',
          service_id: item.service_id,
          contentItems: [item],
        })
        expect(actions.externalContentRetrievalFailed).not.toHaveBeenCalled()
      })
    })
  })
})
