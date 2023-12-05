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
  data: 'http://localhost/test',
}

const reactDevToolsBridge = {
  data: 'http://localhost/test',
  source: 'react-devtools-bridge',
}

function postMessageEvent(data, origin, source) {
  return {
    data,
    origin,
    source: source || {postMessage: jest.fn()},
  }
}

const expectMessage = async (data, wasProcessed) => {
  const wasCalled = await ltiMessageHandler(postMessageEvent(data))
  expect(wasCalled).toBe(wasProcessed)
}

describe('ltiMessageHander', () => {
  it('does not handle unparseable messages from window.postMessage', async () => {
    await expectMessage('abcdef', false)
  })

  it('handles parseable messages from window.postMessage', async () => {
    const flashMessage = jest.spyOn($, 'screenReaderFlashMessageExclusive')
    await expectMessage({subject: 'lti.screenReaderAlert', body: 'Hi'}, true)
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
      await expectMessage(requestFullWindowLaunchMessage, true)
    })
  })

  describe('when a non-whitelisted event is processed', () => {
    it('does not error nor attempt to call the message handler', async () => {
      await expectMessage({subject: 'notSupported'}, false)
    })
  })

  describe('when an ignored event is processed', () => {
    it('does not attempt to call the message handler', async () => {
      await expectMessage({subject: 'LtiDeepLinkingResponse'}, false)
    })
  })

  describe('when source is react-dev-tools', () => {
    it('does not attempt to call the message handler', async () => {
      await expectMessage(reactDevToolsBridge, false)
    })
  })

  describe('LTI Platform Storage subjects', () => {
    it('processes newer lti.* subjects', async () => {
      await expectMessage({subject: 'lti.capabilities'}, true)
      await expectMessage({subject: 'lti.put_data'}, true)
      await expectMessage({subject: 'lti.get_data'}, true)
    })

    it('rejects older org.imsglobal.lti.* subjects', async () => {
      expect(
        await ltiMessageHandler(postMessageEvent({subject: 'org.imsglobal.lti.capabilities'}))
      ).toBe(false)
    })
  })

  describe('when subject is in allow list', () => {
    it('processes message', async () => {
      await expectMessage({subject: 'lti.fetchWindowSize'}, true)
    })
  })

  describe('when message is sent from tool in active RCE', () => {
    it('processes message', async () => {
      const event = postMessageEvent({subject: 'lti.showAlert', in_rce: true})
      expect(await ltiMessageHandler(event)).toBe(true)
    })

    describe('when subject is not supported in active RCE', () => {
      it('does not process message', async () => {
        const event = postMessageEvent({subject: 'lti.scrollToTop', in_rce: true})
        expect(await ltiMessageHandler(event)).toBe(false)
      })

      it('sends unsupported subject response with some context', async () => {
        const event = postMessageEvent({subject: 'lti.scrollToTop', in_rce: true})
        await ltiMessageHandler(event)
        expect(event.source.postMessage).toHaveBeenCalledWith(
          expect.objectContaining({
            error: {
              code: 'unsupported_subject',
              message: 'Not supported inside Rich Content Editor',
            },
          }),
          undefined
        )
      })
    })
  })

  describe('response messages', () => {
    describe('when message handler succeeds', () => {
      afterEach(() => {
        // reset from message handler effects
        delete ltiState.tray
      })

      it('should send response message', async () => {
        const event = postMessageEvent({subject: 'lti.resourceImported'})
        await ltiMessageHandler(event)
        expect(event.source.postMessage).toHaveBeenCalled()
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

      it('should send response message', async () => {
        // this message handler fails when run without a DOM
        const event = postMessageEvent({subject: 'lti.scrollToTop'})
        await ltiMessageHandler(event)
        expect(event.source.postMessage).toHaveBeenCalled()
      })
    })

    describe('when subject is not supported', () => {
      it('should send response message', async () => {
        const event = postMessageEvent({subject: 'notSupported'})
        await ltiMessageHandler(event)
        expect(event.source.postMessage).toHaveBeenCalled()
      })
    })

    describe('when message handler sends a response message', () => {
      it('should send response message', async () => {
        const event = postMessageEvent({subject: 'lti.fetchWindowSize'})
        await ltiMessageHandler(event)
        expect(event.source.postMessage).toHaveBeenCalled()
      })

      it('should not respond to response messages', async () => {
        const event = postMessageEvent({subject: 'notSupported.response'})
        await ltiMessageHandler(event)
        expect(event.source.postMessage).not.toHaveBeenCalled()
      })
    })
  })
})

describe('ltiState', () => {
  it('is empty initially', () => {
    expect(ltiState).toEqual({})
  })
})
