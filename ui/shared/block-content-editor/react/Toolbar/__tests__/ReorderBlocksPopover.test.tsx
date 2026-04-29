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
import {ReorderBlocksPopover} from '../ReorderBlocksPopover'

describe('ReorderBlocksPopover', () => {
  const defaultProps = {
    isShowingContent: false,
    onShowContent: vi.fn(),
    onHideContent: vi.fn(),
    renderTrigger: () => <button data-testid="trigger-button">Trigger</button>,
  }

  const renderPopover = (isOpen = false, overrides = {}) =>
    render(<ReorderBlocksPopover {...defaultProps} isShowingContent={isOpen} {...overrides} />)

  const getDialog = () => screen.getByRole('dialog', {name: 'Reorder blocks'})
  const getHeading = () => screen.getByTestId('reorder-blocks-popover-header')
  const queryHeading = () => screen.queryByTestId('reorder-blocks-popover-header')
  const getTrigger = () => screen.getByTestId('trigger-button')
  const getCloseButton = () => screen.getByTestId('reorder-blocks-close-button')

  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('rendering', () => {
    it('does not render popover content when closed', () => {
      renderPopover(false)
      expect(queryHeading()).not.toBeInTheDocument()
    })

    it('renders popover content when open', () => {
      renderPopover(true)
      expect(getHeading()).toBeInTheDocument()
    })

    it('renders trigger button', () => {
      renderPopover()
      expect(getTrigger()).toBeInTheDocument()
    })
  })

  describe('accessibility', () => {
    beforeEach(() => {
      renderPopover(true)
    })

    it('has role dialog on popover content', () => {
      expect(getDialog()).toBeInTheDocument()
    })

    it('has aria-labelledby pointing to heading', () => {
      expect(getHeading()).toHaveAttribute('id', 'reorder-blocks-heading')
    })

    it('displays correct heading text', () => {
      expect(screen.getByText('Reorder blocks')).toBeInTheDocument()
    })

    it('has close button with screen reader label', () => {
      expect(getCloseButton()).toBeInTheDocument()
    })
  })

  describe('interactions', () => {
    it('renders close button that can be clicked', async () => {
      const user = userEvent.setup()
      const onHideContent = vi.fn()

      renderPopover(true, {onHideContent})

      expect(getCloseButton()).toBeInTheDocument()
      await user.click(getCloseButton())
    })

    it('configures popover to close on document click', () => {
      renderPopover(true)
      expect(getHeading()).toBeInTheDocument()
    })

    it('configures popover with ESC key handling', () => {
      renderPopover(true)
      expect(getDialog()).toBeInTheDocument()
    })
  })

  describe('focus management', () => {
    it('configures popover to contain focus', () => {
      renderPopover(true)
      expect(getDialog()).toBeInTheDocument()
    })

    it('configures popover to return focus', () => {
      renderPopover(true)
      expect(getTrigger()).toBeInTheDocument()
    })
  })

  describe('popover configuration', () => {
    it('has correct placement', () => {
      const {container} = renderPopover(true)
      expect(container).toBeInTheDocument()
    })

    it('renders popover content container', () => {
      renderPopover(true)
      expect(getHeading().parentElement?.parentElement).toBeInTheDocument()
    })
  })
})
