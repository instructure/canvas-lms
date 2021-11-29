/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React from 'react'
import {mount} from 'enzyme'
import {Text} from '@instructure/ui-text'
import {RetrievingContent} from '../DeepLinkingResponse'

let wrapper = 'empty wrapper'
const windowMock = {}
const env = {
  DEEP_LINKING_POST_MESSAGE_ORIGIN: '*',
  deep_link_response: {
    content_items: [{type: 'link'}],
    msg: 'message',
    log: 'log',
    errormsg: 'error message',
    errorlog: 'error log',
    ltiEndpoint: 'https://www.test.com/retrieve',
    reloadpage: false
  }
}

const render = () => mount(<RetrievingContent environment={env} parentWindow={windowMock} />)

beforeEach(() => {
  windowMock.postMessage = jest.fn()
})

afterEach(() => {
  wrapper.unmount()
})

it('renders an informative message', () => {
  wrapper = render()
  expect(wrapper.find(Text).html()).toContain('Retrieving Content')
})

describe('post message', () => {
  beforeEach(() => {
    wrapper = render()
  })

  const messageData = () => windowMock.postMessage.mock.calls[0][0]

  ;['content_items', 'msg', 'log', 'errormsg', 'errorlog', 'ltiEndpoint', 'reloadpage'].forEach(
    attr => {
      it(`sends the correct ${attr}`, () => {
        expect(messageData()[attr]).toEqual(env.deep_link_response[attr])
      })
    }
  )

  it('sends the correct content items', () => {
    expect(messageData().content_items).toMatchObject(env.deep_link_response.content_items)
  })

  it('sends the correct message type', () => {
    expect(messageData().messageType).toEqual('LtiDeepLinkingResponse')
  })
})
