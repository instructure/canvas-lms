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

import {createElement} from 'react'
import {render, screen, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

import {
  AccessibilityCheckerContext,
  type AccessibilityCheckerContextType,
} from '../../../../contexts/AccessibilityCheckerContext'
import {FormType, IssueWorkflowState} from '../../../../types'
import {getAsAccessibilityResourceScan} from '../../../../utils/apiData'
import TextInputForm from '../TextInputForm'
import {useAccessibilityScansStore} from '../../../../stores/AccessibilityScansStore'

const server = setupServer()

// Mock the Button component to handle ai-primary color
vi.mock('@instructure/ui-buttons', async () => {
  const originalModule =
    await vi.importActual<typeof import('@instructure/ui-buttons')>('@instructure/ui-buttons')
  return {
    ...originalModule,
    Button: (props: any) => {
      // Convert ai-primary to primary for testing
      const testProps = {
        ...props,
        color: props.color === 'ai-primary' ? 'primary' : props.color,
      }
      return createElement(originalModule.Button as any, testProps)
    },
  }
})

vi.mock('../../../../stores/AccessibilityScansStore')

describe('TextInputForm', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())
  afterEach(() => {
    server.resetHandlers()
  })

  beforeEach(() => {
    vi.resetAllMocks()
    ;(useAccessibilityScansStore as unknown as any).mockImplementation((selector: any) => {
      const state = {isAiTableCaptionGenerationEnabled: true}
      return selector(state)
    })
  })
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
  }

  // Create a fully typed mock context
  const mockContextValue: AccessibilityCheckerContextType = {
    selectedItem: getAsAccessibilityResourceScan(
      {
        id: 123,
        type: 'Page' as any, // Using string literal that matches ContentItemType.WikiPage
        title: 'Mock Page',
        published: true,
        updatedAt: '2023-01-01',
        count: 0,
        url: 'http://example.com',
        editUrl: 'http://example.com/edit',
      },
      1,
    ),
    setSelectedItem: vi.fn(),
    isTrayOpen: false,
    setIsTrayOpen: vi.fn(),
  }

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

  it('renders without crashing', () => {
    render(
      <AccessibilityCheckerContext.Provider value={mockContextValue}>
        <TextInputForm {...propsWithGenerateOption} />
      </AccessibilityCheckerContext.Provider>,
    )
    expect(screen.getByTestId('text-input-form')).toBeInTheDocument()
  })

  it('displays the correct label', () => {
    render(
      <AccessibilityCheckerContext.Provider value={mockContextValue}>
        <TextInputForm {...propsWithGenerateOption} />
      </AccessibilityCheckerContext.Provider>,
    )
    expect(screen.getByText('Test Label')).toBeInTheDocument()
  })

  it('displays the provided value', () => {
    const propsWithValue = {
      ...defaultProps,
      value: 'test value',
    }
    render(
      <AccessibilityCheckerContext.Provider value={mockContextValue}>
        <TextInputForm {...propsWithValue} />
      </AccessibilityCheckerContext.Provider>,
    )
    const input = screen.getByTestId('text-input-form')
    expect(input).toHaveValue('test value')
  })

  it('calls onChangeValue when the input value changes', async () => {
    render(
      <AccessibilityCheckerContext.Provider value={mockContextValue}>
        <TextInputForm {...propsWithGenerateOption} />
      </AccessibilityCheckerContext.Provider>,
    )
    const input = screen.getByTestId('text-input-form')
    await userEvent.type(input, 'a')
    expect(defaultProps.onChangeValue).toHaveBeenCalledWith('a')
  })

  it('displays the error message when an error is provided', () => {
    const propsWithError = {
      ...defaultProps,
      error: 'Error message',
    }
    render(
      <AccessibilityCheckerContext.Provider value={mockContextValue}>
        <TextInputForm {...propsWithError} />
      </AccessibilityCheckerContext.Provider>,
    )
    expect(screen.getByText('Error message')).toBeInTheDocument()
  })

  it('handles errors when generate API call fails', async () => {
    // Mock API failure
    server.use(
      // Match both /generate and //generate (double slash from URL construction)
      http.post('**/generate/table_caption', () => {
        return new HttpResponse(null, {status: 500})
      }),
    )

    render(
      <AccessibilityCheckerContext.Provider value={mockContextValue}>
        <TextInputForm {...propsWithGenerateOption} />
      </AccessibilityCheckerContext.Provider>,
    )

    // Click the generate button
    const generateButton = screen.getByText('Generate Alt Text')
    fireEvent.click(generateButton)

    // Verify loading indicator appears
    expect(screen.getByText('Generating...')).toBeInTheDocument()

    // Verify that onChangeValue was not called (since the API failed)
    expect(defaultProps.onChangeValue).not.toHaveBeenCalled()
  })

  it('focuses the input when the form is refocused', () => {
    const {container} = render(
      <AccessibilityCheckerContext.Provider value={mockContextValue}>
        <TextInputForm {...propsWithGenerateOption} />
      </AccessibilityCheckerContext.Provider>,
    )
    const input = container.querySelector('input')
    expect(input).not.toHaveFocus()
    input?.focus()
    expect(input).toHaveFocus()
  })

  describe('AI generation feature flag', () => {
    it('shows generate button when feature flag is enabled', () => {
      ;(useAccessibilityScansStore as unknown as any).mockImplementation((selector: any) => {
        const state = {isAiTableCaptionGenerationEnabled: true}
        return selector(state)
      })

      render(
        <AccessibilityCheckerContext.Provider value={mockContextValue}>
          <TextInputForm {...propsWithGenerateOption} />
        </AccessibilityCheckerContext.Provider>,
      )

      expect(screen.getByText('Generate Alt Text')).toBeInTheDocument()
    })

    it('hides generate button when feature flag is disabled', () => {
      ;(useAccessibilityScansStore as unknown as any).mockImplementation((selector: any) => {
        const state = {isAiTableCaptionGenerationEnabled: false}
        return selector(state)
      })

      render(
        <AccessibilityCheckerContext.Provider value={mockContextValue}>
          <TextInputForm {...propsWithGenerateOption} />
        </AccessibilityCheckerContext.Provider>,
      )

      expect(screen.queryByText('Generate Alt Text')).not.toBeInTheDocument()
    })
  })
})
