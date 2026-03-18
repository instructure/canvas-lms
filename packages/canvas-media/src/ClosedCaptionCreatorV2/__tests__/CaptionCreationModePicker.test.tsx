/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {fireEvent, render, screen} from '@testing-library/react'
import {vi} from 'vitest'
import {
  CaptionCreationModePicker,
  type CaptionCreationModePickerProps,
} from '../CaptionCreationModePicker'

function renderComponent(props: Partial<CaptionCreationModePickerProps> = {}) {
  const defaultProps: CaptionCreationModePickerProps = {
    onSelect: vi.fn(),
    ...props,
  }
  return render(<CaptionCreationModePicker {...defaultProps} />)
}

describe('<CaptionCreationModePicker />', () => {
  it('renders both buttons by default', () => {
    renderComponent()

    expect(screen.getByText('Add New')).toBeInTheDocument()
    expect(screen.getByText('Request')).toBeInTheDocument()
  })

  it('renders only "Add New" button when showAutoOption is false', () => {
    renderComponent({showAutoOption: false})

    expect(screen.getByText('Add New')).toBeInTheDocument()
    expect(screen.queryByText('Request')).not.toBeInTheDocument()
  })

  it.each([
    ['true', true],
    ['undefined (defaults to true)', undefined],
  ])('renders "Request" button when showAutoOption is %s', (_, showAutoOption) => {
    renderComponent({showAutoOption})

    expect(screen.getByText('Request')).toBeInTheDocument()
  })

  it.each([
    ['manual', 'Add New'],
    ['auto', 'Request'],
  ])('calls onSelect with "%s" when "%s" is clicked', (expectedMode, buttonText) => {
    const onSelect = vi.fn()
    renderComponent({onSelect})

    fireEvent.click(screen.getByText(buttonText))

    expect(onSelect).toHaveBeenCalledWith(expectedMode)
    expect(onSelect).toHaveBeenCalledTimes(1)
  })
})
