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
import React from 'react'
import {render} from '@testing-library/react'
import AssignmentConfigurationTools from '../AssignmentConfigurationTools'

let secureParams = null
var toolDefinitions = [
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
        title: 'similarity_detection Text',
      },
    },
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
        title: 'My LTI',
      },
    },
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
        title: 'Redirect Tool',
      },
    },
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
        title: 'Lti2Example',
      },
    },
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
        title: 'Redirect Tool',
      },
    },
  },
]

jest.mock('jquery', () => {
  const originalModule = jest.requireActual('jquery')
  return {
    ...originalModule,
    ajax: () => {
      return {status: 200, data: toolDefinitions}
    },
  }
})

describe('AssignmentConfigurationsTools', () => {
  beforeEach(() => {
    secureParams = 'asdf234.lhadf234.adfasd23324'
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = ['midi', 'media']
  })

  afterEach(() => {
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = undefined
  })

  test('it renders', () => {
    const {container} = render(
      <AssignmentConfigurationTools.configTools courseId={1} secureParams={secureParams} />
    )
    expect(container).toBeInTheDocument()
  })

  test('it uses the correct tool definitions URL', () => {
    const ref = React.createRef()
    const courseId = 1
    const correctUrl = `/api/v1/courses/${courseId}/lti_apps/launch_definitions`
    render(
      <AssignmentConfigurationTools.configTools
        courseId={courseId}
        secureParams={secureParams}
        ref={ref}
      />
    )
    expect(ref.current.getDefinitionsUrl()).toBe(correctUrl)
  })

  test('it renders a "none" option', () => {
    const ref = React.createRef()
    const wrapper = render(
      <AssignmentConfigurationTools.configTools
        courseId={1}
        secureParams={secureParams}
        ref={ref}
      />
    )
    ref.current.state.tools = toolDefinitions

    expect(wrapper.container.querySelector('option[data-launch="about:blank"]')).toBeInTheDocument()
  })

  test('it renders "none" for tool type when no tool is selected', () => {
    const ref = React.createRef()
    const wrapper = render(
      <AssignmentConfigurationTools.configTools
        courseId={1}
        secureParams={secureParams}
        ref={ref}
      />
    )
    ref.current.state.tools = toolDefinitions
    const toolType = wrapper.container.querySelector('#configuration-tool-type')
    expect(toolType.value).toBe('none')
  })

  test('it renders each tool', () => {
    const ref = React.createRef()
    const wrapper = render(
      <AssignmentConfigurationTools.configTools
        courseId={1}
        secureParams={secureParams}
        ref={ref}
      />
    )
    ref.current.setState({tools: toolDefinitions})
    expect(wrapper.container.querySelectorAll('#similarity_detection_tool option').length).toBe(
      toolDefinitions.length + 1
    )
  })

  test('it builds the correct Launch URL for LTI 1 tools', () => {
    const ref = React.createRef()
    render(
      <AssignmentConfigurationTools.configTools
        courseId={1}
        secureParams={secureParams}
        ref={ref}
      />
    )
    const tool = toolDefinitions[0]
    const correctUrl = `${
      '/courses/1/external_tools/retrieve?borderless=true&' +
      'url=https%3A%2F%2Flti-tool-provider-example.herokuapp.com%2Fmessages%2Fblti&secure_params='
    }${secureParams}`
    const computedUrl = ref.current.getLaunch(tool)
    expect(computedUrl).toBe(correctUrl)
  })

  test('it builds the correct Launch URL for LTI 2 tools', () => {
    const ref = React.createRef()
    render(
      <AssignmentConfigurationTools.configTools
        courseId={1}
        secureParams={secureParams}
        ref={ref}
      />
    )
    const tool = toolDefinitions[3]
    const correctUrl = `/courses/1/lti/basic_lti_launch_request/5?display=borderless&secure_params=${secureParams}`
    const computedUrl = ref.current.getLaunch(tool)
    expect(computedUrl).toBe(correctUrl)
  })

  test('it renders the proper tool type for LTI 1.x tools', () => {
    const ref = React.createRef()
    const wrapper = render(
      <AssignmentConfigurationTools.configTools
        courseId={1}
        secureParams={secureParams}
        ref={ref}
      />
    )
    ref.current.setState({tools: toolDefinitions})
    const toolSelect = wrapper.container.querySelector('#similarity_detection_tool')
    const toolType = wrapper.container.querySelector('#configuration-tool-type')

    toolSelect.options[1].selected = 'selected'
    ref.current.setToolLaunchUrl()
    expect(toolType.value).toBe('ContextExternalTool')
  })

  test('it renders the proper tool type for LTI 2 tools', () => {
    const ref = React.createRef()
    const wrapper = render(
      <AssignmentConfigurationTools.configTools
        courseId={1}
        secureParams={secureParams}
        ref={ref}
      />
    )
    ref.current.setState({tools: toolDefinitions})
    const toolSelect = wrapper.container.querySelector('#similarity_detection_tool')
    const toolType = wrapper.container.querySelector('#configuration-tool-type')
    toolSelect.options[4].selected = 'selected'
    ref.current.setToolLaunchUrl()
    expect(toolType.value).toBe('Lti::MessageHandler')
  })

  test('it renders proper tool when duplicate IDs but unique tool types are present', () => {
    const ref = React.createRef()
    const wrapper = render(
      <AssignmentConfigurationTools.configTools
        ref={ref}
        courseId={1}
        secureParams={secureParams}
        selectedTool={5}
        selectedToolType="ContextExternalTool"
      />
    )
    ref.current.setState({tools: toolDefinitions})
    const selectBox = wrapper.container.querySelector('#similarity_detection_tool')
    expect(selectBox.value).toBe('ContextExternalTool_5')
  })

  test('shows beginning info alert and adds styles to iframe', async () => {
    const ref = React.createRef()
    const wrapper = render(
      <AssignmentConfigurationTools.configTools
        courseId={1}
        secureParams={secureParams}
        ref={ref}
      />
    )
    ref.current.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
    wrapper.container.querySelector('.before_external_content_info_alert').focus()
    expect(ref.current.state.beforeExternalContentAlertClass).toBe('')
    expect(ref.current.state.iframeStyle).toEqual({border: '2px solid #0374B5', width: '-4px'})
  })

  test('shows ending info alert and adds styles to iframe', () => {
    const ref = React.createRef()
    const wrapper = render(
      <AssignmentConfigurationTools.configTools
        courseId={1}
        secureParams={secureParams}
        ref={ref}
      />
    )
    ref.current.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
    wrapper.container.querySelector('.after_external_content_info_alert').focus()
    expect(ref.current.state.afterExternalContentAlertClass).toBe('')
    expect(ref.current.state.iframeStyle).toEqual({border: '2px solid #0374B5', width: '-4px'})
  })

  test('hides beginning info alert and adds styles to iframe', () => {
    const ref = React.createRef()
    const wrapper = render(
      <AssignmentConfigurationTools.configTools
        courseId={1}
        secureParams={secureParams}
        ref={ref}
      />
    )
    ref.current.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
    wrapper.container.querySelector('.before_external_content_info_alert').focus()
    wrapper.container.querySelector('.before_external_content_info_alert').blur()
    expect(ref.current.state.beforeExternalContentAlertClass).toBe('screenreader-only')
    expect(ref.current.state.iframeStyle).toEqual({border: 'none', width: '100%'})
  })

  test('hides ending info alert and adds styles to iframe', () => {
    const ref = React.createRef()
    const wrapper = render(
      <AssignmentConfigurationTools.configTools
        courseId={1}
        secureParams={secureParams}
        ref={ref}
      />
    )
    ref.current.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
    wrapper.container.querySelector('.after_external_content_info_alert').focus()
    wrapper.container.querySelector('.after_external_content_info_alert').blur()
    expect(ref.current.state.afterExternalContentAlertClass).toBe('screenreader-only')
    expect(ref.current.state.iframeStyle).toEqual({border: 'none', width: '100%'})
  })

  test("doesn't show alerts or add border to iframe by default", () => {
    const ref = React.createRef()
    render(
      <AssignmentConfigurationTools.configTools
        courseId={1}
        secureParams={secureParams}
        ref={ref}
      />
    )
    ref.current.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
    expect(ref.current.state.beforeExternalContentAlertClass).toBe('screenreader-only')
    expect(ref.current.state.iframeStyle).toEqual({})
  })

  test('renders visibility options', () => {
    const ref = React.createRef()
    const wrapper = render(
      <AssignmentConfigurationTools.configTools
        ref={ref}
        courseId={1}
        secureParams={secureParams}
        selectedTool={5}
        selectedToolType="ContextExternalTool"
      />
    )
    ref.current.state.tools = toolDefinitions
    expect(wrapper.container.querySelector('#report_visibility_picker')).toBeInTheDocument()
  })

  test('enables the visibility picker when a tool is selected', () => {
    const ref = React.createRef()
    const wrapper = render(
      <AssignmentConfigurationTools.configTools
        ref={ref}
        courseId={1}
        secureParams={secureParams}
        selectedTool={5}
        selectedToolType="ContextExternalTool"
      />
    )
    ref.current.state.tools = toolDefinitions
    expect(wrapper.container.querySelector('#report_visibility_picker')).toBeVisible()
  })

  test('sets the iframe allowances', () => {
    const ref = React.createRef()
    const wrapper = render(
      <AssignmentConfigurationTools.configTools
        courseId={1}
        secureParams={secureParams}
        selectedTool={5}
        selectedToolType="ContextExternalTool"
      />
    )
    expect(wrapper.container.querySelector('.tool_launch').getAttribute('allow')).toBe(
      ENV.LTI_LAUNCH_FRAME_ALLOWANCES.join('; ')
    )
  })

  test('sets the iframe "data-lti-launch" attribute', () => {
    const wrapper = render(
      <AssignmentConfigurationTools.configTools
        courseId={1}
        secureParams={secureParams}
        selectedTool={5}
        selectedToolType="ContextExternalTool"
      />
    )
    expect(wrapper.container.querySelector('.tool_launch').getAttribute('data-lti-launch')).toBe(
      'true'
    )
  })
})
