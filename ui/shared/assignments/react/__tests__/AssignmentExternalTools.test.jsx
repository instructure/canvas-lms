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
import AssignmentExternalTools from '../AssignmentExternalTools'
import fetchMock from 'fetch-mock'

var toolDefinitions = [
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
        title: 'assignment_edit Text',
      },
      assignment_view: {
        message_type: 'basic-lti-launch-request',
        url: 'https://lti-tool-provider-example.herokuapp.com/messages/blti',
        title: 'assignment_view Text',
        launch_width: 600,
        launch_height: 500,
      },
    },
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
        title: 'My LTI',
      },
      assignment_view: {
        message_type: 'basic-lti-launch-request',
        url: 'http://my-lti.docker/assignment-view',
        title: 'My LTI',
      },
    },
  },
]

jest.mock('jquery', () => {
  const originalModule = jest.requireActual('jquery')
  return {
    ...originalModule,
    ajax: {status: 200, data: toolDefinitions},
  }
})
fetchMock.mock('path:/api/v1/courses/1/lti_apps/launch_definitions', 200)

describe('AssignmentExternalTools', () => {
  let wrapper
  beforeEach(() => {
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = ['midi', 'media']
  })

  afterEach(() => {
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = undefined
  })

  test('it renders', () => {
    wrapper = render(
      <AssignmentExternalTools.configTools
        placement="assignment_edit"
        courseId={1}
        assignmentId={1}
      />
    )
    expect(wrapper.container).toBeInTheDocument()
  })

  test('it uses the correct tool definitions URL', () => {
    const ref = React.createRef()
    const courseId = 1
    const correctUrl = `/api/v1/courses/${courseId}/lti_apps/launch_definitions`
    wrapper = render(
      <AssignmentExternalTools.configTools
        ref={ref}
        placement="assignment_edit"
        courseId={1}
        assignmentId={1}
      />
    )
    expect(ref.current.getDefinitionsUrl()).toEqual(correctUrl)
  })

  test('it renders each tool', () => {
    const ref = React.createRef()
    wrapper = render(
      <AssignmentExternalTools.configTools
        ref={ref}
        placement="assignment_edit"
        courseId={1}
        assignmentId={1}
      />
    )
    ref.current.setState({tools: toolDefinitions})
    expect(wrapper.container.querySelectorAll('.tool_launch').length).toEqual(
      toolDefinitions.length
    )
  })

  test('it builds the correct Launch URL for LTI 1 tools', () => {
    const ref = React.createRef()
    wrapper = render(
      <AssignmentExternalTools.configTools
        ref={ref}
        placement="assignment_edit"
        courseId={1}
        assignmentId={1}
      />
    )
    const tool = toolDefinitions[0]
    const correctUrl = `${
      '/courses/1/external_tools/retrieve?borderless=true&' +
      'url=https%3A%2F%2Flti-tool-provider-example.herokuapp.com%2Fmessages%2Fblti&' +
      'placement=assignment_edit&assignment_id=1'
    }`
    const computedUrl = ref.current.getLaunch(tool)
    expect(computedUrl).toEqual(correctUrl)
  })

  test('shows beginning info alert and adds styles to iframe', () => {
    const ref = React.createRef()
    wrapper = render(
      <AssignmentExternalTools.configTools
        ref={ref}
        placement="assignment_edit"
        courseId={1}
        assignmentId={1}
      />
    )
    ref.current.setState({tools: toolDefinitions})
    wrapper.container.querySelector('.before_external_content_info_alert').focus()
    expect(ref.current.state.beforeExternalContentAlertClass).toEqual('')
    expect(ref.current.state.iframeStyle).toEqual({border: '2px solid #0374B5', width: '-4px'})
  })

  test('shows ending info alert and adds styles to iframe', () => {
    const ref = React.createRef()
    wrapper = render(
      <AssignmentExternalTools.configTools
        ref={ref}
        placement="assignment_edit"
        courseId={1}
        assignmentId={1}
      />
    )
    ref.current.setState({tools: toolDefinitions})
    wrapper.container.querySelector('.after_external_content_info_alert').focus()
    expect(ref.current.state.afterExternalContentAlertClass).toEqual('')
    expect(ref.current.state.iframeStyle).toEqual({border: '2px solid #0374B5', width: '-4px'})
  })

  test('hides beginning info alert and adds styles to iframe', () => {
    const ref = React.createRef()
    wrapper = render(
      <AssignmentExternalTools.configTools
        ref={ref}
        placement="assignment_edit"
        courseId={1}
        assignmentId={1}
      />
    )
    ref.current.setState({tools: toolDefinitions})
    wrapper.container.querySelector('.before_external_content_info_alert').focus()
    wrapper.container.querySelector('.before_external_content_info_alert').blur()
    expect(ref.current.state.beforeExternalContentAlertClass).toEqual('screenreader-only')
    expect(ref.current.state.iframeStyle).toEqual({border: 'none', width: '100%'})
  })

  test('hides ending info alert and adds styles to iframe', () => {
    const ref = React.createRef()
    wrapper = render(
      <AssignmentExternalTools.configTools
        ref={ref}
        placement="assignment_edit"
        courseId={1}
        assignmentId={1}
      />
    )
    ref.current.setState({tools: toolDefinitions})
    wrapper.container.querySelector('.after_external_content_info_alert').focus()
    wrapper.container.querySelector('.after_external_content_info_alert').blur()
    expect(ref.current.state.afterExternalContentAlertClass).toEqual('screenreader-only')
    expect(ref.current.state.iframeStyle).toEqual({border: 'none', width: '100%'})
  })

  test("doesn't show alerts or add border to iframe by default", () => {
    const ref = React.createRef()
    wrapper = render(
      <AssignmentExternalTools.configTools
        ref={ref}
        placement="assignment_edit"
        courseId={1}
        assignmentId={1}
      />
    )
    ref.current.setState({tools: toolDefinitions})
    expect(ref.current.state.beforeExternalContentAlertClass).toEqual('screenreader-only')
    expect(ref.current.state.afterExternalContentAlertClass).toEqual('screenreader-only')
    expect(ref.current.state.iframeStyle).toEqual({})
  })

  test('it renders multiple iframes', () => {
    const ref = React.createRef()
    wrapper = render(
      <AssignmentExternalTools.configTools
        ref={ref}
        placement="assignment_view"
        courseId={1}
        assignmentId={1}
      />
    )
    ref.current.setState({tools: toolDefinitions})
    expect(wrapper.container.querySelectorAll('.tool_launch').length).toEqual(2)
  })

  test('it sets correct placement in launch url', () => {
    const ref = React.createRef()
    wrapper = render(
      <AssignmentExternalTools.configTools
        ref={ref}
        placement="assignment_view"
        courseId={1}
        assignmentId={1}
      />
    )
    const tool = toolDefinitions[0]
    const correctUrl = `${
      '/courses/1/external_tools/retrieve?borderless=true&' +
      'url=https%3A%2F%2Flti-tool-provider-example.herokuapp.com%2Fmessages%2Fblti&' +
      'placement=assignment_view&assignment_id=1'
    }`
    const computedUrl = ref.current.getLaunch(tool)
    expect(computedUrl).toEqual(correctUrl)
  })

  test('it sets the "data-lti-launch" attribute on each iframe', () => {
    const ref = React.createRef()
    wrapper = render(
      <AssignmentExternalTools.configTools
        ref={ref}
        placement="assignment_view"
        courseId={1}
        assignmentId={1}
      />
    )
    ref.current.setState({tools: toolDefinitions})
    wrapper.container.querySelectorAll('.tool_launch').forEach(iframe => {
      expect(iframe.getAttribute('data-lti-launch')).toEqual('true')
    })
  })
})
