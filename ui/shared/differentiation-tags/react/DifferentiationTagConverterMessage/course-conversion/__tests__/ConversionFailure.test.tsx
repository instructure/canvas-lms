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
import ConversionFailure from '../ConversionFailure'

describe('ConversionFailure', () => {
  const renderComponent = (props = {}) => {
    const defaultProps = {
      conversionError: 'An error occurred during tag conversion',
      ...props,
    }

    return render(<ConversionFailure {...defaultProps} />)
  }

  it('renders error message with provided conversion error', () => {
    renderComponent({conversionError: 'Test error'})
    expect(screen.getByText('Tag conversion failed: Test error')).toBeInTheDocument()
  })

  it('renders default error message when no conversion error is provided', () => {
    renderComponent()
    expect(
      screen.getByText('Tag conversion failed: An error occurred during tag conversion'),
    ).toBeInTheDocument()
  })
})
