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

import {fireEvent, render, screen} from '@testing-library/react'
import React from 'react'
import {Card} from '..'

describe('Card', () => {
  const mockOnClick = jest.fn()

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('mounts without crashing', () => {
    render(
      <Card
        href="#"
        icon="/path/to/mock-icon.svg"
        onClick={mockOnClick}
        text="Test Card"
        label="Test Label"
      />,
    )
  })

  it('renders the card with correct text', () => {
    render(
      <Card
        href="#"
        icon="/path/to/mock-icon.svg"
        onClick={mockOnClick}
        text="Test Card"
        label="Test Label"
      />,
    )
    expect(screen.getByText('Test Card')).toBeInTheDocument()
  })

  it('renders the icon image with correct src', () => {
    render(
      <Card
        href="#"
        icon="/path/to/mock-icon.svg"
        onClick={mockOnClick}
        text="Test Card"
        label="Test Label"
      />,
    )
    const icon = screen.getByTestId('card-icon')
    expect(icon).toBeInTheDocument()
    expect(icon).toHaveAttribute('src', '/path/to/mock-icon.svg')
  })

  it('renders a link with the correct href', () => {
    render(
      <Card
        href="/test-path"
        icon="/mock.svg"
        label="Test Label"
        onClick={mockOnClick}
        testId="card-link"
        text="Test Card"
      />,
    )
    const link = screen.getByTestId('card-link')
    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute('href', '/test-path')
  })

  it('triggers onClick when clicked', () => {
    render(
      <Card
        href="#"
        icon="/mock.svg"
        label="Test Label"
        onClick={mockOnClick}
        testId="card-link"
        text="Test Card"
      />,
    )
    const link = screen.getByTestId('card-link')
    fireEvent.click(link)
    expect(mockOnClick).toHaveBeenCalledTimes(1)
  })

  it('has correct aria-label for accessibility', () => {
    render(
      <Card
        href="#"
        icon="/mock.svg"
        label="Accessible Label"
        onClick={mockOnClick}
        testId="card-link"
        text="Test Card"
      />,
    )
    const link = screen.getByTestId('card-link')
    expect(link).toHaveAttribute('aria-label', 'Accessible Label')
  })
})
