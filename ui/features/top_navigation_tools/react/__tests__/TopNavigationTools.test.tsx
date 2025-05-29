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

import React from 'react'
import {shallow} from 'enzyme'
import {
  TopNavigationTools,
  MobileTopNavigationTools,
  handleToolIconError,
} from '../TopNavigationTools'
import type {Tool, TopNavigationToolsProps as _TopNavigationToolsProps} from '../types'

describe('TopNavigationTools', () => {
  it('renders pinned tools as icon buttons and unpinned tools in menu', () => {
    const tools = [
      {
        id: '1',
        title: 'Tool 1',
        base_url: 'https://instructure.com',
        icon_url: 'https://instructure.com',
        pinned: true,
      },
      {
        id: '2',
        title: 'Tool 2',
        base_url: 'https://instructure.com',
        icon_url: 'https://instructure.com/default-icon.png',
        pinned: false,
      },
    ]
    const handleToolLaunch = jest.fn()
    const wrapper = shallow(
      <TopNavigationTools tools={tools} handleToolLaunch={handleToolLaunch} />,
    )

    // Check container structure
    const rootFlex = wrapper.find('Flex').first()
    expect(rootFlex.prop('direction')).toBe('row-reverse')

    // Should have one IconButton for pinned tool
    const iconButtons = wrapper.find('IconButton')
    expect(iconButtons).toHaveLength(1)
    expect(iconButtons.at(0).prop('data-tool-id')).toBe('1')
    expect(iconButtons.at(0).prop('screenReaderLabel')).toBe('Tool 1')

    // Should have one Menu for unpinned tools
    const menus = wrapper.find('Menu')
    expect(menus).toHaveLength(1)
    expect(menus.at(0).prop('label')).toBe('LTI Tools Menu')

    // Menu should contain one MenuItem for unpinned tool
    const menuItems = wrapper.find('MenuItem')
    expect(menuItems).toHaveLength(1)
    expect(menuItems.at(0).prop('value')).toBe('2')
    expect(menuItems.at(0).prop('label')).toBe('Launch Tool 2')
  })

  it('renders empty container when no tools provided', () => {
    const tools: Tool[] = []
    const handleToolLaunch = jest.fn()
    const wrapper = shallow(
      <TopNavigationTools tools={tools} handleToolLaunch={handleToolLaunch} />,
    )

    // Should render empty Flex container
    expect(wrapper.find('Flex')).toHaveLength(1)
    expect(wrapper.find('IconButton')).toHaveLength(0)
    expect(wrapper.find('Menu')).toHaveLength(0)
  })

  it('renders all tools in menu when no tools are pinned', () => {
    const tools = [
      {
        id: '1',
        title: 'Tool 1',
        base_url: 'https://instructure.com',
        icon_url: 'https://instructure.com',
        pinned: false,
      },
      {
        id: '2',
        title: 'Tool 2',
        base_url: 'https://instructure.com',
        icon_url: 'https://instructure.com/default-icon.png',
        pinned: false,
      },
    ]
    const handleToolLaunch = jest.fn()
    const wrapper = shallow(
      <TopNavigationTools tools={tools} handleToolLaunch={handleToolLaunch} />,
    )

    // Should have no IconButtons (no pinned tools)
    expect(wrapper.find('IconButton')).toHaveLength(0)

    // Should have one Menu containing all tools
    const menus = wrapper.find('Menu')
    expect(menus).toHaveLength(1)

    // Menu should contain MenuItems for both tools
    const menuItems = wrapper.find('MenuItem')
    expect(menuItems).toHaveLength(2)
    expect(menuItems.at(0).prop('value')).toBe('1')
    expect(menuItems.at(1).prop('value')).toBe('2')
  })
})

describe('MobileTopNavigationTools', () => {
  it('renders all tools in a single menu with pinned tools at top', () => {
    const tools = [
      {
        id: '1',
        title: 'Tool 1',
        base_url: 'https://instructure.com',
        icon_url: 'https://instructure.com',
        pinned: false,
      },
      {
        id: '2',
        title: 'Tool 2',
        base_url: 'https://instructure.com',
        icon_url: 'https://instructure.com',
        pinned: true,
      },
    ]
    const handleToolLaunch = jest.fn()
    const wrapper = shallow(
      <MobileTopNavigationTools tools={tools} handleToolLaunch={handleToolLaunch} />,
    )

    // Should render single Menu component
    const menu = wrapper.find('Menu')
    expect(menu).toHaveLength(1)

    // Menu trigger should be an IconButton with proper accessibility label
    const trigger = menu.prop('trigger') as React.ReactElement
    expect(trigger.props.screenReaderLabel).toBe('LTI Tool Menu')

    // Should have MenuItems for all tools
    const menuItems = wrapper.find('MenuItem')
    expect(menuItems).toHaveLength(2)

    // Pinned tool (Tool 2) should be listed first
    expect(menuItems.at(0).prop('value')).toBe('2')
    expect(menuItems.at(0).prop('label')).toBe('Launch Tool 2')

    // Unpinned tool (Tool 1) should be after separator
    expect(menuItems.at(1).prop('value')).toBe('1')
    expect(menuItems.at(1).prop('label')).toBe('Launch Tool 1')

    // Should have a separator between pinned and unpinned tools
    expect(wrapper.find('MenuItemSeparator')).toHaveLength(1)
  })
})

describe('handleToolClick', () => {
  it('finds tool', () => {
    const tool = {
      id: '1',
      title: 'Tool 1',
      base_url: 'https://instructure.com',
      icon_url: 'https://instructure.com',
      pinned: true,
    }
    const handleToolLaunch = jest.fn()
    const wrapper = shallow(
      <TopNavigationTools tools={[tool]} handleToolLaunch={handleToolLaunch} />,
    )
    wrapper.find('IconButton').simulate('click', {target: {dataset: {toolId: '1'}}})
    expect(handleToolLaunch).toHaveBeenCalledWith(tool)
  })
})

describe('handleToolIconError', () => {
  it('uses default tool icon', () => {
    const tool = {
      id: '1',
      title: 'Tool 1',
      base_url: 'https://instructure.com',
      icon_url: 'https://instructure.com/default-icon.png',
      pinned: true,
    }
    const event = {
      target: {
        src: '',
      },
    }

    handleToolIconError(tool)(event as unknown as Event & {target: {src: string}})

    expect(event.target.src).toBe('/lti/tool_default_icon?name=T')
  })
})
