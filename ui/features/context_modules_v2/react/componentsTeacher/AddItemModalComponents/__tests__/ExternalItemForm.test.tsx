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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ExternalItemForm from '../ExternalItemForm'
import {ExternalTool} from '../ExternalToolSelector'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../../hooks/useModuleContext'

const mockTool: ExternalTool = {
  definition_type: 'ContextExternalTool',
  definition_id: '1',
  name: 'Google Docs',
  description: 'Create and edit documents online',
  domain: 'docs.google.com',
  url: 'https://docs.google.com/launch',
  placements: {
    assignment_selection: {
      url: 'https://docs.google.com/assignment',
      title: 'Google Docs Assignment',
    },
    link_selection: {
      url: 'https://docs.google.com/link',
      title: 'Google Docs Link',
    },
  },
}

const buildProps = (overrides = {}) => ({
  onChange: jest.fn(),
  itemType: 'external_url' as const,
  ...overrides,
})

const setUp = (props = {}, externalTools: ExternalTool[] = [mockTool]) => {
  const finalProps = buildProps(props)
  return {
    ...render(
      <ContextModuleProvider {...contextModuleDefaultProps} externalTools={externalTools}>
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

    it('calls onChange with selected tool data', async () => {
      const user = userEvent.setup()
      const {props} = setUp({itemType: 'external_tool'})

      const selectInput = screen.getByRole('combobox', {name: /select external tool/i})
      await user.click(selectInput)

      await waitFor(() => {
        expect(screen.getByText('Google Docs')).toBeInTheDocument()
      })

      await user.click(screen.getByText('Google Docs'))

      expect(props.onChange).toHaveBeenCalledWith('url', 'https://docs.google.com/assignment')
      expect(props.onChange).toHaveBeenCalledWith('name', 'Google Docs Assignment')
      expect(props.onChange).toHaveBeenCalledWith('selectedToolId', '1')
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
})
