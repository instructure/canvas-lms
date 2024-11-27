/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {render, screen, fireEvent} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import {ActionDropDown, type ActionObject} from '../ActionDropDown'
import {IconTrashLine, IconLockLine} from '@instructure/ui-icons'

describe('ActionDropDown', () => {
  const MORE_BUTTON_LABEL = 'More Actions'
  const MORE_BUTTON_TEST_ID = 'action-dropdown-button'
  const actions: ActionObject[] = [
    {
      label: 'Delete',
      screenReaderLabel: 'Delete Item',
      icon: IconTrashLine,
      action: jest.fn(),
      disabled: false,
    },
    {
      label: 'Lock',
      screenReaderLabel: 'Lock Item',
      icon: IconLockLine,
      action: jest.fn(),
      disabled: true,
    },
  ]

  const renderDropDown = (props = {}) => {
    render(<ActionDropDown label={MORE_BUTTON_LABEL} actions={actions} {...props} />)
  }

  it('renders the button with label', () => {
    renderDropDown()
    const button = screen.getByTestId(MORE_BUTTON_TEST_ID)
    expect(button).toBeInTheDocument()
  })

  it('opens the dropdown menu when button is clicked', () => {
    renderDropDown()
    const button = screen.getByTestId(MORE_BUTTON_TEST_ID)
    fireEvent.click(button)
    const deleteItem = screen.getByTestId('action-dropdown-item-Delete')
    expect(deleteItem).toBeInTheDocument()
  })

  it('renders the correct actions with icons and labels', () => {
    renderDropDown()
    const button = screen.getByTestId(MORE_BUTTON_TEST_ID)
    fireEvent.click(button)
    const deleteItem = screen.getByTestId('action-dropdown-item-Delete')
    const lockItem = screen.getByTestId('action-dropdown-item-Lock')
    expect(deleteItem).toBeInTheDocument()
    expect(lockItem).toBeInTheDocument()
  })

  it('calls the correct action when an action is clicked', () => {
    renderDropDown()
    const button = screen.getByTestId(MORE_BUTTON_TEST_ID)
    fireEvent.click(button)
    const deleteItem = screen.getByTestId('action-dropdown-item-Delete')
    fireEvent.click(deleteItem)
    expect(actions[0].action).toHaveBeenCalled()
  })

  it('disables the correct actions', () => {
    renderDropDown()
    const button = screen.getByTestId(MORE_BUTTON_TEST_ID)
    fireEvent.click(button)
    const lockItem = screen.getByTestId('action-dropdown-item-Lock')
    expect(lockItem).toHaveAttribute('aria-disabled', 'true')
  })

  it('disabled all based on property', () => {
    renderDropDown({disabled: true})
    const button = screen.getByTestId(MORE_BUTTON_TEST_ID)
    expect(button).toBeDisabled()
  })
})
