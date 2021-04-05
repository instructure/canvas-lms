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
import ManageOutcomeItem from '../ManageOutcomeItem'

describe('ManageOutcomeItem', () => {
  let onMenuHandlerMock
  let onCheckboxHandlerMock
  const defaultProps = (props = {}) => ({
    id: '1',
    title: 'Outcome Title',
    description: 'Outcome Description',
    isFirst: false,
    isChecked: false,
    onMenuHandler: onMenuHandlerMock,
    onCheckboxHandler: onCheckboxHandlerMock,
    ...props
  })

  beforeEach(() => {
    onMenuHandlerMock = jest.fn()
    onCheckboxHandlerMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders title if title prop passed', () => {
    const {getByText} = render(<ManageOutcomeItem {...defaultProps()} />)
    expect(getByText('Outcome Title')).toBeInTheDocument()
  })

  it('does not render component if title prop not passed', () => {
    const {queryByTestId} = render(<ManageOutcomeItem {...defaultProps({title: null})} />)
    expect(queryByTestId('outcome-with-bottom-border')).not.toBeInTheDocument()
  })

  it('handles click on checkbox', () => {
    const {getByText} = render(<ManageOutcomeItem {...defaultProps()} />)
    const checkbox = getByText('Select outcome')
    fireEvent.click(checkbox)
    expect(onCheckboxHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('passes item id to checkbox onClick handler', () => {
    const {getByText} = render(<ManageOutcomeItem {...defaultProps()} />)
    const checkbox = getByText('Select outcome')
    fireEvent.click(checkbox)
    expect(onCheckboxHandlerMock).toHaveBeenCalledWith('1')
  })

  it('displays right pointing caret when description is truncated', () => {
    const {queryByTestId} = render(<ManageOutcomeItem {...defaultProps()} />)
    expect(queryByTestId('icon-arrow-right')).toBeInTheDocument()
  })

  it('displays down pointing caret when description is expanded', () => {
    const {queryByTestId, getByTestId} = render(<ManageOutcomeItem {...defaultProps()} />)
    const descTruncated = getByTestId('description-truncated')
    fireEvent.click(descTruncated)
    expect(queryByTestId('icon-arrow-down')).toBeInTheDocument()
  })

  it('expands description when user clicks on button with right pointing caret', () => {
    const {queryByTestId, getByText} = render(<ManageOutcomeItem {...defaultProps()} />)
    const caretBtn = getByText('Expand outcome description')
    fireEvent.click(caretBtn)
    expect(queryByTestId('description-expanded')).toBeInTheDocument()
  })

  it('collapses description when user clicks on button with down pointing caret', () => {
    const {queryByTestId, getByText} = render(<ManageOutcomeItem {...defaultProps()} />)
    const caretBtn = getByText('Expand outcome description')
    fireEvent.click(caretBtn)
    const caretDownBtn = getByText('Collapse outcome description')
    fireEvent.click(caretDownBtn)
    expect(queryByTestId('description-truncated')).toBeInTheDocument()
  })

  it('displays bottom border when isFirst prop is false', () => {
    const {queryByTestId} = render(<ManageOutcomeItem {...defaultProps()} />)
    expect(queryByTestId('outcome-with-bottom-border')).toBeInTheDocument()
  })

  it('displays both top and bottom border when isFirst prop is true', () => {
    const {queryByTestId} = render(<ManageOutcomeItem {...defaultProps({isFirst: true})} />)
    expect(queryByTestId('outcome-with-top-bottom-border')).toBeInTheDocument()
  })

  it('displays disabled caret button with "not-allowed" cursor if no description', () => {
    const {queryByTestId} = render(<ManageOutcomeItem {...defaultProps({description: null})} />)
    expect(queryByTestId('icon-arrow-right').closest('button')).toHaveAttribute('disabled')
    expect(queryByTestId('icon-arrow-right').closest('button').style).toHaveProperty(
      'cursor',
      'not-allowed'
    )
  })

  it('handles click on individual outcome -> kebab menu -> remove option', () => {
    const {getByText} = render(<ManageOutcomeItem {...defaultProps()} />)
    fireEvent.click(getByText('Outcome Menu'))
    fireEvent.click(getByText('Remove'))
    expect(onMenuHandlerMock).toHaveBeenCalledTimes(1)
    expect(onMenuHandlerMock.mock.calls[0][0]).toBe('1')
    expect(onMenuHandlerMock.mock.calls[0][1]).toBe('remove')
  })
})
