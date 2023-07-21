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
import TrayTextArea from '../TrayTextArea'

describe('TrayTextArea', () => {
  let onAddMock
  const defaultProps = (props = {}) => {
    return {
      isAdding: false,
      onAdd: onAddMock,
      ...props,
    }
  }

  beforeEach(() => {
    onAddMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the text area with a placeholder', () => {
    const {getByPlaceholderText} = render(<TrayTextArea {...defaultProps()} />)
    expect(getByPlaceholderText('Write something...')).toBeInTheDocument()
  })

  it('renders a submit button that is initially disabled', () => {
    const {getByText} = render(<TrayTextArea {...defaultProps()} />)
    expect(getByText('Add to Library').closest('button')).toBeDisabled()
  })

  it('enables the button when text is entered', () => {
    const {getByText, getByLabelText} = render(<TrayTextArea {...defaultProps()} />)
    const input = getByLabelText('Add comment to library')
    fireEvent.change(input, {target: {value: 'test comment'}})
    expect(getByText('Add to Library').closest('button')).not.toBeDisabled()
  })

  it('calls onAdd when the button is clicked', () => {
    const {getByText, getByLabelText} = render(<TrayTextArea {...defaultProps()} />)
    const input = getByLabelText('Add comment to library')
    fireEvent.change(input, {target: {value: 'test comment'}})
    fireEvent.click(getByText('Add to Library'))
    expect(onAddMock).toHaveBeenCalledWith('test comment')
  })

  describe('when isAdding is true', () => {
    it('updates the button text and disables it', () => {
      const {getByText, getByLabelText, rerender} = render(<TrayTextArea {...defaultProps()} />)
      const input = getByLabelText('Add comment to library')
      fireEvent.change(input, {target: {value: 'test comment'}})
      rerender(<TrayTextArea {...defaultProps({isAdding: true})} />)
      expect(getByText('Adding to Library').closest('button')).toBeDisabled()
    })

    it('focuses on the text input and clears the input after isAdding changes to false', () => {
      const {getByLabelText, rerender} = render(
        <TrayTextArea {...defaultProps({isAdding: true})} />
      )
      const input = getByLabelText('Add comment to library')
      fireEvent.change(input, {target: {value: 'test comment'}})
      rerender(<TrayTextArea {...defaultProps({isAdding: false})} />)
      expect(input).toHaveFocus()
      expect(input).toHaveValue('')
    })
  })
})
