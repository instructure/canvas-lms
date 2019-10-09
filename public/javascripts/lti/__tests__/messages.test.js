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

import {ltiMessageHandler} from '../messages'

const requestFullWindowLaunchMessage = {
  messageType: 'requestFullWindowLaunch',
  content: 'http://localhost/test'
}

function postMessageEvent(data, origin, source) {
  return {
    data,
    origin,
    source
  }
}

describe('ltiMessageHandler', () => {
  const origin = 'http://localhost'
  const {assign} = window.location

  global.URL = jest.fn().mockImplementation(() => ({
    searchParams: {append: jest.fn()}
  }))

  beforeAll(() => {
    delete window.location
    window.location = {assign: jest.fn()}
  })

  afterAll(() => {
    window.location.assign = assign
  })

  it('opens new window on requestFullWindowLaunch', () => {
    ENV.context_asset_string = 'account_1'
    ltiMessageHandler(postMessageEvent(requestFullWindowLaunchMessage, origin))
    expect(window.location.assign).toHaveBeenCalled()
  })
})
