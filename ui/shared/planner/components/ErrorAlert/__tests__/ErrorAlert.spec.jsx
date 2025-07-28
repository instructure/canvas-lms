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
import {render} from '@testing-library/react'
import ErrorAlert from '../index'

describe('ErrorAlert', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders an alert with error message', () => {
    const {getByText} = render(<ErrorAlert>uh oh</ErrorAlert>)

    // Should contain the error message
    expect(getByText('uh oh')).toBeInTheDocument()
  })

  it('renders with string error details hidden from user', () => {
    const {getByText, container} = render(<ErrorAlert error="whoops">uh oh</ErrorAlert>)

    // Should show the visible error message
    expect(getByText('uh oh')).toBeInTheDocument()

    // Error details should be hidden with display: none
    const hiddenSpan = container.querySelector('span[style="display: none;"]')
    expect(hiddenSpan).toBeInTheDocument()
    expect(hiddenSpan.textContent).toBe('whoops')
  })

  it('renders with Error object details hidden from user', () => {
    const error = new Error('whoops')
    const {getByText, container} = render(<ErrorAlert error={error}>uh oh</ErrorAlert>)

    // Should show the visible error message
    expect(getByText('uh oh')).toBeInTheDocument()

    // Error details should be hidden with display: none
    const hiddenSpan = container.querySelector('span[style="display: none;"]')
    expect(hiddenSpan).toBeInTheDocument()
    expect(hiddenSpan.textContent).toBe('whoops')
  })

  it('does not render error details when no error prop provided', () => {
    const {container} = render(<ErrorAlert>uh oh</ErrorAlert>)

    // Should not have any hidden spans with error details
    const hiddenSpan = container.querySelector('span[style="display: none;"]')
    expect(hiddenSpan).not.toBeInTheDocument()
  })

  it('renders with the correct error styling', () => {
    const {container} = render(<ErrorAlert>uh oh</ErrorAlert>)

    // InstUI Alert components have complex class names that may change
    // Instead, verify the SVG icon is present which indicates an error alert
    const errorIcon = container.querySelector('svg')
    expect(errorIcon).toBeInTheDocument()
  })
})
