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

import {cleanup, render, screen, waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {ProblemArea} from '../ProblemArea'
import {
  AccessibilityIssue,
  AccessibilityResourceScan,
  FormType,
  IssueWorkflowState,
  ResourceType,
  ResourceWorkflowState,
  ScanWorkflowState,
} from '../../../../types'
import {createRef} from 'react'
import {PreviewHandle} from '../../Preview'

const server = setupServer()

// Test constants
const TEST_IDS = {
  MOCK_PREVIEW: 'mock-preview',
  COLOR_CONTRAST: 'a11y-color-contrast',
  FIRST_COLOR: 'first-color',
  SECOND_COLOR: 'second-color',
  LABEL: 'label',
  VALIDATION_LEVEL: 'validation-level',
} as const

const ARIA_LABELS = {
  PROBLEM_AREA: 'Problem area',
} as const

const COLORS = {
  DEFAULT_BACKGROUND: '#FFFFFF',
  DEFAULT_FOREGROUND: '#000000',
} as const

const LABELS = {
  CUSTOM_CONTRAST_RATIO: 'Custom Contrast Ratio',
  DEFAULT_CONTRAST_RATIO: 'Contrast Ratio',
} as const

const VALIDATION_LEVEL = 'AA' as const

// Mock the A11yColorContrast component
vi.mock('../../../A11yColorContrast', () => ({
  A11yColorContrast: (props: any) => (
    <div data-testid={TEST_IDS.COLOR_CONTRAST}>
      <div data-testid={TEST_IDS.FIRST_COLOR}>{props.firstColor}</div>
      <div data-testid={TEST_IDS.SECOND_COLOR}>{props.secondColor}</div>
      <div data-testid={TEST_IDS.LABEL}>{props.label}</div>
      <div data-testid={TEST_IDS.VALIDATION_LEVEL}>{props.validationLevel}</div>
    </div>
  ),
}))

// Mock Preview component to control its behavior
vi.mock('../../Preview', () => ({
  __esModule: true,
  default: vi.fn(({onPreviewChange}: any) => {
    // Simulate preview loading and calling onPreviewChange
    setTimeout(() => {
      onPreviewChange?.({
        content: '<div>Test content</div>',
        path: '//div',
      })
    }, 0)
    return <div data-testid={TEST_IDS.MOCK_PREVIEW}>Mock Preview</div>
  }),
  PreviewHandle: {} as any,
}))

describe('ProblemArea', () => {
  let mockItem: AccessibilityResourceScan
  let mockIssue: AccessibilityIssue

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    vi.clearAllMocks()
    mockItem = createMockItem()
    mockIssue = createMockIssue(FormType.TextInput)
  })

  afterEach(() => {
    cleanup()
    server.resetHandlers()
  })

  const createMockItem = (): AccessibilityResourceScan => ({
    id: 1,
    courseId: 1,
    resourceId: 123,
    resourceType: ResourceType.Assignment,
    resourceName: 'Test Assignment',
    resourceWorkflowState: ResourceWorkflowState.Published,
    resourceUpdatedAt: '2026-01-29T00:00:00Z',
    resourceUrl: '/courses/1/assignments/123',
    workflowState: ScanWorkflowState.Completed,
    issueCount: 1,
  })

  const createMockIssue = (formType: FormType): AccessibilityIssue => ({
    id: 'test-id',
    ruleId: 'test-rule',
    displayName: 'Test Rule',
    message: 'Test message',
    why: 'Test why',
    element: 'div',
    path: '//div',
    workflowState: IssueWorkflowState.Active,
    form: {
      type: formType,
      label: 'Test Label',
      backgroundColor: COLORS.DEFAULT_BACKGROUND,
      titleLabel: LABELS.CUSTOM_CONTRAST_RATIO,
    },
  })

  const renderProblemArea = (
    item = mockItem,
    issue = mockIssue,
    previewRef?: React.RefObject<PreviewHandle>,
  ) => {
    return render(<ProblemArea item={item} issue={issue} previewRef={previewRef} />)
  }

  const expectColorContrastProps = (
    expectedFirstColor: string,
    expectedSecondColor: string,
    expectedLabel: string,
  ) => {
    expect(screen.getByTestId(TEST_IDS.FIRST_COLOR)).toHaveTextContent(expectedFirstColor)
    expect(screen.getByTestId(TEST_IDS.SECOND_COLOR)).toHaveTextContent(expectedSecondColor)
    expect(screen.getByTestId(TEST_IDS.LABEL)).toHaveTextContent(expectedLabel)
    expect(screen.getByTestId(TEST_IDS.VALIDATION_LEVEL)).toHaveTextContent(VALIDATION_LEVEL)
  }

  describe('rendering', () => {
    it('renders the preview section with proper aria-label', () => {
      renderProblemArea()

      const section = screen.getByRole('region', {name: ARIA_LABELS.PROBLEM_AREA})
      expect(section).toBeInTheDocument()
    })

    it('renders Preview component', () => {
      renderProblemArea()

      expect(screen.getByTestId(TEST_IDS.MOCK_PREVIEW)).toBeInTheDocument()
    })
  })

  describe('ColorPicker form type', () => {
    beforeEach(() => {
      mockIssue = createMockIssue(FormType.ColorPicker)
    })

    it('renders ColorPickerProblemArea when form type is ColorPicker', () => {
      renderProblemArea()

      expect(screen.getByTestId(TEST_IDS.COLOR_CONTRAST)).toBeInTheDocument()
    })

    it('uses default colors when preview response has no color data', () => {
      renderProblemArea()

      expectColorContrastProps(
        COLORS.DEFAULT_BACKGROUND,
        COLORS.DEFAULT_FOREGROUND,
        LABELS.CUSTOM_CONTRAST_RATIO,
      )
    })

    it('passes custom title label to ColorPickerProblemArea', () => {
      renderProblemArea()

      expect(screen.getByTestId(TEST_IDS.LABEL)).toHaveTextContent(LABELS.CUSTOM_CONTRAST_RATIO)
    })

    it('uses default label when titleLabel is not provided', () => {
      mockIssue.form.titleLabel = undefined

      renderProblemArea()

      expect(screen.getByTestId(TEST_IDS.LABEL)).toHaveTextContent(LABELS.DEFAULT_CONTRAST_RATIO)
    })

    it('passes validation level AA to ColorPickerProblemArea', () => {
      renderProblemArea()

      expect(screen.getByTestId(TEST_IDS.VALIDATION_LEVEL)).toHaveTextContent(VALIDATION_LEVEL)
    })
  })

  describe('non-ColorPicker form types', () => {
    const formTypes = [
      {type: FormType.TextInput, name: 'TextInput'},
      {type: FormType.RadioInputGroup, name: 'RadioInputGroup'},
      {type: FormType.CheckboxTextInput, name: 'CheckboxTextInput'},
    ]

    formTypes.forEach(({type, name}) => {
      it(`does not render ColorPickerProblemArea for ${name} form type`, () => {
        mockIssue = createMockIssue(type)
        renderProblemArea()

        expect(screen.queryByTestId(TEST_IDS.COLOR_CONTRAST)).not.toBeInTheDocument()
      })
    })
  })

  describe('previewRef handling', () => {
    it('can receive a ref', () => {
      const ref = createRef<PreviewHandle>()

      renderProblemArea(mockItem, mockIssue, ref)

      expect(screen.getByTestId(TEST_IDS.MOCK_PREVIEW)).toBeInTheDocument()
    })
  })
})
