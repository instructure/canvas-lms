/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {ColorPickerProblemArea} from '../ColorPickerProblemArea'
import {
  AccessibilityIssue,
  ColorContrastPreviewResponse,
  FormType,
  IssueWorkflowState,
} from '../../../../types'

// Mock A11yColorContrast component
vi.mock('../../../A11yColorContrast', () => ({
  A11yColorContrast: (props: any) => (
    <div data-testid="a11y-color-contrast">
      <div data-testid="first-color">{props.firstColor}</div>
      <div data-testid="second-color">{props.secondColor}</div>
      <div data-testid="label">{props.label}</div>
      <div data-testid="validation-level">{props.validationLevel}</div>
      <div data-testid="options">{JSON.stringify(props.options)}</div>
    </div>
  ),
}))

describe('ColorPickerProblemArea', () => {
  // Test constants
  const TEST_IDS = {
    COLOR_CONTRAST: 'a11y-color-contrast',
    FIRST_COLOR: 'first-color',
    SECOND_COLOR: 'second-color',
    LABEL: 'label',
    VALIDATION_LEVEL: 'validation-level',
    OPTIONS: 'options',
  } as const

  const COLORS = {
    DEFAULT_BACKGROUND: '#FFFFFF',
    DEFAULT_FOREGROUND: '#000000',
    CUSTOM_BACKGROUND: '#FF0000',
    CUSTOM_FOREGROUND: '#00FF00',
    BLUE: '#0000FF',
    YELLOW: '#FFFF00',
  } as const

  const LABELS = {
    DEFAULT: 'Contrast Ratio',
    CUSTOM: 'Custom Contrast Label',
  } as const

  const VALIDATION_LEVEL = 'AA' as const

  const ISSUE_DEFAULTS = {
    ID: 'test-id',
    RULE_ID: 'color-contrast',
    DISPLAY_NAME: 'Color Contrast',
    MESSAGE: 'Test message',
    WHY: 'Test why',
    ELEMENT: 'div',
    PATH: '//div',
  } as const

  afterEach(() => {
    cleanup()
  })

  beforeEach(() => {
    vi.clearAllMocks()
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
      titleLabel: LABELS.CUSTOM,
      options: ['Option 1', 'Option 2'],
    },
    ...overrides,
  })

  const createMockPreviewResponse = (
    background?: string,
    foreground?: string,
  ): ColorContrastPreviewResponse | null => {
    if (background === undefined && foreground === undefined) {
      return null
    }
    return {
      content: '',
      background: background || COLORS.DEFAULT_BACKGROUND,
      foreground: foreground || COLORS.DEFAULT_FOREGROUND,
    }
  }

  const renderColorPickerProblemArea = (
    previewResponse: ColorContrastPreviewResponse | null = null,
    issue: AccessibilityIssue = createMockIssue(),
  ) => {
    return render(<ColorPickerProblemArea previewResponse={previewResponse} issue={issue} />)
  }

  const expectColorContrastProps = (
    firstColor: string,
    secondColor: string,
    label: string,
    validationLevel: string = VALIDATION_LEVEL,
  ) => {
    expect(screen.getByTestId(TEST_IDS.FIRST_COLOR)).toHaveTextContent(firstColor)
    expect(screen.getByTestId(TEST_IDS.SECOND_COLOR)).toHaveTextContent(secondColor)
    expect(screen.getByTestId(TEST_IDS.LABEL)).toHaveTextContent(label)
    expect(screen.getByTestId(TEST_IDS.VALIDATION_LEVEL)).toHaveTextContent(validationLevel)
  }

  describe('rendering', () => {
    it('renders A11yColorContrast component', () => {
      renderColorPickerProblemArea()

      expect(screen.getByTestId(TEST_IDS.COLOR_CONTRAST)).toBeInTheDocument()
    })

    it('passes all required props to A11yColorContrast', () => {
      const previewResponse = createMockPreviewResponse(
        COLORS.CUSTOM_BACKGROUND,
        COLORS.CUSTOM_FOREGROUND,
      )

      renderColorPickerProblemArea(previewResponse)

      expectColorContrastProps(COLORS.CUSTOM_BACKGROUND, COLORS.CUSTOM_FOREGROUND, LABELS.CUSTOM)
    })
  })

  describe('color handling', () => {
    it('uses colors from preview response when provided', () => {
      const previewResponse = createMockPreviewResponse(
        COLORS.CUSTOM_BACKGROUND,
        COLORS.CUSTOM_FOREGROUND,
      )

      renderColorPickerProblemArea(previewResponse)

      expectColorContrastProps(COLORS.CUSTOM_BACKGROUND, COLORS.CUSTOM_FOREGROUND, LABELS.CUSTOM)
    })

    it('uses default background color when preview response is null', () => {
      renderColorPickerProblemArea(null)

      expect(screen.getByTestId(TEST_IDS.FIRST_COLOR)).toHaveTextContent(COLORS.DEFAULT_BACKGROUND)
    })

    it('uses default foreground color when preview response is null', () => {
      renderColorPickerProblemArea(null)

      expect(screen.getByTestId(TEST_IDS.SECOND_COLOR)).toHaveTextContent(COLORS.DEFAULT_FOREGROUND)
    })

    it('uses default colors when preview response is undefined', () => {
      renderColorPickerProblemArea(undefined)

      expectColorContrastProps(COLORS.DEFAULT_BACKGROUND, COLORS.DEFAULT_FOREGROUND, LABELS.CUSTOM)
    })

    it('handles different color combinations correctly', () => {
      const colorCombinations = [
        {background: COLORS.BLUE, foreground: COLORS.YELLOW},
        {background: COLORS.YELLOW, foreground: COLORS.BLUE},
        {background: COLORS.CUSTOM_BACKGROUND, foreground: COLORS.CUSTOM_FOREGROUND},
      ]

      colorCombinations.forEach(({background, foreground}) => {
        const previewResponse = createMockPreviewResponse(background, foreground)
        const {unmount} = renderColorPickerProblemArea(previewResponse)

        expectColorContrastProps(background, foreground, LABELS.CUSTOM)
        unmount()
      })
    })
  })

  describe('label handling', () => {
    it('uses custom title label from issue form when provided', () => {
      const issue = createMockIssue({
        form: {
          type: FormType.ColorPicker,
          titleLabel: LABELS.CUSTOM,
        },
      })

      renderColorPickerProblemArea(null, issue)

      expect(screen.getByTestId(TEST_IDS.LABEL)).toHaveTextContent(LABELS.CUSTOM)
    })

    it('uses default label when titleLabel is undefined', () => {
      const issue = createMockIssue({
        form: {
          type: FormType.ColorPicker,
          titleLabel: undefined,
        },
      })

      renderColorPickerProblemArea(null, issue)

      expect(screen.getByTestId(TEST_IDS.LABEL)).toHaveTextContent(LABELS.DEFAULT)
    })

    it('uses default label when titleLabel is empty string', () => {
      const issue = createMockIssue({
        form: {
          type: FormType.ColorPicker,
          titleLabel: '',
        },
      })

      renderColorPickerProblemArea(null, issue)

      expect(screen.getByTestId(TEST_IDS.LABEL)).toHaveTextContent(LABELS.DEFAULT)
    })
  })

  describe('validation level', () => {
    it('always passes AA as validation level', () => {
      renderColorPickerProblemArea()

      expect(screen.getByTestId(TEST_IDS.VALIDATION_LEVEL)).toHaveTextContent(VALIDATION_LEVEL)
    })
  })

  describe('options handling', () => {
    it('passes options from issue form to A11yColorContrast', () => {
      const options = ['Option A', 'Option B', 'Option C']
      const issue = createMockIssue({
        form: {
          type: FormType.ColorPicker,
          options,
        },
      })

      renderColorPickerProblemArea(null, issue)

      expect(screen.getByTestId(TEST_IDS.OPTIONS)).toHaveTextContent(JSON.stringify(options))
    })

    it('passes undefined options when not provided', () => {
      const issue = createMockIssue({
        form: {
          type: FormType.ColorPicker,
        },
      })

      renderColorPickerProblemArea(null, issue)

      const optionsText = screen.getByTestId(TEST_IDS.OPTIONS).textContent
      expect(optionsText === '' || optionsText === 'null').toBe(true)
    })

    it('passes empty array when options is empty', () => {
      const issue = createMockIssue({
        form: {
          type: FormType.ColorPicker,
          options: [],
        },
      })

      renderColorPickerProblemArea(null, issue)

      expect(screen.getByTestId(TEST_IDS.OPTIONS)).toHaveTextContent('[]')
    })
  })

  describe('edge cases', () => {
    it('handles preview response with only background color', () => {
      const previewResponse: ColorContrastPreviewResponse = {
        background: COLORS.CUSTOM_BACKGROUND,
        foreground: undefined as any,
        content: '',
      }

      renderColorPickerProblemArea(previewResponse)

      expect(screen.getByTestId(TEST_IDS.FIRST_COLOR)).toHaveTextContent(COLORS.CUSTOM_BACKGROUND)
      expect(screen.getByTestId(TEST_IDS.SECOND_COLOR)).toHaveTextContent(COLORS.DEFAULT_FOREGROUND)
    })

    it('handles preview response with only foreground color', () => {
      const previewResponse: ColorContrastPreviewResponse = {
        background: undefined as any,
        foreground: COLORS.CUSTOM_FOREGROUND,
        content: '',
      }

      renderColorPickerProblemArea(previewResponse)

      expect(screen.getByTestId(TEST_IDS.FIRST_COLOR)).toHaveTextContent(COLORS.DEFAULT_BACKGROUND)
      expect(screen.getByTestId(TEST_IDS.SECOND_COLOR)).toHaveTextContent(COLORS.CUSTOM_FOREGROUND)
    })
  })
})
