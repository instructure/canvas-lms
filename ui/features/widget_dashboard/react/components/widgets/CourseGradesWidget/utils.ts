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

const COURSE_COLOR_PALETTE: CourseCodeColors[] = [
  {background: '#F1E6F5', textColor: '#7F399E'}, // Purple
  {background: '#DDECF3', textColor: '#135F81'}, // Teal
  {background: '#FFE5D3', textColor: '#90420D'}, // Orange
  {background: '#DFEBFB', textColor: '#1C57A8'}, // Blue
  {background: '#DAEEE8', textColor: '#036549'}, // Green
  {background: '#F7E5F0', textColor: '#A31C73'}, // Pink
]

export const getCourseCodeColor = (gridIndex?: number, code?: string): CourseCodeColors => {
  if (typeof gridIndex === 'number') {
    // Use grid index for consistent positioning
    return COURSE_COLOR_PALETTE[gridIndex % COURSE_COLOR_PALETTE.length]
  }

  if (code) {
    // Fallback to hash-based selection for backwards compatibility
    const hash = code.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0)
    return COURSE_COLOR_PALETTE[hash % COURSE_COLOR_PALETTE.length]
  }

  // Default to first color if no parameters provided
  return COURSE_COLOR_PALETTE[0]
}

export const createGradebookHandler = (courseId: string) => () => {
  window.open(URL_PATTERNS.GRADEBOOK.replace('{courseId}', courseId), '_blank')
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
