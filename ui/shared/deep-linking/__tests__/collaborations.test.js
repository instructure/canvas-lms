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
import {
  addDeepLinkingListener,
  handleDeepLinking,
  collaborationUrl,
  onExternalContentReady
} from '../collaborations'

describe('addDeepLinkingListener', () => {
  let addEventListener
  const subject = () => {
    addDeepLinkingListener()
  }

  beforeAll(() => {
    addEventListener = global.addEventListener
    global.addEventListener = jest.fn()
  })

  afterAll(() => {
    global.addEventListener = addEventListener
  })

  beforeEach(() => {
    global.addEventListener.mockClear()
  })

  it('adds the message handler to the window', () => {
    subject()
    expect(global.addEventListener).toHaveBeenCalledWith('message', handleDeepLinking)
  })
})

describe('handleDeepLinking', () => {
  const content_items = [
    {
      type: 'link',
      title: 'title',
      url: 'http://www.tool.com'
    }
  ]

  const event = overrides => ({
    origin: 'http://www.test.com',
    data: {messageType: 'LtiDeepLinkingResponse', content_items},
    ...overrides
  })

  let ajaxJSON, flashError, env

  beforeAll(() => {
    env = window.ENV
    flashError = $.flashError
    ajaxJSON = $.ajaxJSON

    window.ENV = {
      DEEP_LINKING_POST_MESSAGE_ORIGIN: 'http://www.test.com'
    }

    $.flashError = jest.fn()
    $.ajaxJSON = jest.fn().mockImplementation(() => ({}))
  })

  afterAll(() => {
    window.ENV = env
    $.flashError = flashError
    $.ajaxJSON = ajaxJSON
  })

  beforeEach(() => {
    $.ajaxJSON.mockClear()
    $.flashError.mockClear()
  })

  it('creates the collaboration', async () => {
    await handleDeepLinking(event())
    expect($.ajaxJSON).toHaveBeenCalledWith(
      undefined,
      'POST',
      {contentItems: JSON.stringify(content_items)},
      expect.anything(),
      expect.anything()
    )
  })

  describe('when the event is invalid', () => {
    const overrides = {
      origin: 'http://bad.origin.com'
    }

    it('does not attempt to create a collaboration', async () => {
      await handleDeepLinking(event(overrides))
      expect($.ajaxJSON).not.toHaveBeenCalled()
    })
  })

  describe('when there is a unhandled error parsing the content item', () => {
    const overrides = {
      data: {messageType: 'LtiDeepLinkingResponse', content_items: 1}
    }

    it('does not attempt to create a collaboration', async () => {
      await handleDeepLinking(event(overrides))
      expect($.ajaxJSON).not.toHaveBeenCalled()
    })

    it('shows an error message to the user', async () => {
      await handleDeepLinking(event(overrides))
      expect($.flashError).toHaveBeenCalled()
    })
  })
})

describe('collaborationUrl', () => {
  it('returns a collaboration url', () => {
    expect(collaborationUrl(1)).toEqual(`${window.location.toString()}/1`)
  })
})

describe('onExternalContentReady', () => {
  const params = overrides => [
    {},
    {
      contentItems: {},
      ...overrides
    }
  ]
  let querySelector, ajaxJSON

  beforeAll(() => {
    querySelector = global.document.querySelector
    ajaxJSON = $.ajaxJSON

    global.document.querySelector = jest.fn().mockImplementation(() => ({
      href: 'http://www.test.com/update',
      getAttribute: () => 'http://www.test.com/create'
    }))
    $.ajaxJSON = jest.fn().mockImplementation(() => ({}))
  })

  afterAll(() => {
    global.document.querySelector = querySelector
    $.ajaxJSON = ajaxJSON
  })

  beforeEach(() => {
    global.document.querySelector.mockClear()
    $.ajaxJSON.mockClear()
  })

  it('creates a new collaboration', () => {
    onExternalContentReady(...params())
    expect($.ajaxJSON).toHaveBeenCalledWith(
      'http://www.test.com/create',
      'POST',
      expect.anything(),
      expect.anything(),
      expect.anything()
    )
  })

  describe('with a service id', () => {
    it('updates the existing collaboration', () => {
      onExternalContentReady(...params({service_id: 1}))
      expect($.ajaxJSON).toHaveBeenCalledWith(
        'http://www.test.com/update',
        'PUT',
        expect.anything(),
        expect.anything(),
        expect.anything()
      )
    })
  })
})
