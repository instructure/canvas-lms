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
import ExternalToolSelector, {ExternalTool} from '../ExternalToolSelector'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../../hooks/useModuleContext'
import {ContentItem} from '../../../hooks/queries/useModuleItemContent'
import {ExternalToolModalItem} from '../../../utils/types'

const contentItems: ExternalToolModalItem[] = [
  {
    definition_id: '1',
    definition_type: 'external_tool',
    name: 'Google Docs',
    description: 'Create and edit documents online',
    domain: 'docs.google.com',
    url: 'https://docs.google.com/launch',
    placements: {
      assignmentSelection: {
        url: 'https://docs.google.com/assignment',
        title: 'Google Docs Assignment',
      },
      linkSelection: {
        url: 'https://docs.google.com/link',
        title: 'Google Docs Link',
      },
    },
  },
  {
    definition_id: '2',
    definition_type: 'external_tool',
    name: 'YouTube',
    description: 'Video platform',
    domain: 'youtube.com',
    url: 'https://youtube.com/launch',
    placements: {
      linkSelection: {
        url: 'https://youtube.com/link',
        title: 'YouTube Video',
      },
    },
  },
  {
    definition_id: '3',
    definition_type: 'external_tool',
    name: 'Khan Academy',
    description: 'Educational platform',
    domain: 'khanacademy.org',
    placements: {
      assignmentSelection: {
        url: 'https://khanacademy.org/assignment',
        title: 'Khan Academy Exercise',
      },
    },
  },
]

const buildProps = (overrides = {}) => ({
  onToolSelect: vi.fn(),
  contentItems: contentItems,
  ...overrides,
})

const setUp = (props = {}) => {
  const finalProps = buildProps(props)
  return {
    ...render(<ExternalToolSelector {...finalProps} />),
    props: finalProps,
  }
}

describe('ExternalToolSelector', () => {
  it('renders with available tools', () => {
    const {container} = setUp()

    expect(screen.getByText('Select External Tool')).toBeInTheDocument()
    expect(screen.getByRole('combobox', {name: /select external tool/i})).toBeInTheDocument()
    expect(container).toBeInTheDocument()
  })

  it('shows "no tools available" message when no external tools provided', () => {
    setUp({contentItems: []})

    expect(screen.getByText('No external tools are available for this course')).toBeInTheDocument()
  })

  it('calls onToolSelect when a tool is selected', async () => {
    const user = userEvent.setup()
    const {props} = setUp()

    // Open the select dropdown
    const selectInput = screen.getByRole('combobox', {name: /select external tool/i})
    await user.click(selectInput)

    // Wait for options to appear and select Google Docs
    await waitFor(() => {
      expect(screen.getByText('Google Docs')).toBeInTheDocument()
    })

    await user.click(screen.getByText('Google Docs'))

    expect(props.onToolSelect).toHaveBeenCalledWith(contentItems[0])
  })

  it('calls onToolSelect with null when "Select a tool" is chosen', async () => {
    const user = userEvent.setup()
    const {props} = setUp({selectedToolId: '1'})

    const selectInput = screen.getByRole('combobox', {name: /select external tool/i})
    await user.click(selectInput)

    await waitFor(() => {
      expect(screen.getByText('Select a tool')).toBeInTheDocument()
    })

    await user.click(screen.getByText('Select a tool'))

    expect(props.onToolSelect).toHaveBeenCalledWith(null)
  })

  it('displays selected tool information', () => {
    setUp({selectedToolId: '1'})

    expect(screen.getByText('Selected Tool: Google Docs')).toBeInTheDocument()
    expect(screen.getByText('Create and edit documents online')).toBeInTheDocument()
    expect(screen.getByText('Domain: docs.google.com')).toBeInTheDocument()
  })

  it('handles tools without descriptions or domains', () => {
    const toolsWithoutDetails: ExternalToolModalItem[] = [
      {
        definition_id: '4',
        definition_type: 'external_tool',
        name: 'Simple Tool',
        placements: {},
      },
    ]

    setUp({selectedToolId: '4', contentItems: toolsWithoutDetails})

    expect(screen.getByText('Selected Tool: Simple Tool')).toBeInTheDocument()
    expect(screen.queryByText('Domain:')).not.toBeInTheDocument()
  })

  it('is disabled when disabled prop is true', () => {
    setUp({disabled: true})

    const selectInput = screen.getByRole('combobox', {name: /select external tool/i})
    expect(selectInput).toBeDisabled()
  })

  it('sorts tools alphabetically', async () => {
    const user = userEvent.setup()
    setUp()

    const selectInput = screen.getByRole('combobox', {name: /select external tool/i})
    await user.click(selectInput)

    await waitFor(() => {
      const options = screen.getAllByRole('option')
      // First option should be "Select a tool", then tools in alphabetical order
      expect(options[1]).toHaveTextContent('Google Docs')
      expect(options[2]).toHaveTextContent('Khan Academy')
      expect(options[3]).toHaveTextContent('YouTube')
    })
  })

  it('handles tool selection through dropdown', async () => {
    const user = userEvent.setup()
    setUp()

    const selectInput = screen.getByRole('combobox', {name: /select external tool/i})

    // Open dropdown
    await user.click(selectInput)

    await waitFor(() => {
      // Should show tools in dropdown
      expect(screen.getByText('Google Docs')).toBeInTheDocument()
    })
  })

  it('shows tool names in dropdown options', async () => {
    const user = userEvent.setup()
    setUp()

    const selectInput = screen.getByRole('combobox', {name: /select external tool/i})
    await user.click(selectInput)

    await waitFor(() => {
      expect(screen.getByText('Google Docs')).toBeInTheDocument()
      expect(screen.getByText('YouTube')).toBeInTheDocument()
      expect(screen.getByText('Khan Academy')).toBeInTheDocument()
    })
  })
})
