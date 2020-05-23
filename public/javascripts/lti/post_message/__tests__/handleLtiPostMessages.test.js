/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import handleLtiPostMessage, {ltiState} from '../handleLtiPostMessage'

const requestFullWindowLaunchMessage = {
  messageType: 'requestFullWindowLaunch',
  data: 'http://localhost/test'
}

const reactDevToolsBridge = {
  data: 'http://localhost/test',
  source: 'react-devtools-bridge'
}

function postMessageEvent(data, origin, source) {
  return {
    data,
    origin,
    source
  }
}

describe('handleLtiPostMessage', () => {
  describe('when a whitelisted event is processed', () => {
    it('attempts to call the message handler', async () => {
      ENV.context_asset_string = 'account_1'
      const wasCalled = await handleLtiPostMessage(postMessageEvent(requestFullWindowLaunchMessage))
      expect(wasCalled).toBeTruthy()
    })
  })

  describe('when a non-whitelisted event is processed', () => {
    it('does not attempt to call the message handler', async () => {
      const wasCalled = await handleLtiPostMessage(postMessageEvent({messageType: 'notSupported'}))
      expect(wasCalled).toBeFalsy()
    })
  })

  describe('when source is react-dev-tools', () => {
    it('does not attempt to call the message handler', async () => {
      const wasCalled = await handleLtiPostMessage(postMessageEvent(reactDevToolsBridge))
      expect(wasCalled).toBeFalsy()
    })
  })
})

describe('ltiState', () => {
  it('is empty initially', () => {
    expect(ltiState).toEqual({})
  })
})
