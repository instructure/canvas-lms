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
import AssignmentConfigurationTools from 'jsx/assignments/AssignmentConfigurationTools'

let toolDefinitions = null
let secureParams = null

QUnit.module('AssignmentConfigurationsTools', {
  setup() {
    secureParams = 'asdf234.lhadf234.adfasd23324'
    toolDefinitions = [
      {
        definition_type: 'ContextExternalTool',
        definition_id: 8,
        name: 'similarity_detection Text',
        description: 'This is a Sample Tool Provider.',
        domain: 'lti-tool-provider-example.herokuapp.com',
        placements: {
          similarity_detection: {
            message_type: 'basic-lti-launch-request',
            url: 'https://lti-tool-provider-example.herokuapp.com/messages/blti',
            title: 'similarity_detection Text'
          }
        }
      },
      {
        definition_type: 'ContextExternalTool',
        definition_id: 9,
        name: 'My LTI',
        description: 'The most impressive LTI app',
        domain: 'my-lti.docker',
        placements: {
          similarity_detection: {
            message_type: 'basic-lti-launch-request',
            url: 'http://my-lti.docker/course-navigation',
            title: 'My LTI'
          }
        }
      },
      {
        definition_type: 'ContextExternalTool',
        definition_id: 7,
        name: 'Redirect Tool',
        description:
          'Add links to external web resources that show up as navigation items in course, user or account navigation. Whatever URL you specify is loaded within the content pane when users click the link.',
        domain: null,
        placements: {
          similarity_detection: {
            message_type: 'basic-lti-launch-request',
            url: 'https://www.edu-apps.org/redirect',
            title: 'Redirect Tool'
          }
        }
      },
      {
        definition_type: 'Lti::MessageHandler',
        definition_id: 5,
        name: 'Lti2Example',
        description: null,
        domain: 'localhost',
        placements: {
          similarity_detection: {
            message_type: 'basic-lti-launch-request',
            url: 'http://localhost:3000/messages/blti',
            title: 'Lti2Example'
          }
        }
      },
      {
        definition_type: 'ContextExternalTool',
        definition_id: 5,
        name: 'Redirect Tool',
        description:
          'Add links to external web resources that show up as navigation items in course, user or account navigation. Whatever URL you specify is loaded within the content pane when users click the link.',
        domain: null,
        placements: {
          similarity_detection: {
            message_type: 'basic-lti-launch-request',
            url: 'https://www.edu-apps.org/redirect',
            title: 'Redirect Tool'
          }
        }
      }
    ]
    sandbox.stub($, 'ajax').returns({status: 200, data: toolDefinitions})
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = ['midi', 'media']
  },
  teardown() {
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = undefined
  }
})

test('it renders', () => {
  const wrapper = mount(
    <AssignmentConfigurationTools.configTools
      courseId={1}
      secureParams={secureParams}
    />
  )
  ok(wrapper.exists())
})

test('it uses the correct tool definitions URL', () => {
  const courseId = 1
  const correctUrl = `/api/v1/courses/${courseId}/lti_apps/launch_definitions`
  const wrapper = mount(
    <AssignmentConfigurationTools.configTools
      courseId={courseId}
      secureParams={secureParams}
    />
  )
  equal(wrapper.instance().getDefinitionsUrl(), correctUrl)
})

test('it renders a "none" option', () => {
  const wrapper = mount(
    <AssignmentConfigurationTools.configTools
      courseId={1}
      secureParams={secureParams}
    />
  )
  wrapper.setState({tools: toolDefinitions})

  ok(wrapper.find('option[data-launch="about:blank"]').exists())
})

test('it renders "none" for tool type when no tool is selected', () => {
  const wrapper = mount(
    <AssignmentConfigurationTools.configTools
      courseId={1}
      secureParams={secureParams}
    />
  )
  wrapper.setState({tools: toolDefinitions})
  const toolType = wrapper.find('#configuration-tool-type').getDOMNode()
  equal(toolType.value, 'none')
})

test('it renders each tool', () => {
  const wrapper = mount(
    <AssignmentConfigurationTools.configTools
      courseId={1}
      secureParams={secureParams}
    />
  )
  wrapper.setState({tools: toolDefinitions})
  equal(wrapper.find('#similarity_detection_tool option').length, toolDefinitions.length + 1)
})

test('it builds the correct Launch URL for LTI 1 tools', () => {
  const wrapper = mount(
    <AssignmentConfigurationTools.configTools
      courseId={1}
      secureParams={secureParams}
    />
  )
  const tool = toolDefinitions[0]
  const correctUrl = `${'/courses/1/external_tools/retrieve?borderless=true&' +
    'url=https%3A%2F%2Flti-tool-provider-example.herokuapp.com%2Fmessages%2Fblti&secure_params='}${secureParams}`
  const computedUrl = wrapper.instance().getLaunch(tool)
  equal(computedUrl, correctUrl)
})

test('it builds the correct Launch URL for LTI 2 tools', () => {
  const wrapper = mount(
    <AssignmentConfigurationTools.configTools
      courseId={1}
      secureParams={secureParams}
    />
  )
  const tool = toolDefinitions[3]
  const correctUrl = `/courses/1/lti/basic_lti_launch_request/5?display=borderless&secure_params=${secureParams}`
  const computedUrl = wrapper.instance().getLaunch(tool)
  equal(computedUrl, correctUrl)
})

