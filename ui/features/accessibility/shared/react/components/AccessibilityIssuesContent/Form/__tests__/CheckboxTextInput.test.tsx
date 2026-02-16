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

import {cleanup, render, screen, fireEvent, waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import CheckboxTextInput from '../CheckboxTextInput'
import {FormType, IssueWorkflowState} from '../../../../types'

const server = setupServer()

import {useAccessibilityScansStore} from '../../../../stores/AccessibilityScansStore'

vi.mock('../../../../stores/AccessibilityScansStore')

beforeAll(() => server.listen())
afterAll(() => server.close())

afterEach(() => {
  cleanup()
})

beforeEach(() => {
  server.resetHandlers()
  vi.resetAllMocks()
  ;(useAccessibilityScansStore as unknown as any).mockImplementation((selector: any) => {
    const state = {isAiAltTextGenerationEnabled: true}
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
    onChangeValue: vi.fn(),
  }

  it('renders without crashing', () => {
    render(<CheckboxTextInput {...defaultProps} />)
    expect(screen.getByTestId('checkbox-text-input-form')).toBeInTheDocument()
  })

  it('displays all text elements correctly', () => {
    render(<CheckboxTextInput {...defaultProps} />)

    expect(screen.getByText('Test Checkbox Label')).toBeInTheDocument()
    expect(screen.getByText('Test checkbox subtext')).toBeInTheDocument()
    expect(screen.getByText('Test TextArea Label')).toBeInTheDocument()
    expect(screen.getByText('Test input description')).toBeInTheDocument()
  })

  it('toggles checkbox and disables/enables textarea accordingly', () => {
    render(<CheckboxTextInput {...defaultProps} />)
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
    render(<CheckboxTextInput {...propsWithValue} />)
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
    render(<CheckboxTextInput {...propsWithValue} />)
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
          isCanvasImage: true,
          generateButtonLabel: 'Generate Alt Text',
        },
      },
    }

    render(<CheckboxTextInput {...propsWithGenerateOption} />)
    const button = screen.getByTestId('generate-alt-text-button')
    expect(button).toBeInTheDocument()
    expect(button).not.toBeDisabled()
  })

  it('shows generate button as disabled when isCanvasImage is false', () => {
    const propsWithGenerateDisabled = {
      ...defaultProps,
      issue: {
        ...defaultProps.issue,
        form: {
          ...defaultProps.issue.form,
          canGenerateFix: true,
          isCanvasImage: false,
          generateButtonLabel: 'Generate Alt Text',
        },
      },
    }

    render(<CheckboxTextInput {...propsWithGenerateDisabled} />)
    const button = screen.getByTestId('generate-alt-text-button')
    expect(button).toBeInTheDocument()
    expect(button).toBeDisabled()
  })

  it('disables generate button when checkbox is checked', () => {
    const propsWithGenerateOption = {
      ...defaultProps,
      issue: {
        ...defaultProps.issue,
        form: {
          ...defaultProps.issue.form,
          canGenerateFix: true,
          isCanvasImage: true,
          generateButtonLabel: 'Generate Alt Text',
        },
      },
    }

    render(<CheckboxTextInput {...propsWithGenerateOption} />)

    const generateButton = screen.getByTestId('generate-alt-text-button')
    const checkbox = screen.getByTestId('decorative-img-checkbox')

    expect(generateButton).not.toBeDisabled()
    expect(checkbox).not.toBeChecked()

    fireEvent.click(checkbox)

    expect(checkbox).toBeChecked()
    expect(generateButton).toBeDisabled()
  })

  it('shows message when the image is from an external source', () => {
    const propsWithGenerateDisabled = {
      ...defaultProps,
      issue: {
        ...defaultProps.issue,
        form: {
          ...defaultProps.issue.form,
          canGenerateFix: true,
          isCanvasImage: false,
          generateButtonLabel: 'Generate Alt Text',
        },
      },
    }

    render(<CheckboxTextInput {...propsWithGenerateDisabled} />)

    const message = screen.getByTestId('alt-text-generation-not-available-message')
    expect(message).toBeInTheDocument()
    expect(message).toHaveTextContent(
      'AI alt text generation is only available for images uploaded to Canvas.',
    )
  })

  it('does not show message when the image is from Canvas', () => {
    const propsWithGenerateEnabled = {
      ...defaultProps,
      issue: {
        ...defaultProps.issue,
        form: {
          ...defaultProps.issue.form,
          canGenerateFix: true,
          isCanvasImage: true,
          generateButtonLabel: 'Generate Alt Text',
        },
      },
    }

    render(<CheckboxTextInput {...propsWithGenerateEnabled} />)

    const message = screen.queryByTestId('alt-text-generation-not-available-message')
    expect(message).not.toBeInTheDocument()
  })

  it('calls API and updates value when generate button is clicked', async () => {
    const propsWithGenerateOption = {
      ...defaultProps,
      issue: {
        ...defaultProps.issue,
        form: {
          ...defaultProps.issue.form,
          canGenerateFix: true,
          isCanvasImage: true,
          generateButtonLabel: 'Generate Alt Text',
        },
      },
    }

    // Mock the API response
    const mockGeneratedText = 'This is AI generated alt text'
    let generateCalled = false
    server.use(
      // Match both /generate and //generate (double slash from URL construction)
      http.post('**/generate/alt_text', () => {
        generateCalled = true
        return HttpResponse.json({
          value: mockGeneratedText,
        })
      }),
    )

    render(<CheckboxTextInput {...propsWithGenerateOption} />)

    // Click the generate button
    const generateButton = screen.getByTestId('generate-alt-text-button')
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
          isCanvasImage: true,
          generateButtonLabel: 'Generate Alt Text',
        },
      },
    }

    // Mock console.error to suppress expected error output
    const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

    // Mock API failure
    server.use(
      // Match both /generate and //generate (double slash from URL construction)
      http.post('**/generate', () => {
        return new HttpResponse(null, {status: 500})
      }),
    )

    render(<CheckboxTextInput {...propsWithGenerateOption} />)

    // Click the generate button
    const generateButton = screen.getByTestId('generate-alt-text-button')
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
      const onValidationChange = vi.fn()
      const onChangeValue = vi.fn()

      const {rerender} = render(
        <CheckboxTextInput
          {...defaultProps}
          onValidationChange={onValidationChange}
          onChangeValue={onChangeValue}
        />,
      )

      onValidationChange.mockClear()

      const textarea = screen.getByTestId('checkbox-text-input-form')
      fireEvent.change(textarea, {target: {value: 'Valid alt text'}})

      rerender(
        <CheckboxTextInput
          {...defaultProps}
          value="Valid alt text"
          onValidationChange={onValidationChange}
          onChangeValue={onChangeValue}
        />,
      )

      await waitFor(() => {
        expect(onValidationChange).toHaveBeenCalledWith(true, undefined)
      })
    })

    it('calls onValidationChange when text exceeds max length', async () => {
      const onValidationChange = vi.fn()
      const onChangeValue = vi.fn()

      const {rerender} = render(
        <CheckboxTextInput
          {...defaultProps}
          onValidationChange={onValidationChange}
          onChangeValue={onChangeValue}
        />,
      )

      onValidationChange.mockClear()

      const longText = 'a'.repeat(150)
      const textarea = screen.getByTestId('checkbox-text-input-form')
      fireEvent.change(textarea, {target: {value: longText}})

      rerender(
        <CheckboxTextInput
          {...defaultProps}
          value={longText}
          onValidationChange={onValidationChange}
          onChangeValue={onChangeValue}
        />,
      )

      await waitFor(() => {
        expect(onValidationChange).toHaveBeenCalledWith(
          false,
          'Keep alt text under 100 characters.',
        )
      })
    })

    it('calls onValidationChange when checkbox is checked (decorative image)', async () => {
      const onValidationChange = vi.fn()

      render(<CheckboxTextInput {...defaultProps} onValidationChange={onValidationChange} />)

      onValidationChange.mockClear()

      const checkbox = screen.getByRole('checkbox', {
        name: 'Test Checkbox Label Test checkbox subtext',
      })
      fireEvent.click(checkbox)

      expect(onValidationChange).toHaveBeenCalledWith(true, undefined)
    })

    it('calls onValidationChange when textarea is empty', async () => {
      const onValidationChange = vi.fn()

      render(<CheckboxTextInput {...defaultProps} onValidationChange={onValidationChange} />)

      expect(onValidationChange).toHaveBeenCalledWith(false, 'Alt text is required.')
    })

    it('calls onValidationChange when textarea has only whitespaces input', () => {
      const onValidationChange = vi.fn()

      render(
        <CheckboxTextInput {...defaultProps} value="   " onValidationChange={onValidationChange} />,
      )

      expect(onValidationChange).toHaveBeenCalledWith(false, 'Alt text is required.')
    })
  })

  describe('AI generation feature flag', () => {
    it('shows generate button when feature flag is enabled', () => {
      ;(useAccessibilityScansStore as unknown as any).mockImplementation((selector: any) => {
        const state = {isAiAltTextGenerationEnabled: true}
        return selector(state)
      })

      const propsWithGenerateOption = {
        ...defaultProps,
        issue: {
          ...defaultProps.issue,
          form: {
            ...defaultProps.issue.form,
            canGenerateFix: true,
            isCanvasImage: true,
            generateButtonLabel: 'Generate Alt Text',
          },
        },
      }

      render(<CheckboxTextInput {...propsWithGenerateOption} />)

      expect(screen.getByTestId('generate-alt-text-button')).toBeInTheDocument()
    })

    it('hides generate button when feature flag is disabled', () => {
      ;(useAccessibilityScansStore as unknown as any).mockImplementation((selector: any) => {
        const state = {isAiAltTextGenerationEnabled: false}
        return selector(state)
      })

      const propsWithGenerateOption = {
        ...defaultProps,
        issue: {
          ...defaultProps.issue,
          form: {
            ...defaultProps.issue.form,
            canGenerateFix: true,
            isCanvasImage: true,
            generateButtonLabel: 'Generate Alt Text',
          },
        },
      }

      render(<CheckboxTextInput {...propsWithGenerateOption} />)

      expect(screen.queryByTestId('generate-alt-text-button')).not.toBeInTheDocument()
    })
  })

  describe('isDisabled prop', () => {
    it('disables textarea when isDisabled is true', () => {
      render(<CheckboxTextInput {...defaultProps} isDisabled={true} />)

      const textarea = screen.getByTestId('checkbox-text-input-form')
      expect(textarea).toBeDisabled()
    })

    it('keeps generate button visible but disabled when isDisabled is true', () => {
      const propsWithGenerate = {
        ...defaultProps,
        isDisabled: true,
        issue: {
          ...defaultProps.issue,
          form: {
            ...defaultProps.issue.form,
            canGenerateFix: true,
            isCanvasImage: true,
            generateButtonLabel: 'Generate Alt Text',
          },
        },
      }

      render(<CheckboxTextInput {...propsWithGenerate} />)

      const button = screen.getByTestId('generate-alt-text-button')
      expect(button).toBeInTheDocument()
      expect(button).toBeDisabled()
    })
  })
})
