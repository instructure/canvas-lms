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
import { mount } from 'enzyme'
import Text from '@instructure/ui-elements/lib/components/Text'
import {RetrievingContent} from '../DeepLinkingResponse'

let wrapper = 'empty wrapper'
const env = {
  content_items: [{type: 'link'}],
  message: 'message',
  log: 'log',
  error_message: 'error message',
  error_log: "error log",
  DEEP_LINKING_POST_MESSAGE_ORIGIN: '*',
  lti_endpoint: 'https://www.test.com/retrieve'
}
let oldEnv = {}

beforeEach(() => {
  oldEnv = window.ENV
  window.ENV = env
})

afterEach(() => {
  wrapper.unmount()
  window.ENV = oldEnv
})

it('renders an informative message', () => {
  wrapper = mount(<RetrievingContent />)
  expect(wrapper.find(Text).html()).toContain("Retrieving Content")
})

describe('post message', () => {
  const oldPostMessage = window.postMessage
  const postMessageDouble = jest.fn()

  beforeEach(() => {
    window.postMessage = postMessageDouble
    wrapper = mount(<RetrievingContent />)
  })

  afterEach(() => {
    window.postMessage = oldPostMessage
  })

  const messageData = () => (postMessageDouble.mock.calls[0][0])

  it('sends the correct message type', () => {
    expect(messageData().messageType).toEqual('LtiDeepLinkingResponse')
  })

  it('sends the correct content items', () => {
    expect(messageData().content_items).toMatchObject(env.content_items)
  })

  it('sends the correct message', () => {
    expect(messageData().msg).toEqual(env.message)
  })

  it('sends the correct log', () => {
    expect(messageData().log).toEqual(env.log)
  })

  it('sends the correct error message', () => {
    expect(messageData().errormsg).toEqual(env.error_message)
  })

  it('sends the correct error log', () => {
    expect(messageData().errorlog).toEqual(env.error_log)
  })

  it('sends the correct ltiEndpiont', () => {
    expect(messageData().ltiEndpoint).toEqual('https://www.test.com/retrieve')
  })
})
