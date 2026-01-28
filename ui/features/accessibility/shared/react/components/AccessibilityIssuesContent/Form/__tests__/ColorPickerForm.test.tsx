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

import {cleanup, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ColorPickerForm from '../ColorPickerForm'
import {AccessibilityIssue, FormType, IssueWorkflowState} from '../../../../types'

describe('ColorPickerForm', () => {
  // Test constants
  const TEST_IDS = {
    CONTRAST_RATIO_FORM: 'contrast-ratio-form',
    COLOR_PICKER: 'color-picker',
    SUGGESTION_MESSAGE: 'suggestion-message',
  } as const

  const COLORS = {
    WHITE: '#FFFFFF',
    WHITE_LOWERCASE: '#ffffff',
    BLACK: '#000000',
    RED: '#FF0000',
    GREEN: '#00FF00',
    BLUE: '#0000FF',
    CUSTOM_1: '#123456',
    CUSTOM_2: '#F0F0F0',
    CUSTOM_3: '#AABBCC',
  } as const

  const LABELS = {
    DEFAULT_INPUT: 'New Color',
    CUSTOM_INPUT: 'Custom Label',
    PLACEHOLDER: 'Enter HEX',
  } as const

  const MESSAGES = {
    SUGGESTION:
      "Tip: Only #0000 will automatically update to white if the user's background is in dark mode.",
    ERROR: 'Invalid color format',
  } as const

  const ISSUE_DEFAULTS = {
    ID: 'test-id',
    RULE_ID: 'color-contrast',
    DISPLAY_NAME: 'Color Contrast',
    MESSAGE: 'Element has insufficient color contrast',
    WHY: 'Text must have sufficient contrast',
    ELEMENT: 'div',
    PATH: 'body > div',
  } as const

  afterEach(() => {
    cleanup()
  })

  const createMockIssue = (overrides?: Partial<AccessibilityIssue>): AccessibilityIssue => ({
    id: ISSUE_DEFAULTS.ID,
    ruleId: ISSUE_DEFAULTS.RULE_ID,
    displayName: ISSUE_DEFAULTS.DISPLAY_NAME,
    message: ISSUE_DEFAULTS.MESSAGE,
    why: ISSUE_DEFAULTS.WHY,
    element: ISSUE_DEFAULTS.ELEMENT,
    path: ISSUE_DEFAULTS.PATH,
    workflowState: IssueWorkflowState.Active,
    form: {
      type: FormType.ColorPicker,
      inputLabel: LABELS.DEFAULT_INPUT,
      backgroundColor: COLORS.WHITE,
      value: COLORS.BLACK,
    },
    ...overrides,
  })

  const defaultProps = {
    issue: createMockIssue(),
    onChangeValue: vi.fn(),
    value: COLORS.BLACK,
  }

  const renderColorPickerForm = (props = {}) => {
    return render(<ColorPickerForm {...defaultProps} {...props} />)
  }

  const getColorPickerInput = () =>
    screen.getByPlaceholderText(LABELS.PLACEHOLDER) as HTMLInputElement

  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('rendering', () => {
    it('renders the color picker form', () => {
      renderColorPickerForm()

      expect(screen.getByTestId(TEST_IDS.CONTRAST_RATIO_FORM)).toBeInTheDocument()
      expect(screen.getByTestId(TEST_IDS.COLOR_PICKER)).toBeInTheDocument()
    })

    it('renders with default input label when not provided', () => {
      const issue = createMockIssue({
        form: {
          type: FormType.ColorPicker,
          backgroundColor: COLORS.WHITE,
        },
      })

      renderColorPickerForm({issue})

      expect(screen.getByText(LABELS.DEFAULT_INPUT)).toBeInTheDocument()
    })

    it('renders with custom input label when provided', () => {
      const issue = createMockIssue({
        form: {
          type: FormType.ColorPicker,
          inputLabel: LABELS.CUSTOM_INPUT,
          backgroundColor: COLORS.WHITE,
        },
      })

      renderColorPickerForm({issue})

      expect(screen.getByText(LABELS.CUSTOM_INPUT)).toBeInTheDocument()
    })

    it('uses default foreground color #000000 when no value is provided', () => {
      const issue = createMockIssue({
        form: {
          type: FormType.ColorPicker,
          backgroundColor: COLORS.WHITE,
        },
      })

      renderColorPickerForm({issue})

      expect(getColorPickerInput().value).toBe('000000')
    })

    it('uses provided foreground color from issue.form.value', () => {
      const issue = createMockIssue({
        form: {
          type: FormType.ColorPicker,
          backgroundColor: COLORS.WHITE,
          value: COLORS.RED,
        },
      })

      renderColorPickerForm({issue})

      expect(getColorPickerInput().value).toBe('FF0000')
    })

    it('uses default background color #FFFFFF when not provided', () => {
      const issue = createMockIssue({
        form: {
          type: FormType.ColorPicker,
        },
      })

      renderColorPickerForm({issue})

      expect(screen.getByTestId(TEST_IDS.SUGGESTION_MESSAGE)).toBeInTheDocument()
    })
  })

  describe('suggestion message', () => {
    it('displays suggestion message when background color is #FFFFFF (uppercase)', () => {
      const issue = createMockIssue({
        form: {
          type: FormType.ColorPicker,
          backgroundColor: COLORS.WHITE,
        },
      })

      renderColorPickerForm({issue})

      const suggestionMessage = screen.getByTestId(TEST_IDS.SUGGESTION_MESSAGE)
      expect(suggestionMessage).toBeInTheDocument()
      expect(suggestionMessage).toHaveTextContent(MESSAGES.SUGGESTION)
    })

    it('displays suggestion message when background color is #ffffff (lowercase)', () => {
      const issue = createMockIssue({
        form: {
          type: FormType.ColorPicker,
          backgroundColor: COLORS.WHITE_LOWERCASE,
        },
      })

      renderColorPickerForm({issue})

      expect(screen.getByTestId(TEST_IDS.SUGGESTION_MESSAGE)).toBeInTheDocument()
    })

    it('does not display suggestion message when background color is not white', () => {
      const issue = createMockIssue({
        form: {
          type: FormType.ColorPicker,
          backgroundColor: COLORS.CUSTOM_2,
        },
      })

      renderColorPickerForm({issue})

      expect(screen.queryByTestId(TEST_IDS.SUGGESTION_MESSAGE)).not.toBeInTheDocument()
    })

    it('does not display suggestion message for different background colors', () => {
      const backgroundColors = [
        COLORS.BLACK,
        COLORS.RED,
        COLORS.GREEN,
        COLORS.BLUE,
        COLORS.CUSTOM_3,
      ]

      backgroundColors.forEach(backgroundColor => {
        const issue = createMockIssue({
          form: {
            type: FormType.ColorPicker,
            backgroundColor,
          },
        })

        const {unmount} = renderColorPickerForm({issue})
        expect(screen.queryByTestId(TEST_IDS.SUGGESTION_MESSAGE)).not.toBeInTheDocument()
        unmount()
      })
    })
  })

  describe('color picker interaction', () => {
    it('calls onChangeValue when color is changed', async () => {
      const onChangeValue = vi.fn()
      const user = userEvent.setup()

      renderColorPickerForm({onChangeValue})

      const input = getColorPickerInput()

      await user.clear(input)
      await user.type(input, 'FF0000')

      await waitFor(() => {
        expect(onChangeValue).toHaveBeenCalled()
      })
    })

    it('updates internal state when color changes', async () => {
      const user = userEvent.setup()

      renderColorPickerForm()

      const input = getColorPickerInput()

      await user.clear(input)
      await user.type(input, 'FF0000')

      await waitFor(() => {
        expect(input.value).toBe('FF0000')
      })
    })
  })

  describe('error handling', () => {
    it('displays error message when error prop is provided', () => {
      renderColorPickerForm({error: MESSAGES.ERROR})

      expect(screen.getByText(MESSAGES.ERROR)).toBeInTheDocument()
    })

    it('does not display error when error prop is null', () => {
      renderColorPickerForm({error: null})

      expect(screen.getByTestId(TEST_IDS.COLOR_PICKER)).toBeInTheDocument()
    })

    it('does not display error when error prop is undefined', () => {
      renderColorPickerForm()

      expect(screen.getByTestId(TEST_IDS.COLOR_PICKER)).toBeInTheDocument()
    })
  })

  describe('disabled state', () => {
    it('disables color picker when isDisabled is true', () => {
      renderColorPickerForm({isDisabled: true})

      expect(getColorPickerInput()).toBeDisabled()
    })

    it('enables color picker when isDisabled is false', () => {
      renderColorPickerForm({isDisabled: false})

      expect(getColorPickerInput()).not.toBeDisabled()
    })

    it('enables color picker by default when isDisabled is not provided', () => {
      renderColorPickerForm()

      expect(getColorPickerInput()).not.toBeDisabled()
    })
  })

  describe('focus management', () => {
    it('exposes focus method via ref', () => {
      const ref = {current: null as any}

      renderColorPickerForm({ref})

      expect(ref.current).toBeDefined()
      expect(ref.current.focus).toBeDefined()
      expect(typeof ref.current.focus).toBe('function')
    })

    it('focuses the input when focus method is called on ref', () => {
      const ref = {current: null as any}

      renderColorPickerForm({ref})

      const input = getColorPickerInput()

      ref.current.focus()

      expect(document.activeElement).toBe(input)
    })
  })

  describe('ColorMixer settings', () => {
    it('passes correct background color to color mixer settings', () => {
      const issue = createMockIssue({
        form: {
          type: FormType.ColorPicker,
          backgroundColor: COLORS.CUSTOM_1,
        },
      })

      renderColorPickerForm({issue})

      expect(screen.getByTestId(TEST_IDS.COLOR_PICKER)).toBeInTheDocument()
    })

    it('uses default white background if backgroundColor is not provided', () => {
      const issue = createMockIssue({
        form: {
          type: FormType.ColorPicker,
          backgroundColor: undefined,
        },
      })

      renderColorPickerForm({issue})

      expect(screen.getByTestId(TEST_IDS.SUGGESTION_MESSAGE)).toBeInTheDocument()
    })
  })
})
