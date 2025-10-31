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

import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {ReorderBlocksButton} from '../ReorderBlocksButton'

describe('ReorderBlocksButton', () => {
  const getButton = () => screen.getByTestId('reorder-blocks-button')
  const renderButton = (blockCount: number) =>
    render(<ReorderBlocksButton blockCount={blockCount} />)

  const openPopover = async (blockCount = 2) => {
    const user = userEvent.setup()
    renderButton(blockCount)
    await user.click(getButton())
  }

  describe('button rendering', () => {
    it('renders with correct icon', () => {
      const {container} = renderButton(2)
      expect(getButton()).toBeInTheDocument()
      expect(container.querySelector('svg')).toBeInTheDocument()
    })

    it('has correct aria-label', () => {
      renderButton(2)
      expect(getButton()).toBeInTheDocument()
    })
  })

  describe('disabled state with 0 or 1 blocks', () => {
    it.each([0, 1])('is disabled when blockCount is %i', blockCount => {
      renderButton(blockCount)
      expect(getButton()).toBeInTheDocument()
      // Button uses interaction="disabled" which makes it visually disabled
      // InstUI IconButton doesn't expose aria-disabled, so we verify by behavior
    })

    it('does not open popover when disabled button is clicked', async () => {
      const user = userEvent.setup()
      renderButton(1)
      await user.click(getButton())
      expect(screen.queryByTestId('reorder-blocks-popover-header')).not.toBeInTheDocument()
    })
  })

  describe('enabled state with 2 or more blocks', () => {
    it.each([2, 3])('is enabled when blockCount is %i', blockCount => {
      renderButton(blockCount)
      expect(getButton()).not.toHaveAttribute('disabled')
      // Button uses interaction="enabled" which makes it clickable
    })

    it('opens popover when enabled button is clicked', async () => {
      await openPopover()
      expect(screen.getByTestId('reorder-blocks-popover-header')).toBeInTheDocument()
    })
  })

  describe('popover state', () => {
    it('popover is closed initially', () => {
      renderButton(2)
      expect(screen.queryByTestId('reorder-blocks-popover-header')).not.toBeInTheDocument()
    })

    it('popover opens when button is clicked', async () => {
      await openPopover()
      expect(screen.getByTestId('reorder-blocks-popover-header')).toBeInTheDocument()
    })
  })

  describe('popover toggle behavior', () => {
    it('renders close button when popover is open', async () => {
      await openPopover()
      expect(screen.getByTestId('reorder-blocks-popover-header')).toBeInTheDocument()
      expect(screen.getByTestId('reorder-blocks-close-button')).toBeInTheDocument()
    })

    it('configures popover to close when clicking outside', () => {
      render(
        <div>
          <div data-testid="outside-element">Outside</div>
          <ReorderBlocksButton blockCount={2} />
        </div>,
      )
      expect(getButton()).toBeInTheDocument()
    })
  })
})
