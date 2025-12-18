/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {ColumnHeader} from '../ColumnHeader'
import {Menu} from '@instructure/ui-menu'

describe('ColumnHeader', () => {
  const defaultProps = {
    title: 'Test Column',
    optionsMenuTriggerLabel: 'Test Options',
    optionsMenuItems: [],
  }

  it('renders the title', () => {
    render(<ColumnHeader {...defaultProps} />)
    expect(screen.getByText('Test Column')).toBeInTheDocument()
  })

  it('does not render the options menu when no items are provided', () => {
    render(<ColumnHeader {...defaultProps} />)
    expect(screen.queryByRole('button', {name: 'Test Options'})).not.toBeInTheDocument()
  })

  it('renders the options menu trigger', () => {
    const menuItems = [<Menu.Item key="item-a">Item A</Menu.Item>]

    render(<ColumnHeader {...defaultProps} optionsMenuItems={menuItems} />)
    expect(screen.getByRole('button', {name: 'Test Options'})).toBeInTheDocument()
  })

  it('renders multiple menu groups correctly', async () => {
    const user = userEvent.setup({pointerEventsCheck: 0})

    const menuItems = [
      <Menu.Group key="group-1" label="Group 1">
        <Menu.Item>Item A</Menu.Item>
      </Menu.Group>,
      <Menu.Group key="group-2" label="Group 2">
        <Menu.Item>Item B</Menu.Item>
      </Menu.Group>,
    ]

    render(<ColumnHeader {...defaultProps} optionsMenuItems={menuItems} />)
    await user.click(screen.getByRole('button', {name: 'Test Options'}))

    expect(screen.getByText('Group 1')).toBeInTheDocument()
    expect(screen.getByText('Group 2')).toBeInTheDocument()
    expect(screen.getByText('Item A')).toBeInTheDocument()
    expect(screen.getByText('Item B')).toBeInTheDocument()
  })

  it('uses custom column width when provided', () => {
    const {container} = render(<ColumnHeader {...defaultProps} columnWidth={300} />)
    const headerElement = container.querySelector('[data-testid="column-header"]')
    expect(headerElement).toHaveStyle({width: '300px'})
  })
})
