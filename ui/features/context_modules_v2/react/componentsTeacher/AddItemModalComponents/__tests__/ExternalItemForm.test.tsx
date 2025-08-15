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

import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ExternalItemForm from '../ExternalItemForm'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../../hooks/useModuleContext'
import {ContentItem} from '../../../hooks/queries/useModuleItemContent'

const mockContentItems: ContentItem[] = [
  {
    id: '1',
    name: 'Google Docs',
    description: 'Create and edit documents online',
    domain: 'docs.google.com',
    url: 'https://docs.google.com/launch',
  },
  {
    id: '2',
    name: 'Youtube',
    description: 'Watch and share videos',
    domain: 'youtube.com',
    url: 'https://youtube.com/video',
    placements: {
      assignmentSelection: {
        url: 'https://youtube.com/video/assignment_selection',
        title: 'Youtube Assignment',
      },
    },
  },
]

const buildProps = (overrides = {}) => ({
  onChange: jest.fn(),
  itemType: 'external_url' as const,
  contentItems: mockContentItems,
  formErrors: {},
  indentValue: 0,
  onIndentChange: () => {},
  moduleName: 'Test Module',
  ...overrides,
})

const setUp = (props = {}) => {
  const finalProps = buildProps(props)
  return {
    ...render(
      <ContextModuleProvider {...contextModuleDefaultProps}>
        <ExternalItemForm {...finalProps} />
      </ContextModuleProvider>,
    ),
    props: finalProps,
  }
}

describe('ExternalItemForm', () => {
  describe('when itemType is external_url', () => {
    it('renders URL and Page Name inputs without tool selector', () => {
      const {container} = setUp({itemType: 'external_url'})

      expect(screen.getByLabelText('URL')).toBeInTheDocument()
      expect(screen.getByLabelText('Page Name')).toBeInTheDocument()
      expect(screen.getByLabelText('Load in a new tab')).toBeInTheDocument()
      expect(screen.queryByText('Select External Tool')).not.toBeInTheDocument()
      expect(container).toBeInTheDocument()
    })

    it('allows editing URL and Page Name inputs', async () => {
      const user = userEvent.setup()
      setUp({itemType: 'external_url'})

      const urlInput = screen.getByLabelText('URL')
      const nameInput = screen.getByLabelText('Page Name')

      await user.type(urlInput, 'https://example.com')
      await user.type(nameInput, 'Test Page')

      expect(urlInput).not.toBeDisabled()
      expect(nameInput).not.toBeDisabled()
    })
  })

  describe('when itemType is external_tool', () => {
    it('renders tool selector with URL and Page Name inputs', () => {
      const {container} = setUp({itemType: 'external_tool'})

      expect(screen.getByText('Select External Tool')).toBeInTheDocument()
      expect(screen.getByLabelText('URL')).toBeInTheDocument()
      expect(screen.getByLabelText('Page Name')).toBeInTheDocument()
      expect(screen.getByLabelText('Load in a new tab')).toBeInTheDocument()
      expect(container).toBeInTheDocument()
    })

    describe('tool selection', () => {
      const prepareExternalToolSelector = async () => {
        const user = userEvent.setup()
        const {props} = setUp({itemType: 'external_tool'})
        const selectInput = screen.getByRole('combobox', {name: /select external tool/i})
        await user.click(selectInput)
        return {user, props, selectInput}
      }

      it('shows all available tools', async () => {
        await prepareExternalToolSelector()

        await waitFor(() => {
          expect(screen.getByText('Google Docs')).toBeInTheDocument()
          expect(screen.getByText('Youtube')).toBeInTheDocument()
        })
      })

      it('calls onChange with selected tool data', async () => {
        const {user, props} = await prepareExternalToolSelector()

        await user.click(screen.getByText('Google Docs'))

        expect(props.onChange).toHaveBeenCalledWith('url', 'https://docs.google.com/launch')
        expect(props.onChange).toHaveBeenCalledWith('name', 'Google Docs')
        expect(props.onChange).toHaveBeenCalledWith('selectedToolId', '1')
      })

      it('Assignment selection placement url and title are shown', async () => {
        const {user} = await prepareExternalToolSelector()

        await user.click(screen.getByText('Youtube'))

        expect(screen.getByLabelText('URL')).toHaveValue(
          'https://youtube.com/video/assignment_selection',
        )
        expect(screen.getByLabelText('Page Name')).toHaveValue('Youtube Assignment')
      })
    })
  })

  it('handles checkbox changes', async () => {
    const user = userEvent.setup()
    const {props} = setUp({itemType: 'external_url'})

    const checkbox = screen.getByLabelText('Load in a new tab')
    await user.click(checkbox)

    expect(props.onChange).toHaveBeenCalledWith('newTab', true)
  })

  it('uses provided initial values', () => {
    setUp({
      itemType: 'external_url',
      externalUrlValue: 'https://initial.com',
      externalUrlName: 'Initial Name',
      newTab: true,
    })

    const urlInput = screen.getByLabelText('URL') as HTMLInputElement
    const nameInput = screen.getByLabelText('Page Name') as HTMLInputElement
    const checkbox = screen.getByLabelText('Load in a new tab') as HTMLInputElement

    expect(urlInput.value).toBe('https://initial.com')
    expect(nameInput.value).toBe('Initial Name')
    expect(checkbox.checked).toBe(true)
  })

  it('validates URL format and shows error for invalid URLs', async () => {
    const user = userEvent.setup()
    const {props} = setUp({itemType: 'external_url'})

    const urlInput = screen.getByLabelText('URL')

    // Type invalid URL that URL.canParse will reject
    await user.type(urlInput, 'not a valid url')

    await waitFor(() => {
      expect(screen.getByText('Please enter a valid URL')).toBeInTheDocument()
    })

    // Check that isUrlValid is false
    expect(props.onChange).toHaveBeenCalledWith('isUrlValid', false)
  })

  it('validates URL format and shows no error for valid URLs', async () => {
    const user = userEvent.setup()
    const {props} = setUp({itemType: 'external_url'})

    const urlInput = screen.getByLabelText('URL')

    await user.type(urlInput, 'https://example.com')

    await waitFor(() => {
      expect(screen.queryByText('Please enter a valid URL')).not.toBeInTheDocument()
    })

    expect(props.onChange).toHaveBeenCalledWith('isUrlValid', true)
  })
})
