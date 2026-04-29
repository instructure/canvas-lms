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

import {useScope as createI18nScope} from '@canvas/i18n'
import {URL_PATTERNS} from '../../../constants'

const I18n = createI18nScope('widget_dashboard')

export const formatUpdatedDate = (date: Date): string => {
  const now = new Date()
  const daysDiff = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24))

  if (daysDiff === 0) {
    return I18n.t('Updated today')
  } else if (daysDiff === 1) {
    return I18n.t('Grade updated 1 day ago')
  } else {
    return I18n.t('Grade updated %{days} days ago', {days: daysDiff})
  }
}

interface CourseCodeColors {
  background: string
  textColor: string
}

// Default neutral color for course codes when no custom color is set
// Custom colors should be provided via the preferences.custom_colors system
export const DEFAULT_COURSE_COLOR: CourseCodeColors = {
  background: '#E5E5E5', // Neutral gray background
  textColor: '#2D3B45', // Dark text for accessibility
}

export const getCourseCodeColor = (): CourseCodeColors => {
  return DEFAULT_COURSE_COLOR
}

export const createGradebookHandler = (courseId: string) => () => {
  window.open(URL_PATTERNS.GRADEBOOK.replace('{courseId}', courseId), '_blank')
}

export const getAccessibleTextColor = (backgroundColor: string): string => {
  const color = backgroundColor.replace('#', '').toLowerCase()
  const r = parseInt(color.substring(0, 2), 16)
  const g = parseInt(color.substring(2, 4), 16)
  const b = parseInt(color.substring(4, 6), 16)

  const getLuminance = (r: number, g: number, b: number) => {
    const [rs, gs, bs] = [r, g, b].map(c => {
      c = c / 255
      return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
    })
    return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs
  }

  const backgroundLuminance = getLuminance(r, g, b)
  const contrastWithWhite = 1.05 / (backgroundLuminance + 0.05)
  return contrastWithWhite >= 4.5 ? '#FFFFFF' : '#000000'
}

export const convertToLetterGrade = (
  numericGrade: number,
  gradingStandardData: Array<[string, number]>,
): string => {
  const gradeAsDecimal = numericGrade / 100

  for (const [letter, minScore] of gradingStandardData) {
    if (gradeAsDecimal >= minScore) {
      return letter
    }
  }

  return gradingStandardData[gradingStandardData.length - 1]?.[0] || 'F'
}
