/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import {merge} from 'lodash'
import OutcomeKebabMenu from '../OutcomeKebabMenu'

describe('OutcomeKebabMenu', () => {
  let onMenuHandlerMock
  const groupMenuTitle = 'Outcome Group Menu'
  const defaultMenuTitle = 'Menu'
  const defaultProps = (props = {}) =>
    merge(
      {
        menuTitle: groupMenuTitle,
        onMenuHandler: onMenuHandlerMock,
        canDestroy: true
      },
      props
    )

  beforeEach(() => {
    onMenuHandlerMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders Kebab menu with custom menu title for screen readers if menuTitle prop provided', () => {
    const {getByText} = render(<OutcomeKebabMenu {...defaultProps()} />)
    expect(getByText(groupMenuTitle)).toBeInTheDocument()
  })

  it('renders Kebab menu with default menu title for screen readers if menuTitle prop missing', () => {
    const {getByText} = render(<OutcomeKebabMenu {...defaultProps({menuTitle: null})} />)
    expect(getByText(defaultMenuTitle)).toBeInTheDocument()
  })

  it('renders Kebab menu when menu button clicked', () => {
    const {getByText} = render(<OutcomeKebabMenu {...defaultProps()} />)
    const menuButton = getByText(groupMenuTitle)
    fireEvent.click(menuButton)
    expect(getByText('Edit')).toBeInTheDocument()
    expect(getByText('Remove')).toBeInTheDocument()
    expect(getByText('Move')).toBeInTheDocument()
  })

  describe('with Kebab menu open', () => {
    it('handles click on Edit item', () => {
      const {getByText} = render(<OutcomeKebabMenu {...defaultProps()} />)
      const menuButton = getByText(groupMenuTitle)
      fireEvent.click(menuButton)
      const menuItem = getByText('Edit')
      fireEvent.click(menuItem)
      expect(onMenuHandlerMock).toHaveBeenCalledTimes(1)
      expect(onMenuHandlerMock.mock.calls[0][1]).toBe('edit')
    })

    it('handles click on Remove item', () => {
      const {getByText} = render(<OutcomeKebabMenu {...defaultProps()} />)
      const menuButton = getByText(groupMenuTitle)
      fireEvent.click(menuButton)
      const menuItem = getByText('Remove')
      fireEvent.click(menuItem)
      expect(onMenuHandlerMock).toHaveBeenCalledTimes(1)
      expect(onMenuHandlerMock.mock.calls[0][1]).toBe('remove')
    })

    it('handles click on Move item', () => {
      const {getByText} = render(<OutcomeKebabMenu {...defaultProps()} />)
      const menuButton = getByText(groupMenuTitle)
      fireEvent.click(menuButton)
      const menuItem = getByText('Move')
      fireEvent.click(menuItem)
      expect(onMenuHandlerMock).toHaveBeenCalledTimes(1)
      expect(onMenuHandlerMock.mock.calls[0][1]).toBe('move')
    })

    it('does not call menuHandler if canDestroy is false', () => {
      const {getByText} = render(<OutcomeKebabMenu {...defaultProps({canDestroy: false})} />)
      const menuButton = getByText(groupMenuTitle)
      fireEvent.click(menuButton)
      const menuItem = getByText('Remove')
      fireEvent.click(menuItem)
      expect(onMenuHandlerMock).toHaveBeenCalledTimes(0)
    })
  })
})