test('it renders the proper tool type for LTI 1.x tools', () => {
  const wrapper = mount(
    <AssignmentConfigurationTools.configTools
      courseId={1}
      secureParams={secureParams}
    />
  )
  wrapper.setState({tools: toolDefinitions})
  const toolSelect = wrapper.find('#similarity_detection_tool')
  const toolType = wrapper.find('#configuration-tool-type')

  toolSelect.getDOMNode().options[1].selected = 'selected'
  wrapper.instance().setToolLaunchUrl()
  equal(toolType.getDOMNode().value, 'ContextExternalTool')
})

test('it renders the proper tool type for LTI 2 tools', () => {
  const wrapper = mount(
    <AssignmentConfigurationTools.configTools
      courseId={1}
      secureParams={secureParams}
    />
  )
  wrapper.setState({tools: toolDefinitions})
  const toolSelect = wrapper.find('#similarity_detection_tool')
  const toolType = wrapper.find('#configuration-tool-type')
  toolSelect.getDOMNode().options[4].selected = 'selected'
  wrapper.instance().setToolLaunchUrl()
  equal(toolType.getDOMNode().value, 'Lti::MessageHandler')
})

test('it renders proper tool when duplicate IDs but unique tool types are present', () => {
  const wrapper = mount(
    <AssignmentConfigurationTools.configTools
      courseId={1}
      secureParams={secureParams}
      selectedTool={5}
      selectedToolType="ContextExternalTool"
    />
  )
  wrapper.setState({tools: toolDefinitions})
  const selectBox = wrapper.find('#similarity_detection_tool')
  equal(selectBox.props().value, 'ContextExternalTool_5')
})

test('shows beginning info alert and adds styles to iframe', () => {
  const wrapper = mount(
    <AssignmentConfigurationTools.configTools
      courseId={1}
      secureParams={secureParams}
    />
  )
  wrapper.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
  wrapper.find('.before_external_content_info_alert').simulate('focus')
  equal(wrapper.state().beforeExternalContentAlertClass, '')
  deepEqual(wrapper.state().iframeStyle, {border: '2px solid #008EE2', width: '-4px'})
})

test('shows ending info alert and adds styles to iframe', () => {
  const wrapper = mount(
    <AssignmentConfigurationTools.configTools
      courseId={1}
      secureParams={secureParams}
    />
  )
  wrapper.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
  wrapper.find('.after_external_content_info_alert').simulate('focus')
  equal(wrapper.state().afterExternalContentAlertClass, '')
  deepEqual(wrapper.state().iframeStyle, {border: '2px solid #008EE2', width: '-4px'})
})

test('hides beginning info alert and adds styles to iframe', () => {
  const wrapper = mount(
    <AssignmentConfigurationTools.configTools
      courseId={1}
      secureParams={secureParams}
    />
  )
  wrapper.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
  wrapper.find('.before_external_content_info_alert').simulate('focus')
  wrapper.find('.before_external_content_info_alert').simulate('blur')
  equal(wrapper.state().beforeExternalContentAlertClass, 'screenreader-only')
  deepEqual(wrapper.state().iframeStyle, {border: 'none', width: '100%'})
})

test('hides ending info alert and adds styles to iframe', () => {
  const wrapper = mount(
    <AssignmentConfigurationTools.configTools
      courseId={1}
      secureParams={secureParams}
    />
  )
  wrapper.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
  wrapper.find('.after_external_content_info_alert').simulate('focus')
  wrapper.find('.after_external_content_info_alert').simulate('blur')
  equal(wrapper.state().afterExternalContentAlertClass, 'screenreader-only')
  deepEqual(wrapper.state().iframeStyle, {border: 'none', width: '100%'})
})

test("doesn't show alerts or add border to iframe by default", () => {
  const wrapper = mount(
    <AssignmentConfigurationTools.configTools
      courseId={1}
      secureParams={secureParams}
    />
  )
  wrapper.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
  equal(wrapper.state().beforeExternalContentAlertClass, 'screenreader-only')
  equal(wrapper.state().afterExternalContentAlertClass, 'screenreader-only')
  deepEqual(wrapper.state().iframeStyle, {})
})

test('renders visibility options', () => {
  const wrapper = mount(
    <AssignmentConfigurationTools.configTools
      courseId={1}
      secureParams={secureParams}
      selectedTool={5}
      selectedToolType="ContextExternalTool"
    />
  )
  wrapper.setState({tools: toolDefinitions})
  ok(wrapper.find('#report_visibility_picker'))
})

test('enables the visibility picker when a tool is selected', () => {
  const wrapper = mount(
    <AssignmentConfigurationTools.configTools
      courseId={1}
      secureParams={secureParams}
      selectedTool={5}
      selectedToolType="ContextExternalTool"
    />
  )
  wrapper.setState({tools: toolDefinitions})
  notOk(wrapper.find('#report_visibility_picker').getElement().disabled)
})

test('sets the iframe allowances', () => {
  const wrapper = mount(
    <AssignmentConfigurationTools.configTools
      courseId={1}
      secureParams={secureParams}
      selectedTool={5}
      selectedToolType="ContextExternalTool"
    />
  )

  equal(
    wrapper
      .find('.tool_launch')
      .instance()
      .getAttribute('allow'),
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES.join('; ')
  )
})
