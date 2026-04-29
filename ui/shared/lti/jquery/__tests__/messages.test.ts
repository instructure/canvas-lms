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
} from '../messages'

vi.mock('@canvas/util/globalUtils', () => ({
  assignLocation: vi.fn(),
}))

const requestFullWindowLaunchMessage = {
  subject: 'requestFullWindowLaunch',
  data: 'http://localhost/test',
}

const reactDevToolsBridge = {
  data: 'http://localhost/test',
  source: 'react-devtools-bridge',
}

let source: Window
let iframe: HTMLIFrameElement
let iframeThunk: () => HTMLIFrameElement

beforeEach(() => {
  source = {postMessage: vi.fn()} as any as Window
  iframe = {contentWindow: source} as any as HTMLIFrameElement
  iframeThunk = () => iframe
})

afterEach(() => vi.restoreAllMocks())

function postMessageEvent(data: unknown, origin?: string): MessageEvent {
  return {
    data,
    origin,
    source,
  } as unknown as MessageEvent
}

const expectMessage = async (data: unknown, wasProcessed: boolean) => {
  const wasCalled = await ltiMessageHandler(postMessageEvent(data))
  expect(wasCalled).toBe(wasProcessed)
}

describe('ltiMessageHander', () => {
  it('does not handle unparseable messages from window.postMessage', async () => {
    await expectMessage('abcdef', false)
  })

  it('handles parseable messages from window.postMessage', async () => {
    const flashMessage = vi.spyOn($, 'screenReaderFlashMessageExclusive')
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
        expect(event.source?.postMessage).toHaveBeenCalledWith(
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
  })

  describe('with callbacks', () => {
    const subject = 'lti.close'
    let toCleanup: (() => void)[] = []

    // Runs callbackOnLtiPostMessage but ensures we cleanup after test is done
    function runCallbackOnLtiPostMessage(...args: Parameters<typeof callbackOnLtiPostMessage>) {
      const cleanup = callbackOnLtiPostMessage(...args)
      toCleanup.push(cleanup)
      return cleanup
    }

    // Runs onLtiClosePostMessage but ensures we cleanup after test is done
    function runOnLtiClosePostMessage(...args: Parameters<typeof onLtiClosePostMessage>) {
      const cleanup = onLtiClosePostMessage(...args)
      toCleanup.push(cleanup)
      return cleanup
    }

    afterEach(() => {
      for (const cleanup of toCleanup) {
        cleanup?.()
      }
      toCleanup = []
    })

    it('calls callback when added', async () => {
      const callback = vi.fn()

      runCallbackOnLtiPostMessage(subject, iframeThunk, callback)

      const event = postMessageEvent({subject})
      await ltiMessageHandler(event)
      expect(callback).toHaveBeenCalled()
    })

    it('does not call callback once removed', async () => {
      const callback = vi.fn()

      const remove = runCallbackOnLtiPostMessage(subject, iframeThunk, callback)
      remove()

      const event = postMessageEvent({subject})
      await ltiMessageHandler(event)
      expect(callback).not.toHaveBeenCalled()
    })

    it('calls callback when added with hook', async () => {
      const callback = vi.fn()

      runOnLtiClosePostMessage(callback, iframeThunk)

      const event = postMessageEvent({subject})
      await ltiMessageHandler(event)
      expect(callback).toHaveBeenCalled()
    })

    it('does not call callback when hook is cleaned up', async () => {
      const callback = vi.fn()

      const cleanup = runOnLtiClosePostMessage(iframeThunk, callback)
      cleanup()

      const event = postMessageEvent({subject})
      await ltiMessageHandler(event)
      expect(callback).not.toHaveBeenCalled()
    })

    it('calls all callbacks for subject', async () => {
      const callback1 = vi.fn()
      const callback2 = vi.fn()

      runCallbackOnLtiPostMessage(subject, iframeThunk, callback1)
      runCallbackOnLtiPostMessage(subject, iframeThunk, callback2)

      const event = postMessageEvent({subject})
      await ltiMessageHandler(event)
      expect(callback1).toHaveBeenCalled()
      expect(callback2).toHaveBeenCalled()
    })

    it('keeps callbacks for separate invocations separate', async () => {
      const callback1 = vi.fn()
      const callback2 = vi.fn()

      const remove1 = runCallbackOnLtiPostMessage(subject, iframeThunk, callback1)
      runCallbackOnLtiPostMessage(subject, iframeThunk, callback2)
      remove1?.()

      const event = postMessageEvent({subject})
      await ltiMessageHandler(event)
      expect(callback1).not.toHaveBeenCalled()
      expect(callback2).toHaveBeenCalled()
    })

    it('only calls callbacks for subject', async () => {
      const callback1 = vi.fn()
      const callback2 = vi.fn()

      runCallbackOnLtiPostMessage(subject, iframeThunk, callback1)
      runCallbackOnLtiPostMessage('lti.frameResize', iframeThunk, callback2)

      const event = postMessageEvent({subject})
      await ltiMessageHandler(event)
      expect(callback1).toHaveBeenCalled()
      expect(callback2).not.toHaveBeenCalled()
    })

    it('does not call callbacks if the iframe does not match', async () => {
      const callback = vi.fn()

      runCallbackOnLtiPostMessage(subject, () => document.createElement('iframe'), callback)

      const event = postMessageEvent({subject})
      await ltiMessageHandler(event)
      expect(callback).not.toHaveBeenCalled()
    })

    describe('forwarded message handling', () => {
      let iframe: HTMLIFrameElement

      beforeEach(() => {
        iframe = {contentWindow: {postMessage: vi.fn()}} as any as HTMLIFrameElement

        vi.spyOn(window.top!, 'frames', 'get').mockReturnValue({
          post_message_forwarding: source,
          0: source,
          1: iframe.contentWindow,
          2: {},
          length: 3,
        } as any)
      })

      it('calls callbacks if the event source is the forwarder and the iframe matches the indexInTopFrame', async () => {
        const callback = vi.fn()
        runCallbackOnLtiPostMessage(subject, () => iframe, callback)

        const event = postMessageEvent({subject, sourceToolInfo: {indexInTopFrames: 1}})
        await ltiMessageHandler(event)
        expect(callback).toHaveBeenCalled()
      })

      it('does not call callbacks if the event source is the forwarder but the iframe does not match the indexInTopFrame', async () => {
        const callback = vi.fn()
        runCallbackOnLtiPostMessage(subject, () => iframe, callback)

        const event = postMessageEvent({subject, sourceToolInfo: {indexInTopFrames: 0}})
        await ltiMessageHandler(event)
        expect(callback).not.toHaveBeenCalled()
      })

      it('does not call callbacks if the iframe matches the indexInTopFrame but the event source is not the forwarder (e.g. spoofed)', async () => {
        const callback = vi.fn()
        runCallbackOnLtiPostMessage(subject, () => iframe, callback)

        window.top!.frames['post_message_forwarding' as any] = {
          postMessage: vi.fn(),
        } as any as Window
        const event = postMessageEvent({subject, sourceToolInfo: {indexInTopFrames: 1}})
        await ltiMessageHandler(event)
        expect(callback).not.toHaveBeenCalled()
      })
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
      expect(event.source?.postMessage).toHaveBeenCalledWith(
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
      expect(event.source?.postMessage).toHaveBeenCalledWith(
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
      expect(event.source?.postMessage).toHaveBeenCalledWith(
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
      expect(event.source?.postMessage).toHaveBeenCalled()
    })
  })

  describe('when message handler fails', () => {
    beforeEach(() => {
      // mock console.error to avoid vi complaints
      vi.spyOn(console, 'error').mockImplementation(() => {})
    })

    it('should send response message', async () => {
      // this message handler fails when run without a DOM
      const event = postMessageEvent({subject: 'lti.scrollToTop'})
      await ltiMessageHandler(event)
      expect(event.source?.postMessage).toHaveBeenCalled()
    })
  })

  describe('when subject is not supported', () => {
    it('should send response message', async () => {
      const event = postMessageEvent({subject: 'notSupported'})
      await ltiMessageHandler(event)
      expect(event.source?.postMessage).toHaveBeenCalled()
    })
  })

  describe('when message handler sends a response message', () => {
    it('should send response message', async () => {
      const event = postMessageEvent({subject: 'lti.fetchWindowSize'})
      await ltiMessageHandler(event)
      expect(event.source?.postMessage).toHaveBeenCalled()
    })

    it('should not respond to response messages', async () => {
      const event = postMessageEvent({subject: 'notSupported.response'})
      await ltiMessageHandler(event)
      expect(event.source?.postMessage).not.toHaveBeenCalled()
    })
  })
})

describe('page functionality', () => {
  let ltiToolWrapperFixture: HTMLDivElement | undefined

  beforeEach(() => {
    ltiToolWrapperFixture = document.createElement('div')
    ltiToolWrapperFixture.id = 'fixtures'
    document.body.appendChild(ltiToolWrapperFixture)
  })

  afterEach(() => {
    ltiToolWrapperFixture?.remove()
  })

  it('returns the height and width of the page along with the iframe offset', async () => {
    ltiToolWrapperFixture!.innerHTML = `
        <div>
          <h1 class="page-title">LTI resize test</h1>
          <p><iframe style="width: 100%; height: 100px;" src="https://canvas.example.com/courses/4/external_tools/retrieve?display=borderless" width="100%" height="100px" allowfullscreen="allowfullscreen" webkitallowfullscreen="webkitallowfullscreen" mozallowfullscreen="mozallowfullscreen"></iframe></p>
        </div>
      `
    await ltiMessageHandler(postMessageEvent({subject: 'lti.fetchWindowSize'}, 'origin'))
    expect(source.postMessage).toHaveBeenCalled()
  })

  it('hides the module navigation', async () => {
    ltiToolWrapperFixture!.innerHTML = `
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
    const addEventListenerSpy = vi.spyOn(window, 'addEventListener')
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
    const addEventListenerSpy = vi.spyOn(window, 'addEventListener')
    await ltiMessageHandler(
      postMessageEvent({
        subject: 'lti.setUnloadMessage',
      }),
    )
    expect(addEventListenerSpy).toHaveBeenCalled()
    const handler = addEventListenerSpy.mock.calls[0][1] as (event: any) => void
    const event = {returnValue: undefined}
    handler(event)
    expect(event.returnValue).toBeTruthy()
    addEventListenerSpy.mockRestore()
  })

  it('hides the right side wrapper', async () => {
    ltiToolWrapperFixture!.innerHTML = `
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

describe('ltiState', () => {
  it('is empty initially', () => {
    expect(ltiState).toEqual({})
  })
})
