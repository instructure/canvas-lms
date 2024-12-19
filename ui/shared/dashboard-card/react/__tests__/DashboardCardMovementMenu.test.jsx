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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import DashboardCardMovementMenu from '../DashboardCardMovementMenu'

describe('DashboardCardMovementMenu', () => {
  const defaultProps = {
    assetString: 'course_1',
    cardTitle: 'Strategery 101',
    handleMove: jest.fn(),
    onUnfavorite: jest.fn(),
    isFavorited: true,
    menuOptions: {
      canMoveLeft: true,
      canMoveRight: true,
      canMoveToBeginning: true,
      canMoveToEnd: true,
    },
  }

  const renderMenu = (props = {}) => {
    return render(<DashboardCardMovementMenu {...defaultProps} {...props} />)
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('handleMoveCard', () => {
    it('calls handleMove with correct parameters', async () => {
      const user = userEvent.setup()
      renderMenu()

      const menu = screen.getByRole('menu', {name: 'Dashboard Card Movement Menu'})
      expect(menu).toBeInTheDocument()

      const moveDownOption = screen.getByRole('menuitem', {name: /Move down/})
      await user.click(moveDownOption)

      expect(defaultProps.handleMove).toHaveBeenCalledWith('course_1', 1)
      expect(defaultProps.handleMove).toHaveBeenCalledTimes(1)
    })
  })

  describe('onUnfavorite', () => {
    it('calls onUnfavorite when Unfavorite option is clicked', async () => {
      const user = userEvent.setup()
      renderMenu()

      const menu = screen.getByRole('menu', {name: 'Dashboard Card Movement Menu'})
      expect(menu).toBeInTheDocument()

      const unfavoriteOption = screen.getByRole('menuitem', {name: /Unfavorite/})
      await user.click(unfavoriteOption)

      expect(defaultProps.onUnfavorite).toHaveBeenCalledTimes(1)
    })
  })

  describe('isFavorited', () => {
    it('renders Unfavorite option when isFavorited is true', () => {
      renderMenu()
      const menu = screen.getByRole('menu', {name: 'Dashboard Card Movement Menu'})
      expect(menu).toBeInTheDocument()

      const unfavoriteOption = screen.getByRole('menuitem', {name: /Unfavorite/})
      expect(unfavoriteOption).toBeInTheDocument()
    })

    it('does not render Unfavorite option when isFavorited is false', () => {
      renderMenu({isFavorited: false})
      const menu = screen.getByRole('menu', {name: 'Dashboard Card Movement Menu'})
      expect(menu).toBeInTheDocument()

      const unfavoriteOption = screen.queryByRole('menuitem', {name: /Unfavorite/})
      expect(unfavoriteOption).not.toBeInTheDocument()
    })
  })
})
