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
import {TopNavigationTools, MobileTopNavigationTools} from '../TopNavigationTools'

describe('TopNavigationTools', () => {
  it('renders', () => {
    const tools = [
      {
        id: '1',
        title: 'Tool 1',
        icon_url: 'https://instructure.com',
        pinned: true,
      },
      {
        id: '2',
        title: 'Tool 2',
        pinned: false,
      },
    ]
    const handleToolLaunch = jest.fn()
    const wrapper = shallow(
      <TopNavigationTools tools={tools} handleToolLaunch={handleToolLaunch} />
    )
    expect(wrapper).toMatchSnapshot()
  })

  it('renders with no tools', () => {
    const tools = []
    const handleToolLaunch = jest.fn()
    const wrapper = shallow(
      <TopNavigationTools tools={tools} handleToolLaunch={handleToolLaunch} />
    )
    expect(wrapper).toMatchSnapshot()
  })

  it('renders with no pinned tools', () => {
    const tools = [
      {
        id: '1',
        title: 'Tool 1',
        icon_url: 'https://instructure.com',
        pinned: false,
      },
      {
        id: '2',
        title: 'Tool 2',
        icon_url: 'https://instructure.com',
        pinned: false,
      },
    ]
    const handleToolLaunch = jest.fn()
    const wrapper = shallow(
      <TopNavigationTools tools={tools} handleToolLaunch={handleToolLaunch} />
    )
    expect(wrapper).toMatchSnapshot()
  })
})

describe('MobileTopNavigationTools', () => {
  it('renders', () => {
    const tools = [
      {
        id: '1',
        title: 'Tool 1',
        icon_url: 'https://instructure.com',
        pinned: false,
      },
      {
        id: '2',
        title: 'Tool 2',
        icon_url: 'https://instructure.com',
        pinned: true,
      },
    ]
    const handleToolLaunch = jest.fn()
    const wrapper = shallow(
      <MobileTopNavigationTools tools={tools} handleToolLaunch={handleToolLaunch} />
    )
    expect(wrapper).toMatchSnapshot()
  })
})

describe('handleToolClick', () => {
  it('finds tool', () => {
    const tool = {
      id: '1',
      title: 'Tool 1',
      icon_url: 'https://instructure.com',
      pinned: true,
    }
    const handleToolLaunch = jest.fn()
    const wrapper = shallow(
      <TopNavigationTools tools={[tool]} handleToolLaunch={handleToolLaunch} />
    )
    wrapper.find('IconButton').simulate('click', {target: {dataset: {toolId: '1'}}})
    expect(handleToolLaunch).toHaveBeenCalledWith(tool)
  })
})
