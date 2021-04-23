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
import Library from '../Library'

jest.useFakeTimers()

describe('Library', () => {
  let setCommentMock

  const defaultProps = (props = {}) => {
    return {
      comments: [
        {
          _id: '1',
          comment: 'great comment'
        },
        {
          _id: '2',
          comment: 'great comment 2'
        }
      ],
      setComment: setCommentMock,
      ...props
    }
  }

  beforeEach(() => {
    setCommentMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('should open the tray when the link is clicked', () => {
    const {getByText, queryByText} = render(<Library {...defaultProps()} />)
    expect(queryByText('Manage Comment Library')).not.toBeInTheDocument()
    fireEvent.click(getByText('2'))
    expect(getByText('Manage Comment Library')).toBeInTheDocument()
  })

  it('calls setComment and hides the tray when a tray comment is clicked', async () => {
    const {getByText, queryByText} = render(<Library {...defaultProps()} />)
    fireEvent.click(getByText('2'))
    fireEvent.click(getByText('great comment 2'))
    expect(setCommentMock).toHaveBeenCalledWith('great comment 2')
    await act(async () => jest.runAllTimers())
    expect(queryByText('Manage Comment Library')).not.toBeInTheDocument()
  })

  it('closes the tray when the close IconButton is clicked', async () => {
    const {getByText, queryByText} = render(<Library {...defaultProps()} />)
    fireEvent.click(getByText('2'))
    fireEvent.click(getByText('Close comment library'))
    await act(async () => jest.runAllTimers())
    expect(queryByText('Manage Comment Library')).not.toBeInTheDocument()
  })
})
