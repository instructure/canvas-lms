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

import {isValidDeepLinkingEvent, handleDeepLinking, type DeepLinkEvent} from '../DeepLinking'

describe('isValidDeepLinkingEvent', () => {
  let data: {
      subject: 'LtiDeepLinkingResponse'
    },
    event: DeepLinkEvent,
    env: {
      DEEP_LINKING_POST_MESSAGE_ORIGIN: string
    }

  beforeEach(() => {
    event = {
      data: {subject: 'LtiDeepLinkingResponse', placement: 'not_editor_button'},
      origin: 'canvas.instructure.com',
    } as unknown as DeepLinkEvent
    env = {DEEP_LINKING_POST_MESSAGE_ORIGIN: 'canvas.instructure.com'}
  })

  const subject = () => isValidDeepLinkingEvent(event, env)

  it('return true', () => {
    expect(subject()).toEqual(true)
  })

  describe('when the message origin is incorrect', () => {
    beforeEach(() => {
      event = {data, origin: 'wrong.origin.com'} as unknown as DeepLinkEvent
    })

    it('return false', () => {
      expect(subject()).toEqual(false)
    })
  })

  describe('when the event data is not present', () => {
    beforeEach(() => {
      event = {origin: 'canvas.instructure.com'} as unknown as DeepLinkEvent
    })

    it('return false', () => {
      expect(subject()).toEqual(false)
    })
  })

  describe('when the subject is incorrect', () => {
    beforeEach(() => {
      event = {
        data: {subject: 'WrongMessageType'},
        origin: 'canvas.instructure.com',
      } as unknown as DeepLinkEvent
    })

    it('return false', () => {
      expect(subject()).toEqual(false)
    })
  })

  describe('when the placement is "editor-button"', () => {
    beforeEach(() => {
      event = {
        data: {subject: 'LtiDeepLinkingResponse', placement: 'editor_button'},
        origin: 'canvas.instructure.com',
      } as unknown as DeepLinkEvent
    })

    it('return false', () => {
      expect(subject()).toEqual(false)
    })
  })
})

describe('handleDeepLinking', () => {
  const content_items = [
    {
      type: 'link',
      title: 'title',
      url: 'http://www.tool.com',
    },
  ]

  const event = (overrides: {}): DeepLinkEvent =>
    ({
      origin: 'http://www.test.com',
      data: {subject: 'LtiDeepLinkingResponse', content_items},
      ...overrides,
    } as unknown as DeepLinkEvent)

  let env: typeof window.ENV

  beforeAll(() => {
    env = window.ENV
    ;(window.ENV as any) = {
      DEEP_LINKING_POST_MESSAGE_ORIGIN: 'http://www.test.com',
    }
  })

  afterAll(() => {
    ;(window.ENV as any) = env
  })

  it('passes event to callback', async () => {
    const callback = jest.fn()
    const ev = event({})
    await handleDeepLinking(callback)(ev)

    expect(callback).toHaveBeenCalledWith(ev)
  })

  describe('when the event is invalid', () => {
    const overrides = {
      origin: 'http://bad.origin.com',
    }

    it('does not pass event to callback', async () => {
      const callback = jest.fn()
      await handleDeepLinking(callback)(event(overrides))

      expect(callback).not.toHaveBeenCalled()
    })
  })
})
