/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {render, fireEvent, waitFor} from '@testing-library/react'
import MoveToDialog from '../MoveToDialog'

describe('MoveToDialog', () => {
  const defaultProps = {
    header: 'This is a dialog',
    source: {label: 'foo', id: '0'},
    destinations: [
      {label: 'bar', id: '1'},
      {label: 'baz', id: '2'},
    ],
  }

  const renderDialog = (props = {}) => {
    return render(<MoveToDialog {...defaultProps} {...props} />)
  }

  test('calls onMove with a destination id when selected', () => {
    const onMove = jest.fn()
    const {getByTestId} = renderDialog({onMove})

    fireEvent.click(getByTestId('move-dialog-move-button'))
    expect(onMove).toHaveBeenCalledWith('1')
  })

  test('does not call onMove when cancelled via close button', async () => {
    const onMove = jest.fn()
    const onClose = jest.fn()
    const {getByTestId} = renderDialog({onMove, onClose})

    fireEvent.click(getByTestId('move-dialog-cancel-button'))
    expect(onMove).not.toHaveBeenCalled()
    await waitFor(() => expect(onClose).toHaveBeenCalled())
  })

  test('does not fail when no onMove is specified', async () => {
    const onClose = jest.fn()
    const {getByTestId} = renderDialog({onClose})

    fireEvent.click(getByTestId('move-dialog-move-button'))
    await waitFor(() => expect(onClose).toHaveBeenCalled())
  })
})
