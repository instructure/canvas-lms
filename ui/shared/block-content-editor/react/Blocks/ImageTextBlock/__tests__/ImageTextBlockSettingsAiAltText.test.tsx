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
import {renderBlock, RenderBlockOptions} from '../../__tests__/render-helper'
import {waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {ImageTextBlockProps} from '../types'
import {generateAiAltText} from '../../../utilities/aiAltTextApi'

vi.mock('../../../utilities/aiAltTextApi', () => ({
  generateAiAltText: vi.fn().mockResolvedValue({
    image: {altText: 'AI generated alt text'},
  }),
}))

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

describe('ImageTextBlockSettings - AI Alt Text', () => {
  const aiAltTextOptions: RenderBlockOptions = {
    aiAltTextGenerationURL: '/api/v1/courses/1/pages_ai/alt_text',
  }

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('does not show when AI alt text URL is not provided', () => {
    const component = renderBlock(ImageTextBlockSettings, defaultProps)
    expect(component.queryByText(/\(Re\)generate Alt Text/i)).not.toBeInTheDocument()
  })

  it('does not show when AI alt text URL is empty string', () => {
    const component = renderBlock(ImageTextBlockSettings, defaultProps, {
      aiAltTextGenerationURL: '',
    })
    expect(component.queryByText(/\(Re\)generate Alt Text/i)).not.toBeInTheDocument()
  })

  it('shows when AI alt text URL is provided', () => {
    const component = renderBlock(ImageTextBlockSettings, defaultProps, aiAltTextOptions)
    expect(component.queryByText(/\(Re\)generate Alt Text/i)).toBeInTheDocument()
  })

  it('is disabled when image is decorative', () => {
    const component = renderBlock(
      ImageTextBlockSettings,
      {
        ...defaultProps,
        decorativeImage: true,
      },
      aiAltTextOptions,
    )
    const button = component.getByTestId('generate-alt-text-button')
    expect(button).toBeDisabled()
  })

  it('is disabled when no image URL is provided', () => {
    const component = renderBlock(
      ImageTextBlockSettings,
      {
        ...defaultProps,
        attachmentId: undefined,
      },
      aiAltTextOptions,
    )
    const button = component.getByTestId('generate-alt-text-button')
    expect(button).toBeDisabled()
  })

  it('is disabled when no fileName is provided', () => {
    const component = renderBlock(
      ImageTextBlockSettings,
      {...defaultProps, fileName: ''},
      aiAltTextOptions,
    )
    const button = component.getByTestId('generate-alt-text-button')
    expect(button).toBeDisabled()
  })

  it('generates alt text when clicked', async () => {
    const component = renderBlock(
      ImageTextBlockSettings,
      {
        ...defaultProps,
        altText: 'Original alt text',
      },
      aiAltTextOptions,
    )
    const button = component.getByTestId('generate-alt-text-button')
    const altTextInput = component.getByRole('textbox', {name: /Alt text/i}) as HTMLInputElement

    expect(altTextInput.value).toBe('Original alt text')

    await userEvent.click(button)

    await waitFor(() => {
      expect(generateAiAltText).toHaveBeenCalledWith({
        url: '/api/v1/courses/1/pages_ai/alt_text',
        requestData: {
          attachment_id: '123',
        },
        signal: expect.any(AbortSignal),
      })
    })

    await waitFor(() => {
      expect(altTextInput.value).toBe('AI generated alt text')
    })
  })

  it('shows generating state while processing', async () => {
    // Make the API call take longer to resolve
    vi.mocked(generateAiAltText).mockImplementation(
      () =>
        new Promise(resolve =>
          setTimeout(() => resolve({image: {altText: 'AI generated alt text'}}), 100),
        ),
    )

    const component = renderBlock(ImageTextBlockSettings, defaultProps, aiAltTextOptions)
    const button = component.getByTestId('generate-alt-text-button')

    await userEvent.click(button)

    expect(component.getByText('Generating Alt Text...')).toBeInTheDocument()

    await waitFor(() => {
      expect(component.queryByText(/\(Re\)generate Alt Text/i)).toBeInTheDocument()
    })
  })
})
