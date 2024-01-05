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
import {fireEvent} from '@testing-library/react'
import {
  EXTERNAL_CONTENT_CANCEL,
  EXTERNAL_CONTENT_READY,
  handleExternalContentMessages,
  postMessageExternalContentReady,
  postMessageExternalContentCancel,
  Service,
} from '../messages'

describe('1.1 content item messages', () => {
  describe('handleExternalContentMessages', () => {
    const env = {
      DEEP_LINKING_POST_MESSAGE_ORIGIN: 'http://canvas.test',
    }

    function sendPostMessage(data, origin = env.DEEP_LINKING_POST_MESSAGE_ORIGIN) {
      fireEvent(
        window,
        new MessageEvent('message', {
          data,
          origin,
        })
      )
    }

    const externalContentCancel = () => ({
      subject: EXTERNAL_CONTENT_CANCEL,
    })

    const externalContentReady = (props = {}) => ({
      subject: EXTERNAL_CONTENT_READY,
      contentItems: [{url: 'test'}],
      service: 'equella',
      service_id: '1',
      ...props,
    })

    let ready: () => void
    let cancel: () => void
    let remove: () => void | undefined
    beforeEach(() => {
      ready = jest.fn()
      cancel = jest.fn()
    })

    afterEach(() => {
      remove && remove()
    })

    it('calls cancel handler on externalContentCancel event', () => {
      remove = handleExternalContentMessages({
        cancel,
        env,
      })

      sendPostMessage(externalContentCancel())
      expect(cancel).toHaveBeenCalled()
    })

    it('calls ready handler on externalContentReady event', () => {
      remove = handleExternalContentMessages({
        ready,
        env,
      })

      sendPostMessage(externalContentReady())
      expect(ready).toHaveBeenCalled()
    })

    it('does not call handlers after listener is removed', () => {
      remove = handleExternalContentMessages({
        cancel,
        ready,
        env,
      })

      remove()

      sendPostMessage(externalContentCancel())
      expect(cancel).not.toHaveBeenCalled()

      sendPostMessage(externalContentReady())
      expect(ready).not.toHaveBeenCalled()
    })

    it('ignores events from other origins', () => {
      remove = handleExternalContentMessages({
        cancel,
        env,
      })

      sendPostMessage(externalContentCancel(), 'http://other.test')
      expect(cancel).not.toHaveBeenCalled()
    })

    describe('when service is provided', () => {
      it('calls ready handler when service matches', () => {
        const service: Service = 'external_tool_redirect'
        remove = handleExternalContentMessages({
          ready,
          env,
          service,
        })

        sendPostMessage(externalContentReady({service}))
        expect(ready).toHaveBeenCalled()
      })

      it('does not call ready handler when service is different', () => {
        const service: Service = 'external_tool_redirect'
        remove = handleExternalContentMessages({
          ready,
          env,
          service,
        })

        sendPostMessage(externalContentReady())
        expect(ready).not.toHaveBeenCalled()
      })
    })
  })

  describe('sending messages', () => {
    let originalEnv

    beforeEach(() => {
      originalEnv = window.ENV
      window.ENV = {...ENV, DEEP_LINKING_POST_MESSAGE_ORIGIN: 'http://canvas.test'}
    })
    afterEach(() => (window.ENV = originalEnv))

    describe('postMessageExternalContentReady', () => {
      it('posts message to window', () => {
        const window = {postMessage: jest.fn()}
        const eventData = {
          contentItems: [{url: 'test'}],
          service: 'equella',
        }
        postMessageExternalContentReady(window, eventData)
        expect(window.postMessage).toHaveBeenCalledWith(
          {subject: 'externalContentReady', ...eventData},
          'http://canvas.test'
        )
      })
    })

    describe('postMessageExternalContentCancel', () => {
      it('posts message to window', () => {
        const window = {postMessage: jest.fn()}
        postMessageExternalContentCancel(window)
        expect(window.postMessage).toHaveBeenCalledWith(
          {subject: 'externalContentCancel'},
          'http://canvas.test'
        )
      })
    })
  })
})
