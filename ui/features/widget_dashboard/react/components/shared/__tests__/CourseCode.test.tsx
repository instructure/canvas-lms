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
import {CourseCode} from '../CourseCode'
import {getCourseCodeColor} from '../../widgets/CourseGradesWidget/utils'
import {WidgetDashboardProvider} from '../../../hooks/useWidgetDashboardContext'

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
    it('should return consistent colors based on grid index', () => {
      const color1 = getCourseCodeColor(0)
      const color2 = getCourseCodeColor(0)
      expect(color1).toEqual(color2)
    })

    it('should return different colors for different grid indices', () => {
      const color1 = getCourseCodeColor(0)
      const color2 = getCourseCodeColor(1)
      expect(color1).not.toEqual(color2)
    })

    it('should cycle through the palette', () => {
      const color1 = getCourseCodeColor(0)
      const color7 = getCourseCodeColor(6) // Should be same as index 0
      expect(color1).toEqual(color7)
    })

    it('should use code hash when no grid index provided', () => {
      const color1 = getCourseCodeColor(undefined, 'CS101')
      const color2 = getCourseCodeColor(undefined, 'CS101')
      expect(color1).toEqual(color2)
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
  })
})
