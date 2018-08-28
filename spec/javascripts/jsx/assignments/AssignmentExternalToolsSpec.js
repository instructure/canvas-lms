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
import React from 'react'
import {mount} from 'enzyme'
import AssignmentExternalTools from 'jsx/assignments/AssignmentExternalTools'


QUnit.module('AssignmentExternalTools', hooks => {
  let toolDefinitions;
  let wrapper;
  function setup () {
    toolDefinitions = [
      {
        definition_type: 'ContextExternalTool',
        definition_id: 8,
        name: 'assignment_edit Text',
        description: 'This is a Sample Tool Provider.',
        domain: 'lti-tool-provider-example.herokuapp.com',
        placements: {
          assignment_edit: {
            message_type: 'basic-lti-launch-request',
            url: 'https://lti-tool-provider-example.herokuapp.com/messages/blti',
            title: 'assignment_edit Text'
          },
          assignment_view: {
            message_type: 'basic-lti-launch-request',
            url: 'https://lti-tool-provider-example.herokuapp.com/messages/blti',
            title: 'assignment_view Text',
            launch_width: 600,
            launch_height: 500
          }
        }
      },
      {
        definition_type: 'ContextExternalTool',
        definition_id: 9,
        name: 'A second LTI App',
        description: 'The most impressive LTI app',
        domain: 'my-lti.docker',
        placements: {
          assignment_edit: {
            message_type: 'basic-lti-launch-request',
            url: 'http://my-lti.docker/course-navigation',
            title: 'My LTI'
          },
          assignment_view: {
            message_type: 'basic-lti-launch-request',
            url: 'http://my-lti.docker/assignment-view',
            title: 'My LTI'
          }
        }
      }
    ]
    sandbox.stub($, 'ajax').returns({status: 200, data: toolDefinitions});
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = ['midi', 'media']
  }

  function teardown () {
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = undefined
  }

  hooks.beforeEach(() => {
    setup();
  })

  hooks.afterEach(() => {
    wrapper.unmount();
    teardown();
  })

  test('it renders', () => {
    wrapper = mount(
      <AssignmentExternalTools.configTools
        placement="assignment_edit"
        courseId={1}
        assignmentId={1}
      />
    );
    ok(wrapper.exists())
  })

  test('it uses the correct tool definitions URL', () => {
    const courseId = 1
    const correctUrl = `/api/v1/courses/${courseId}/lti_apps/launch_definitions`
    wrapper = mount(
      <AssignmentExternalTools.configTools
        placement="assignment_edit"
        courseId={1}
        assignmentId={1}
      />
    );
    equal(wrapper.instance().getDefinitionsUrl(), correctUrl)
  })

  test('it renders each tool', () => {
    wrapper = mount(
      <AssignmentExternalTools.configTools
        placement="assignment_edit"
        courseId={1}
        assignmentId={1}
      />
    );
    wrapper.setState({tools: toolDefinitions})
    equal(wrapper.find('.tool_launch').length, toolDefinitions.length)
  })

  test('it builds the correct Launch URL for LTI 1 tools', () => {
    wrapper = mount(
      <AssignmentExternalTools.configTools
        placement="assignment_edit"
        courseId={1}
        assignmentId={1}
      />
    );
    const tool = toolDefinitions[0]
    const correctUrl = `${'/courses/1/external_tools/retrieve?borderless=true&' +
                       'url=https%3A%2F%2Flti-tool-provider-example.herokuapp.com%2Fmessages%2Fblti&' +
                       'placement=assignment_edit&assignment_id=1'}`
    const computedUrl = wrapper.instance().getLaunch(tool)
    equal(computedUrl, correctUrl);
  })

  test('shows beginning info alert and adds styles to iframe', () => {
    wrapper = mount(
      <AssignmentExternalTools.configTools
        placement="assignment_edit"
        courseId={1}
        assignmentId={1}
      />
    )
    wrapper.setState({tools: toolDefinitions})
    wrapper.find('.before_external_content_info_alert').simulate('focus')
    equal(wrapper.state().beforeExternalContentAlertClass, '')
    deepEqual(wrapper.state().iframeStyle, { border: '2px solid #008EE2', width: '-4px' })
  })

  test('shows ending info alert and adds styles to iframe', () => {
    wrapper = mount(
      <AssignmentExternalTools.configTools
        placement="assignment_edit"
        courseId={1}
        assignmentId={1}
      />
    )
    wrapper.setState({tools: toolDefinitions})
    wrapper.find('.after_external_content_info_alert').simulate('focus')
    equal(wrapper.state().afterExternalContentAlertClass, '')
    deepEqual(wrapper.state().iframeStyle, { border: '2px solid #008EE2', width: '-4px' })
  })

  test('hides beginning info alert and adds styles to iframe', () => {
    wrapper = mount(
      <AssignmentExternalTools.configTools
        placement="assignment_edit"
        courseId={1}
        assignmentId={1}
      />
    )
    wrapper.setState({tools: toolDefinitions})
    wrapper.find('.before_external_content_info_alert').simulate('focus')
    wrapper.find('.before_external_content_info_alert').simulate('blur')
    equal(wrapper.state().beforeExternalContentAlertClass, 'screenreader-only')
    deepEqual(wrapper.state().iframeStyle, { border: 'none', width: '100%' })
  })

  test('hides ending info alert and adds styles to iframe', () => {
    wrapper = mount(
      <AssignmentExternalTools.configTools
        placement="assignment_edit"
        courseId={1}
        assignmentId={1}
      />
    )
    wrapper.setState({tools: toolDefinitions})
    wrapper.find('.after_external_content_info_alert').simulate('focus')
    wrapper.find('.after_external_content_info_alert').simulate('blur')
    equal(wrapper.state().afterExternalContentAlertClass, 'screenreader-only')
    deepEqual(wrapper.state().iframeStyle, { border: 'none', width: '100%' })
  })

  test("doesn't show alerts or add border to iframe by default", () => {
    wrapper = mount(
      <AssignmentExternalTools.configTools
        placement="assignment_edit"
        courseId={1}
        assignmentId={1}
      />
    )
    wrapper.setState({tools: toolDefinitions})
    equal(wrapper.state().beforeExternalContentAlertClass, 'screenreader-only')
    equal(wrapper.state().afterExternalContentAlertClass, 'screenreader-only')
    deepEqual(wrapper.state().iframeStyle, {})
  })

  test("it renders multiple iframes", () => {
    wrapper = mount(
      <AssignmentExternalTools.configTools
        placement="assignment_view"
        courseId={1}
        assignmentId={1}
      />
    )
    wrapper.setState({tools: toolDefinitions})
    equal(wrapper.find('.tool_launch').length, 2)
  })

  test('it sets correct placement in launch url', () => {
    wrapper = mount(
      <AssignmentExternalTools.configTools
        placement="assignment_view"
        courseId={1}
        assignmentId={1}
      />
    );
    const tool = toolDefinitions[0]
    const correctUrl = `${'/courses/1/external_tools/retrieve?borderless=true&' +
                       'url=https%3A%2F%2Flti-tool-provider-example.herokuapp.com%2Fmessages%2Fblti&' +
                       'placement=assignment_view&assignment_id=1'}`
    const computedUrl = wrapper.instance().getLaunch(tool)
    equal(computedUrl, correctUrl);
  })

})
