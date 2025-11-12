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
import {IconButton} from '@instructure/ui-buttons'
import {IconDragHandleLine} from '@instructure/ui-icons'
import WidgetContextMenu from '../WidgetContextMenu'

describe('WidgetContextMenu', () => {
  const buildDefaultProps = (overrides = {}) => {
    return {
      trigger: (
        <IconButton screenReaderLabel="Drag to reorder widget" data-testid="menu-trigger">
          <IconDragHandleLine />
        </IconButton>
      ),
      onSelect: jest.fn(),
      ...overrides,
    }
  }

  const setup = (props = buildDefaultProps()) => {
    return render(<WidgetContextMenu {...props} />)
  }

  it('renders the trigger button', () => {
    setup()
    expect(screen.getByTestId('menu-trigger')).toBeInTheDocument()
  })

  it('shows menu items when trigger is clicked', async () => {
    const user = userEvent.setup()
    setup()

    await user.click(screen.getByTestId('menu-trigger'))

    expect(screen.getByText('Move to top')).toBeInTheDocument()
    expect(screen.getByText('Move up')).toBeInTheDocument()
    expect(screen.getByText('Move down')).toBeInTheDocument()
    expect(screen.getByText('Move to bottom')).toBeInTheDocument()
  })

  it('calls onSelect with "move-to-top" when Move to top is clicked', async () => {
    const user = userEvent.setup()
    const onSelect = jest.fn()
    setup(buildDefaultProps({onSelect}))

    await user.click(screen.getByTestId('menu-trigger'))
    await user.click(screen.getByText('Move to top'))

    expect(onSelect).toHaveBeenCalledWith('move-to-top')
  })

  it('calls onSelect with "move-up" when Move up is clicked', async () => {
    const user = userEvent.setup()
    const onSelect = jest.fn()
    setup(buildDefaultProps({onSelect}))

    await user.click(screen.getByTestId('menu-trigger'))
    await user.click(screen.getByText('Move up'))

    expect(onSelect).toHaveBeenCalledWith('move-up')
  })

  it('calls onSelect with "move-down" when Move down is clicked', async () => {
    const user = userEvent.setup()
    const onSelect = jest.fn()
    setup(buildDefaultProps({onSelect}))

    await user.click(screen.getByTestId('menu-trigger'))
    await user.click(screen.getByText('Move down'))

    expect(onSelect).toHaveBeenCalledWith('move-down')
  })

  it('calls onSelect with "move-to-bottom" when Move to bottom is clicked', async () => {
    const user = userEvent.setup()
    const onSelect = jest.fn()
    setup(buildDefaultProps({onSelect}))

    await user.click(screen.getByTestId('menu-trigger'))
    await user.click(screen.getByText('Move to bottom'))

    expect(onSelect).toHaveBeenCalledWith('move-to-bottom')
  })

  it('does not call onSelect if onSelect prop is not provided', async () => {
    const user = userEvent.setup()
    setup(buildDefaultProps({onSelect: undefined}))

    await user.click(screen.getByTestId('menu-trigger'))
    await user.click(screen.getByText('Move to top'))
  })
})
