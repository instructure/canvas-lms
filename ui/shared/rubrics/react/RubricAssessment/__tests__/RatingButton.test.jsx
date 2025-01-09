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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {RatingButton} from '../RatingButton'

describe('RatingButton', () => {
  const defaultProps = {
    buttonDisplay: '5',
    isPreviewMode: false,
    isSelected: false,
    selectedArrowDirection: 'right',
    onClick: jest.fn(),
  }

  const renderRatingButton = (props = {}) => {
    return render(<RatingButton {...defaultProps} {...props} />)
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders with the provided button display text', () => {
    renderRatingButton()
    expect(screen.getByText('5')).toBeInTheDocument()
  })

  it('includes selected state in screen reader label when selected', () => {
    renderRatingButton({isSelected: true})
    expect(screen.getByRole('button', {hidden: true})).toHaveAccessibleName(
      '5 Rating Button 5 Selected',
    )
  })

  it('calls onClick when clicked in normal mode', async () => {
    const user = userEvent.setup()
    renderRatingButton()
    await user.click(screen.getByRole('button', {hidden: true}))
    expect(defaultProps.onClick).toHaveBeenCalledTimes(1)
  })

  it('does not call onClick when clicked in preview mode', async () => {
    const user = userEvent.setup()
    renderRatingButton({isPreviewMode: true})
    await user.click(screen.getByRole('button', {hidden: true}))
    expect(defaultProps.onClick).not.toHaveBeenCalled()
  })

  it('has not-allowed cursor in preview mode', () => {
    renderRatingButton({isPreviewMode: true})
    expect(screen.getByRole('button', {hidden: true})).toHaveStyle({cursor: 'not-allowed'})
  })
})
