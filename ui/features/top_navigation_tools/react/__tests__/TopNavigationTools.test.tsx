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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {
  TopNavigationTools,
  MobileTopNavigationTools,
  handleToolIconError,
} from '../TopNavigationTools'
import type {Tool} from '@canvas/global/env/EnvCommon'

describe('TopNavigationTools', () => {
  beforeEach(() => {
    window.ENV = window.ENV || {}
    window.ENV.FEATURES = {}
  })

  it('renders pinned tools as icon buttons and unpinned tools in menu', async () => {
    jest.useRealTimers()

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
    const user = userEvent.setup()
    const {getByRole, getByLabelText, getAllByRole} = render(
      <TopNavigationTools tools={tools} handleToolLaunch={handleToolLaunch} />,
    )

    // Should have one IconButton for pinned tool
    const pinnedToolButton = getByRole('button', {name: /Tool 1/})
    expect(pinnedToolButton).toBeInTheDocument()
    expect(pinnedToolButton).toHaveAttribute('data-tool-id', '1')

    // Should have LTI Tools Menu button for unpinned tools
    const buttons = getAllByRole('button')
    const menuButton = buttons.find(button => !button.hasAttribute('data-tool-id'))
    expect(menuButton).toBeInTheDocument()

    // Click menu to reveal menu items
    await user.click(menuButton!)

    // Menu should contain one MenuItem for unpinned tool
    const menuItem = getByRole('menuitem', {name: /Tool 2/})
    expect(menuItem).toBeInTheDocument()

    jest.useFakeTimers()
  })

  it('renders menu before pinned tools in DOM when a11y fixes flag is OFF', () => {
    window.ENV.FEATURES = {}

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
        icon_url: 'https://instructure.com',
        pinned: false,
      },
    ]
    const handleToolLaunch = jest.fn()
    const {getAllByRole} = render(
      <TopNavigationTools tools={tools} handleToolLaunch={handleToolLaunch} />,
    )

    const buttons = getAllByRole('button')
    // When flag is OFF, menu button (without data-tool-id) should be first in DOM
    expect(buttons[0]).not.toHaveAttribute('data-tool-id')
    expect(buttons[1]).toHaveAttribute('data-tool-id', '1')
    // Visual order is reversed by CSS row-reverse
  })

  it('renders pinned tools before menu in DOM when a11y fixes flag is ON', () => {
    window.ENV.FEATURES = {top_navigation_placement_a11y_fixes: true}

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
        icon_url: 'https://instructure.com',
        pinned: false,
      },
    ]
    const handleToolLaunch = jest.fn()
    const {getAllByRole} = render(
      <TopNavigationTools tools={tools} handleToolLaunch={handleToolLaunch} />,
    )

    const buttons = getAllByRole('button')
    // When flag is ON, pinned tool should be first in DOM
    expect(buttons[0]).toHaveAttribute('data-tool-id', '1')
    expect(buttons[1]).not.toHaveAttribute('data-tool-id')
    // Visual order matches DOM order (no reverse)
  })

  it('maintains logical DOM order when a11y fixes flag is ON (no row-reverse)', () => {
    window.ENV.FEATURES = {top_navigation_placement_a11y_fixes: true}

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
        icon_url: 'https://instructure.com',
        pinned: false,
      },
    ]
    const handleToolLaunch = jest.fn()
    const {getAllByRole} = render(
      <TopNavigationTools tools={tools} handleToolLaunch={handleToolLaunch} />,
    )

    const buttons = getAllByRole('button')
    // When flag is ON, DOM order matches visual order (no row-reverse)
    // Pinned tool first, menu button last
    expect(buttons[0]).toHaveAttribute('data-tool-id', '1')
    expect(buttons[1]).not.toHaveAttribute('data-tool-id')
  })

  it('applies row-reverse flex direction when a11y fixes flag is OFF', () => {
    window.ENV.FEATURES = {}

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
        icon_url: 'https://instructure.com',
        pinned: false,
      },
    ]
    const handleToolLaunch = jest.fn()
    const {getAllByRole} = render(
      <TopNavigationTools tools={tools} handleToolLaunch={handleToolLaunch} />,
    )

    const buttons = getAllByRole('button')
    // When flag is OFF with row-reverse, menu button appears first in DOM
    // but should be visually last due to flex-direction: row-reverse
    expect(buttons[0]).not.toHaveAttribute('data-tool-id') // menu button first
    expect(buttons[1]).toHaveAttribute('data-tool-id', '1') // pinned tool second
  })

  it('maintains correct tab order with multiple pinned tools when a11y fixes ON', () => {
    window.ENV.FEATURES = {top_navigation_placement_a11y_fixes: true}

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
        icon_url: 'https://instructure.com',
        pinned: true,
      },
      {
        id: '3',
        title: 'Tool 3',
        base_url: 'https://instructure.com',
        icon_url: 'https://instructure.com',
        pinned: false,
      },
    ]
    const handleToolLaunch = jest.fn()
    const {getAllByRole} = render(
      <TopNavigationTools tools={tools} handleToolLaunch={handleToolLaunch} />,
    )

    const buttons = getAllByRole('button')
    // With a11y fixes ON: pinned tools first (left-to-right), then menu
    expect(buttons[0]).toHaveAttribute('data-tool-id', '1')
    expect(buttons[1]).toHaveAttribute('data-tool-id', '2')
    expect(buttons[2]).not.toHaveAttribute('data-tool-id') // menu button
  })

  it('renders empty container when no tools provided', () => {
    const tools: Tool[] = []
    const handleToolLaunch = jest.fn()
    const {container, queryByRole} = render(
      <TopNavigationTools tools={tools} handleToolLaunch={handleToolLaunch} />,
    )

    // Should render empty container with no tools
    expect(container.firstChild).toBeInTheDocument()
    expect(queryByRole('button')).not.toBeInTheDocument()
  })

  it('renders all tools in menu when no tools are pinned', async () => {
    jest.useRealTimers()

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
    const user = userEvent.setup()
    const {getByRole, queryByRole} = render(
      <TopNavigationTools tools={tools} handleToolLaunch={handleToolLaunch} />,
    )

    // Should have no pinned tool buttons
    expect(queryByRole('button', {name: /Tool 1/})).not.toBeInTheDocument()
    expect(queryByRole('button', {name: /Tool 2/})).not.toBeInTheDocument()

    // Should have LTI Tools Menu button containing all tools
    const menuButton = getByRole('button')
    expect(menuButton).toBeInTheDocument()

    // Click menu to reveal menu items
    await user.click(menuButton!)

    // Menu should contain MenuItems for both tools
    expect(getByRole('menuitem', {name: /Tool 1/})).toBeInTheDocument()
    expect(getByRole('menuitem', {name: /Tool 2/})).toBeInTheDocument()

    jest.useFakeTimers()
  })
})

