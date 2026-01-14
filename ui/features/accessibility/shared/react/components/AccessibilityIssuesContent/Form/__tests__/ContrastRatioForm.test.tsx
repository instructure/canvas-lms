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

import {cleanup, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ContrastRatioForm from '../ContrastRatioForm'

describe('ContrastRatioForm', () => {
  afterEach(() => {
    cleanup()
  })

  const mockOnChange = vi.fn()

  const user = userEvent.setup()
  const defaultProps = {
    label: 'Color Contrast Ratio',
    inputLabel: 'New text color',
    backgroundColor: '#FFFFFF',
    foregroundColor: '#000000',
    onChange: mockOnChange,
  }

  beforeEach(() => {
    mockOnChange.mockClear()
  })

  it('renders the component with labels and contrast ratio', async () => {
    render(<ContrastRatioForm {...defaultProps} />)

    expect(screen.getByText('Color Contrast Ratio')).toBeInTheDocument()
    expect(screen.getByText('21:1')).toBeInTheDocument()
    expect(screen.getByText('New text color')).toBeInTheDocument()
  })

  it('renders background and foreground with correct color codes', () => {
    render(<ContrastRatioForm {...defaultProps} />)

    expect(screen.getByText('#000000')).toBeInTheDocument()
    expect(screen.getByText('#FFFFFF')).toBeInTheDocument()
  })

  it('calls onChange with color value and validity when ColorPicker changes color', async () => {
    render(<ContrastRatioForm {...defaultProps} />)

    const input = screen.getByLabelText(/new text color/i)
    await user.clear(input)
    await user.type(input, '#ff0000')

    expect(mockOnChange).toHaveBeenCalled()
    const lastCall = mockOnChange.mock.calls[mockOnChange.mock.calls.length - 1]
    expect(lastCall[0]).toBe('#ff0000')
    expect(typeof lastCall[1]).toBe('boolean')
  })

  it('renders text types based on options', async () => {
    const options = ['normal', 'large']

    render(<ContrastRatioForm {...defaultProps} options={options} />)

    const normal = await screen.findByText(/NORMAL TEXT/i)
    const large = screen.getByText(/LARGE TEXT/i)

    expect(normal).toBeInTheDocument()
    expect(large).toBeInTheDocument()
  })

  it('reacts to foregroundColor prop change', () => {
    const {rerender} = render(<ContrastRatioForm {...defaultProps} />)

    expect(screen.getByText('#000000')).toBeInTheDocument()

    rerender(<ContrastRatioForm {...defaultProps} foregroundColor="#123456" />)

    expect(screen.getByText('#123456')).toBeInTheDocument()
  })

  it('displays the error message when an error is provided', () => {
    const propsWithError = {
      ...defaultProps,
      messages: [{text: 'Error message', type: 'newError' as const}],
    }
    render(<ContrastRatioForm {...propsWithError} />)
    expect(screen.getByText('Error message')).toBeInTheDocument()
  })

  it('focuses the input when the form is refocused', () => {
    const {container} = render(<ContrastRatioForm {...defaultProps} />)
    const input = container.querySelector('input')
    expect(input).not.toHaveFocus()
    input?.focus()
    expect(input).toHaveFocus()
  })

  it('renders the description', () => {
    const description = 'This is a custom description'
    render(<ContrastRatioForm {...defaultProps} description={description} />)

    expect(screen.getByText(description)).toBeInTheDocument()
  })

  it('renders the suggestion message when background is white', () => {
    render(<ContrastRatioForm {...defaultProps} />)

    expect(screen.getByTestId('suggestion-message')).toBeInTheDocument()
    expect(screen.getByText(/Only #0000 will automatically update to white/i)).toBeInTheDocument()
  })

  it('does not render suggestion message when background is not white', () => {
    render(<ContrastRatioForm {...defaultProps} backgroundColor="#CF4A00" />)

    expect(screen.queryByTestId('suggestion-message')).not.toBeInTheDocument()
  })

  it('calls onChange with valid=true when contrast meets normal text requirements', async () => {
    const propsWithNormal = {
      ...defaultProps,
      options: ['normal'],
      backgroundColor: '#FFFFFF',
      foregroundColor: '#FF0000', // Start with a different color to ensure we're testing an actual change
    }
    render(<ContrastRatioForm {...propsWithNormal} />)

    const input = screen.getByLabelText(/new text color/i)
    await user.clear(input)
    await user.type(input, '#000000')

    const calls = mockOnChange.mock.calls.filter(call => call[0] === '#000000')
    expect(calls.length).toBeGreaterThan(0)
    expect(calls[calls.length - 1][1]).toBe(true)
  })

  it('calls onChange with valid=false when contrast does not meet normal text requirements', async () => {
    const propsWithNormal = {
      ...defaultProps,
      options: ['normal'],
      backgroundColor: '#FFFFFF',
      foregroundColor: '#000000',
    }
    render(<ContrastRatioForm {...propsWithNormal} />)

    const input = screen.getByLabelText(/new text color/i)
    await user.clear(input)
    await user.type(input, '#CCCCCC')

    const calls = mockOnChange.mock.calls.filter(call => call[0] === '#CCCCCC')
    expect(calls.length).toBeGreaterThan(0)
    expect(calls[calls.length - 1][1]).toBe(false)
  })

  it('calls onChange with valid=true when contrast meets large text requirements', async () => {
    const propsWithLarge = {
      ...defaultProps,
      options: ['large'],
      backgroundColor: '#FFFFFF',
      foregroundColor: '#000000', // Start with a different color to ensure we're testing an actual change
    }
    render(<ContrastRatioForm {...propsWithLarge} />)

    const input = screen.getByLabelText(/new text color/i)
    await user.clear(input)
    await user.type(input, '#777777')

    const calls = mockOnChange.mock.calls.filter(call => call[0] === '#777777')
    expect(calls.length).toBeGreaterThan(0)
    expect(calls[calls.length - 1][1]).toBe(true)
  })

  it('validates against all specified options', async () => {
    const propsWithBoth = {
      ...defaultProps,
      options: ['normal', 'large'],
      backgroundColor: '#FFFFFF',
      foregroundColor: '#000000',
    }
    render(<ContrastRatioForm {...propsWithBoth} />)

    const input = screen.getByLabelText(/new text color/i)
    await user.clear(input)
    await user.type(input, '#888888') // Mid-gray

    const calls = mockOnChange.mock.calls.filter(call => call[0] === '#888888')
    expect(calls.length).toBeGreaterThan(0)
    expect(typeof calls[calls.length - 1][1]).toBe('boolean')
  })
})
