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
import React from 'react'
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {StudentPerPageSelector, StudentPerPageSelectorProps} from '../StudentPerPageSelector'

describe('StudentPerPageSelector', () => {
  const defaultProps: StudentPerPageSelectorProps = {
    options: [10, 20, 50],
    value: 20,
    onChange: vi.fn(),
  }

  it('renders the correct number of options', async () => {
    const {getByTestId, getByText} = render(<StudentPerPageSelector {...defaultProps} />)
    const selector = getByTestId('per-page-selector')
    await userEvent.click(selector)
    defaultProps.options.forEach(option => {
      expect(getByText(option)).toBeInTheDocument()
    })
  })

  it('renders the current value as selected', () => {
    const {getByDisplayValue} = render(<StudentPerPageSelector {...defaultProps} />)
    expect(getByDisplayValue(defaultProps.value.toString())).toBeInTheDocument()
  })

  it('calls onChange with the new value when an option is selected', async () => {
    const {getByTestId, getByText} = render(<StudentPerPageSelector {...defaultProps} />)
    const selector = getByTestId('per-page-selector')
    await userEvent.click(selector)
    const newValue = 50
    const option = getByText(newValue)
    await userEvent.click(option)
    expect(defaultProps.onChange).toHaveBeenCalledWith(newValue)
  })
})
