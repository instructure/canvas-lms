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
import type {Widget, WidgetConfig} from '../../../types'

describe('WidgetContextMenu', () => {
  const mockWidget: Widget = {
    id: 'test-widget',
    type: 'test',
    position: {col: 1, row: 1, relative: 1},
    title: 'Test Widget',
  }

  const mockConfig: WidgetConfig = {
    columns: 2,
    widgets: [
      {
        id: 'test-widget',
        type: 'test',
        position: {col: 1, row: 1, relative: 1},
        title: 'Test Widget',
      },
      {
        id: 'other-widget',
        type: 'test',
        position: {col: 1, row: 2, relative: 2},
        title: 'Other Widget',
      },
      {
        id: 'right-widget',
        type: 'test',
        position: {col: 2, row: 1, relative: 3},
        title: 'Right Widget',
      },
    ],
  }

  const buildDefaultProps = (overrides = {}) => {
    return {
      trigger: (
        <IconButton screenReaderLabel="Reorder Test Widget" data-testid="menu-trigger">
          <IconDragHandleLine />
        </IconButton>
      ),
      widget: mockWidget,
      config: mockConfig,
      isStacked: false,
      onSelect: vi.fn(),
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
    expect(screen.getByText('Move left top')).toBeInTheDocument()
    expect(screen.getByText('Move left bottom')).toBeInTheDocument()
    expect(screen.getByText('Move right top')).toBeInTheDocument()
    expect(screen.getByText('Move right bottom')).toBeInTheDocument()
  })

  it('calls onSelect with "move-left" when Move left bottom is clicked', async () => {
    const user = userEvent.setup()
    const onSelect = vi.fn()
    setup(
      buildDefaultProps({
        widget: {
          id: 'right-widget',
          type: 'test',
          position: {col: 2, row: 1, relative: 3},
          title: 'Right Widget',
        },
        onSelect,
      }),
    )

    await user.click(screen.getByTestId('menu-trigger'))
    await user.click(screen.getByText('Move left bottom'))

    expect(onSelect).toHaveBeenCalledWith('move-left')
  })

  it('calls onSelect with "move-right" when Move right bottom is clicked', async () => {
    const user = userEvent.setup()
    const onSelect = vi.fn()
    setup(buildDefaultProps({onSelect}))

    await user.click(screen.getByTestId('menu-trigger'))
    await user.click(screen.getByText('Move right bottom'))

    expect(onSelect).toHaveBeenCalledWith('move-right')
  })

  it('calls onSelect with "move-left-top" when Move left top is clicked', async () => {
    const user = userEvent.setup()
    const onSelect = vi.fn()
    setup(
      buildDefaultProps({
        widget: {
          id: 'right-widget',
          type: 'test',
          position: {col: 2, row: 1, relative: 3},
          title: 'Right Widget',
        },
        onSelect,
      }),
    )

    await user.click(screen.getByTestId('menu-trigger'))
    await user.click(screen.getByText('Move left top'))

    expect(onSelect).toHaveBeenCalledWith('move-left-top')
  })

  it('calls onSelect with "move-right-top" when Move right top is clicked', async () => {
    const user = userEvent.setup()
    const onSelect = vi.fn()
    setup(buildDefaultProps({onSelect}))

    await user.click(screen.getByTestId('menu-trigger'))
    await user.click(screen.getByText('Move right top'))

    expect(onSelect).toHaveBeenCalledWith('move-right-top')
  })

  it('calls onSelect with "move-to-top" when Move to top is clicked', async () => {
    const user = userEvent.setup()
    const onSelect = vi.fn()
    setup(
      buildDefaultProps({
        widget: {
          id: 'other-widget',
          type: 'test',
          position: {col: 1, row: 2, relative: 2},
          title: 'Other Widget',
        },
        onSelect,
      }),
    )

    await user.click(screen.getByTestId('menu-trigger'))
    await user.click(screen.getByText('Move to top'))

    expect(onSelect).toHaveBeenCalledWith('move-to-top')
  })

  it('calls onSelect with "move-up" when Move up is clicked', async () => {
    const user = userEvent.setup()
    const onSelect = vi.fn()
    setup(
      buildDefaultProps({
        widget: {
          id: 'other-widget',
          type: 'test',
          position: {col: 1, row: 2, relative: 2},
          title: 'Other Widget',
        },
        onSelect,
      }),
    )

    await user.click(screen.getByTestId('menu-trigger'))
    await user.click(screen.getByText('Move up'))

    expect(onSelect).toHaveBeenCalledWith('move-up')
  })

  it('calls onSelect with "move-down" when Move down is clicked', async () => {
    const user = userEvent.setup()
    const onSelect = vi.fn()
    setup(buildDefaultProps({onSelect}))

    await user.click(screen.getByTestId('menu-trigger'))
    await user.click(screen.getByText('Move down'))

    expect(onSelect).toHaveBeenCalledWith('move-down')
  })

  it('calls onSelect with "move-to-bottom" when Move to bottom is clicked', async () => {
    const user = userEvent.setup()
    const onSelect = vi.fn()
    setup(buildDefaultProps({onSelect}))

    await user.click(screen.getByTestId('menu-trigger'))
    await user.click(screen.getByText('Move to bottom'))

    expect(onSelect).toHaveBeenCalledWith('move-to-bottom')
  })

  it('does not call onSelect if onSelect prop is not provided', async () => {
    const user = userEvent.setup()
    setup(
      buildDefaultProps({
        widget: {
          id: 'other-widget',
          type: 'test',
          position: {col: 1, row: 2, relative: 2},
          title: 'Other Widget',
        },
        onSelect: undefined,
      }),
    )

    await user.click(screen.getByTestId('menu-trigger'))
    await user.click(screen.getByText('Move to top'))
  })

  it('disables Move left top and Move left bottom when widget is in left column', async () => {
    const user = userEvent.setup()
    const onSelect = vi.fn()
    setup(
      buildDefaultProps({
        widget: {...mockWidget, position: {col: 1, row: 1, relative: 1}},
        onSelect,
      }),
    )

    await user.click(screen.getByTestId('menu-trigger'))

    expect(screen.getByText('Move left top')).toBeInTheDocument()
    expect(screen.getByText('Move left bottom')).toBeInTheDocument()

    await expect(user.click(screen.getByText('Move left top'))).rejects.toThrow()
    await expect(user.click(screen.getByText('Move left bottom'))).rejects.toThrow()
    expect(onSelect).not.toHaveBeenCalledWith('move-left-top')
    expect(onSelect).not.toHaveBeenCalledWith('move-left')
  })

  it('disables Move right top and Move right bottom when widget is in right column', async () => {
    const user = userEvent.setup()
    const onSelect = vi.fn()
    setup(
      buildDefaultProps({
        widget: {...mockWidget, position: {col: 2, row: 1, relative: 1}},
        onSelect,
      }),
    )

    await user.click(screen.getByTestId('menu-trigger'))

    expect(screen.getByText('Move right top')).toBeInTheDocument()
    expect(screen.getByText('Move right bottom')).toBeInTheDocument()

    await expect(user.click(screen.getByText('Move right top'))).rejects.toThrow()
    await expect(user.click(screen.getByText('Move right bottom'))).rejects.toThrow()
    expect(onSelect).not.toHaveBeenCalledWith('move-right-top')
    expect(onSelect).not.toHaveBeenCalledWith('move-right')
  })

  it('disables Move up and Move to top when widget is first in column', async () => {
    const user = userEvent.setup()
    const onSelect = vi.fn()
    setup(
      buildDefaultProps({
        widget: {...mockWidget, position: {col: 1, row: 1, relative: 1}},
        onSelect,
      }),
    )

    await user.click(screen.getByTestId('menu-trigger'))

    expect(screen.getByText('Move up')).toBeInTheDocument()
    expect(screen.getByText('Move to top')).toBeInTheDocument()

    await expect(user.click(screen.getByText('Move up'))).rejects.toThrow()
    await expect(user.click(screen.getByText('Move to top'))).rejects.toThrow()

    expect(onSelect).not.toHaveBeenCalledWith('move-up')
    expect(onSelect).not.toHaveBeenCalledWith('move-to-top')
  })

  it('disables Move down and Move to bottom when widget is last in column', async () => {
    const user = userEvent.setup()
    const onSelect = vi.fn()
    const lastWidget = {
      id: 'other-widget',
      type: 'test',
      position: {col: 1, row: 2, relative: 2},
      title: 'Last Widget',
    }
    setup(
      buildDefaultProps({
        widget: lastWidget,
        onSelect,
      }),
    )

    await user.click(screen.getByTestId('menu-trigger'))

    expect(screen.getByText('Move down')).toBeInTheDocument()
    expect(screen.getByText('Move to bottom')).toBeInTheDocument()

    await expect(user.click(screen.getByText('Move down'))).rejects.toThrow()
    await expect(user.click(screen.getByText('Move to bottom'))).rejects.toThrow()

    expect(onSelect).not.toHaveBeenCalledWith('move-down')
    expect(onSelect).not.toHaveBeenCalledWith('move-to-bottom')
  })

  describe('Stacked mode (mobile/tablet)', () => {
    it('only shows Move up and Move down options', async () => {
      const user = userEvent.setup()
      setup(buildDefaultProps({isStacked: true}))

      await user.click(screen.getByTestId('menu-trigger'))

      expect(screen.getByText('Move up')).toBeInTheDocument()
      expect(screen.getByText('Move down')).toBeInTheDocument()
      expect(screen.queryByText('Move to top')).not.toBeInTheDocument()
      expect(screen.queryByText('Move to bottom')).not.toBeInTheDocument()
      expect(screen.queryByText('Move left top')).not.toBeInTheDocument()
      expect(screen.queryByText('Move left bottom')).not.toBeInTheDocument()
      expect(screen.queryByText('Move right top')).not.toBeInTheDocument()
      expect(screen.queryByText('Move right bottom')).not.toBeInTheDocument()
    })

    it('disables Move up for first widget in left column', async () => {
      const user = userEvent.setup()
      const onSelect = vi.fn()
      setup(
        buildDefaultProps({
          isStacked: true,
          widget: mockWidget,
          onSelect,
        }),
      )

      await user.click(screen.getByTestId('menu-trigger'))
      await expect(user.click(screen.getByText('Move up'))).rejects.toThrow()
      expect(onSelect).not.toHaveBeenCalled()
    })

    it('disables Move down for last widget in right column', async () => {
      const user = userEvent.setup()
      const onSelect = vi.fn()
      setup(
        buildDefaultProps({
          isStacked: true,
          widget: {
            id: 'right-widget',
            type: 'test',
            position: {col: 2, row: 1, relative: 3},
            title: 'Right Widget',
          },
          onSelect,
        }),
      )

      await user.click(screen.getByTestId('menu-trigger'))
      await expect(user.click(screen.getByText('Move down'))).rejects.toThrow()
      expect(onSelect).not.toHaveBeenCalled()
    })

    it('fires move-up-cross when moving up from top of right column', async () => {
      const user = userEvent.setup()
      const onSelect = vi.fn()
      setup(
        buildDefaultProps({
          isStacked: true,
          widget: {
            id: 'right-widget',
            type: 'test',
            position: {col: 2, row: 1, relative: 3},
            title: 'Right Widget',
          },
          onSelect,
        }),
      )

      await user.click(screen.getByTestId('menu-trigger'))
      await user.click(screen.getByText('Move up'))

      expect(onSelect).toHaveBeenCalledWith('move-up-cross')
    })

    it('fires move-down-cross when moving down from bottom of left column', async () => {
      const user = userEvent.setup()
      const onSelect = vi.fn()
      setup(
        buildDefaultProps({
          isStacked: true,
          widget: {
            id: 'other-widget',
            type: 'test',
            position: {col: 1, row: 2, relative: 2},
            title: 'Other Widget',
          },
          onSelect,
        }),
      )

      await user.click(screen.getByTestId('menu-trigger'))
      await user.click(screen.getByText('Move down'))

      expect(onSelect).toHaveBeenCalledWith('move-down-cross')
    })

    it('fires normal move-up within a column', async () => {
      const user = userEvent.setup()
      const onSelect = vi.fn()
      setup(
        buildDefaultProps({
          isStacked: true,
          widget: {
            id: 'other-widget',
            type: 'test',
            position: {col: 1, row: 2, relative: 2},
            title: 'Other Widget',
          },
          onSelect,
        }),
      )

      await user.click(screen.getByTestId('menu-trigger'))
      await user.click(screen.getByText('Move up'))

      expect(onSelect).toHaveBeenCalledWith('move-up')
    })

    it('fires normal move-down within a column', async () => {
      const user = userEvent.setup()
      const onSelect = vi.fn()
      setup(buildDefaultProps({isStacked: true, onSelect}))

      await user.click(screen.getByTestId('menu-trigger'))
      await user.click(screen.getByText('Move down'))

      expect(onSelect).toHaveBeenCalledWith('move-down')
    })
  })
})
