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

import React, {useMemo, useState} from 'react'
import {Pill} from '@instructure/ui-pill'
import {Tooltip} from '@instructure/ui-tooltip'
import {TruncateText} from '@instructure/ui-truncate-text'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {getCourseCodeColor, getAccessibleTextColor} from '../widgets/CourseGradesWidget/utils'
import {useWidgetDashboard} from '../../hooks/useWidgetDashboardContext'

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
  const [isTruncated, setIsTruncated] = useState(false)
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

  const pillElement = (
    <Pill
      color="primary"
      className={`course-code-pill ${className || ''}`}
      themeOverride={{
        background: courseCodeStyle.background,
        primaryColor: courseCodeStyle.textColor,
        maxWidth,
      }}
    >
      {isTruncated && <ScreenReaderContent>{displayCode}</ScreenReaderContent>}
      <span aria-hidden={isTruncated}>
        <TruncateText onUpdate={setIsTruncated}>{displayCode}</TruncateText>
      </span>
    </Pill>
  )

  if (isTruncated) {
    return (
      <Tooltip renderTip={displayCode} placement="top">
        {/* eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex */}
        <span tabIndex={0} style={{display: 'inline-block'}}>
          {pillElement}
        </span>
      </Tooltip>
    )
  }

  return pillElement
}

export default CourseCode
