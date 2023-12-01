/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import ToolLaunchResizer from '@canvas/lti/jquery/tool_launch_resizer'

QUnit.module('ToolLaunchResizer', {
  setup() {
    this.fixtures = document.getElementById('fixtures')
    this.fixtures.innerHTML = `\
<div class='tool_content_wrapper' id="first-wrapper" data-tool-wrapper-id="1234" >
  <form action='http://my-lti.docker/course-navigation' class='hide' method='POST' target='tool_content' id='tool_form_1' data-tool-launch-type=' data-tool-id='my-lti.docker' data-tool-path='/course-navigation' data-message-type='tool_launch' style='display: none;'>
      <div style='margin-bottom: 20px;'>
          <div class='load_tab'>
              This tool needs to be loaded in a new browser window
              <div style='margin: 10px 0;'>
                  <button class='btn' type='submit' data-expired_message='The session for this tool has expired. Please reload the page to access the tool again'>
                      Load My LTI in a new window
                  </button>
              </div>
          </div>
          <div class='tab_loaded' style='display: none;'>
              This tool was successfully loaded in a new browser window. Reload the page to access the tool again.
          </div>
      </div>
  </form>
  <iframe src='about:blank' name='tool_content' id='tool_content' class='tool_launch' allowfullscreen='allowfullscreen' webkitallowfullscreen='true' mozallowfullscreen='true' tabindex='0' title='Tool Content' style='height:100%;width:100%;'></iframe>
</div>

<div class='tool_content_wrapper' id="second-wrapper" data-tool-wrapper-id="5678">
  <form action='http://chat.docker' class='hide' method='POST' target='tool_content' id='tool_form_1' data-tool-launch-type=' data-tool-id='my-lti.docker' data-tool-path='/course-navigation' data-message-type='tool_launch' style='display: none;'>
      <div style='margin-bottom: 20px;'>
          <div class='load_tab'>
              This tool needs to be loaded in a new browser window
              <div style='margin: 10px 0;'>
                  <button class='btn' type='submit' data-expired_message='The session for this tool has expired. Please reload the page to access the tool again'>
                      Load My LTI in a new window
                  </button>
              </div>
          </div>
          <div class='tab_loaded' style='display: none;'>
              This tool was successfully loaded in a new browser window. Reload the page to access the tool again.
          </div>
      </div>
  </form>
  <iframe src='about:blank' name='tool_content' id='tool_content' class='tool_launch' allowfullscreen='allowfullscreen' webkitallowfullscreen='true' mozallowfullscreen='true' tabindex='0' title='Tool Content' style='height:100%;width:100%;'></iframe>
</div>\
`
  },
  teardown() {
    this.fixtures.innerHTML = ''
  },
})

test('selects the last iframe when the wrapper id matches', () => {
  const launchResizer = new ToolLaunchResizer()
  const container = launchResizer.tool_content_wrapper('5678')
  equal(container[0].id, 'second-wrapper')
})

test('selects the first iframe when the wrapper id matches', () => {
  const launchResizer = new ToolLaunchResizer()
  const container = launchResizer.tool_content_wrapper('1234')
  equal(container[0].id, 'first-wrapper')
})

test("Does not default to '.tool_content_wrapper' if more than one tool is present", () => {
  const launchResizer = new ToolLaunchResizer()
  const container = launchResizer.tool_content_wrapper()
  equal(container.length, 0)
})

test('does not allow setting a height smaller than the min tool height', () => {
  const launchResizer = new ToolLaunchResizer(100)
  launchResizer.resize_tool_content_wrapper(50, $('#second-wrapper'))
  equal($('#second-wrapper').height(), 100)
})

test('resizes the specified container', () => {
  const launchResizer = new ToolLaunchResizer(100)
  launchResizer.resize_tool_content_wrapper(500, $('#second-wrapper'))
  equal($('#second-wrapper').height(), 500)
})

test('resizes the first container if no container is specified and only one container exists', () => {
  document.querySelector('#second-wrapper').className = ''
  const launchResizer = new ToolLaunchResizer(100)
  launchResizer.resize_tool_content_wrapper(500)
  equal($('.tool_content_wrapper').height(), 500)
  document.querySelector('#second-wrapper').className = 'tool_content_wrapper'
})

test('does not resize any other container', () => {
  const launchResizer = new ToolLaunchResizer(100)
  launchResizer.resize_tool_content_wrapper(300, $('.tool_content_wrapper'))
  launchResizer.resize_tool_content_wrapper(500, $('#second-wrapper'))
  equal($('.tool_content_wrapper').height(), 300)
})

test('defaults the resize height to 450px if no `#tool_content` is found', () => {
  document.querySelector('#second-wrapper').className = ''
  document.querySelectorAll('#tool_content').forEach(element => {
    element.id = 'another_tool_content'
  })
  const launchResizer = new ToolLaunchResizer()
  launchResizer.resize_tool_content_wrapper()
  equal($('.tool_content_wrapper').height(), 450)
  document.querySelectorAll('#another_tool_content').forEach(element => {
    element.id = 'tool_content'
  })
  document.querySelector('#second-wrapper').className = 'tool_content_wrapper'
})

test('defaults the resize height to 450px if non numeric value passed and no `#tool_content` is found', () => {
  document.querySelector('#second-wrapper').className = ''
  document.querySelectorAll('#tool_content').forEach(element => {
    element.id = 'another_tool_content'
  })
  const launchResizer = new ToolLaunchResizer()
  launchResizer.resize_tool_content_wrapper({a: 1})
  equal($('.tool_content_wrapper').height(), 450)
  document.querySelectorAll('#another_tool_content').forEach(element => {
    element.id = 'tool_content'
  })
  document.querySelector('#second-wrapper').className = 'tool_content_wrapper'
})
