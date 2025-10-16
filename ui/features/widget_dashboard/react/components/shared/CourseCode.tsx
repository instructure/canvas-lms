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

import React, {useMemo} from 'react'
import {Pill} from '@instructure/ui-pill'
import {getCourseCodeColor} from '../widgets/CourseGradesWidget/utils'
import {useWidgetDashboard} from '../../hooks/useWidgetDashboardContext'

// Helper function to determine appropriate text color for accessibility
// Uses white (#FFFFFF) by default, but switches to black (#000000) for light backgrounds
const getAccessibleTextColor = (backgroundColor: string): string => {
  // Remove # if present and convert to lowercase
  const color = backgroundColor.replace('#', '').toLowerCase()

  // Convert to RGB
  const r = parseInt(color.substring(0, 2), 16)
  const g = parseInt(color.substring(2, 4), 16)
  const b = parseInt(color.substring(4, 6), 16)

  // Calculate relative luminance using WCAG formula
  const getLuminance = (r: number, g: number, b: number) => {
    const [rs, gs, bs] = [r, g, b].map(c => {
      c = c / 255
      return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
    })
    return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs
  }

  const backgroundLuminance = getLuminance(r, g, b)

  // Calculate contrast ratio with white (luminance = 1)
  // WCAG AA requires 4.5:1 for normal text
  const contrastWithWhite = 1.05 / (backgroundLuminance + 0.05)
  return contrastWithWhite >= 4.5 ? '#FFFFFF' : '#000000'
}

export interface CourseCodeProps {
  courseId: string
  gridIndex?: number
  size?: 'x-small' | 'small' | 'medium'
  className?: string
  overrideCode?: string
  overrideColor?: {background: string; textColor: string}
  useCustomColors?: boolean // Whether to use user's custom course colors
  maxWidth?: string
}

export const CourseCode: React.FC<CourseCodeProps> = ({
  courseId,
  gridIndex,
  size = 'x-small',
  className,
  overrideCode,
  overrideColor,
  useCustomColors = true,
  maxWidth = '15rem',
}) => {
  const {preferences, sharedCourseData} = useWidgetDashboard()

  // Find course data from shared context
  const courseData = sharedCourseData.find(course => course.courseId === courseId)

  const courseCodeStyle = useMemo(() => {
    if (overrideColor) {
      return overrideColor
    }

    // Try to use custom color if enabled and available
    if (useCustomColors && preferences?.custom_colors) {
      const customColorKey = `course_${courseId}`
      const customColor = preferences.custom_colors[customColorKey]

      if (customColor) {
        // Convert custom color to course code style format with accessibility-compliant colors
        const textColor = getAccessibleTextColor(customColor)
        return {
          background: customColor,
          textColor,
        }
      }
    }

    return getCourseCodeColor()
  }, [
    overrideColor,
    overrideCode,
    courseData?.courseCode,
    gridIndex,
    useCustomColors,
    preferences?.custom_colors,
    courseId,
  ])

  const displayCode = overrideCode || courseData?.courseCode || 'N/A'

  return (
    <Pill
      color="primary"
      className={className}
      themeOverride={{
        background: courseCodeStyle.background,
        primaryColor: courseCodeStyle.textColor,
        maxWidth,
      }}
    >
      {displayCode}
    </Pill>
  )
}

export default CourseCode
