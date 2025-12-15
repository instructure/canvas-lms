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
import {SettingsUploadImage} from '../SettingsUploadImage'

describe('SettingsUploadImage', () => {
  const mockOnImageChange = vi.fn()

  beforeEach(() => {
    mockOnImageChange.mockClear()
  })

  it('renders upload button when no image is provided', () => {
    const component = render(
      <SettingsUploadImage url="" fileName="" onImageChange={mockOnImageChange} />,
    )

    expect(component.getByText('Add image')).toBeInTheDocument()
    expect(component.queryByTestId('remove-image-button')).not.toBeInTheDocument()
  })

  it('renders replace button when image is provided', () => {
    const component = render(
      <SettingsUploadImage
        url="https://example.com/image.jpg"
        fileName="my-image.jpg"
        onImageChange={mockOnImageChange}
      />,
    )

    expect(component.getByText('Replace image')).toBeInTheDocument()
  })

  it('displays filename when image has fileName', () => {
    const component = render(
      <SettingsUploadImage
        url="https://example.com/image.jpg"
        fileName="my-image.jpg"
        onImageChange={mockOnImageChange}
      />,
    )

    expect(component.getByText('my-image.jpg')).toBeInTheDocument()
  })

  it('displays external URL link when image has URL but no fileName', () => {
    const component = render(
      <SettingsUploadImage
        url="https://example.com/image.jpg"
        fileName=""
        onImageChange={mockOnImageChange}
      />,
    )

    const externalLink = component.getByText('Image external URL')
    expect(externalLink).toBeInTheDocument()
    expect(externalLink.closest('a')).toHaveAttribute('href', 'https://example.com/image.jpg')
    expect(externalLink.closest('a')).toHaveAttribute('target', '_blank')
  })

  it('removes image when remove button is clicked', async () => {
    const user = userEvent.setup()

    const component = render(
      <SettingsUploadImage
        url="https://example.com/image.jpg"
        fileName="my-image.jpg"
        onImageChange={mockOnImageChange}
      />,
    )

    const removeButton = component.getByTestId('remove-image-button')
    await user.click(removeButton)

    expect(mockOnImageChange).toHaveBeenCalledWith({
      url: '',
      altText: '',
      fileName: '',
      decorativeImage: false,
    })
  })

  it('does not render image info when URL is missing', () => {
    const component = render(
      <SettingsUploadImage fileName="my-image.jpg" onImageChange={mockOnImageChange} />,
    )

    expect(component.queryByText('my-image.jpg')).not.toBeInTheDocument()
    expect(component.queryByTestId('remove-image-button')).not.toBeInTheDocument()
    expect(component.getByText('Add image')).toBeInTheDocument()
  })

  it('does not render image info when URL is only whitespace', () => {
    const component = render(
      <SettingsUploadImage url="   " fileName="my-image.jpg" onImageChange={mockOnImageChange} />,
    )

    expect(component.queryByText('my-image.jpg')).not.toBeInTheDocument()
    expect(component.queryByTestId('remove-image-button')).not.toBeInTheDocument()
    expect(component.getByText('Add image')).toBeInTheDocument()
  })
})
