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

QUnit.module('Messages', function (suiteHooks) {
  suiteHooks.beforeEach(function () {
    clock = sinon.useFakeTimers();
  });

  suiteHooks.afterEach(function () {
    clock.restore();
  });

  test('finds and resizes the tool content wrapper', () => {
    const ltiToolWrapperFixture = $('#fixtures')
    ltiToolWrapperFixture.append(`
      <div id="content-wrapper" class="ic-Layout-contentWrapper">
        <div id="content" class="ic-Layout-contentMain" role="main">
          <div class="tool_content_wrapper" data-tool-wrapper-id="b58b20b7-c097-43bd-9f6c-c08adbac0ea3" style="height: ${intialHeight}px;">
            <iframe src="about:blank" name="tool_content" id="tool_content" class="tool_launch" allowfullscreen="allowfullscreen" webkitallowfullscreen="true" mozallowfullscreen="true" tabindex="0" title="Tool Content" style="height:100%;width:100%;" allow="geolocation *; microphone *; camera *; midi *; encrypted-media *"></iframe>
          </div>
        </div>
      </div>
    `)
    const message = {
      subject: 'lti.frameResize',
      height: finalHeight
    }

    const e = { data: JSON.stringify(message) };
    const el = $('#content-wrapper')
    const toolContentWrapper = el.find('.tool_content_wrapper')
    ok(toolContentWrapper.height() === 100)
    ltiMessageHandler(e);
    ok(toolContentWrapper.height() === finalHeight)
    ltiToolWrapperFixture.empty()
  })

  test('finds and resizes an iframe in embedded content', () => {
    const ltiToolWrapperFixture = $('#fixtures')
    ltiToolWrapperFixture.append(`
      <div>
        <h1 class="page-title">LTI resize test</h1>
        <p><iframe style="width: 100%; height: ${intialHeight}px;" src="https://canvas.example.com/courses/4/external_tools/retrieve?display=borderless" width="100%" height="${intialHeight}px" allowfullscreen="allowfullscreen" webkitallowfullscreen="webkitallowfullscreen" mozallowfullscreen="mozallowfullscreen"></iframe></p>
      </div>
    `)
    const message = {
      subject: 'lti.frameResize',
      height: finalHeight
    }
    const iframe = $('iframe')
    const e = {
      data: JSON.stringify(message),
      source: iframe[0].contentWindow
    };

    ok(iframe.height() === 100)
    ltiMessageHandler(e);
    ok(iframe.height() === finalHeight)
    ltiToolWrapperFixture.empty()
  })

  test('hides the module navigation', () => {
    const ltiToolWrapperFixture = $('#fixtures')
    ltiToolWrapperFixture.append(`
      <div>
        <div id="module-footer" class="module-sequence-footer">Next</div>
      </div>
    `)
    const message = {
      subject: 'lti.showModuleNavigation',
      show: false
    }
    const moduleFooter = $('#module-footer')
    const e = {
      data: JSON.stringify(message),
    };

    ok(moduleFooter.is(':visible') === true)
    ltiMessageHandler(e);
    ok(moduleFooter.is(':visible') === false)
    ltiToolWrapperFixture.empty()
  })

  test('scrolls to the top of the content wrapper', () => {
    const ltiToolWrapperFixture = $('#fixtures')
    ltiToolWrapperFixture.append(`
    <div style="height:333px;">
    </div>
    <div id="content-wrapper" class="ic-Layout-contentWrapper">
      <div id="content" class="ic-Layout-contentMain" role="main">
        <div class="tool_content_wrapper" data-tool-wrapper-id="b58b20b7-c097-43bd-9f6c-c08adbac0ea3" style="height: ${intialHeight}px;">
          <iframe src="about:blank" name="tool_content" id="tool_content" class="tool_launch" allowfullscreen="allowfullscreen" webkitallowfullscreen="true" mozallowfullscreen="true" tabindex="0" title="Tool Content" style="height:4000px;width:100%;" allow="geolocation *; microphone *; camera *; midi *; encrypted-media *"></iframe>
        </div>
      </div>
    </div>
    <div style="height:444px;">
    </div>
    `)
    const message = {
      subject: 'lti.scrollToTop',
    }
    const wrapper = $('.tool_content_wrapper')
    const e = {
      data: JSON.stringify(message),
    };

    const html = $('html,body')
    const scrolledTo = 1
    html.scrollTop(scrolledTo)

    ok(html.scrollTop() === scrolledTo)
    ltiMessageHandler(e);
    clock.tick(1000)
    ok(html.scrollTop() === wrapper.offset().top)
    ltiToolWrapperFixture.empty()
  })
})
