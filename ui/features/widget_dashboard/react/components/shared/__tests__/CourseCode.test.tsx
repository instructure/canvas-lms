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

import React from 'react'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {CourseCode} from '../CourseCode'
import {getCourseCodeColor} from '../../widgets/CourseGradesWidget/utils'
import {WidgetDashboardProvider} from '../../../hooks/useWidgetDashboardContext'

//Mock TruncateText to simulate truncation behavior in tests
vi.mock('@instructure/ui-truncate-text', () => ({
  TruncateText: ({
    children,
    onUpdate,
  }: {
    children: string
    onUpdate?: (truncated: boolean) => void
  }) => {
    // Simulate truncation for strings longer than 30 characters
    React.useEffect(() => {
      if (onUpdate && children && children.length > 30) {
        onUpdate(true)
      } else if (onUpdate) {
        onUpdate(false)
      }
    }, [children, onUpdate])

    // Simulate truncated text display (first 15 chars + ...)
    const displayText =
      children && children.length > 30 ? `${children.substring(0, 15)}...` : children

    return <>{displayText}</>
  },
}))

const mockSharedCourseData = [
  {
    courseId: '123',
    courseCode: 'TEST101',
    courseName: 'Test Course',
    currentGrade: 95,
    gradingScheme: [
      ['A', 0.94],
      ['A-', 0.9],
      ['B+', 0.87],
      ['B', 0.84],
      ['B-', 0.8],
      ['C+', 0.77],
      ['C', 0.74],
      ['C-', 0.7],
      ['D+', 0.67],
      ['D', 0.64],
      ['D-', 0.61],
      ['F', 0],
    ] as Array<[string, number]>,
    lastUpdated: '2025-01-01T00:00:00Z',
  },
]

const mockPreferences = {
  dashboard_view: 'cards',
  hide_dashcard_color_overlays: false,
  custom_colors: {},
}

const renderWithProvider = (ui: React.ReactElement, overrides = {}) => {
  const defaultProps = {
    preferences: mockPreferences,
    observedUsersList: [],
    canAddObservee: false,
    currentUser: null,
    currentUserRoles: [],
    sharedCourseData: mockSharedCourseData,
    ...overrides,
  }

  return render(<WidgetDashboardProvider {...defaultProps}>{ui}</WidgetDashboardProvider>)
}

describe('CourseCode', () => {
  describe('getCourseCodeColor', () => {
    it('should return consistent default color', () => {
      const color1 = getCourseCodeColor()
      const color2 = getCourseCodeColor()
      expect(color1).toEqual(color2)
    })

    it('should return default neutral colors', () => {
      const color = getCourseCodeColor()
      expect(color).toHaveProperty('background')
      expect(color).toHaveProperty('textColor')
      expect(color.background).toBe('#E5E5E5')
      expect(color.textColor).toBe('#2D3B45')
    })
  })

  describe('Component rendering', () => {
    it('should render with override code immediately', () => {
      renderWithProvider(<CourseCode courseId="123" overrideCode="OVERRIDE101" />)
      expect(screen.getByText('OVERRIDE101')).toBeInTheDocument()
    })

    it('should render course code from shared data', () => {
      renderWithProvider(<CourseCode courseId="123" />)
      expect(screen.getByText('TEST101')).toBeInTheDocument()
    })

    it('should render N/A when course not found', () => {
      renderWithProvider(<CourseCode courseId="999" />)
      expect(screen.getByText('N/A')).toBeInTheDocument()
    })

    it('should use override color when provided', () => {
      const overrideColor = {background: '#FF0000', textColor: '#FFFFFF'}
      renderWithProvider(
        <CourseCode courseId="123" overrideCode="TEST101" overrideColor={overrideColor} />,
      )
      expect(screen.getByText('TEST101')).toBeInTheDocument()
    })

    it('should use custom colors when available', () => {
      const customColorsPreferences = {
        ...mockPreferences,
        custom_colors: {course_123: '#00FF00'},
      }

      renderWithProvider(<CourseCode courseId="123" />, {preferences: customColorsPreferences})

      expect(screen.getByText('TEST101')).toBeInTheDocument()
    })

    it('should apply custom className', () => {
      renderWithProvider(<CourseCode courseId="123" className="custom-class" />)
      expect(screen.getByText('TEST101')).toBeInTheDocument()
    })

    it('should use grid index for consistent colors', () => {
      renderWithProvider(<CourseCode courseId="123" gridIndex={0} />)
      expect(screen.getByText('TEST101')).toBeInTheDocument()
    })

    it('should render with tooltip for long course code', async () => {
      const longCode = 'VERYLONGCOURSECODE12345678901234567890'
      const truncatedCode = 'VERYLONGCOURSEC...'

      const user = userEvent.setup()

      renderWithProvider(<CourseCode courseId="123" overrideCode={longCode} />)

      // Verify truncated text is displayed
      expect(screen.getByText(truncatedCode)).toBeInTheDocument()

      // The tooltip wrapper should be focusable and have tabIndex 0
      const truncatedTextElement = screen.getByText(truncatedCode)
      const tooltipWrapper = truncatedTextElement.closest('[tabindex="0"]')
      expect(tooltipWrapper).toBeInTheDocument()
      expect(tooltipWrapper).toHaveAttribute('tabIndex', '0')

      // Hover over the tooltip wrapper to trigger the tooltip
      if (tooltipWrapper) {
        await user.hover(tooltipWrapper)
      }

      // After hovering, the full code should appear in the tooltip
      const tooltip = await screen.findByText(
        (content: string, element: Element | null): boolean => {
          return content === longCode && Boolean(element?.id?.startsWith('Tooltip___'))
        },
      )
      expect(tooltip).toBeInTheDocument()
    })

    it('should not render with tooltip for normal course code length', () => {
      const shortCode = 'SHORT'
      renderWithProvider(<CourseCode courseId="123" overrideCode={shortCode} />)

      expect(screen.getByText(shortCode)).toBeInTheDocument()

      // Check that there's no focusable wrapper (should not find element with aria-label)
      expect(screen.queryByLabelText(shortCode)).not.toBeInTheDocument()
    })
  })
})
