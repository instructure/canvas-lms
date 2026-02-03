/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {CriterionRowPopover} from '../CriterionRowPopover'

describe('CriterionRowPopover', () => {
  const defaultProps = {
    isFirstIndex: false,
    isLastIndex: false,
    onMoveUp: vi.fn(),
    onMoveDown: vi.fn(),
  }

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('renders the popover trigger button', () => {
    const {getByTestId} = render(<CriterionRowPopover {...defaultProps} />)
    expect(getByTestId('criterion-options-popover')).toBeInTheDocument()
  })

  it('opens the menu when trigger button is clicked', async () => {
    const user = userEvent.setup()
    const {getByTestId, queryByTestId} = render(<CriterionRowPopover {...defaultProps} />)

    expect(queryByTestId('move-up-criterion-menu-item')).not.toBeInTheDocument()

    await user.click(getByTestId('criterion-options-popover'))

    await waitFor(() => {
      expect(queryByTestId('move-up-criterion-menu-item')).toBeInTheDocument()
      expect(queryByTestId('move-down-criterion-menu-item')).toBeInTheDocument()
    })
  })

  it('calls onMoveUp when Move Up is clicked', async () => {
    const user = userEvent.setup()
    const onMoveUp = vi.fn()
    const {getByTestId} = render(<CriterionRowPopover {...defaultProps} onMoveUp={onMoveUp} />)

    await user.click(getByTestId('criterion-options-popover'))

    await waitFor(() => {
      expect(getByTestId('move-up-criterion-menu-item')).toBeInTheDocument()
    })

    await user.click(getByTestId('move-up-criterion-menu-item'))

    expect(onMoveUp).toHaveBeenCalledTimes(1)
  })

  it('calls onMoveDown when Move Down is clicked', async () => {
    const user = userEvent.setup()
    const onMoveDown = vi.fn()
    const {getByTestId} = render(<CriterionRowPopover {...defaultProps} onMoveDown={onMoveDown} />)

    await user.click(getByTestId('criterion-options-popover'))

    await waitFor(() => {
      expect(getByTestId('move-down-criterion-menu-item')).toBeInTheDocument()
    })

    await user.click(getByTestId('move-down-criterion-menu-item'))

    expect(onMoveDown).toHaveBeenCalledTimes(1)
  })

  it('closes the popover after Move Up is clicked', async () => {
    const user = userEvent.setup()
    const {getByTestId, queryByTestId} = render(<CriterionRowPopover {...defaultProps} />)

    await user.click(getByTestId('criterion-options-popover'))

    await waitFor(() => {
      expect(queryByTestId('move-up-criterion-menu-item')).toBeInTheDocument()
    })

    await user.click(getByTestId('move-up-criterion-menu-item'))

    await waitFor(() => {
      expect(queryByTestId('move-up-criterion-menu-item')).not.toBeInTheDocument()
    })
  })

  it('closes the popover after Move Down is clicked', async () => {
    const user = userEvent.setup()
    const {getByTestId, queryByTestId} = render(<CriterionRowPopover {...defaultProps} />)

    await user.click(getByTestId('criterion-options-popover'))

    await waitFor(() => {
      expect(queryByTestId('move-down-criterion-menu-item')).toBeInTheDocument()
    })

    await user.click(getByTestId('move-down-criterion-menu-item'))

    await waitFor(() => {
      expect(queryByTestId('move-down-criterion-menu-item')).not.toBeInTheDocument()
    })
  })

  it('disables Move Up when isFirstIndex is true', async () => {
    const user = userEvent.setup()
    const {getByTestId} = render(<CriterionRowPopover {...defaultProps} isFirstIndex={true} />)

    await user.click(getByTestId('criterion-options-popover'))

    await waitFor(() => {
      const moveUpItem = getByTestId('move-up-criterion-menu-item')
      expect(moveUpItem).toBeInTheDocument()
      expect(moveUpItem.closest('button')).toHaveAttribute('aria-disabled', 'true')
    })
  })

  it('disables Move Down when isLastIndex is true', async () => {
    const user = userEvent.setup()
    const {getByTestId} = render(<CriterionRowPopover {...defaultProps} isLastIndex={true} />)

    await user.click(getByTestId('criterion-options-popover'))

    await waitFor(() => {
      const moveDownItem = getByTestId('move-down-criterion-menu-item')
      expect(moveDownItem).toBeInTheDocument()
      expect(moveDownItem.closest('button')).toHaveAttribute('aria-disabled', 'true')
    })
  })

  it('Move Up button is not clickable when disabled', async () => {
    const user = userEvent.setup()
    const onMoveUp = vi.fn()
    const {getByTestId} = render(
      <CriterionRowPopover {...defaultProps} isFirstIndex={true} onMoveUp={onMoveUp} />,
    )

    await user.click(getByTestId('criterion-options-popover'))

    await waitFor(() => {
      const moveUpItem = getByTestId('move-up-criterion-menu-item')
      expect(moveUpItem).toBeInTheDocument()
      const button = moveUpItem.closest('button')
      expect(button).toHaveAttribute('aria-disabled', 'true')
    })

    expect(onMoveUp).not.toHaveBeenCalled()
  })

  it('Move Down button is not clickable when disabled', async () => {
    const user = userEvent.setup()
    const onMoveDown = vi.fn()
    const {getByTestId} = render(
      <CriterionRowPopover {...defaultProps} isLastIndex={true} onMoveDown={onMoveDown} />,
    )

    await user.click(getByTestId('criterion-options-popover'))

    await waitFor(() => {
      const moveDownItem = getByTestId('move-down-criterion-menu-item')
      expect(moveDownItem).toBeInTheDocument()
      const button = moveDownItem.closest('button')
      expect(button).toHaveAttribute('aria-disabled', 'true')
    })

    expect(onMoveDown).not.toHaveBeenCalled()
  })
})
