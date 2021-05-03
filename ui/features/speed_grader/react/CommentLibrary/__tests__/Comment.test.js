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
import {fireEvent, render} from '@testing-library/react'
import Comment from '../Comment'

describe('Comment', () => {
  let onClickMock

  const defaultProps = (props = {}) => {
    return {
      comment: 'My assignment comment',
      onClick: onClickMock,
      ...props
    }
  }

  beforeEach(() => {
    onClickMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the comment text and a trash icon', () => {
    const props = defaultProps()
    const {getByText} = render(<Comment {...props} />)
    expect(getByText(props.comment)).toBeInTheDocument()
    expect(getByText('Delete comment: My assignment comment')).toBeInTheDocument()
  })

  it('calls the onClick prop when the comment is clicked', () => {
    const {getByText} = render(<Comment {...defaultProps()} />)
    fireEvent.click(getByText('My assignment comment'))
    expect(onClickMock).toHaveBeenCalledTimes(1)
  })
})
