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
import FindOutcomeItem from '../FindOutcomeItem'

jest.useFakeTimers()

describe('FindOutcomeItem', () => {
  let onMenuHandlerMock
  let onAddOutcomeHandlerMock
  const defaultProps = (props = {}) => ({
    id: '1',
    title: 'Outcome Title',
    description: 'Outcome Description',
    isAdded: false,
    onMenuHandler: onMenuHandlerMock,
    onAddOutcomeHandler: onAddOutcomeHandlerMock,
    ...props
  })

  beforeEach(() => {
    onMenuHandlerMock = jest.fn()
    onAddOutcomeHandlerMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders title if title prop passed', () => {
    const {getByText} = render(<FindOutcomeItem {...defaultProps()} />)
    expect(getByText('Outcome Title')).toBeInTheDocument()
  })

  it('does not render component if title prop not passed', () => {
    const {queryByTestId} = render(<FindOutcomeItem {...defaultProps({title: null})} />)
    expect(queryByTestId('outcome-management-item')).not.toBeInTheDocument()
  })

  it('if outcome has not been added, add button should be enabled with Add as the text', () => {
    const {getByText} = render(<FindOutcomeItem {...defaultProps()} />)
    expect(getByText('Add')).toBeInTheDocument()
    expect(getByText('Add').closest('button')).not.toBeDisabled()
  })

  it('if outcome has been added, add button should be disabled with Added as the text', () => {
    const {getByText} = render(<FindOutcomeItem {...defaultProps({isAdded: true})} />)
    expect(getByText('Added')).toBeInTheDocument()
    expect(getByText('Added').closest('button')).toBeDisabled()
  })

  it('displays right pointing caret when description is collapsed', () => {
    const {queryByTestId} = render(<FindOutcomeItem {...defaultProps()} />)
    expect(queryByTestId('icon-arrow-right')).toBeInTheDocument()
  })

  it('displays down pointing caret when description is expanded', () => {
    const {queryByTestId, getByTestId} = render(<FindOutcomeItem {...defaultProps()} />)
    fireEvent.click(getByTestId('description-truncated'))
    expect(queryByTestId('icon-arrow-down')).toBeInTheDocument()
  })

  it('expands description when user clicks on right pointing caret', () => {
    const {queryByTestId, getByText} = render(<FindOutcomeItem {...defaultProps()} />)
    fireEvent.click(getByText('Expand outcome description'))
    expect(queryByTestId('description-expanded')).toBeInTheDocument()
  })

  it('collapses description when user clicks on downward pointing caret', () => {
    const {queryByTestId, getByText} = render(<FindOutcomeItem {...defaultProps()} />)
    fireEvent.click(getByText('Expand outcome description'))
    fireEvent.click(getByText('Collapse outcome description'))
    expect(queryByTestId('description-truncated')).toBeInTheDocument()
  })

  it('displays disabled caret button if no description', () => {
    const {queryByTestId} = render(<FindOutcomeItem {...defaultProps({description: null})} />)
    expect(queryByTestId('icon-arrow-right').closest('button')).toHaveAttribute('disabled')
  })

  describe('onAddOutcomeHandler is called', () => {
    it('when user clicks on Add button', () => {
      const {getByText} = render(<FindOutcomeItem {...defaultProps()} />, {
        contextType: 'Course'
      })
      fireEvent.click(getByText('Add'))
      expect(onAddOutcomeHandlerMock).toHaveBeenCalledTimes(1)
    })

    it('with outcomeId and two functions for state handling', () => {
      const {getByText} = render(<FindOutcomeItem {...defaultProps()} />, {
        contextType: 'Course'
      })
      fireEvent.click(getByText('Add'))
      expect(onAddOutcomeHandlerMock).toHaveBeenCalledWith(
        '1',
        expect.any(Function),
        expect.any(Function)
      )
    })
  })
})
