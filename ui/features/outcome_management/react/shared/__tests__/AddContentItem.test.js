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
import AddContentItem from '../AddContentItem'

jest.useFakeTimers()

describe('AddContentItem', () => {
  let onSaveHandler
  const defaultProps = (props = {}) => ({
    labelInstructions: 'Create New Group',
    textInputInstructions: 'Enter new group name',
    showIcon: true,
    onSaveHandler,
    ...props
  })

  beforeEach(() => {
    onSaveHandler = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders component with labelInstructions', () => {
    const props = defaultProps()
    const {getByText} = render(<AddContentItem {...props} />)
    expect(getByText(props.labelInstructions)).toBeInTheDocument()
  })

  describe('when expanded', () => {
    it('renders textInputInstructions', () => {
      const props = defaultProps()
      const {getByText} = render(<AddContentItem {...props} />)
      fireEvent.click(getByText(props.labelInstructions))
      expect(getByText(props.textInputInstructions)).toBeInTheDocument()
    })

    it('renders a cancel button and disabled submit button', () => {
      const props = defaultProps()
      const {getByText} = render(<AddContentItem {...props} />)
      fireEvent.click(getByText(props.labelInstructions))
      expect(getByText('Cancel')).toBeInTheDocument()
      expect(getByText(props.textInputInstructions)).toBeInTheDocument()
      expect(getByText(props.labelInstructions).closest('button')).toHaveAttribute('disabled')
    })

    it('the submit button calls the onSaveHandler and resets the input field', () => {
      const props = defaultProps()
      const {getByText, getByLabelText, queryByText} = render(<AddContentItem {...props} />)
      fireEvent.click(getByText(props.labelInstructions))
      fireEvent.change(getByLabelText(props.textInputInstructions), {
        target: {value: 'new group name'}
      })
      fireEvent.click(getByText(props.labelInstructions))
      expect(onSaveHandler).toHaveBeenCalledWith('new group name')
      // confirm input field was reset
      fireEvent.click(getByText(props.labelInstructions))
      expect(queryByText('new group name')).not.toBeInTheDocument()
    })

    it('the cancel button hides the expanded view and resets the input field', () => {
      const props = defaultProps()
      const {getByText, getByLabelText, queryByText} = render(<AddContentItem {...props} />)
      fireEvent.click(getByText(props.labelInstructions))
      fireEvent.change(getByLabelText(props.textInputInstructions), {
        target: {value: 'new group name'}
      })
      fireEvent.click(getByText('Cancel'))
      expect(queryByText(props.textInputInstructions)).not.toBeInTheDocument()
      expect(onSaveHandler).not.toHaveBeenCalled()
      // confirm input field was reset
      fireEvent.click(getByText(props.labelInstructions))
      expect(queryByText('new group name')).not.toBeInTheDocument()
    })
  })
})