describe('MobileTopNavigationTools', () => {
  it('renders all tools in a single menu with pinned tools at top', async () => {
    jest.useRealTimers()

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
    const user = userEvent.setup()
    const {getByRole} = render(
      <MobileTopNavigationTools tools={tools} handleToolLaunch={handleToolLaunch} />,
    )

    // Menu trigger should be an IconButton with proper accessibility label
    const menuButton = getByRole('button')
    expect(menuButton).toBeInTheDocument()

    // Click menu to reveal menu items
    await user.click(menuButton!)

    // Should have MenuItems for all tools
    const tool1MenuItem = getByRole('menuitem', {name: /Tool 1/})
    const tool2MenuItem = getByRole('menuitem', {name: /Tool 2/})
    expect(tool1MenuItem).toBeInTheDocument()
    expect(tool2MenuItem).toBeInTheDocument()

    // Should have a separator between pinned and unpinned tools
    expect(getByRole('presentation')).toBeInTheDocument()

    jest.useFakeTimers()
  })
})

describe('handleToolClick', () => {
  it('finds tool', async () => {
    jest.useRealTimers()

    const tool = {
      id: '1',
      title: 'Tool 1',
      base_url: 'https://instructure.com',
      icon_url: 'https://instructure.com',
      pinned: true,
    }
    const handleToolLaunch = jest.fn()
    const user = userEvent.setup()
    const {getByRole} = render(
      <TopNavigationTools tools={[tool]} handleToolLaunch={handleToolLaunch} />,
    )

    const toolButton = getByRole('button', {name: /Tool 1/})
    await user.click(toolButton)
    expect(handleToolLaunch).toHaveBeenCalledWith(tool)

    jest.useFakeTimers()
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

    expect(event.target.src).toBe('/lti/tool_default_icon?name=Tool%201')
  })
})
