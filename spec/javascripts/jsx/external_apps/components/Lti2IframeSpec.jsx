/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'

import fakeENV from 'helpers/fakeENV'
import Lti2Iframe from 'ui/features/external_apps/react/components/Lti2Iframe'

QUnit.module('ExternalApps Lti2Iframe', suiteHooks => {
  let $container
  let props
  const originalPostMessageOrigin = ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN

  suiteHooks.beforeEach(() => {
    fakeENV.setup()
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = ['media', 'midi']
    ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = window.origin

    $container = document.body.appendChild(document.createElement('div'))

    props = {
      handleInstall() {},
      registrationUrl: 'http://localhost/register',
      reregistration: false,
      toolName: 'The best LTI tool ever',
    }
  })

  suiteHooks.afterEach(() => {
    ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = originalPostMessageOrigin

    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
    fakeENV.teardown()
  })

  function renderComponent() {
    ReactDOM.render(<Lti2Iframe {...props} />, $container)
  }

  async function postMessage(message) {
    await new Promise(resolve => {
      const listen = () => {
        window.removeEventListener('message', listen, false)
        resolve()
      }

      window.addEventListener('message', listen, false)
      window.postMessage(message, '*')
    })
  }

  test('renders the given children', () => {
    props.children = <div id="test-child" />
    renderComponent()
    strictEqual($container.querySelectorAll('#test-child').length, 1)
  })

  QUnit.module('iframe', () => {
    function getIframe() {
      return $container.querySelector('iframe')
    }

    test('uses the registration url as src when doing reregistration', () => {
      props.reregistration = true
      renderComponent()
      equal(getIframe().getAttribute('src'), 'http://localhost/register')
    })

    test('uses "about:blank" as src when not doing reregistration', () => {
      props.reregistration = false
      renderComponent()
      equal(getIframe().getAttribute('src'), 'about:blank')
    })

    test('allows the items given in the ENV', () => {
      renderComponent()
      equal(getIframe().getAttribute('allow'), 'media; midi')
    })

    test('sets the "data-lti-launch" attribute', () => {
      renderComponent()
      equal(getIframe().getAttribute('data-lti-launch'), 'true')
    })

    test('sets the iframe title', () => {
      renderComponent()
      equal(getIframe().getAttribute('title'), 'The best LTI tool ever')
    })
  })

  QUnit.module('"handleInstall" prop', hooks => {
    hooks.beforeEach(() => {
      props.handleInstall = sinon.spy()
      renderComponent()
    })

    QUnit.module('when a "message" event for registration is triggered on the window', () => {
      test('is called', async () => {
        const message = {subject: 'lti.lti2Registration'}
        await postMessage(JSON.stringify(message))
        strictEqual(props.handleInstall.callCount, 1)
      })

      test('is called with the parsed message', async () => {
        const message = {subject: 'lti.lti2Registration'}
        await postMessage(JSON.stringify(message))
        const [messageReceived] = props.handleInstall.lastCall.args
        deepEqual(messageReceived, message)
      })

      test('is called with the message event', async () => {
        const message = {subject: 'lti.lti2Registration'}
        await postMessage(JSON.stringify(message))
        const [, event] = props.handleInstall.lastCall.args
        equal(event.constructor, MessageEvent)
      })

      QUnit.module('when the message origin != DEEP_LINKING_POST_MESSAGE_ORIGIN', () => {
        test('is not called', async () => {
          ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = 'https://someothersite.example.com'
          // ^ is set back in afterEach hook

          const message = {subject: 'lti.lti2Registration'}
          await postMessage(JSON.stringify(message))
          strictEqual(props.handleInstall.callCount, 0)
        })
      })
    })

    test('skips parsing when the message is already an object', async () => {
      await postMessage({subject: 'lti.lti2Registration'})
      strictEqual(props.handleInstall.callCount, 1)
    })

    test('is not called when a "message" event not for registration is triggered', async () => {
      const message = {subject: 'not lti2Registration'}
      await postMessage(JSON.stringify(message))
      strictEqual(props.handleInstall.callCount, 0)
    })

    test('is not called when a "message" event does not have parsable data', async () => {
      await postMessage('not a JSON string')
      strictEqual(props.handleInstall.callCount, 0)
    })
  })

  test('removes the "message" event listener when unmounting', async () => {
    props.handleInstall = sinon.spy()
    renderComponent()
    ReactDOM.unmountComponentAtNode($container)
    const message = {subject: 'lti.lti2Registration'}
    await postMessage(JSON.stringify(message))
    strictEqual(props.handleInstall.callCount, 0)
  })
})
