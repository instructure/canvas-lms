/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import CommentButton from '../CommentButton'

describe('The CommentButton component', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders a button with the correct accessibility label', () => {
    const onClick = jest.fn()
    const {getByTestId, getByText} = render(<CommentButton onClick={onClick} />)

    // Check that the button is rendered with the correct test ID
    const button = getByTestId('add-comment-button')
    expect(button).toBeInTheDocument()

    // Check that the screen reader text is present
    // InstUI components often use ScreenReaderContent instead of aria-label
    expect(getByText('Add Additional Comments', {selector: 'span'})).toBeInTheDocument()
  })

  it('calls onClick when the button is clicked', () => {
    const onClick = jest.fn()
    const {getByTestId} = render(<CommentButton onClick={onClick} />)

    const button = getByTestId('add-comment-button')
    fireEvent.click(button)

    expect(onClick).toHaveBeenCalledTimes(1)
  })

  it('renders the feedback icon', () => {
    const onClick = jest.fn()
    const {container} = render(<CommentButton onClick={onClick} />)

    // Check that an SVG icon is rendered
    const iconSVG = container.querySelector('svg')
    expect(iconSVG).toBeInTheDocument()
  })
})
