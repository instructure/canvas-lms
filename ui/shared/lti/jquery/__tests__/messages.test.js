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

import $ from '@canvas/rails-flash-notifications'
import {
  callbackOnLtiPostMessage,
  ltiMessageHandler,
  ltiState,
  onLtiClosePostMessage,
  removeLtiPostMessageCallback,
} from '../messages'

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

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
    afterEach(() => {
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
        await ltiMessageHandler(postMessageEvent({subject: 'org.imsglobal.lti.capabilities'})),
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
          undefined,
        )
      })
    })

    describe('with callbacks', () => {
      const subject = 'lti.close'
      const placement = 'placement'

      it('calls callback when added', async () => {
        const callback = jest.fn()

        callbackOnLtiPostMessage(subject, placement, callback)

        const event = postMessageEvent({subject})
        await ltiMessageHandler(event)
        expect(callback).toHaveBeenCalled()
      })

      it('does not call callback once removed', async () => {
        const callback = jest.fn()

        callbackOnLtiPostMessage(subject, placement, callback)
        removeLtiPostMessageCallback(subject, placement)

        const event = postMessageEvent({subject})
        await ltiMessageHandler(event)
        expect(callback).not.toHaveBeenCalled()
      })

      it('calls callback when added with hook', async () => {
        const callback = jest.fn()

        onLtiClosePostMessage(placement, callback)

        const event = postMessageEvent({subject})
        await ltiMessageHandler(event)
        expect(callback).toHaveBeenCalled()
      })

      it('does not call callback when hook is cleaned up', async () => {
        const callback = jest.fn()

        const cleanup = onLtiClosePostMessage(placement, callback)
        cleanup()

        const event = postMessageEvent({subject})
        await ltiMessageHandler(event)
        expect(callback).not.toHaveBeenCalled()
      })

      it('calls all callbacks for subject', async () => {
        const callback1 = jest.fn()
        const callback2 = jest.fn()

        callbackOnLtiPostMessage(subject, placement, callback1)
        callbackOnLtiPostMessage(subject, 'placement2', callback2)

        const event = postMessageEvent({subject})
        await ltiMessageHandler(event)
        expect(callback1).toHaveBeenCalled()
        expect(callback2).toHaveBeenCalled()
      })

      it('only calls callbacks for subject', async () => {
        const callback1 = jest.fn()
        const callback2 = jest.fn()

        callbackOnLtiPostMessage(subject, placement, callback1)
        callbackOnLtiPostMessage('lti.frameResize', placement, callback2)

        const event = postMessageEvent({subject})
        await ltiMessageHandler(event)
        expect(callback1).toHaveBeenCalled()
        expect(callback2).not.toHaveBeenCalled()
      })

      it('replaces callbacks when added twice', async () => {
        const callback1 = jest.fn()
        const callback2 = jest.fn()

        callbackOnLtiPostMessage(subject, placement, callback1)
        callbackOnLtiPostMessage(subject, placement, callback2)

        const event = postMessageEvent({subject})
        await ltiMessageHandler(event)
        expect(callback1).not.toHaveBeenCalled()
        expect(callback2).toHaveBeenCalled()
      })
    })
  })

  describe('when subject requires authorized scopes', () => {
    const subject = 'lti.getPageContent'
    const subject_response = 'lti.getPageContent.response'
    const error_code = 'unauthorized'
    const origin = 'http://lti-tool.example.com'

    describe('when tool has no scopes', () => {
      it('returns unauthorized error', async () => {
        const event = postMessageEvent({subject, origin})
        ENV.LTI_TOOL_SCOPES = {origin: []}

        await ltiMessageHandler(event)
        expect(event.source.postMessage).toHaveBeenCalledWith(
          expect.objectContaining({
            error: {
              code: error_code,
            },
          }),
          undefined,
        )
      })
    })

    describe('when tool has only other scopes', () => {
      it('returns unauthorized error', async () => {
        const event = postMessageEvent({subject, origin})
        ENV.LTI_TOOL_SCOPES = {origin: ['https://canvas.instructure.com/lti/something/else']}

        await ltiMessageHandler(event)
        expect(event.source.postMessage).toHaveBeenCalledWith(
          expect.objectContaining({
            error: {
              code: error_code,
            },
          }),
          undefined,
        )
      })
    })

    describe('when tool has a required scope', () => {
      it('processes message', async () => {
        const event = postMessageEvent({subject, origin})
        ENV.LTI_TOOL_SCOPES = {
          origin: ['https://canvas.instructure.com/lti/page_content/show'],
        }

        await ltiMessageHandler(event)
        expect(event.source.postMessage).toHaveBeenCalledWith(
          expect.objectContaining({
            subject: subject_response,
          }),
          undefined,
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

  describe('page functionality', () => {
    let ltiToolWrapperFixture

    beforeEach(() => {
      ltiToolWrapperFixture = document.createElement('div')
      ltiToolWrapperFixture.id = 'fixtures'
      document.body.appendChild(ltiToolWrapperFixture)
    })

    afterEach(() => {
      ltiToolWrapperFixture.remove()
    })

    it('returns the height and width of the page along with the iframe offset', async () => {
      ltiToolWrapperFixture.innerHTML = `
        <div>
          <h1 class="page-title">LTI resize test</h1>
          <p><iframe style="width: 100%; height: 100px;" src="https://canvas.example.com/courses/4/external_tools/retrieve?display=borderless" width="100%" height="100px" allowfullscreen="allowfullscreen" webkitallowfullscreen="webkitallowfullscreen" mozallowfullscreen="mozallowfullscreen"></iframe></p>
        </div>
      `
      const postMessageMock = jest.fn()
      await ltiMessageHandler(
        postMessageEvent({subject: 'lti.fetchWindowSize'}, 'origin', {
          postMessage: postMessageMock,
        }),
      )
      expect(postMessageMock).toHaveBeenCalled()
    })

    it('hides the module navigation', async () => {
      ltiToolWrapperFixture.innerHTML = `
        <div>
          <div id="module-footer" class="module-sequence-footer">Next</div>
        </div>
      `
      const moduleFooter = document.getElementById('module-footer')

      expect(moduleFooter).toBeVisible()
      await ltiMessageHandler(
        postMessageEvent({
          subject: 'lti.showModuleNavigation',
          show: false,
        }),
      )
      expect(moduleFooter).not.toBeVisible()
    })

    it('sets the unload message', async () => {
      const addEventListenerSpy = jest.spyOn(window, 'addEventListener')
      await ltiMessageHandler(
        postMessageEvent({
          subject: 'lti.setUnloadMessage',
          message: 'unload message',
        }),
      )
      expect(addEventListenerSpy).toHaveBeenCalled()
      addEventListenerSpy.mockRestore()
    })

    it('sets the unload message event if no "message" is given', async () => {
      const addEventListenerSpy = jest.spyOn(window, 'addEventListener')
      await ltiMessageHandler(
        postMessageEvent({
          subject: 'lti.setUnloadMessage',
        }),
      )
      expect(addEventListenerSpy).toHaveBeenCalled()
      const handler = addEventListenerSpy.mock.calls[0][1]
      const event = {}
      handler(event)
      expect(event.returnValue).toBeTruthy()
      addEventListenerSpy.mockRestore()
    })

    it('hides the right side wrapper', async () => {
      ltiToolWrapperFixture.innerHTML = `
        <div>
          <div id="right-side-wrapper">someWrapping</div>
        </div>
      `
      const moduleWrapper = document.getElementById('right-side-wrapper')

      expect(moduleWrapper).toBeVisible()
      await ltiMessageHandler(
        postMessageEvent({
          subject: 'lti.hideRightSideWrapper',
        }),
      )
      expect(moduleWrapper).not.toBeVisible()
    })
  })
})

describe('ltiState', () => {
  it('is empty initially', () => {
    expect(ltiState).toEqual({})
  })
})
