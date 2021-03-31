// Copyright (C) 2020 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import React from 'react'
import {mount} from 'enzyme'
import store from '../../lib/ExternalAppsStore'
import ExternalToolPlacementButton from '../ExternalToolPlacementButton'

jest.mock('../../lib/ExternalAppsStore')

describe('ExternalToolPlacementButton', () => {
  let wrapper
  let instance
  let tool

  const render = (overrides = {}) => {
    tool = {
      name: 'test',
      app_type: 'ContextExternalTool',
      editor_button: {
        enabled: true
      },
      account_navigation: null,
      version: '1.1',
      context: 'account',
      ...overrides
    }
    wrapper = mount(
      <ExternalToolPlacementButton
        type="button"
        tool={tool}
        returnFocus={() => {}}
        onSuccess={jest.fn()}
      />
    )
    instance = wrapper.instance()
  }

  beforeEach(() => {
    render()
  })

  afterEach(() => {
    wrapper.unmount()
    jest.clearAllMocks()
  })

  describe('#handleTogglePlacement', () => {
    it('toggles placement status in tool', () => {
      instance.handleTogglePlacement('editor_button')
      expect(instance.state.tool.editor_button.enabled).toBeFalsy()
      instance.handleTogglePlacement('editor_button')
      expect(instance.state.tool.editor_button.enabled).toBeTruthy()
    })

    it('sends new placement status to api', () => {
      instance.handleTogglePlacement('editor_button')
      expect(store.togglePlacement).toHaveBeenCalled()
      expect(store.togglePlacement.mock.calls[0][0].tool.editor_button.enabled).toBeFalsy()
    })

    it('resets placement status on api fail', () => {
      store.togglePlacement.mockImplementation(({onError}) => onError())
      instance.handleTogglePlacement('editor_button')
      expect(instance.state.tool.editor_button.enabled).toBeTruthy()
    })

    it('executes onSuccess callback from props on api success', () => {
      store.togglePlacement.mockImplementation(({onSuccess}) => onSuccess())

      instance.handleTogglePlacement('editor_button')
      expect(store.togglePlacement).toHaveBeenCalled()
      expect(instance.props.onSuccess).toHaveBeenCalled()
    })
  })

  describe('#placements', () => {
    const expectAllPlacements = cb => {
      instance
        .placements()
        .filter(p => p != null)
        .forEach(p => cb(p))
    }

    beforeEach(() => {
      global.ENV = {
        CONTEXT_BASE_URL: '/accounts/1',
        PERMISSIONS: {
          create_tool_manually: true
        }
      }
    })
    it('omits toggle buttons if tool is 1.3', () => {
      render({version: '1.3'})
      expectAllPlacements(p => expect(p.type).toBe('div'))
    })

    it('omits toggle buttons if page context does not match tool installation context', () => {
      global.ENV.CONTEXT_BASE_URL = '/courses/1'
      render()
      expectAllPlacements(p => expect(p.type).toBe('div'))
    })

    it('omits toggle buttons if user does not have permission to edit the tool', () => {
      global.ENV.PERMISSIONS.create_tool_manually = false
      render()
      expectAllPlacements(p => expect(p.type).toBe('div'))
    })

    it('does not show deactivated placements when toggle buttons omitted', () => {
      global.ENV.PERMISSIONS.create_tool_manually = false
      render({homework_submission: {enabled: false}})
      expect(instance.placements().map(p => p != null && p.key)).toEqual(['editor_button'])
    })

    it('does show deactivated placements with toggle buttons', () => {
      render({homework_submission: {enabled: false}})
      expect(instance.placements().map(p => p != null && p.key)).toEqual([
        'editor_button',
        'homework_submission'
      ])
    })

    it('renders toggle buttons for each placement', () => {
      expectAllPlacements(p => expect(p.type.displayName).toBe('Flex'))
    })

    it('renders special placements for resource_selection when toggle buttons omitted', () => {
      global.ENV.CONTEXT_BASE_URL = '/courses/1'
      render({resource_selection: {enabled: true}})
      const placements = mount(<div>{instance.placements()}</div>)
      const assignmentSelection = placements.findWhere(p => p.key() === 'assignment_selection')
      const linkSelection = placements.findWhere(p => p.key() === 'link_selection')
      expect(assignmentSelection.text()).toMatch('Assignment Selection')
      expect(linkSelection.text()).toMatch('Link Selection')
    })

    it('omits both placements for resource_selection when toggle buttons omitted', () => {
      global.ENV.CONTEXT_BASE_URL = '/courses/1'
      render({resource_selection: {enabled: false}})
      expect(instance.placements().map(p => p != null && p.key)).toEqual(['editor_button'])
    })

    it('renders assignment_ and link_selection normally when toggle buttons omitted', () => {
      global.ENV.CONTEXT_BASE_URL = '/courses/1'
      render({assignment_selection: {enabled: true}, link_selection: {enabled: true}})
      expect(instance.placements().map(p => p != null && p.key)).toEqual([
        'assignment_selection',
        'editor_button',
        'link_selection'
      ])
    })

    it('renders special text for resource_selection toggle button', () => {
      render({resource_selection: {enabled: true}})
      const placements = mount(<div>{instance.placements()}</div>)
      const resourceSelection = placements.findWhere(p => p.key() === 'resource_selection')
      expect(resourceSelection.text()).toMatch('Assignment and Link Selection')
    })

    it('renders assignment_ and link_selection normally with toggle buttons', () => {
      render({assignment_selection: {enabled: true}, link_selection: {enabled: true}})
      const placements = mount(<div>{instance.placements()}</div>)
      const assignmentSelection = placements.findWhere(p => p.key() === 'assignment_selection')
      const linkSelection = placements.findWhere(p => p.key() === 'link_selection')
      expect(assignmentSelection.text()).toMatch('Assignment Selection')
      expect(linkSelection.text()).toMatch('Link Selection')
    })
  })
})
