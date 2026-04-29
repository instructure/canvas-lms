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
import {cleanup, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {UtidSelector} from '../UtidSelector'
import * as useUtidMatchingModule from '../../hooks/useUtidMatching'
import {type MockedFunction} from 'vitest'

vi.mock('../../hooks/useUtidMatching')

const mockUseUtidMatching = useUtidMatchingModule.useUtidMatching as MockedFunction<
  typeof useUtidMatchingModule.useUtidMatching
>

describe('UtidSelector', () => {
  const defaultProps = {
    redirectUris: 'https://example.com/redirect',
    accountId: '123',
    selectedUtid: null,
    onUtidChange: vi.fn(),
    showRequiredMessage: false,
  }

  const mockMatches = [
    {
      unified_tool_id: '550e8400-e29b-41d4-a716-446655440000',
      global_product_id: 'e8f9a0b1-c2d3-4567-e890-123456789abc',
      tool_name: 'Math Learning Platform',
      tool_id: 789,
      company_id: 456,
      company_name: 'Educational Tech Solutions',
      source: 'partner_provided',
    },
    {
      unified_tool_id: '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
      global_product_id: 'd7e8f9a0-b1c2-4345-d678-90abcdef1234',
      tool_name: 'Science Lab Simulator',
      tool_id: 321,
      company_id: 654,
      company_name: 'STEM Education Corp',
      source: 'manual',
    },
  ]

  afterEach(() => {
    cleanup()
  })

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders with label', () => {
    mockUseUtidMatching.mockReturnValue({
      matches: [],
      loading: false,
      error: null,
    })

    render(<UtidSelector {...defaultProps} />)
    expect(screen.getByText('Linked Partner App:')).toBeInTheDocument()
  })

  it('shows loading state', () => {
    mockUseUtidMatching.mockReturnValue({
      matches: [],
      loading: true,
      error: null,
    })

    render(<UtidSelector {...defaultProps} />)
    expect(screen.getByPlaceholderText('Checking')).toBeInTheDocument()
    expect(screen.getByTitle('Checking')).toBeInTheDocument()
  })

  it('shows loading state with "Checking" text even when field is populated', () => {
    mockUseUtidMatching.mockReturnValue({
      matches: mockMatches,
      loading: true,
      error: null,
    })

    render(<UtidSelector {...defaultProps} selectedUtid="550e8400-e29b-41d4-a716-446655440000" />)

    expect(screen.getByPlaceholderText('Checking')).toBeInTheDocument()
    expect(screen.getByTitle('Checking')).toBeInTheDocument()

    const select = screen.getByTestId('utid-selector')
    expect(select).toHaveAttribute('disabled')
  })

  it('shows error state', () => {
    mockUseUtidMatching.mockReturnValue({
      matches: [],
      loading: false,
      error: 'API Error',
    })

    render(<UtidSelector {...defaultProps} />)
    expect(screen.getByPlaceholderText('Error loading products')).toBeInTheDocument()
  })

  it('shows "no matches" message when no matches found', () => {
    mockUseUtidMatching.mockReturnValue({
      matches: [],
      loading: false,
      error: null,
    })

    render(<UtidSelector {...defaultProps} />)
    expect(screen.getByPlaceholderText('No products match these URIs')).toBeInTheDocument()
  })

  it('disables dropdown when no matches', () => {
    mockUseUtidMatching.mockReturnValue({
      matches: [],
      loading: false,
      error: null,
    })

    render(<UtidSelector {...defaultProps} />)
    const select = screen.getByTestId('utid-selector')
    expect(select).toHaveAttribute('disabled')
  })

  it('disables dropdown when loading', () => {
    mockUseUtidMatching.mockReturnValue({
      matches: mockMatches,
      loading: true,
      error: null,
    })

    render(<UtidSelector {...defaultProps} />)
    const select = screen.getByTestId('utid-selector')
    expect(select).toHaveAttribute('disabled')
  })

  it('enables dropdown when matches are available', () => {
    mockUseUtidMatching.mockReturnValue({
      matches: mockMatches,
      loading: false,
      error: null,
    })

    render(<UtidSelector {...defaultProps} />)
    const select = screen.getByTestId('utid-selector')
    expect(select).not.toHaveAttribute('disabled')
  })

  it('displays multiple matches as options', async () => {
    mockUseUtidMatching.mockReturnValue({
      matches: mockMatches,
      loading: false,
      error: null,
    })

    render(<UtidSelector {...defaultProps} />)

    const select = screen.getByTestId('utid-selector')
    await userEvent.click(select)

    expect(
      screen.getByText('Educational Tech Solutions - Math Learning Platform'),
    ).toBeInTheDocument()
    expect(screen.getByText('STEM Education Corp - Science Lab Simulator')).toBeInTheDocument()
  })

  it('auto-selects when only one match', () => {
    const onUtidChange = vi.fn()
    const singleMatch = [mockMatches[0]]

    mockUseUtidMatching.mockReturnValue({
      matches: singleMatch,
      loading: false,
      error: null,
    })

    render(<UtidSelector {...defaultProps} onUtidChange={onUtidChange} />)

    expect(onUtidChange).toHaveBeenCalledWith(singleMatch[0].unified_tool_id)
  })

  it('does not auto-select when already selected', () => {
    const onUtidChange = vi.fn()
    const singleMatch = [mockMatches[0]]

    mockUseUtidMatching.mockReturnValue({
      matches: singleMatch,
      loading: false,
      error: null,
    })

    render(
      <UtidSelector
        {...defaultProps}
        selectedUtid={singleMatch[0].unified_tool_id}
        onUtidChange={onUtidChange}
      />,
    )

    expect(onUtidChange).not.toHaveBeenCalled()
  })

  it('clears existing utid when no matches (for editing existing keys)', () => {
    const onUtidChange = vi.fn()

    mockUseUtidMatching.mockReturnValue({
      matches: [],
      loading: false,
      error: null,
    })

    render(
      <UtidSelector
        {...defaultProps}
        selectedUtid="550e8400-e29b-41d4-a716-446655440000"
        onUtidChange={onUtidChange}
      />,
    )

    expect(onUtidChange).toHaveBeenCalledWith(null)
  })

  it('shows validation error when required and not selected', () => {
    mockUseUtidMatching.mockReturnValue({
      matches: mockMatches,
      loading: false,
      error: null,
    })

    render(<UtidSelector {...defaultProps} showRequiredMessage={true} />)

    expect(
      screen.getByText('Please select a linked partner app when matches are available'),
    ).toBeInTheDocument()
  })

  it('does not show validation error when not required', () => {
    mockUseUtidMatching.mockReturnValue({
      matches: [],
      loading: false,
      error: null,
    })

    render(<UtidSelector {...defaultProps} showRequiredMessage={true} />)

    expect(
      screen.queryByText('Please select an Linked Partner App when matches are available'),
    ).not.toBeInTheDocument()
  })

  it('calls onUtidChange when selection changes', async () => {
    const onUtidChange = vi.fn()

    mockUseUtidMatching.mockReturnValue({
      matches: mockMatches,
      loading: false,
      error: null,
    })

    render(<UtidSelector {...defaultProps} onUtidChange={onUtidChange} />)

    const select = screen.getByTestId('utid-selector')
    await userEvent.click(select)

    const option = screen.getByText('Educational Tech Solutions - Math Learning Platform')
    await userEvent.click(option)

    expect(onUtidChange).toHaveBeenCalledWith(mockMatches[0].unified_tool_id)
  })

  it('marks field as required when matches exist and nothing is selected', () => {
    mockUseUtidMatching.mockReturnValue({
      matches: mockMatches,
      loading: false,
      error: null,
    })

    render(<UtidSelector {...defaultProps} />)

    const label = screen.getByText('Linked Partner App:')
    expect(label.parentElement).toHaveTextContent('*')
  })

  it('does not mark field as required when matches exist but something is already selected', () => {
    mockUseUtidMatching.mockReturnValue({
      matches: mockMatches,
      loading: false,
      error: null,
    })

    render(<UtidSelector {...defaultProps} selectedUtid={mockMatches[0].unified_tool_id} />)

    const label = screen.getByText('Linked Partner App:')
    expect(label.parentElement).not.toHaveTextContent('*')
  })

  it('does not mark field as required when no matches', () => {
    mockUseUtidMatching.mockReturnValue({
      matches: [],
      loading: false,
      error: null,
    })

    render(<UtidSelector {...defaultProps} />)

    const select = screen.getByTestId('utid-selector')
    expect(select).not.toHaveAttribute('required')
  })

  it('shows tooltip with explanation text on focus', async () => {
    mockUseUtidMatching.mockReturnValue({
      matches: mockMatches,
      loading: false,
      error: null,
    })

    render(<UtidSelector {...defaultProps} />)

    const infoButton = screen.getByTestId('dev-key-utid-selector-info')

    expect(infoButton).toBeInTheDocument()

    infoButton.focus()

    const tooltip = await screen.findByRole('tooltip', {
      name: /We suggest apps based on the redirect URIs.*Please select an app/i,
    })
    expect(tooltip).toBeInTheDocument()
  })

  it('shows tooltip with explanation text on hover', async () => {
    mockUseUtidMatching.mockReturnValue({
      matches: mockMatches,
      loading: false,
      error: null,
    })

    render(<UtidSelector {...defaultProps} />)

    const infoButton = screen.getByTestId('dev-key-utid-selector-info')

    expect(infoButton).toBeInTheDocument()

    await userEvent.hover(infoButton)

    const tooltip = await screen.findByRole('tooltip', {
      name: /We suggest apps based on the redirect URIs.*Please select an app/i,
    })
    expect(tooltip).toBeInTheDocument()
  })

  it('calls onValidationChange with invalid when matches are available but nothing is selected', () => {
    const onValidationChange = vi.fn()

    mockUseUtidMatching.mockReturnValue({
      matches: mockMatches,
      loading: false,
      error: null,
    })

    render(<UtidSelector {...defaultProps} onValidationChange={onValidationChange} />)

    expect(onValidationChange).toHaveBeenCalledWith(false)
  })

  it('calls onValidationChange with valid when matches are available and one is selected', () => {
    const onValidationChange = vi.fn()

    mockUseUtidMatching.mockReturnValue({
      matches: mockMatches,
      loading: false,
      error: null,
    })

    render(
      <UtidSelector
        {...defaultProps}
        selectedUtid={mockMatches[0].unified_tool_id}
        onValidationChange={onValidationChange}
      />,
    )

    expect(onValidationChange).toHaveBeenCalledWith(true)
  })

  it('calls onValidationChange with valid when no matches are available', () => {
    const onValidationChange = vi.fn()

    mockUseUtidMatching.mockReturnValue({
      matches: [],
      loading: false,
      error: null,
    })

    render(<UtidSelector {...defaultProps} onValidationChange={onValidationChange} />)

    expect(onValidationChange).toHaveBeenCalledWith(true)
  })

  it('preserves pre-existing UTID selection when editing a key', () => {
    const onUtidChange = vi.fn()
    const onValidationChange = vi.fn()
    const existingUtid = '550e8400-e29b-41d4-a716-446655440000'

    mockUseUtidMatching.mockReturnValue({
      matches: mockMatches,
      loading: false,
      error: null,
    })

    render(
      <UtidSelector
        {...defaultProps}
        selectedUtid={existingUtid}
        onUtidChange={onUtidChange}
        onValidationChange={onValidationChange}
      />,
    )

    expect(onUtidChange).not.toHaveBeenCalled()
    expect(onValidationChange).toHaveBeenCalledWith(true)
  })

  it('preserves pre-existing UTID even when not in current matches', () => {
    const onUtidChange = vi.fn()
    const onValidationChange = vi.fn()
    const existingUtid = 'some-other-utid-not-in-matches'

    mockUseUtidMatching.mockReturnValue({
      matches: mockMatches,
      loading: false,
      error: null,
    })

    render(
      <UtidSelector
        {...defaultProps}
        selectedUtid={existingUtid}
        onUtidChange={onUtidChange}
        onValidationChange={onValidationChange}
      />,
    )

    expect(onUtidChange).not.toHaveBeenCalled()
    expect(onValidationChange).toHaveBeenCalledWith(true)
  })
})
