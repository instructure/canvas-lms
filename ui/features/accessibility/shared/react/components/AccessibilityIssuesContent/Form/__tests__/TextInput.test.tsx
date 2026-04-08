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
import userEvent from '@testing-library/user-event'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

import {FormType, IssueWorkflowState} from '../../../../types'
import TextInputForm from '../TextInputForm'
import {useAccessibilityScansStore} from '../../../../stores/AccessibilityScansStore'

const server = setupServer()

vi.mock('../../../../stores/AccessibilityScansStore')

beforeAll(() => server.listen())
afterAll(() => server.close())

beforeEach(() => {
  server.resetHandlers()
  vi.resetAllMocks()
  ;(useAccessibilityScansStore as unknown as any).mockImplementation((selector: any) => {
    const state = {isAiTableCaptionGenerationEnabled: true, selectedScan: null}
    return selector(state)
  })
})

describe('TextInputForm', () => {
  const defaultProps = {
    issue: {
      id: 'test-id',
      ruleId: 'test-rule',
      displayName: 'Test rule',
      message: 'Test message',
      why: 'Test why',
      element: 'test-element',
      path: 'test-path',
      workflowState: IssueWorkflowState.Active,
      form: {
        type: FormType.TextInput,
        label: 'Test Label',
      },
    },
    value: '',
    onChangeValue: vi.fn(),
    onValidationChange: vi.fn(),
  }

  const propsWithGenerateOption = {
    ...defaultProps,
    issue: {
      ...defaultProps.issue,
      form: {
        ...defaultProps.issue.form,
        canGenerateFix: true,
      },
    },
  }

  it('renders without crashing', () => {
    render(<TextInputForm {...defaultProps} />)
    expect(screen.getByTestId('text-input-form')).toBeInTheDocument()
  })

  it('displays the correct label', () => {
    render(<TextInputForm {...defaultProps} />)
    expect(screen.getByText('Test Label')).toBeInTheDocument()
  })

  it('displays the provided value', () => {
    const propsWithValue = {
      ...defaultProps,
      value: 'test value',
    }
    render(<TextInputForm {...propsWithValue} />)
    const input = screen.getByTestId('text-input-form')
    expect(input).toHaveValue('test value')
  })

  it('calls onChangeValue when the input value changes', async () => {
    render(<TextInputForm {...defaultProps} />)
    const input = screen.getByTestId('text-input-form')
    await userEvent.type(input, 'a')
    expect(defaultProps.onChangeValue).toHaveBeenCalledWith('a')
  })

  it('focuses the input when the form is refocused', () => {
    const {container} = render(<TextInputForm {...propsWithGenerateOption} />)
    const input = container.querySelector('input')
    expect(input).not.toHaveFocus()
    input?.focus()
    expect(input).toHaveFocus()
  })

  describe('generate button', () => {
    it('shows initial generate caption label', () => {
      render(<TextInputForm {...propsWithGenerateOption} />)
      expect(screen.getByTestId('initial-label')).toHaveTextContent('Generate caption')
    })

    describe('during generation loading', () => {
      beforeEach(() => {
        server.use(
          http.post('**/generate/table_caption', async () => {
            await new Promise(resolve => setTimeout(resolve, 100))
            return HttpResponse.json({value: 'Generated caption'})
          }),
        )
      })

      it('shows loading label and disables input during generation', async () => {
        render(<TextInputForm {...propsWithGenerateOption} />)

        const generateButton = screen.getByTestId('generate-button')
        fireEvent.click(generateButton)

        expect(screen.getByTestId('loading-label')).toHaveTextContent('Generating caption...')

        const input = screen.getByTestId('text-input-form')
        expect(input).toBeDisabled()

        await waitFor(() => {
          expect(screen.getByTestId('loaded-label')).toHaveTextContent('Regenerate caption')
        })
      })

      it('uses aria-disabled on button during loading', async () => {
        render(<TextInputForm {...propsWithGenerateOption} />)

        const generateButton = screen.getByTestId('generate-button')
        fireEvent.click(generateButton)

        expect(generateButton).toHaveAttribute('aria-disabled', 'true')
        expect(generateButton).toHaveAttribute('aria-busy', 'true')
        expect(generateButton).not.toBeDisabled()

        await waitFor(() => {
          expect(screen.getByTestId('loaded-label')).toHaveTextContent('Regenerate caption')
        })
      })
    })

    it('handles errors when generate API call fails', async () => {
      server.use(
        http.post('**/generate/table_caption', () => {
          return new HttpResponse(null, {status: 500})
        }),
      )

      render(<TextInputForm {...propsWithGenerateOption} />)

      const generateButton = screen.getByTestId('generate-button')
      fireEvent.click(generateButton)

      expect(screen.getByTestId('loading-label')).toHaveTextContent('Generating caption...')

      await waitFor(() => {
        expect(
          screen.getByText(
            'There was an error generating table caption. Please try again, or enter it manually.',
          ),
        ).toBeInTheDocument()
      })

      expect(defaultProps.onChangeValue).not.toHaveBeenCalled()
    })

    it('renders data-pendo="AiTableCaptionButtonPushed" on the generate button', () => {
      render(<TextInputForm {...propsWithGenerateOption} />)
      expect(screen.getByTestId('generate-button')).toHaveAttribute(
        'data-pendo',
        'AiTableCaptionButtonPushed',
      )
    })

    describe('AI generation feature flag', () => {
      it('shows generate button when feature flag is enabled', () => {
        ;(useAccessibilityScansStore as unknown as any).mockImplementation((selector: any) => {
          const state = {isAiTableCaptionGenerationEnabled: true, selectedScan: null}
          return selector(state)
        })

        render(<TextInputForm {...propsWithGenerateOption} />)

        expect(screen.getByTestId('generate-button')).toBeInTheDocument()
      })

      it('hides generate button when feature flag is disabled', () => {
        ;(useAccessibilityScansStore as unknown as any).mockImplementation((selector: any) => {
          const state = {isAiTableCaptionGenerationEnabled: false, selectedScan: null}
          return selector(state)
        })

        render(<TextInputForm {...propsWithGenerateOption} />)

        expect(screen.queryByTestId('generate-button')).not.toBeInTheDocument()
      })
    })
  })

  describe('Error display', () => {
    it('does not show errors when error prop is not provided', () => {
      render(<TextInputForm {...defaultProps} />)

      expect(screen.queryByText('Caption cannot be empty.')).not.toBeInTheDocument()
    })

    it('shows error message when error prop is provided', () => {
      const propsWithError = {
        ...defaultProps,
        error: 'Caption cannot be empty.',
      }
      render(<TextInputForm {...propsWithError} />)

      expect(screen.getByText('Caption cannot be empty.')).toBeInTheDocument()
    })

    it('does not show validation errors on initial mount with empty input', () => {
      render(<TextInputForm {...defaultProps} />)

      expect(screen.queryByText('Caption cannot be empty.')).not.toBeInTheDocument()
    })

    it('does not show error when user enters non-empty text', async () => {
      render(<TextInputForm {...defaultProps} />)

      const input = screen.getByTestId('text-input-form')
      await userEvent.type(input, 'Valid caption')

      expect(screen.queryByText('Caption cannot be empty.')).not.toBeInTheDocument()
    })

    it('shows error when user clears the input', async () => {
      const propsWithValue = {
        ...defaultProps,
        value: 'Some text',
      }

      render(<TextInputForm {...propsWithValue} />)

      const input = screen.getByTestId('text-input-form')
      await userEvent.clear(input)

      expect(defaultProps.onValidationChange).toHaveBeenCalledWith(
        false,
        'Caption cannot be empty.',
      )
    })

    it('shows error when user enters only whitespace', async () => {
      render(<TextInputForm {...defaultProps} />)

      const input = screen.getByTestId('text-input-form')
      await userEvent.type(input, '   ')

      expect(defaultProps.onValidationChange).toHaveBeenCalledWith(
        false,
        'Caption cannot be empty.',
      )
    })

    it('clears error when user enters valid text after error', async () => {
      render(<TextInputForm {...defaultProps} />)

      const input = screen.getByTestId('text-input-form')

      await userEvent.type(input, '   ')
      expect(defaultProps.onValidationChange).toHaveBeenCalledWith(
        false,
        'Caption cannot be empty.',
      )

      await userEvent.clear(input)
      await userEvent.type(input, 'Valid caption')

      expect(defaultProps.onValidationChange).toHaveBeenLastCalledWith(true)
    })
  })
})
