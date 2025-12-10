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
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import CheckboxTextInput from '../CheckboxTextInput'
import {FormType, IssueWorkflowState} from '../../../../types'

const server = setupServer()

// Import the actual context
import {
  AccessibilityCheckerContext,
  type AccessibilityCheckerContextType,
} from '../../../../contexts/AccessibilityCheckerContext'
import {getAsAccessibilityResourceScan} from '../../../../utils/apiData'
import {useAccessibilityScansStore} from '../../../../stores/AccessibilityScansStore'

jest.mock('../../../../stores/AccessibilityScansStore')

// Create a fully typed mock context
const mockContextValue: AccessibilityCheckerContextType = {
  selectedItem: getAsAccessibilityResourceScan({
    id: 123,
    type: 'Page' as any, // Using string literal that matches ContentItemType.WikiPage
    title: 'Mock Page',
    published: true,
    updatedAt: '2023-01-01',
    count: 0,
    url: 'http://example.com',
    editUrl: 'http://example.com/edit',
  }),
  setSelectedItem: jest.fn(),
  isTrayOpen: false,
  setIsTrayOpen: jest.fn(),
}

beforeAll(() => server.listen())
afterAll(() => server.close())

beforeEach(() => {
  server.resetHandlers()
  jest.resetAllMocks()
  ;(useAccessibilityScansStore as unknown as jest.Mock).mockImplementation((selector: any) => {
    const state = {aiGenerationEnabled: true}
    return selector(state)
  })
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
      workflowState: IssueWorkflowState.Active,
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
  })

  it('toggles checkbox and disables/enables textarea accordingly', () => {
    render(
      <AccessibilityCheckerContext.Provider value={mockContextValue}>
        <CheckboxTextInput {...defaultProps} />
      </AccessibilityCheckerContext.Provider>,
    )
    const checkbox = screen.getByRole('checkbox', {
      name: 'Test Checkbox Label Test checkbox subtext',
    })
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
    const checkbox = screen.getByRole('checkbox', {
      name: 'Test Checkbox Label Test checkbox subtext',
    })

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
    let generateCalled = false
    server.use(
      // Match both /generate and //generate (double slash from URL construction)
      http.post('**/generate', () => {
        generateCalled = true
        return HttpResponse.json({
          value: mockGeneratedText,
        })
      }),
    )

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
      expect(generateCalled).toBe(true)
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

    // Mock console.error to suppress expected error output
    const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})

    // Mock API failure
    server.use(
      // Match both /generate and //generate (double slash from URL construction)
      http.post('**/generate', () => {
        return new HttpResponse(null, {status: 500})
      }),
    )

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

    // Wait for the loading state to be cleared after the error
    await waitFor(() => {
      expect(screen.queryByText('Generating...')).not.toBeInTheDocument()
    })

    // Verify that console.error was called with the expected error
    expect(consoleErrorSpy).toHaveBeenCalledWith('Error generating text input:', expect.any(Error))

    // Verify that onChangeValue was not called (since the API failed)
    expect(defaultProps.onChangeValue).not.toHaveBeenCalled()

    // Restore console.error
    consoleErrorSpy.mockRestore()
  })

  describe('onValidationChange callback', () => {
    it('calls onValidationChange when user types valid text', async () => {
      const onValidationChange = jest.fn()
      const onChangeValue = jest.fn()

      const {rerender} = render(
        <AccessibilityCheckerContext.Provider value={mockContextValue}>
          <CheckboxTextInput
            {...defaultProps}
            onValidationChange={onValidationChange}
            onChangeValue={onChangeValue}
          />
        </AccessibilityCheckerContext.Provider>,
      )

      onValidationChange.mockClear()

      const textarea = screen.getByTestId('checkbox-text-input-form')
      fireEvent.change(textarea, {target: {value: 'Valid alt text'}})

      rerender(
        <AccessibilityCheckerContext.Provider value={mockContextValue}>
          <CheckboxTextInput
            {...defaultProps}
            value="Valid alt text"
            onValidationChange={onValidationChange}
            onChangeValue={onChangeValue}
          />
        </AccessibilityCheckerContext.Provider>,
      )

      await waitFor(() => {
        expect(onValidationChange).toHaveBeenCalledWith(true, undefined)
      })
    })

    it('calls onValidationChange when text exceeds max length', async () => {
      const onValidationChange = jest.fn()
      const onChangeValue = jest.fn()

      const {rerender} = render(
        <AccessibilityCheckerContext.Provider value={mockContextValue}>
          <CheckboxTextInput
            {...defaultProps}
            onValidationChange={onValidationChange}
            onChangeValue={onChangeValue}
          />
        </AccessibilityCheckerContext.Provider>,
      )

      onValidationChange.mockClear()

      const longText = 'a'.repeat(150)
      const textarea = screen.getByTestId('checkbox-text-input-form')
      fireEvent.change(textarea, {target: {value: longText}})

      rerender(
        <AccessibilityCheckerContext.Provider value={mockContextValue}>
          <CheckboxTextInput
            {...defaultProps}
            value={longText}
            onValidationChange={onValidationChange}
            onChangeValue={onChangeValue}
          />
        </AccessibilityCheckerContext.Provider>,
      )

      await waitFor(() => {
        expect(onValidationChange).toHaveBeenCalledWith(
          false,
          'Keep alt text under 100 characters.',
        )
      })
    })

    it('calls onValidationChange when checkbox is checked (decorative image)', async () => {
      const onValidationChange = jest.fn()

      render(
        <AccessibilityCheckerContext.Provider value={mockContextValue}>
          <CheckboxTextInput {...defaultProps} onValidationChange={onValidationChange} />
        </AccessibilityCheckerContext.Provider>,
      )

      onValidationChange.mockClear()

      const checkbox = screen.getByRole('checkbox', {
        name: 'Test Checkbox Label Test checkbox subtext',
      })
      fireEvent.click(checkbox)

      expect(onValidationChange).toHaveBeenCalledWith(true, undefined)
    })

    it('calls onValidationChange when textarea is empty', async () => {
      const onValidationChange = jest.fn()

      render(
        <AccessibilityCheckerContext.Provider value={mockContextValue}>
          <CheckboxTextInput {...defaultProps} onValidationChange={onValidationChange} />
        </AccessibilityCheckerContext.Provider>,
      )

      expect(onValidationChange).toHaveBeenCalledWith(false, 'Alt text is required.')
    })
  })

  describe('AI generation feature flag', () => {
    it('shows generate button when feature flag is enabled', () => {
      ;(useAccessibilityScansStore as unknown as jest.Mock).mockImplementation((selector: any) => {
        const state = {aiGenerationEnabled: true}
        return selector(state)
      })

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

    it('hides generate button when feature flag is disabled', () => {
      ;(useAccessibilityScansStore as unknown as jest.Mock).mockImplementation((selector: any) => {
        const state = {aiGenerationEnabled: false}
        return selector(state)
      })

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

      expect(screen.queryByText('Generate Alt Text')).not.toBeInTheDocument()
    })
  })

  describe('action buttons', () => {
    it('renders custom action buttons when provided', () => {
      const actionButtons = <button data-testid="custom-action-button">Custom Action</button>

      render(
        <AccessibilityCheckerContext.Provider value={mockContextValue}>
          <CheckboxTextInput {...defaultProps} actionButtons={actionButtons} />
        </AccessibilityCheckerContext.Provider>,
      )

      expect(screen.getByTestId('custom-action-button')).toBeInTheDocument()
      expect(screen.getByText('Custom Action')).toBeInTheDocument()
    })

    it('renders action buttons alongside generate button', () => {
      const actionButtons = <button data-testid="custom-action-button">Custom Action</button>
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
        actionButtons,
      }

      render(
        <AccessibilityCheckerContext.Provider value={mockContextValue}>
          <CheckboxTextInput {...propsWithGenerateOption} />
        </AccessibilityCheckerContext.Provider>,
      )

      expect(screen.getByText('Generate Alt Text')).toBeInTheDocument()
      expect(screen.getByTestId('custom-action-button')).toBeInTheDocument()
    })
  })

  describe('isDisabled prop', () => {
    it('disables textarea when isDisabled is true', () => {
      render(
        <AccessibilityCheckerContext.Provider value={mockContextValue}>
          <CheckboxTextInput {...defaultProps} isDisabled={true} />
        </AccessibilityCheckerContext.Provider>,
      )

      const textarea = screen.getByTestId('checkbox-text-input-form')
      expect(textarea).toBeDisabled()
    })
  })
})
