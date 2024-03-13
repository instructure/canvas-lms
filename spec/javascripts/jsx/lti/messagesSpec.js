/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import $ from 'jquery'
import 'jquery-migrate'
import sinon from 'sinon'
import {ltiMessageHandler} from '@canvas/lti/jquery/messages'

const intialHeight = 100
const finalHeight = 800

let clock
const ltiToolWrapperFixture = $('#fixtures')

const resizeMessage = {
  subject: 'lti.frameResize',
  height: finalHeight,
}

const fetchWindowSize = {
  subject: 'lti.fetchWindowSize',
}

const hideRightSideWrapper = {
  subject: 'lti.hideRightSideWrapper',
}

const removeUnloadMessage = {
  subject: 'lti.removeUnloadMessage',
}

function showMessage(show = true) {
  return {
    subject: 'lti.showModuleNavigation',
    show,
  }
}

function alertMessage(message = 'Alert message') {
  return {
    subject: 'lti.screenReaderAlert',
    body: message,
  }
}

function unloadMessage(message = undefined) {
  return {
    subject: 'lti.setUnloadMessage',
    message,
  }
}

function postMessageEvent(data, source = {postMessage: () => {}}) {
  return {
    data: JSON.stringify(data),
    source,
  }
}

QUnit.module('Messages', suiteHooks => {
  suiteHooks.beforeEach(() => {
    clock = sinon.useFakeTimers()
  })

  suiteHooks.afterEach(() => {
    clock.restore()
    ltiToolWrapperFixture.empty()
  })

  test('finds and resizes the tool content wrapper', async () => {
    ltiToolWrapperFixture.append(`
      <div id="content-wrapper" class="ic-Layout-contentWrapper">
        <div id="content" class="ic-Layout-contentMain" role="main">
          <div class="tool_content_wrapper" data-tool-wrapper-id="b58b20b7-c097-43bd-9f6c-c08adbac0ea3" style="height: ${intialHeight}px;">
            <iframe src="about:blank" name="tool_content" id="tool_content" class="tool_launch" allowfullscreen="allowfullscreen" webkitallowfullscreen="true" mozallowfullscreen="true" tabindex="0" title="Tool Content" style="height:100%;width:100%;" allow="geolocation *; microphone *; camera *; midi *; encrypted-media *"></iframe>
          </div>
        </div>
      </div>
    `)
    const el = $('#content-wrapper')
    const toolContentWrapper = el.find('.tool_content_wrapper')
    const iframe = $('iframe')

    equal(toolContentWrapper.height(), 100)
    await ltiMessageHandler(postMessageEvent(resizeMessage, iframe[0].contentWindow))
    equal(toolContentWrapper.height(), finalHeight)
  })

  test('finds and resizes an iframe in embedded content', async () => {
    ltiToolWrapperFixture.append(`
      <div>
        <h1 class="page-title">LTI resize test</h1>
        <p><iframe style="width: 100%; height: ${intialHeight}px;" src="https://canvas.example.com/courses/4/external_tools/retrieve?display=borderless" width="100%" height="${intialHeight}px" allowfullscreen="allowfullscreen" webkitallowfullscreen="webkitallowfullscreen" mozallowfullscreen="mozallowfullscreen"></iframe></p>
      </div>
    `)
    const iframe = $('iframe')

    equal(iframe.height(), 100)
    await ltiMessageHandler(postMessageEvent(resizeMessage, iframe[0].contentWindow))
    equal(iframe.height(), finalHeight)
  })

  test('finds and resizes an iframe in embedded RCE iframes', async () => {
    ltiToolWrapperFixture.append(`
      <div>
        <h1 class="page-title">LTI resize test</h1>
        <div class="tox-tinymce">
          <iframe src="about:blank" />
        </div>
      </div>
    `)
    const iframeDoc = $('iframe')[0].contentWindow.document
    iframeDoc.open()
    iframeDoc.write(`
      <html>
        <body>
          <div>
            <iframe style="width: 100%; height: ${intialHeight}px;" src="https://canvas.example.com/courses/4/external_tools/retrieve?display=borderless" width="100%" height="${intialHeight}px" allowfullscreen="allowfullscreen" webkitallowfullscreen="webkitallowfullscreen" mozallowfullscreen="mozallowfullscreen"></iframe>
          </div>
        </body>
      </html>
    `)
    iframeDoc.close()
    const innerIframe = $('iframe', iframeDoc)

    equal(innerIframe.height(), 100)
    await ltiMessageHandler(postMessageEvent(resizeMessage, innerIframe[0].contentWindow))
    equal(innerIframe.height(), finalHeight)
  })

  test('returns the height and width of the page along with the iframe offset', async () => {
    ltiToolWrapperFixture.append(`
      <div>
        <h1 class="page-title">LTI resize test</h1>
        <p><iframe style="width: 100%; height: ${intialHeight}px;" src="https://canvas.example.com/courses/4/external_tools/retrieve?display=borderless" width="100%" height="${intialHeight}px" allowfullscreen="allowfullscreen" webkitallowfullscreen="webkitallowfullscreen" mozallowfullscreen="mozallowfullscreen"></iframe></p>
      </div>
    `)
    const postMessageStub = sinon.stub()
    notOk(postMessageStub.calledOnce)
    await ltiMessageHandler(postMessageEvent(fetchWindowSize, {postMessage: postMessageStub}))
    ok(postMessageStub.calledOnce)
  })

  test('hides the module navigation', async () => {
    ltiToolWrapperFixture.append(`
      <div>
        <div id="module-footer" class="module-sequence-footer">Next</div>
      </div>
    `)
    const moduleFooter = $('#module-footer')

    ok(moduleFooter.is(':visible'))
    await ltiMessageHandler(postMessageEvent(showMessage(false)))
    notOk(moduleFooter.is(':visible'))
  })

  test('sets the unload message', async () => {
    sinon.spy(window, 'addEventListener')
    notOk(window.addEventListener.calledOnce)
    await ltiMessageHandler(postMessageEvent(unloadMessage('unload message')))
    ok(window.addEventListener.calledOnce)
  })

  test('sets the unload message event if no "message" is given', async () => {
    sinon.spy(window, 'addEventListener')
    notOk(window.addEventListener.calledOnce)
    await ltiMessageHandler(postMessageEvent(unloadMessage()))
    ok(window.addEventListener.calledOnce)
    // handler needs to set the returnValue to a truthy value to work
    const handler = window.addEventListener.getCall(0).args[1]
    const event = {}
    handler(event)
    ok(event.returnValue)
  })

  test('hide the right side wrapper', async () => {
    ltiToolWrapperFixture.append(`
      <div>
        <div id="right-side-wrapper">someWrapping</div>
      </div>
    `)
    const moduleWrapper = $('#right-side-wrapper')

    ok(moduleWrapper.is(':visible'))
    await ltiMessageHandler(postMessageEvent(hideRightSideWrapper))
    notOk(moduleWrapper.is(':visible'))
  })

  test('remove the unload message', async () => {
    await ltiMessageHandler(postMessageEvent(unloadMessage()))
    sinon.spy(window, 'removeEventListener')
    notOk(window.removeEventListener.calledOnce)
    await ltiMessageHandler(postMessageEvent(removeUnloadMessage))
    ok(window.removeEventListener.calledOnce)
  })

  test('triggers a screen reader alert', async () => {
    sinon.spy($, 'screenReaderFlashMessageExclusive')
    await ltiMessageHandler(postMessageEvent(alertMessage()))
    ok($.screenReaderFlashMessageExclusive.calledOnce)
  })

  test('uses iframe title for visible alert', async () => {
    sinon.spy($, 'flashMessageSafe')
    const title = 'Tool Name'
    ltiToolWrapperFixture.append(`
      <iframe data-lti-launch="true" title="${title}" src="https://canvas.example.com/courses/4/external_tools/retrieve?display=borderless"></iframe>
    `)
    await ltiMessageHandler(postMessageEvent({subject: 'lti.showAlert', body: 'Hello world!'}))
    sinon.assert.calledWith($.flashMessageSafe, sinon.match(title))
  })
})
