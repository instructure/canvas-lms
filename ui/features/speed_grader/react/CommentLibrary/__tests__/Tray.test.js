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
  let setIsOpenMock, setShowSuggestionsMock, setRemovedItemIndexMock
  const defaultProps = (props = {}) => {
    return {
      isOpen: true,
      setIsOpen: setIsOpenMock,
      onItemClick: () => {},
      comments: [{_id: '1', comment: 'assignment comment'}],
      onDeleteComment: () => {},
      onAddComment: () => {},
      isAddingComment: false,
      showSuggestions: false,
      setShowSuggestions: setShowSuggestionsMock,
      updateComment: () => {},
      setRemovedItemIndex: setRemovedItemIndexMock,
      ...props,
    }
  }

  beforeEach(() => {
    setIsOpenMock = jest.fn()
    setShowSuggestionsMock = jest.fn()
    setRemovedItemIndexMock = jest.fn()
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

  it('focuses on the close button when deletedIndex is 0 and there are no more comments', () => {
    const {rerender, getByText} = render(<Tray {...defaultProps()} />)
    rerender(<Tray {...defaultProps({removedItemIndex: 0, comments: []})} />)
    expect(getByText('Close comment library').closest('button')).toHaveFocus()
  })

  describe('checkbox', () => {
    it('renders a checkbox as unchecked when showSuggestions is false', () => {
      const {getByLabelText} = render(<Tray {...defaultProps()} />)
      expect(getByLabelText('Show suggestions when typing')).not.toBeChecked()
    })

    it('renders a checkbox as checked when showSuggestions is true', () => {
      const {getByLabelText} = render(<Tray {...defaultProps({showSuggestions: true})} />)
      expect(getByLabelText('Show suggestions when typing')).toBeChecked()
    })

    it('calls setShowSuggestions when clicked', () => {
      const {getByLabelText} = render(<Tray {...defaultProps({showSuggestions: true})} />)
      fireEvent.click(getByLabelText('Show suggestions when typing'))
      expect(setShowSuggestionsMock).toHaveBeenCalled()
    })
  })

  it('calls setRemovedItemIndexMock after focus is set', () => {
    render(<Tray {...defaultProps({removedItemIndex: 0, comments: []})} />)
    expect(setRemovedItemIndexMock).toHaveBeenCalledWith(null)
  })
})
