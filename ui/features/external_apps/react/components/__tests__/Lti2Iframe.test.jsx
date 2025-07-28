/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, waitFor} from '@testing-library/react'
import fakeENV from '@canvas/test-utils/fakeENV'
import Lti2Iframe from '../Lti2Iframe'

describe('ExternalApps Lti2Iframe', () => {
  let props
  const originalPostMessageOrigin = ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN

  beforeEach(() => {
    fakeENV.setup()
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = ['media', 'midi']
    ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = window.origin

    props = {
      handleInstall: jest.fn(),
      registrationUrl: 'http://localhost/register',
      reregistration: false,
      toolName: 'The best LTI tool ever',
    }
  })

  afterEach(() => {
    ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = originalPostMessageOrigin
    fakeENV.teardown()
  })

  async function postMessage(message) {
    const event = new MessageEvent('message', {
      data: message,
      origin: window.origin,
    })
    window.dispatchEvent(event)
    // Wait for the next tick to ensure the message event is processed
    await new Promise(resolve => setTimeout(resolve, 0))
  }

  it('renders the given children', () => {
    const {container} = render(
      <Lti2Iframe {...props}>
        <div id="test-child" />
      </Lti2Iframe>,
    )
    expect(container.querySelector('#test-child')).toBeInTheDocument()
  })

  describe('iframe', () => {
    it('uses the registration url as src when doing reregistration', () => {
      props.reregistration = true
      const {container} = render(<Lti2Iframe {...props} />)
      const iframe = container.querySelector('iframe')
      expect(iframe.getAttribute('src')).toBe('http://localhost/register')
    })

    it('uses "about:blank" as src when not doing reregistration', () => {
      props.reregistration = false
      const {container} = render(<Lti2Iframe {...props} />)
      const iframe = container.querySelector('iframe')
      expect(iframe.getAttribute('src')).toBe('about:blank')
    })

    it('allows the items given in the ENV', () => {
      const {container} = render(<Lti2Iframe {...props} />)
      const iframe = container.querySelector('iframe')
      expect(iframe.getAttribute('allow')).toBe('media; midi')
    })

    it('sets the "data-lti-launch" attribute', () => {
      const {container} = render(<Lti2Iframe {...props} />)
      const iframe = container.querySelector('iframe')
      expect(iframe.getAttribute('data-lti-launch')).toBe('true')
    })

    it('sets the iframe title', () => {
      const {container} = render(<Lti2Iframe {...props} />)
      const iframe = container.querySelector('iframe')
      expect(iframe.getAttribute('title')).toBe('The best LTI tool ever')
    })
  })

  describe('handleInstall prop', () => {
    beforeEach(() => {
      props.handleInstall = jest.fn()
      render(<Lti2Iframe {...props} />)
    })

    describe('when a "message" event for registration is triggered on the window', () => {
      it('is called', async () => {
        const message = {subject: 'lti.lti2Registration'}
        await postMessage(JSON.stringify(message))
        await waitFor(() => {
          expect(props.handleInstall).toHaveBeenCalledTimes(1)
        })
      })

      it('is called with the parsed message', async () => {
        const message = {subject: 'lti.lti2Registration'}
        await postMessage(JSON.stringify(message))
        await waitFor(() => {
          expect(props.handleInstall).toHaveBeenCalledWith(message, expect.any(MessageEvent))
        })
      })

      describe('when the message origin != DEEP_LINKING_POST_MESSAGE_ORIGIN', () => {
        it('is not called', async () => {
          ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = 'https://someothersite.example.com'

          const message = {subject: 'lti.lti2Registration'}
          await postMessage(JSON.stringify(message))
          await waitFor(() => {
            expect(props.handleInstall).not.toHaveBeenCalled()
          })
        })
      })
    })

    it('skips parsing when the message is already an object', async () => {
      await postMessage({subject: 'lti.lti2Registration'})
      await waitFor(() => {
        expect(props.handleInstall).toHaveBeenCalledTimes(1)
      })
    })

    it('is not called when a "message" event not for registration is triggered', async () => {
      const message = {subject: 'not lti2Registration'}
      await postMessage(JSON.stringify(message))
      await waitFor(() => {
        expect(props.handleInstall).not.toHaveBeenCalled()
      })
    })

    it('is not called when a "message" event does not have parsable data', async () => {
      await postMessage('not a JSON string')
      await waitFor(() => {
        expect(props.handleInstall).not.toHaveBeenCalled()
      })
    })
  })

  it('removes the "message" event listener when unmounting', async () => {
    props.handleInstall = jest.fn()
    const {unmount} = render(<Lti2Iframe {...props} />)
    unmount()
    const message = {subject: 'lti.lti2Registration'}
    await postMessage(JSON.stringify(message))
    await waitFor(() => {
      expect(props.handleInstall).not.toHaveBeenCalled()
    })
  })
})
