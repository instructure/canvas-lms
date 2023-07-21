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
import {fireEvent, render, act} from '@testing-library/react'
import CommentEditView from '../CommentEditView'

jest.useFakeTimers()

describe('Comment', () => {
  let onCloseMock, updateCommentMock

  const defaultProps = (props = {}) => {
    return {
      comment: 'My assignment comment',
      id: '1',
      updateComment: updateCommentMock,
      onClose: onCloseMock,
      ...props,
    }
  }

  beforeEach(() => {
    updateCommentMock = jest.fn()
    onCloseMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the comment text', () => {
    const {getByText} = render(<CommentEditView {...defaultProps()} />)
    expect(getByText('My assignment comment')).toBeInTheDocument()
  })

  it('renders a textarea with a placeholder and label', () => {
    const {getByPlaceholderText, getByLabelText} = render(<CommentEditView {...defaultProps()} />)
    expect(getByPlaceholderText('Write something...')).toBeInTheDocument()
    expect(getByLabelText('Edit comment')).toBeInTheDocument()
  })

  it('renders a cancel button', () => {
    const {getByText} = render(<CommentEditView {...defaultProps()} />)
    expect(getByText('Cancel')).toBeInTheDocument()
  })

  it('calls onClose when the cancel button is clicked', () => {
    const {getByText} = render(<CommentEditView {...defaultProps()} />)
    fireEvent.click(getByText('Cancel'))
    expect(onCloseMock).toHaveBeenCalled()
  })

  it('renders a save button that is initially disabled', () => {
    const {getByText} = render(<CommentEditView {...defaultProps()} />)
    expect(getByText('Save').closest('button')).toBeDisabled()
  })

  it('enables the save button when new text is entered', () => {
    const {getByText, getByLabelText} = render(<CommentEditView {...defaultProps()} />)
    const input = getByLabelText('Edit comment')
    fireEvent.change(input, {target: {value: 'test comment'}})
    expect(getByText('Save').closest('button')).not.toBeDisabled()
  })

  it('disables the save button when the textarea is empty', () => {
    const {getByText, getByLabelText} = render(<CommentEditView {...defaultProps()} />)
    const input = getByLabelText('Edit comment')
    fireEvent.change(input, {target: {value: ''}})
    expect(getByText('Save').closest('button')).toBeDisabled()
  })

  it('calls updateComment followed by onClose when the save button is clicked', async () => {
    const {getByText, getByLabelText} = render(<CommentEditView {...defaultProps()} />)
    const input = getByLabelText('Edit comment')
    fireEvent.change(input, {target: {value: 'test comment'}})
    fireEvent.click(getByText('Save'))
    expect(getByText('Save').closest('button')).toBeDisabled()
    expect(updateCommentMock).toHaveBeenCalled()
    await act(async () => jest.runAllTimers())
    expect(onCloseMock).toHaveBeenCalled()
  })
})
