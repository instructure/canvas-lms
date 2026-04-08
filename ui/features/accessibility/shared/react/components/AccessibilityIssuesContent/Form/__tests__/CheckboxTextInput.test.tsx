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
import {useAccessibilityScansStore} from '../../../../stores/AccessibilityScansStore'
import CheckboxTextInput, {
  ALT_TEXT_REQUIRED_MESSAGE,
  altTextMaxLengthMessage,
} from '../CheckboxTextInput'
import {FormType, IssueWorkflowState} from '../../../../types'

const server = setupServer()

vi.mock('../../../../stores/AccessibilityScansStore')

beforeAll(() => server.listen())
afterAll(() => server.close())

beforeEach(() => {
  server.resetHandlers()
  vi.resetAllMocks()
  ;(useAccessibilityScansStore as unknown as any).mockImplementation((selector: any) => {
    const state = {isAiAltTextGenerationEnabled: true, selectedScan: null}
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
    onValidationChange: vi.fn(),
  }

  const withGenerateFix = (formOverrides = {}) => ({
    ...defaultProps,
    issue: {
      ...defaultProps.issue,
      form: {
        ...defaultProps.issue.form,
        canGenerateFix: true,
        isCanvasImage: true,
        ...formOverrides,
      },
    },
  })

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

  describe('generate button', () => {
    it('shows a generate button when the form has can_generate_fix set', () => {
      render(<CheckboxTextInput {...withGenerateFix()} />)
      const button = screen.getByTestId('generate-button')
      expect(button).toBeInTheDocument()
      expect(button).not.toBeDisabled()
    })

    it('shows initial "Generate alt text" label', () => {
      render(<CheckboxTextInput {...withGenerateFix()} />)
      expect(screen.getByTestId('initial-label')).toHaveTextContent('Generate alt text')
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
          },
        },
      }

      render(<CheckboxTextInput {...propsWithGenerateDisabled} />)
      const button = screen.getByTestId('generate-button')
      expect(button).toBeInTheDocument()
      expect(button).toBeDisabled()
    })

    it('disables generate button when checkbox is checked', () => {
      render(<CheckboxTextInput {...withGenerateFix()} />)

      const generateButton = screen.getByTestId('generate-button')
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
      render(<CheckboxTextInput {...withGenerateFix()} />)

      const message = screen.queryByTestId('alt-text-generation-not-available-message')
      expect(message).not.toBeInTheDocument()
    })

    it('button has aria-describedby pointing to helper text when isCanvasImage is false', () => {
      const props = {
        ...defaultProps,
        issue: {
          ...defaultProps.issue,
          form: {
            ...defaultProps.issue.form,
            canGenerateFix: true,
            isCanvasImage: false,
          },
        },
      }

      render(<CheckboxTextInput {...props} />)

      const button = screen.getByTestId('generate-button')
      const helperText = screen.getByTestId('alt-text-generation-not-available-message')

      expect(helperText).toHaveAttribute('id')
      expect(button).toHaveAttribute('aria-describedby', helperText.id)
    })

    it('button does not have aria-describedby when isCanvasImage is true', () => {
      render(<CheckboxTextInput {...withGenerateFix()} />)

      const button = screen.getByTestId('generate-button')
      expect(button).not.toHaveAttribute('aria-describedby')
    })

    describe('during generation loading', () => {
      beforeEach(() => {
        server.use(
          http.post('**/generate/alt_text', async () => {
            await new Promise(resolve => setTimeout(resolve, 100))
            return HttpResponse.json({value: 'Generated alt text'})
          }),
        )
      })

      it('uses aria-disabled on button during loading', async () => {
        render(<CheckboxTextInput {...withGenerateFix()} />)

        const generateButton = screen.getByTestId('generate-button')
        fireEvent.click(generateButton)

        expect(generateButton).toHaveAttribute('aria-disabled', 'true')
        expect(generateButton).toHaveAttribute('aria-busy', 'true')
        expect(generateButton).not.toBeDisabled()

        await waitFor(() => {
          expect(screen.getByTestId('loaded-label')).toHaveTextContent('Regenerate alt text')
        })
      })

      it('disables textarea during generation', async () => {
        render(<CheckboxTextInput {...withGenerateFix()} />)

        const generateButton = screen.getByTestId('generate-button')
        const textarea = screen.getByTestId('checkbox-text-input-form')

        expect(textarea).toBeEnabled()
        fireEvent.click(generateButton)
        expect(textarea).toBeDisabled()

        await waitFor(() => {
          expect(screen.getByTestId('loaded-label')).toHaveTextContent('Regenerate alt text')
        })

        expect(textarea).toBeEnabled()
      })

      it('disables checkbox during generation', async () => {
        render(<CheckboxTextInput {...withGenerateFix()} />)

        const generateButton = screen.getByTestId('generate-button')
        const checkbox = screen.getByTestId('decorative-img-checkbox')

        expect(checkbox).toBeEnabled()
        fireEvent.click(generateButton)
        expect(checkbox).toBeDisabled()

        await waitFor(() => {
          expect(screen.getByTestId('loaded-label')).toHaveTextContent('Regenerate alt text')
        })

        expect(checkbox).toBeEnabled()
      })
    })

    it('calls API and updates value when generate button is clicked', async () => {
      const mockGeneratedText = 'This is AI generated alt text'
      let generateCalled = false
      server.use(
        http.post('**/generate/alt_text', () => {
          generateCalled = true
          return HttpResponse.json({
            value: mockGeneratedText,
          })
        }),
      )

      render(<CheckboxTextInput {...withGenerateFix()} />)

      const generateButton = screen.getByTestId('generate-button')
      fireEvent.click(generateButton)

      expect(screen.getByTestId('loading-label')).toHaveTextContent('Generating alt text...')

      await waitFor(() => {
        expect(generateCalled).toBe(true)
        expect(defaultProps.onChangeValue).toHaveBeenCalledWith(mockGeneratedText)
      })
    })

    it('calls onValidationChange when generate button is clicked', async () => {
      const mockGeneratedText = 'Generated alt text'

      server.use(
        http.post('**/generate/alt_text', () => {
          return HttpResponse.json({value: mockGeneratedText})
        }),
      )

      render(<CheckboxTextInput {...withGenerateFix()} />)

      const generateButton = screen.getByTestId('generate-button')
      fireEvent.click(generateButton)

      await waitFor(() => {
        expect(defaultProps.onValidationChange).toHaveBeenCalledWith(true, undefined)
      })
    })

    it('shows "Regenerate alt text" label after successful generation', async () => {
      server.use(
        http.post('**/generate/alt_text', () => {
          return HttpResponse.json({value: 'Generated alt text'})
        }),
      )

      render(<CheckboxTextInput {...withGenerateFix()} />)

      const generateButton = screen.getByTestId('generate-button')
      fireEvent.click(generateButton)

      await waitFor(() => {
        expect(screen.getByTestId('loaded-label')).toHaveTextContent('Regenerate alt text')
      })
    })

    describe('error messages by status code', () => {
      const errorCases = [
        {status: 403, message: 'You do not have permission to access this attachment.'},
        {status: 404, message: 'Attachment not found.'},
        {status: 413, message: 'The file exceeds the maximum allowed size for AI processing.'},
        {status: 415, message: 'This file type is not supported for AI processing.'},
        {
          status: 429,
          message:
            'You have exceeded your daily limit for alt text generation. (You can generate alt text for 300 images per day.) Please try again after a day, or enter alt text manually.',
        },
        {
          status: 500,
          message:
            'There was an error generating alt text. Please try again, or enter it manually.',
        },
      ]

      errorCases.forEach(({status, message}) => {
        it(`shows correct message for status ${status}`, async () => {
          const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

          server.use(http.post('**/generate/alt_text', () => new HttpResponse(null, {status})))

          render(<CheckboxTextInput {...withGenerateFix()} />)
          fireEvent.click(screen.getByTestId('generate-button'))

          await waitFor(() => {
            expect(screen.getByText(message)).toBeInTheDocument()
          })

          consoleErrorSpy.mockRestore()
        })
      })
    })

    it('renders data-pendo="AiAltTextButtonPushed" on the generate button', () => {
      render(<CheckboxTextInput {...withGenerateFix()} />)
      expect(screen.getByTestId('generate-button')).toHaveAttribute(
        'data-pendo',
        'AiAltTextButtonPushed',
      )
    })

    describe('AI generation feature flag', () => {
      it('shows generate button when feature flag is enabled', () => {
        ;(useAccessibilityScansStore as unknown as any).mockImplementation((selector: any) => {
          const state = {isAiAltTextGenerationEnabled: true, selectedScan: null}
          return selector(state)
        })

        render(<CheckboxTextInput {...withGenerateFix()} />)

        expect(screen.getByTestId('generate-button')).toBeInTheDocument()
      })

      it('hides generate button when feature flag is disabled', () => {
        ;(useAccessibilityScansStore as unknown as any).mockImplementation((selector: any) => {
          const state = {isAiAltTextGenerationEnabled: false, selectedScan: null}
          return selector(state)
        })

        render(<CheckboxTextInput {...withGenerateFix()} />)

        expect(screen.queryByTestId('generate-button')).not.toBeInTheDocument()
      })
    })
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
        expect(onValidationChange).toHaveBeenCalledWith(false, altTextMaxLengthMessage(100))
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

    it('does not call onValidationChange on initial render', () => {
      render(<CheckboxTextInput {...defaultProps} />)

      expect(defaultProps.onValidationChange).not.toHaveBeenCalled()
    })

    it('calls onValidationChange with invalid when user types only whitespace', () => {
      render(<CheckboxTextInput {...defaultProps} />)

      const textarea = screen.getByTestId('checkbox-text-input-form')
      fireEvent.change(textarea, {target: {value: '   '}})

      expect(defaultProps.onValidationChange).toHaveBeenCalledWith(false, ALT_TEXT_REQUIRED_MESSAGE)
    })
  })

  describe('isDisabled prop', () => {
    it('disables textarea when isDisabled is true', () => {
      render(<CheckboxTextInput {...defaultProps} isDisabled={true} />)

      const textarea = screen.getByTestId('checkbox-text-input-form')
      expect(textarea).toBeDisabled()
    })

    it('hides generate button when isDisabled is true', () => {
      const propsWithGenerate = {
        ...defaultProps,
        isDisabled: true,
        issue: {
          ...defaultProps.issue,
          form: {
            ...defaultProps.issue.form,
            canGenerateFix: true,
            isCanvasImage: true,
          },
        },
      }

      render(<CheckboxTextInput {...propsWithGenerate} />)

      expect(screen.queryByTestId('generate-button')).not.toBeInTheDocument()
    })

    it('shows generate button when isDisabled is false', () => {
      const propsWithGenerate = {
        ...defaultProps,
        isDisabled: false,
        issue: {
          ...defaultProps.issue,
          form: {
            ...defaultProps.issue.form,
            canGenerateFix: true,
            isCanvasImage: true,
          },
        },
      }

      render(<CheckboxTextInput {...propsWithGenerate} />)

      expect(screen.getByTestId('generate-button')).toBeInTheDocument()
    })
  })
})
