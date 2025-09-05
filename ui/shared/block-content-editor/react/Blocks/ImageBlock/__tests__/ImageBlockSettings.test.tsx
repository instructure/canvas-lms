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

import {ImageBlockSettings} from '../ImageBlockSettings'
import {renderBlock} from '../../__tests__/render-helper'
import userEvent from '@testing-library/user-event'
import {RenderResult, waitFor} from '@testing-library/react'

const color = '123456'

const toggleSection = async (component: RenderResult, name: RegExp | string) => {
  const button = component.getByRole('button', {name})
  await userEvent.click(button)
}

const defaultProps = {
  title: '',
  includeBlockTitle: false,
  backgroundColor: 'color',
  textColor: 'color',
  url: 'https://example.com/image.jpg',
  altText: 'Example Image',
  caption: 'This is an example image.',
  altTextAsCaption: false,
  decorativeImage: false,
}

describe('ImageBlockSettings', () => {
  describe('include title', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageBlockSettings, {...defaultProps, includeBlockTitle: false})
      const checkbox = component.getByLabelText(/Include block title/i)
      expect(checkbox).not.toBeChecked()
      await userEvent.click(checkbox)
      expect(checkbox).toBeChecked()
    })
  })

  describe('caption', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageBlockSettings, {
        ...defaultProps,
        caption: 'Initial caption',
      })
      const input = component.getByLabelText(/Image caption/i) as HTMLInputElement
      expect(input.value).toBe('Initial caption')
      await userEvent.clear(input)
      await userEvent.type(input, 'New caption')
      expect(input.value).toBe('New caption')
    })
  })

  describe('alt text', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageBlockSettings, {...defaultProps, altText: 'text'})
      const input = component.getByRole('textbox', {name: /Alt text/i}) as HTMLInputElement
      expect(input.value).toBe('text')
      await userEvent.clear(input)
      await userEvent.type(input, 'New text')
      expect(input.value).toBe('New text')
    })
  })

  describe('alt text as caption', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageBlockSettings, {
        ...defaultProps,
        altText: 'Sample alt text',
        altTextAsCaption: false,
      })
      const checkbox = component.getByLabelText(/Use alt text as caption/i)
      expect(checkbox).not.toBeChecked()
      await userEvent.click(checkbox)
      expect(checkbox).toBeChecked()
    })
  })

  describe('decorative image', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageBlockSettings, {...defaultProps, decorativeImage: false})
      const checkbox = component.getByLabelText(/Decorative image/i)
      expect(checkbox).not.toBeChecked()
      await userEvent.click(checkbox)
      expect(checkbox).toBeChecked()
    })
  })

  describe('image upload', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageBlockSettings, {
        ...defaultProps,
        url: 'https://example.com/image.jpg',
        fileName: 'my-image.jpg',
      })

      expect(component.getByText('my-image.jpg')).toBeInTheDocument()
      await userEvent.click(component.getByTestId('remove-image-button'))
      expect(component.getByText('Upload image')).toBeInTheDocument()
      expect(component.queryByText('my-image.jpg')).not.toBeInTheDocument()
    })
  })

  describe('background color', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageBlockSettings, {
        ...defaultProps,
        backgroundColor: '000000',
      })
      await toggleSection(component, /Expand color settings/i)
      const input = component.getByLabelText(/Background color/i) as HTMLInputElement
      await userEvent.clear(input)
      await userEvent.type(input, color)
      await waitFor(() => expect(input.value).toBe(color))
    })
  })

  describe('default text color', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageBlockSettings, {...defaultProps, textColor: '000000'})
      await toggleSection(component, /Expand color settings/i)
      const input = component.getByLabelText(/Default text color/i) as HTMLInputElement
      await userEvent.clear(input)
      await userEvent.type(input, color)
      await waitFor(() => expect(input.value).toBe(color))
    })
  })
})
