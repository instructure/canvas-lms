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
import {waitFor} from '@testing-library/react'
import {createMockStore} from '../../../__tests__/createMockStore'
import {generateAiAltText} from '../../../utilities/aiAltTextApi'

const mockStore = vi.fn()
vi.mock('react', async () => {
  const ActualReact = await vi.importActual<typeof import('react')>('react')
  return {
    ...ActualReact,
    useContext: (context: React.Context<any>) => {
      const result = ActualReact.useContext(context) as any
      if (context.displayName === 'FastContext') {
        return {
          ...result,
          get: () => mockStore(),
        }
      }
      return result
    },
  }
})

vi.mock('../../../utilities/aiAltTextApi', () => ({
  generateAiAltText: vi.fn().mockResolvedValue({
    image: {altText: 'AI generated alt text'},
  }),
}))

const color = '123456'

const defaultProps = {
  title: '',
  includeBlockTitle: false,
  backgroundColor: 'color',
  titleColor: 'color',
  url: 'https://example.com/image.jpg',
  altText: 'Example Image',
  caption: 'This is an example image.',
  altTextAsCaption: false,
  decorativeImage: false,
  fileName: 'test',
  attachmentId: '123',
}

describe('ImageBlockSettings', () => {
  beforeEach(() => {
    mockStore.mockReturnValue(
      createMockStore({
        aiAltTextGenerationURL: null,
      }),
    )
  })
  afterEach(() => {
    vi.clearAllMocks()
  })

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
      const input = component.getByTestId('image-alt-text-input') as HTMLInputElement
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
      expect(component.getByText('Add image')).toBeInTheDocument()
      expect(component.queryByText('my-image.jpg')).not.toBeInTheDocument()
    })
  })

  describe('background color', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageBlockSettings, {
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
      const component = renderBlock(ImageBlockSettings, {...defaultProps, titleColor: '000000'})
      const input = component.getByLabelText(/Title color/i) as HTMLInputElement
      await userEvent.clear(input)
      await userEvent.type(input, color)
      await waitFor(() => expect(input.value).toBe(color))
    })
  })

  describe('regenerate alt text', () => {
    it('does not show when AI alt text URL is not provided', () => {
      mockStore.mockReturnValue(
        createMockStore({
          aiAltTextGenerationURL: null,
        }),
      )
      const component = renderBlock(ImageBlockSettings, defaultProps)
      expect(component.queryByText(/\(Re\)generate Alt Text/i)).not.toBeInTheDocument()
    })

    it('does not show when AI alt text URL is empty string', () => {
      mockStore.mockReturnValue(
        createMockStore({
          aiAltTextGenerationURL: '',
        }),
      )
      const component = renderBlock(ImageBlockSettings, defaultProps)
      expect(component.queryByText(/\(Re\)generate Alt Text/i)).not.toBeInTheDocument()
    })

    it('shows when AI alt text URL is available', () => {
      mockStore.mockReturnValue(
        createMockStore({
          aiAltTextGenerationURL: '/api/v1/courses/1/pages_ai/alt_text',
        }),
      )
      const component = renderBlock(ImageBlockSettings, defaultProps)
      expect(component.getByText(/\(Re\)generate Alt Text/i)).toBeInTheDocument()
    })

    it('is disabled when image is decorative', () => {
      mockStore.mockReturnValue(
        createMockStore({
          aiAltTextGenerationURL: '/api/v1/courses/1/pages_ai/alt_text',
        }),
      )
      const component = renderBlock(ImageBlockSettings, {...defaultProps, decorativeImage: true})
      const button = component.getByTestId('generate-alt-text-button')
      expect(button).toBeDisabled()
    })

    it('is disabled when no image URL is provided', () => {
      mockStore.mockReturnValue(
        createMockStore({
          aiAltTextGenerationURL: '/api/v1/courses/1/pages_ai/alt_text',
        }),
      )
      const component = renderBlock(ImageBlockSettings, {...defaultProps, attachmentId: undefined})
      const button = component.getByTestId('generate-alt-text-button')
      expect(button).toBeDisabled()
    })

    it('is disabled when no fileName is provided', () => {
      mockStore.mockReturnValue(
        createMockStore({
          aiAltTextGenerationURL: '/api/v1/courses/1/pages_ai/alt_text',
        }),
      )
      const component = renderBlock(ImageBlockSettings, {...defaultProps, fileName: ''})
      const button = component.getByTestId('generate-alt-text-button')
      expect(button).toBeDisabled()
    })

    it('generates alt text when clicked', async () => {
      mockStore.mockReturnValue(
        createMockStore({
          aiAltTextGenerationURL: '/api/v1/courses/1/pages_ai/alt_text',
        }),
      )

      const component = renderBlock(ImageBlockSettings, {
        ...defaultProps,
        altText: 'Original alt text',
      })
      const button = component.getByTestId('generate-alt-text-button')
      const altTextInput = component.getByTestId('image-alt-text-input') as HTMLInputElement

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
      mockStore.mockReturnValue(
        createMockStore({
          aiAltTextGenerationURL: '/api/v1/courses/1/pages_ai/alt_text',
        }),
      )

      vi.mocked(generateAiAltText).mockImplementation(
        () =>
          new Promise(resolve =>
            setTimeout(() => resolve({image: {altText: 'AI generated alt text'}}), 100),
          ),
      )

      const component = renderBlock(ImageBlockSettings, defaultProps)
      const button = component.getByTestId('generate-alt-text-button')

      await userEvent.click(button)

      expect(button).toHaveTextContent(/Generating Alt Text\.\.\./i)

      await waitFor(() => {
        expect(button).toHaveTextContent(/\(Re\)generate Alt Text/i)
      })
    })
  })
})
