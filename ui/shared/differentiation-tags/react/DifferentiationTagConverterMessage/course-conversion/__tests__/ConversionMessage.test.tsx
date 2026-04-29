/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {render, screen} from '@testing-library/react'
import ConversionMessage from '../ConversionMessage'
import userEvent from '@testing-library/user-event'

describe('ConversionMessage', () => {
  const renderComponent = (props = {}) => {
    const defaultProps = {
      onCourseConvertTags: vi.fn(),
      ...props,
    }

    return render(<ConversionMessage {...defaultProps} />)
  }

  it('renders conversion message with button', () => {
    renderComponent()
    expect(screen.getByTestId('course-tag-conversion-message')).toBeInTheDocument()
    expect(screen.getByTestId('course-tag-conversion-button')).toBeInTheDocument()
  })

  it('calls onCourseConvertTags when button is clicked', async () => {
    const onCourseConvertTagsMock = vi.fn()
    renderComponent({onCourseConvertTags: onCourseConvertTagsMock})
    const button = screen.getByTestId('course-tag-conversion-button')
    await userEvent.click(button)

    expect(onCourseConvertTagsMock).toHaveBeenCalledTimes(1)
  })
})
