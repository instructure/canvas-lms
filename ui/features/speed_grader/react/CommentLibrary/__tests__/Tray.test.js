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
import {render, fireEvent} from '@testing-library/react'
import Tray from '../Tray'

describe('Tray', () => {
  let setIsOpenMock
  const defaultProps = (props = {}) => {
    return {
      isOpen: true,
      setIsOpen: setIsOpenMock,
      onItemClick: () => {},
      comments: [{_id: '1', comment: 'assignment comment'}],
      ...props
    }
  }

  beforeEach(() => {
    setIsOpenMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders a header', () => {
    const {getByText} = render(<Tray {...defaultProps()} />)
    expect(getByText('Manage Comment Library')).toBeInTheDocument()
  })

  it('does not render the tray when isOpen is false', () => {
    const {queryByText} = render(<Tray {...defaultProps({isOpen: false})} />)
    expect(queryByText('Manage Comment Library')).not.toBeInTheDocument()
  })

  it('renders a checkbox', () => {
    const {getByLabelText} = render(<Tray {...defaultProps()} />)
    expect(getByLabelText('Show suggestions when typing').checked).toBe(true)
  })

  it('renders comments', () => {
    const {getByText} = render(<Tray {...defaultProps()} />)
    expect(getByText('assignment comment')).toBeInTheDocument()
  })

  it('renders a text area', () => {
    const {getByLabelText} = render(<Tray {...defaultProps()} />)
    expect(getByLabelText('Add comment to library')).toBeInTheDocument()
  })

  it('renders a "Close comment library" icon', () => {
    const {getByText} = render(<Tray {...defaultProps()} />)
    expect(getByText('Close comment library')).toBeInTheDocument()
  })

  it('calls setIsOpen when the close button is clicked', () => {
    const {getByText} = render(<Tray {...defaultProps()} />)
    fireEvent.click(getByText('Close comment library'))
    expect(setIsOpenMock).toHaveBeenCalledWith(false)
  })
})
