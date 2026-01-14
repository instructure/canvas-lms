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

import {ImageTextBlockSettings} from '../ImageTextBlockSettings'
import {renderBlock} from '../../__tests__/render-helper'
import {waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {ImageTextBlockProps} from '../types'

const color = '123456'

const defaultProps: ImageTextBlockProps = {
  title: '',
  content: '',
  url: 'http://example.com/image.jpg',
  altText: '',
  includeBlockTitle: false,
  backgroundColor: '',
  titleColor: '',
  arrangement: 'left',
  textToImageRatio: '1:1',
  fileName: 'name',
  altTextAsCaption: false,
  decorativeImage: false,
  caption: '',
  attachmentId: '123',
}

describe('ImageTextBlockSettings - Fields', () => {
  describe('include title', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageTextBlockSettings, {
        ...defaultProps,
        includeBlockTitle: false,
      })
      const checkbox = component.getByLabelText(/Include block title/i)
      expect(checkbox).not.toBeChecked()
      await userEvent.click(checkbox)
      expect(checkbox).toBeChecked()
    })
  })

  describe('background color', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageTextBlockSettings, {
        ...defaultProps,
        backgroundColor: '000000',
      })
      const input = component.getByLabelText(/Background color/i) as HTMLInputElement
      await userEvent.clear(input)
      await userEvent.type(input, color)
      await waitFor(() => expect(input.value).toBe(color))
    })
  })

  describe('title color', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageTextBlockSettings, {...defaultProps, titleColor: '000000'})
      const input = component.getByLabelText(/Title color/i) as HTMLInputElement
      await userEvent.clear(input)
      await userEvent.type(input, color)
      await waitFor(() => expect(input.value).toBe(color))
    })
  })

  describe('arrangement', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageTextBlockSettings, {...defaultProps, arrangement: 'left'})
      const radioButton = component.getByLabelText(/Image on the right/i)
      expect(radioButton).not.toBeChecked()
      await userEvent.click(radioButton)
      expect(radioButton).toBeChecked()
    })
  })

  describe('text to image ratio', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageTextBlockSettings, {
        ...defaultProps,
        textToImageRatio: '1:1',
      })
      const radioButton = component.getByLabelText(/2:1/i)
      expect(radioButton).not.toBeChecked()
      await userEvent.click(radioButton)
      expect(radioButton).toBeChecked()
    })
  })

  describe('image upload', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageTextBlockSettings, {
        ...defaultProps,
        url: 'https://example.com/image.jpg',
        altText: 'Sample image',
        fileName: 'my-image.jpg',
      })

      expect(component.getByText('my-image.jpg')).toBeInTheDocument()
      await userEvent.click(component.getByTestId('remove-image-button'))
      expect(component.getByText('Add image')).toBeInTheDocument()
      expect(component.queryByText('my-image.jpg')).not.toBeInTheDocument()
    })
  })

  describe('caption', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageTextBlockSettings, {
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
      const component = renderBlock(ImageTextBlockSettings, {
        ...defaultProps,
        altText: 'Initial alt text',
      })
      const input = component.getByRole('textbox', {name: /Alt text/i}) as HTMLInputElement
      expect(input.value).toBe('Initial alt text')
      await userEvent.clear(input)
      await userEvent.type(input, 'New alt text')
      expect(input.value).toBe('New alt text')
    })
  })

  describe('alt text as caption', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageTextBlockSettings, {
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
      const component = renderBlock(ImageTextBlockSettings, {
        ...defaultProps,
        decorativeImage: false,
      })
      const checkbox = component.getByLabelText(/Decorative image/i)
      expect(checkbox).not.toBeChecked()
      await userEvent.click(checkbox)
      expect(checkbox).toBeChecked()
    })
  })
})
