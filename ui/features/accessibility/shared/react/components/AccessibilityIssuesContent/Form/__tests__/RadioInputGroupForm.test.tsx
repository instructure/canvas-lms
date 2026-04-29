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

import {cleanup, render, screen, fireEvent} from '@testing-library/react'

import {AccessibilityIssue, FormType, IssueWorkflowState} from '../../../../types'
import RadioInputGroupForm from '../RadioInputGroupForm'

describe('RadioInputGroupForm', () => {
  afterEach(() => {
    cleanup()
  })

  const createMockIssue = (options?: string[]): AccessibilityIssue => ({
    id: '1',
    ruleId: 'test-rule',
    displayName: 'Test rule',
    message: 'Test issue',
    why: '',
    element: '',
    path: '',
    workflowState: IssueWorkflowState.Active,
    form: {
      type: FormType.RadioInputGroup,
      label: 'Test label',
      options: options || ['Option A', 'Option B', 'Option C'],
    },
  })

  const defaultProps = {
    issue: createMockIssue(),
    value: null,
    onChangeValue: vi.fn(),
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('rendering', () => {
    it('renders the radio input group with correct description', () => {
      render(<RadioInputGroupForm {...defaultProps} />)

      expect(screen.getByTestId('radio-input-group')).toBeInTheDocument()
      expect(screen.getByTestId('radio-description')).toHaveTextContent('Test label')
    })

    it('renders all radio options from the issue form', () => {
      const props = {
        ...defaultProps,
        issue: createMockIssue(),
      }

      render(<RadioInputGroupForm {...props} />)

      expect(screen.getByTestId('radio-Option A')).toBeInTheDocument()
      expect(screen.getByTestId(`radio-Option B`)).toBeInTheDocument()
      expect(screen.getByTestId(`radio-Option C`)).toBeInTheDocument()
    })

    it('sets the provided value as selected', () => {
      const props = {
        ...defaultProps,
        issue: createMockIssue(),
        value: 'Option B',
      }

      render(<RadioInputGroupForm {...props} />)

      const secondRadio = screen.getByTestId('radio-Option B') as HTMLInputElement
      expect(secondRadio).toBeChecked()
    })

    it('renders nothing when issue.form.options is not provided', () => {
      const issueWithoutOptions = {
        ...defaultProps.issue,
        form: {
          ...defaultProps.issue.form,
          options: undefined,
        },
      }

      const {container} = render(
        <RadioInputGroupForm {...defaultProps} issue={issueWithoutOptions} />,
      )

      expect(container.firstChild).toBeNull()
    })
  })

  it('calls onChangeValue when a radio option is selected', () => {
    const onChangeValue = vi.fn()
    const props = {
      ...defaultProps,
      issue: createMockIssue(),
      onChangeValue,
    }

    render(<RadioInputGroupForm {...props} />)

    const optionBRadio = screen.getByTestId('radio-Option B')
    fireEvent.click(optionBRadio)

    expect(onChangeValue).toHaveBeenCalledWith('Option B')
  })

  describe('edge cases', () => {
    it('handles empty options array', () => {
      const props = {
        ...defaultProps,
        issue: createMockIssue([]),
      }

      const {container} = render(<RadioInputGroupForm {...props} />)

      expect(container.firstChild).toBeNull()
    })

    it('handles single option', () => {
      const options = ['Single Option']
      const props = {
        ...defaultProps,
        issue: createMockIssue(options),
        value: 'Single Option',
      }

      render(<RadioInputGroupForm {...props} />)

      expect(screen.getByTestId('radio-Single Option')).toBeInTheDocument()
      expect(screen.getByTestId('radio-Single Option')).toBeChecked()
    })

    it('handles undefined value', () => {
      const props = {
        ...defaultProps,
        issue: createMockIssue(),
        value: undefined,
      }

      render(<RadioInputGroupForm {...props} />)

      const firstRadio = screen.getByTestId('radio-Option A') as HTMLInputElement
      expect(firstRadio).not.toBeChecked()
      const secondRadio = screen.getByTestId('radio-Option B') as HTMLInputElement
      expect(secondRadio).not.toBeChecked()
      const thirdRadio = screen.getByTestId('radio-Option C') as HTMLInputElement
      expect(thirdRadio).not.toBeChecked()
    })

    it('handles value that does not exist in options', () => {
      const props = {
        ...defaultProps,
        issue: createMockIssue(),
        value: 'Non-existent Option',
      }

      render(<RadioInputGroupForm {...props} />)

      const firstRadio = screen.getByTestId('radio-Option A') as HTMLInputElement
      expect(firstRadio).not.toBeChecked()
      const secondRadio = screen.getByTestId('radio-Option B') as HTMLInputElement
      expect(secondRadio).not.toBeChecked()
      const thirdRadio = screen.getByTestId('radio-Option C') as HTMLInputElement
      expect(thirdRadio).not.toBeChecked()
    })
  })

  it('displays the error message when an error is provided', () => {
    const propsWithError = {
      ...defaultProps,
      error: 'Error message',
    }
    render(<RadioInputGroupForm {...propsWithError} />)
    expect(screen.getByText('Error message')).toBeInTheDocument()
  })

  describe('disabled state', () => {
    it('disables the radio group when isDisabled prop is true', () => {
      const props = {
        ...defaultProps,
        isDisabled: true,
      }

      render(<RadioInputGroupForm {...props} />)

      const radioGroup = screen.getByTestId('radio-input-group')
      expect(radioGroup).toHaveAttribute('aria-disabled', 'true')
    })

    it('does not disable the radio group when isDisabled prop is false', () => {
      const props = {
        ...defaultProps,
        isDisabled: false,
      }

      render(<RadioInputGroupForm {...props} />)

      const radioGroup = screen.getByTestId('radio-input-group')
      expect(radioGroup).not.toHaveAttribute('aria-disabled', 'true')
    })

    it('does not disable the radio group when disabled prop is not provided', () => {
      render(<RadioInputGroupForm {...defaultProps} />)

      const radioGroup = screen.getByTestId('radio-input-group')
      expect(radioGroup).not.toHaveAttribute('aria-disabled', 'true')
    })
  })
})
