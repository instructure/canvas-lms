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
import {handleDeepLinking, collaborationUrl, onExternalContentReady} from '../collaborations'

describe('handleDeepLinking', () => {
  const content_items = [
    {
      type: 'link',
      title: 'title',
      url: 'http://www.tool.com',
    },
  ]

  const event = dataOverrides => ({
    origin: 'http://www.test.com',
    data: {subject: 'LtiDeepLinkingResponse', content_items, ...dataOverrides},
  })

  let ajaxJSON, flashError, env

  beforeAll(() => {
    env = window.ENV
    flashError = $.flashError
    ajaxJSON = $.ajaxJSON

    window.ENV = {
      DEEP_LINKING_POST_MESSAGE_ORIGIN: 'http://www.test.com',
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

  function mockNewCollaborationElement() {
    jest
      .spyOn(document, 'querySelector')
      .mockReturnValue({getAttribute: key => ({action: '/collaborations'}[key])})
  }

  function expectAJAXWithContentItems(url, method) {
    const data = {contentItems: JSON.stringify(content_items)}
    expect($.ajaxJSON).toHaveBeenCalledWith(url, method, data, expect.anything(), expect.anything())
  }

  it('creates the collaboration', async () => {
    mockNewCollaborationElement()
    await handleDeepLinking(event())
    expectAJAXWithContentItems('/collaborations?tool_id=', 'POST')
    expect(document.querySelector).toHaveBeenCalledWith('#new_collaboration')
  })

  it('passes along the tool_id from the postMessage', async () => {
    mockNewCollaborationElement()
    await handleDeepLinking(event({tool_id: 9876}))
    expectAJAXWithContentItems('/collaborations?tool_id=9876', 'POST')
    expect(document.querySelector).toHaveBeenCalledWith('#new_collaboration')
  })

  describe('when there is a service_id in the postMessage', () => {
    it('updates the collaboration', async () => {
      jest.spyOn(document, 'querySelector').mockReturnValue({href: '/collaborations/123'})
      await handleDeepLinking(event({service_id: 123}))
      expectAJAXWithContentItems('/collaborations/123?tool_id=', 'PUT')
    })

    it('passes along the tool_id from the postMessage', async () => {
      jest.spyOn(document, 'querySelector').mockReturnValue({href: '/collaborations/123'})
      await handleDeepLinking(event({service_id: 123, tool_id: 9876}))
      expectAJAXWithContentItems('/collaborations/123?tool_id=9876', 'PUT')
    })
  })

  describe('when there is a unhandled error parsing the content item', () => {
    it('does not attempt to create a collaboration', async () => {
      await handleDeepLinking(event({content_items: 1}))
      expect($.ajaxJSON).not.toHaveBeenCalled()
    })

    it('shows an error message to the user', async () => {
      await handleDeepLinking(event({content_items: 1}))
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
  let querySelector, ajaxJSON

  beforeAll(() => {
    querySelector = global.document.querySelector
    ajaxJSON = $.ajaxJSON

    global.document.querySelector = jest.fn().mockImplementation(() => ({
      href: 'http://www.test.com/update',
      getAttribute: () => 'http://www.test.com/create',
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
    onExternalContentReady({contentItems: {}})
    expect($.ajaxJSON).toHaveBeenCalledWith(
      'http://www.test.com/create?tool_id=',
      'POST',
      expect.anything(),
      expect.anything(),
      expect.anything()
    )
  })

  describe('with a service id', () => {
    it('updates the existing collaboration', () => {
      onExternalContentReady({contentItems: {}, service_id: 1})
      expect($.ajaxJSON).toHaveBeenCalledWith(
        'http://www.test.com/update?tool_id=',
        'PUT',
        expect.anything(),
        expect.anything(),
        expect.anything()
      )
    })
  })
})
