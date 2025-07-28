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

import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import CheckboxTextInput from '../CheckboxTextInput'
import {FormType} from '../../../../types'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('@canvas/do-fetch-api-effect')

// Import the actual context
import {
  AccessibilityCheckerContext,
  type AccessibilityCheckerContextType,
} from '../../../../contexts/AccessibilityCheckerContext'
import React from 'react'

// Create a fully typed mock context
const mockContextValue: AccessibilityCheckerContextType = {
  selectedItem: {
    id: 123,
    type: 'Page' as any, // Using string literal that matches ContentItemType.WikiPage
    title: 'Mock Page',
    published: true,
    updatedAt: '2023-01-01',
    count: 0,
    url: 'http://example.com',
    editUrl: 'http://example.com/edit',
  },
  setSelectedItem: jest.fn(),
  isTrayOpen: false,
  setIsTrayOpen: jest.fn(),
}

// Reset mock implementation before each test
beforeEach(() => {
  jest.resetAllMocks()
})

describe('CheckboxTextInput', () => {
  const defaultProps = {
    issue: {
      id: 'test-id',
      ruleId: 'test-rule',
      message: 'Test message',
      why: 'Test why',
      element: 'test-element',
      displayName: 'Test Display Name',
      path: 'test-path',
      form: {
        type: FormType.CheckboxTextInput,
        checkboxLabel: 'Test Checkbox Label',
        checkboxSubtext: 'Test checkbox subtext',
        label: 'Test TextArea Label',
        inputDescription: 'Test input description',
        inputMaxLength: 100,
      },
    },
    value: '',
    onChangeValue: jest.fn(),
  }

  it('renders without crashing', () => {
    render(
      <AccessibilityCheckerContext.Provider value={mockContextValue}>
        <CheckboxTextInput {...defaultProps} />
      </AccessibilityCheckerContext.Provider>,
    )
    expect(screen.getByTestId('checkbox-text-input-form')).toBeInTheDocument()
  })

  it('displays all text elements correctly', () => {
    render(
      <AccessibilityCheckerContext.Provider value={mockContextValue}>
        <CheckboxTextInput {...defaultProps} />
      </AccessibilityCheckerContext.Provider>,
    )

    expect(screen.getByText('Test Checkbox Label')).toBeInTheDocument()
    expect(screen.getByText('Test checkbox subtext')).toBeInTheDocument()
    expect(screen.getByText('Test TextArea Label')).toBeInTheDocument()
    expect(screen.getByText('Test input description')).toBeInTheDocument()
    expect(screen.getByText('0/100')).toBeInTheDocument()
  })

  it('toggles checkbox and disables/enables textarea accordingly', () => {
    render(
      <AccessibilityCheckerContext.Provider value={mockContextValue}>
        <CheckboxTextInput {...defaultProps} />
      </AccessibilityCheckerContext.Provider>,
    )
    const checkbox = screen.getByLabelText('Test Checkbox Label')
    const textarea = screen.getByTestId('checkbox-text-input-form')

    expect(checkbox).not.toBeChecked()
    expect(textarea).toBeEnabled()

    fireEvent.click(checkbox)
    expect(checkbox).toBeChecked()
    expect(textarea).toBeDisabled()

    fireEvent.click(checkbox)
    expect(checkbox).not.toBeChecked()
    expect(textarea).toBeEnabled()
  })

  it('clears textarea value when checkbox is checked', () => {
    const propsWithValue = {
      ...defaultProps,
      value: 'test value',
    }
    render(
      <AccessibilityCheckerContext.Provider value={mockContextValue}>
        <CheckboxTextInput {...propsWithValue} />
      </AccessibilityCheckerContext.Provider>,
    )
    const checkbox = screen.getByLabelText('Test Checkbox Label')

    fireEvent.click(checkbox)
    expect(defaultProps.onChangeValue).toHaveBeenCalledWith('')
  })

  it('displays the provided value in textarea', () => {
    const propsWithValue = {
      ...defaultProps,
      value: 'test value',
    }
    render(
      <AccessibilityCheckerContext.Provider value={mockContextValue}>
        <CheckboxTextInput {...propsWithValue} />
      </AccessibilityCheckerContext.Provider>,
    )
    const textarea = screen.getByTestId('checkbox-text-input-form')
    expect(textarea).toHaveValue('test value')
  })

  it('shows a generate button when the form has can_generate_fix set', () => {
    const propsWithGenerateOption = {
      ...defaultProps,
      issue: {
        ...defaultProps.issue,
        form: {
          ...defaultProps.issue.form,
          canGenerateFix: true,
          generateButtonLabel: 'Generate Alt Text',
        },
      },
    }

    render(
      <AccessibilityCheckerContext.Provider value={mockContextValue}>
        <CheckboxTextInput {...propsWithGenerateOption} />
      </AccessibilityCheckerContext.Provider>,
    )
    expect(screen.getByText('Generate Alt Text')).toBeInTheDocument()
  })

  it('calls API and updates value when generate button is clicked', async () => {
    const propsWithGenerateOption = {
      ...defaultProps,
      issue: {
        ...defaultProps.issue,
        form: {
          ...defaultProps.issue.form,
          canGenerateFix: true,
          generateButtonLabel: 'Generate Alt Text',
        },
      },
    }

    // Mock the API response
    const mockGeneratedText = 'This is AI generated alt text'
    ;(doFetchApi as jest.Mock).mockImplementation(options => {
      // Test that the path contains "/generate"
      expect(options.path).toContain('/generate')
      // Return our mock response
      return Promise.resolve({
        json: {
          value: mockGeneratedText,
        },
      })
    })

    render(
      <AccessibilityCheckerContext.Provider value={mockContextValue}>
        <CheckboxTextInput {...propsWithGenerateOption} />
      </AccessibilityCheckerContext.Provider>,
    )

    // Click the generate button
    const generateButton = screen.getByText('Generate Alt Text')
    fireEvent.click(generateButton)

    // Verify loading indicator appears
    expect(screen.getByText('Generating...')).toBeInTheDocument()

    // Verify the value gets updated with the API response
    await waitFor(() => {
      expect(defaultProps.onChangeValue).toHaveBeenCalledWith(mockGeneratedText)
    })
  })

  it('handles errors when generate API call fails', async () => {
    const propsWithGenerateOption = {
      ...defaultProps,
      issue: {
        ...defaultProps.issue,
        form: {
          ...defaultProps.issue.form,
          canGenerateFix: true,
          generateButtonLabel: 'Generate Alt Text',
        },
      },
    }

    // Mock console.error to prevent test output pollution
    const consoleSpy = jest.fn()
    const originalConsoleError = console.error
    console.error = consoleSpy

    // Mock API failure
    ;(doFetchApi as jest.Mock).mockImplementation(options => {
      // Test that the path contains "/generate"
      expect(options.path).toContain('/generate')
      // Return a rejected promise
      return Promise.reject(new Error('API Error'))
    })

    render(
      <AccessibilityCheckerContext.Provider value={mockContextValue}>
        <CheckboxTextInput {...propsWithGenerateOption} />
      </AccessibilityCheckerContext.Provider>,
    )

    // Click the generate button
    const generateButton = screen.getByText('Generate Alt Text')
    fireEvent.click(generateButton)

    // Wait for the async operation to complete
    await waitFor(() => {
      expect(consoleSpy).toHaveBeenCalledWith('Error during generation:', expect.any(Error))
    })

    // Check that loading state is cleared
    expect(screen.queryByText('Generating...')).not.toBeInTheDocument()

    // Restore the original console.error
    console.error = originalConsoleError
  })

  it('does not call onReload on initial mount', () => {
    const onReload = jest.fn()
    render(<CheckboxTextInput {...defaultProps} onReload={onReload} />)
    expect(onReload).not.toHaveBeenCalled()
  })

  it('calls onReload when the value changes', async () => {
    const onReload = jest.fn()
    const {rerender} = render(<CheckboxTextInput {...defaultProps} onReload={onReload} />)
    expect(onReload).not.toHaveBeenCalled()
    rerender(<CheckboxTextInput {...defaultProps} onReload={onReload} value="test value" />)
    expect(onReload).toHaveBeenCalledWith('test value')
  })
})
