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

import $ from 'jquery'
import ToolLaunchResizer from '../tool_launch_resizer'

describe('ToolLaunchResizer', () => {
  let container

  beforeEach(() => {
    container = document.createElement('div')
    container.innerHTML = `
      <div class='tool_content_wrapper' id="first-wrapper" data-tool-wrapper-id="1234" data-testid="first-wrapper">
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
        <iframe src='about:blank' name='tool_content' id='tool_content' class='tool_launch' allowfullscreen='allowfullscreen' webkitallowfullscreen='true' mozallowfullscreen='true' tabindex='0' title='Tool Content' style='height:100%;width:100%;' data-testid="first-iframe"></iframe>
      </div>

      <div class='tool_content_wrapper' id="second-wrapper" data-tool-wrapper-id="5678" data-testid="second-wrapper">
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
        <iframe src='about:blank' name='tool_content' id='tool_content' class='tool_launch' allowfullscreen='allowfullscreen' webkitallowfullscreen='true' mozallowfullscreen='true' tabindex='0' title='Tool Content' style='height:100%;width:100%;' data-testid="second-iframe"></iframe>
      </div>
    `
    document.body.appendChild(container)
  })

  afterEach(() => {
    container.remove()
  })

  it('selects the wrapper with matching id', () => {
    const launchResizer = new ToolLaunchResizer()

    const firstWrapper = launchResizer.tool_content_wrapper('1234')
    expect(firstWrapper[0].id).toBe('first-wrapper')

    const secondWrapper = launchResizer.tool_content_wrapper('5678')
    expect(secondWrapper[0].id).toBe('second-wrapper')
  })

  it('returns empty when no wrapper id is provided with multiple tools', () => {
    const launchResizer = new ToolLaunchResizer()
    const wrapper = launchResizer.tool_content_wrapper()
    expect(wrapper).toHaveLength(0)
  })

  it('enforces minimum height when resizing', () => {
    const minHeight = 100
    const launchResizer = new ToolLaunchResizer(minHeight)
    const wrapper = $('#second-wrapper')

    launchResizer.resize_tool_content_wrapper(50, wrapper)
    expect(wrapper.find('iframe').height()).toBe(minHeight)
  })

  it('resizes wrapper to specified height when above minimum', () => {
    const minHeight = 100
    const targetHeight = 500
    const launchResizer = new ToolLaunchResizer(minHeight)
    const wrapper = $('#second-wrapper')

    launchResizer.resize_tool_content_wrapper(targetHeight, wrapper)
    expect(wrapper.find('iframe').height()).toBe(targetHeight)
  })

  it('resizes first wrapper when only one exists', () => {
    const targetHeight = 500
    const launchResizer = new ToolLaunchResizer()

    // Remove second wrapper class to simulate single wrapper scenario
    document.querySelector('#second-wrapper').className = ''

    launchResizer.resize_tool_content_wrapper(targetHeight)
    expect($('#first-wrapper iframe').height()).toBe(targetHeight)
  })
})
