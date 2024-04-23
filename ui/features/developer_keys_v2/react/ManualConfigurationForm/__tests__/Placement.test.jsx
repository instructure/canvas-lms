/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import get from 'lodash/get'

import Placement from '../Placement'

const props = (overrides = {}, placementOverrides = {}) => {
  return {
    placementName: 'account_navigation',
    displayName: 'Account Navigation',
    placement: {
      target_link_uri: 'http://example.com',
      message_type: 'LtiResourceLinkRequest',
      icon_url: 'http://example.com/icon',
      text: 'asdf',
      selection_height: 10,
      selection_width: 10,
      ...placementOverrides,
    },
    ...overrides,
  }
}

it('generates the toolConfiguration', () => {
  const ref = React.createRef()
  render(<Placement {...props()} ref={ref} />)
  const toolConfig = ref.current.generateToolConfigurationPart()
  expect(Object.keys(toolConfig).length).toEqual(6)
  expect(toolConfig.icon_url).toEqual('http://example.com/icon')
})

const checkToolConfigPart = (toolConfig, path, value) => {
  expect(get(toolConfig, path)).toEqual(value)
}

const checkChange = (path, funcName, value, placementOverrides, event = null) => {
  const ref = React.createRef()
  render(<Placement {...props({}, {...placementOverrides})} ref={ref} />)

  event = event || {target: {value}}
  event = Array.isArray(event) ? event : [event]

  ref.current[funcName](...event)
  checkToolConfigPart(ref.current.generateToolConfigurationPart(), path, value)
}

it('changes the output when target_link_uri changes', () => {
  checkChange(['target_link_uri'], 'handleTargetLinkUriChange', 'http://new.example.com')
})

it('changes the output when icon_url changes', () => {
  checkChange(['icon_url'], 'handleIconUrlChange', 'http://example.com/new_icon')
})

it('changes the output when text changes', () => {
  checkChange(['text'], 'handleTextChange', 'New Text')
})

it('changes the output when selection_height changes', () => {
  checkChange(
    ['selection_height'],
    'handleHeightChange',
    250,
    {},
    {target: {value: 250, name: 'placement_name_selection_height'}}
  )
})

it('changes the output when selection_width changes', () => {
  checkChange(
    ['selection_width'],
    'handleWidthChange',
    250,
    {},
    {target: {value: 250, name: 'placement_name_selection_width'}}
  )
})

it('changes the output when launch_height changes', () => {
  checkChange(
    ['launch_height'],
    'handleHeightChange',
    250,
    {launch_height: 10, launch_width: 10},
    {target: {value: 250, name: 'placement_name_launch_height'}}
  )
})

it('changes the output when launch_width changes', () => {
  checkChange(
    ['launch_width'],
    'handleWidthChange',
    250,
    {launch_height: 10, launch_width: 10},
    {target: {value: 250, name: 'placement_name_launch_width'}}
  )
})

it('changes the output when message_type changes', () => {
  checkChange(['message_type'], 'handleMessageTypeChange', 'LtiDeepLinkingRequest', {}, [
    null,
    'LtiDeepLinkingRequest',
  ])
})

it('removes target_link_uri from the placement if it is empty', () => {
  const ref = React.createRef()
  render(<Placement {...props()} ref={ref} />)
  ref.current.handleTargetLinkUriChange({target: {value: ''}})
  const placement = ref.current.generateToolConfigurationPart()
  expect(Object.keys(placement)).not.toContain('target_link_uri')
})

it('removes selection_width from the placement if it is empty', () => {
  const ref = React.createRef()
  render(<Placement {...props()} ref={ref} />)
  ref.current.handleWidthChange({target: {value: '', name: 'placement_name_selection_width'}})
  const placement = ref.current.generateToolConfigurationPart()
  expect(Object.keys(placement)).not.toContain('selection_width')
})

it('removes launch_width from the placement if it is empty', () => {
  const ref = React.createRef()
  render(<Placement {...props()} ref={ref} />)
  ref.current.handleWidthChange({target: {value: '', name: 'placement_name_launch_width'}})
  const placement = ref.current.generateToolConfigurationPart()
  expect(Object.keys(placement)).not.toContain('launch_width')
})

it('cleans up invalid inputs', () => {
  const ref = React.createRef()
  render(<Placement {...props({}, {message_type: undefined})} ref={ref} />)
  expect(ref.current.valid()).toEqual(true)
})

it('is valid when valid', () => {
  const ref = React.createRef()
  render(<Placement {...props()} ref={ref} />)
  expect(ref.current.valid()).toEqual(true)
})

const alwaysDeeplinkingPlacements = [
  'editor_button',
  'migration_selection',
  'homework_submission',
  'conference_selection',
  'submission_type_selection',
]

alwaysDeeplinkingPlacements.forEach(placementName => {
  it('displays alert when placement only supports deep linking', async () => {
    render(<Placement {...props({placementName})} />)
    await userEvent.click(screen.getByRole('button'))
    expect(
      screen.getByText(/This placement requires Deep Link support by the vendor/i)
    ).toBeInTheDocument()
  })
})

it('does not require icon_url', async () => {
  render(<Placement {...props()} />)
  await userEvent.click(screen.getByRole('button'))
  const iconUrl = screen.getByText(/Icon Url/i)
  expect(iconUrl).toBeInTheDocument()
  expect(iconUrl).not.toBeRequired()
})

it('requires icon_url for editor_button', async () => {
  render(<Placement {...props({placementName: 'editor_button', displayName: 'Editor Button'})} />)
  await userEvent.click(screen.getByRole('button'))
  const iconUrl = expect(screen.getByText(/Icon Url \(required/i)).toBeInTheDocument()
  expect(screen.getByRole('textbox', {name: /icon url/i})).toBeRequired()
})

const couldBeEither = ['assignment_selection']

couldBeEither.forEach(placementName => {
  if (['course_assignments_menu', 'module_menu_modal'].includes(placementName)) {
    beforeAll(() => {
      global.ENV.FEATURES ||= {}
      global.ENV.FEATURES.lti_multiple_assignment_deep_linking = true
    })

    afterAll(() => {
      global.ENV.FEATURES.lti_multiple_assignment_deep_linking = false
    })
  }

  if (placementName === 'module_index_menu_modal') {
    beforeAll(() => {
      global.ENV.FEATURES ||= {}
      global.ENV.FEATURES.lti_deep_linking_module_index_menu_modal = true
    })

    afterAll(() => {
      global.ENV.FEATURES.lti_deep_linking_module_index_menu_modal = false
    })
  }

  it(`${placementName}: displays alert when placement supports deep linking and resource link and deep linking chosen`, async () => {
    render(<Placement {...props({placementName}, {message_type: 'LtiDeepLinkingRequest'})} />)
    await userEvent.click(screen.getByRole('button'))
    expect(
      screen.getByText(/This placement requires Deep Link support by the vendor/i)
    ).toBeInTheDocument()
  })

  it(`${placementName}: does not display alert when placement supports deep linking and resource link and resource link is chosen`, async () => {
    const p = props({placementName}, {message_type: 'LtiResourceLinkRequest'})
    render(<Placement {...p} />)
    await userEvent.click(screen.getByText(p.displayName))
    expect(
      screen.queryByRole(/This placement requires Deep Link support by the vendor/i)
    ).not.toBeInTheDocument()
  })
})
