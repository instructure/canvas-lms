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
import sinon from 'sinon'
import { ltiMessageHandler } from 'lti/messages'

const intialHeight = 100
const finalHeight = 800

let clock;
let ltiToolWrapperFixture = $('#fixtures')

const resizeMessage = {
  subject: 'lti.frameResize',
  height: finalHeight
}

const scrollMessage = {
  subject: 'lti.scrollToTop'
}

const removeUnloadMessage = {
  subject: 'lti.removeUnloadMessage',
}

function showMessage(show = true) {
  return {
    subject: 'lti.showModuleNavigation',
    show: show
  }
}

function alertMessage(message = 'Alert message') {
  return  {
    subject: 'lti.screenReaderAlert',
    body: message
  }
}

function unloadMessage(message = 'unload message') {
  return {
    subject: 'lti.setUnloadMessage',
    message: message
  }
}

function postMessageEvent(data, source) {
  return {
    data: JSON.stringify(data),
    source: source
  }
}

QUnit.module('Messages', function (suiteHooks) {
  suiteHooks.beforeEach(function () {
    clock = sinon.useFakeTimers();
  });

  suiteHooks.afterEach(function () {
    clock.restore();
    ltiToolWrapperFixture.empty()
  });

  test('finds and resizes the tool content wrapper', () => {
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

    equal(toolContentWrapper.height(), 100)
    ltiMessageHandler(postMessageEvent(resizeMessage));
    equal(toolContentWrapper.height(), finalHeight)
  })

  test('finds and resizes an iframe in embedded content', () => {
    ltiToolWrapperFixture.append(`
      <div>
        <h1 class="page-title">LTI resize test</h1>
        <p><iframe style="width: 100%; height: ${intialHeight}px;" src="https://canvas.example.com/courses/4/external_tools/retrieve?display=borderless" width="100%" height="${intialHeight}px" allowfullscreen="allowfullscreen" webkitallowfullscreen="webkitallowfullscreen" mozallowfullscreen="mozallowfullscreen"></iframe></p>
      </div>
    `)
    const iframe = $('iframe')

    equal(iframe.height(), 100)
    ltiMessageHandler(postMessageEvent(resizeMessage, iframe[0].contentWindow));
    equal(iframe.height(), finalHeight)
  })

  test('hides the module navigation', () => {
    ltiToolWrapperFixture.append(`
      <div>
        <div id="module-footer" class="module-sequence-footer">Next</div>
      </div>
    `)
    const moduleFooter = $('#module-footer')

    ok(moduleFooter.is(':visible'))
    ltiMessageHandler(postMessageEvent(showMessage(false)));
    notOk(moduleFooter.is(':visible'))
  })

  test('sets the unload message', () => {
    sinon.spy(window, 'addEventListener')
    notOk(window.addEventListener.calledOnce)
    ltiMessageHandler(postMessageEvent(unloadMessage()))
    ok(window.addEventListener.calledOnce)
  })

  test('remove the unload message', () => {
    ltiMessageHandler(postMessageEvent(unloadMessage()))
    sinon.spy(window, 'removeEventListener')
    notOk(window.removeEventListener.calledOnce)
    ltiMessageHandler(postMessageEvent(removeUnloadMessage))
    ok(window.removeEventListener.calledOnce)
  })

  test('triggers a screen reader alert', () => {
    sinon.spy($, 'screenReaderFlashMessageExclusive')
    ltiMessageHandler(postMessageEvent(alertMessage()));
    ok($.screenReaderFlashMessageExclusive.calledOnce)
  })

})
