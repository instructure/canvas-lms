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

// Helper function to determine appropriate text and border colors for accessibility
const getAccessibleColorsForBackground = (
  backgroundColor: string,
): {textColor: string; borderColor: string} => {
  // Remove # if present and convert to lowercase
  const color = backgroundColor.replace('#', '').toLowerCase()

  // Convert to RGB
  const r = parseInt(color.substring(0, 2), 16)
  const g = parseInt(color.substring(2, 4), 16)
  const b = parseInt(color.substring(4, 6), 16)

  // Calculate luminance for contrast checking
  const getLuminance = (r: number, g: number, b: number) => {
    const [rs, gs, bs] = [r, g, b].map(c => {
      c = c / 255
      return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
    })
    return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs
  }

  const backgroundLuminance = getLuminance(r, g, b)

  let textColor: string
  let borderColor: string

  if (backgroundLuminance > 0.5) {
    // Light background - create darker shades of the same color family
    const darkR = Math.max(0, Math.round(r * 0.3)) // Much darker for good contrast
    const darkG = Math.max(0, Math.round(g * 0.3))
    const darkB = Math.max(0, Math.round(b * 0.3))
    textColor = `#${darkR.toString(16).padStart(2, '0')}${darkG.toString(16).padStart(2, '0')}${darkB.toString(16).padStart(2, '0')}`

    // Border: slightly darker than background but lighter than text
    const borderR = Math.max(0, Math.round(r * 0.7))
    const borderG = Math.max(0, Math.round(g * 0.7))
    const borderB = Math.max(0, Math.round(b * 0.7))
    borderColor = `#${borderR.toString(16).padStart(2, '0')}${borderG.toString(16).padStart(2, '0')}${borderB.toString(16).padStart(2, '0')}`
  } else {
    // Dark background - create lighter shades of the same color family
    const lightR = Math.min(255, Math.round(r + (255 - r) * 0.8)) // Much lighter for good contrast
    const lightG = Math.min(255, Math.round(g + (255 - g) * 0.8))
    const lightB = Math.min(255, Math.round(b + (255 - b) * 0.8))
    textColor = `#${lightR.toString(16).padStart(2, '0')}${lightG.toString(16).padStart(2, '0')}${lightB.toString(16).padStart(2, '0')}`

    // Border: slightly lighter than background but darker than text
    const borderR = Math.min(255, Math.round(r + (255 - r) * 0.4))
    const borderG = Math.min(255, Math.round(g + (255 - g) * 0.4))
    const borderB = Math.min(255, Math.round(b + (255 - b) * 0.4))
    borderColor = `#${borderR.toString(16).padStart(2, '0')}${borderG.toString(16).padStart(2, '0')}${borderB.toString(16).padStart(2, '0')}`
  }

  return {textColor, borderColor}
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
        const {textColor, borderColor} = getAccessibleColorsForBackground(customColor)
        return {
          background: customColor,
          textColor,
          borderColor,
        }
      }
    }

    const code = overrideCode || courseData?.courseCode
    return getCourseCodeColor(gridIndex, code)
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
