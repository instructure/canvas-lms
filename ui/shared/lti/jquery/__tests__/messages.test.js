/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {ltiMessageHandler, ltiState} from '../messages'
import $ from '@canvas/rails-flash-notifications'

const requestFullWindowLaunchMessage = {
  subject: 'requestFullWindowLaunch',
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
    source: source || {postMessage: jest.fn()}
  }
}

describe('ltiMessageHander', () => {
  it('does not handle unparseable messages from window.postMessage', async () => {
    const wasCalled = await ltiMessageHandler(postMessageEvent('abcdef'))
    expect(wasCalled).toBeFalsy()
  })

  it('handles parseable messages from window.postMessage', async () => {
    const flashMessage = jest.spyOn($, 'screenReaderFlashMessageExclusive')
    await ltiMessageHandler(postMessageEvent({subject: 'lti.screenReaderAlert', body: 'Hi'}))
    expect(flashMessage).toHaveBeenCalledWith('Hi')
  })

  describe('when a whitelisted event is processed', () => {
    let oldLocation

    beforeEach(() => {
      oldLocation = window.location
      delete window.location
      window.location = {assign: jest.fn()}
    })

    afterEach(() => {
      window.location = oldLocation
      delete ltiState.fullWindowProxy
    })

    it('attempts to call the message handler', async () => {
      ENV.context_asset_string = 'account_1'
      const wasCalled = await ltiMessageHandler(postMessageEvent(requestFullWindowLaunchMessage))
      expect(wasCalled).toBeTruthy()
    })
  })

  describe('when a non-whitelisted event is processed', () => {
    it('does not error nor attempt to call the message handler', async () => {
      const wasCalled = await ltiMessageHandler(postMessageEvent({subject: 'notSupported'}))
      expect(wasCalled).toBeFalsy()
    })
  })

  describe('when an ignored event is processed', () => {
    it('does not attempt to call the message handler', async () => {
      const wasCalled = await ltiMessageHandler(
        postMessageEvent({subject: 'LtiDeepLinkingResponse'})
      )
      expect(wasCalled).toBeFalsy()
    })
  })

  describe('when source is react-dev-tools', () => {
    it('does not attempt to call the message handler', async () => {
      const wasCalled = await ltiMessageHandler(postMessageEvent(reactDevToolsBridge))
      expect(wasCalled).toBeFalsy()
    })
  })

  describe('response messages', () => {
    let platformStorageFeatureFlag

    describe('when message handler succeeds', () => {
      afterEach(() => {
        // reset from message handler effects
        delete ltiState.tray
      })

      describe('when lti_platform_storage feature flag is disabled', () => {
        beforeEach(() => {
          platformStorageFeatureFlag = false
        })

        it('should not send response message', async () => {
          const event = postMessageEvent({subject: 'lti.resourceImported'})
          await ltiMessageHandler(event, platformStorageFeatureFlag)
          expect(event.source.postMessage).not.toHaveBeenCalled()
        })
      })

      describe('when lti_platform_storage feature flag is enabled', () => {
        beforeEach(() => {
          platformStorageFeatureFlag = true
        })

        it('should send response message', async () => {
          const event = postMessageEvent({subject: 'lti.resourceImported'})
          await ltiMessageHandler(event, platformStorageFeatureFlag)
          expect(event.source.postMessage).toHaveBeenCalled()
        })
      })
    })

    describe('when message handler fails', () => {
      beforeEach(() => {
        // mock console.error to avoid jest complaints
        jest.spyOn(console, 'error').mockImplementation()
      })

      afterEach(() => {
        // eslint-disable-next-line no-console
        console.error.mockRestore()
      })

      describe('when lti_platform_storage feature flag is disabled', () => {
        beforeEach(() => {
          platformStorageFeatureFlag = false
        })

        it('should not send response message', async () => {
          // this message handler fails when run without a DOM
          const event = postMessageEvent({subject: 'lti.scrollToTop'})
          await ltiMessageHandler(event, platformStorageFeatureFlag)
          expect(event.source.postMessage).not.toHaveBeenCalled()
        })
      })

      describe('when lti_platform_storage feature flag is enabled', () => {
        beforeEach(() => {
          platformStorageFeatureFlag = true
        })

        it('should send response message', async () => {
          // this message handler fails when run without a DOM
          const event = postMessageEvent({subject: 'lti.scrollToTop'})
          await ltiMessageHandler(event, platformStorageFeatureFlag)
          expect(event.source.postMessage).toHaveBeenCalled()
        })
      })
    })

    describe('when subject is not supported', () => {
      describe('when lti_platform_storage feature flag is disabled', () => {
        beforeEach(() => {
          platformStorageFeatureFlag = false
        })

        it('should not send response message', async () => {
          const event = postMessageEvent({subject: 'notSupported'})
          await ltiMessageHandler(event, platformStorageFeatureFlag)
          expect(event.source.postMessage).not.toHaveBeenCalled()
        })
      })

      describe('when lti_platform_storage feature flag is enabled', () => {
        beforeEach(() => {
          platformStorageFeatureFlag = true
        })

        it('should send response message', async () => {
          const event = postMessageEvent({subject: 'notSupported'})
          await ltiMessageHandler(event, platformStorageFeatureFlag)
          expect(event.source.postMessage).toHaveBeenCalled()
        })
      })
    })

    describe('when message handler sends a response message', () => {
      describe('when lti_platform_storage feature flag is disabled', () => {
        beforeEach(() => {
          platformStorageFeatureFlag = false
        })

        it('should send response message', async () => {
          const event = postMessageEvent({subject: 'lti.fetchWindowSize'})
          await ltiMessageHandler(event, platformStorageFeatureFlag)
          expect(event.source.postMessage).toHaveBeenCalled()
        })
      })

      describe('when lti_platform_storage feature flag is enabled', () => {
        beforeEach(() => {
          platformStorageFeatureFlag = true
        })

        it('should send response message', async () => {
          const event = postMessageEvent({subject: 'lti.fetchWindowSize'})
          await ltiMessageHandler(event, platformStorageFeatureFlag)
          expect(event.source.postMessage).toHaveBeenCalled()
        })
      })
    })
  })
})

describe('ltiState', () => {
  it('is empty initially', () => {
    expect(ltiState).toEqual({})
  })
})
