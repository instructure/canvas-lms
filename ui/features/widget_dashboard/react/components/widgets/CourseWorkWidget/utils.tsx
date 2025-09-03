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
import {
  IconAssignmentLine,
  IconQuizLine,
  IconDiscussionLine,
  IconDocumentLine,
} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {startOfToday, getTomorrow} from '../../../utils/dateUtils'
import type {CourseWorkItem} from '../../../hooks/useCourseWork'

const I18n = createI18nScope('widget_dashboard')

function dueDateTime(dueDate: Date, day: string): string {
  return I18n.t('Due %{day} at %{time}', {
    day,
    time: dueDate.toLocaleTimeString([], {hour: '2-digit', minute: '2-digit'}),
  })
}

export function formatDueDate(dueAt: string | null): string {
  if (!dueAt) return I18n.t('No due date')

  const dueDate = new Date(dueAt)
  const today = startOfToday()
  const tomorrow = getTomorrow()

  const dueToday = dueDate.toDateString() === today.toDateString()
  const dueTomorrow = dueDate.toDateString() === tomorrow.toDateString()

  if (dueToday) {
    return dueDateTime(dueDate, I18n.t('today'))
  }
  if (dueTomorrow) {
    return dueDateTime(dueDate, I18n.t('tomorrow'))
  }
  return I18n.t('Due %{date} at %{time}', {
    date: dueDate.toLocaleDateString(),
    time: dueDate.toLocaleTimeString([], {hour: '2-digit', minute: '2-digit'}),
  })
}

export function getTypeInfo(type: CourseWorkItem['type']) {
  switch (type) {
    case 'assignment':
      return {color: 'info' as const, label: I18n.t('Assignment')}
    case 'quiz':
      return {color: 'warning' as const, label: I18n.t('Quiz')}
    case 'discussion':
      return {color: 'success' as const, label: I18n.t('Discussion')}
    default:
      return {color: 'primary' as const, label: I18n.t('Item')}
  }
}

export function getTypeIcon(type: CourseWorkItem['type']) {
  const iconSize = 'small'
  switch (type) {
    case 'assignment':
      return <IconAssignmentLine size={iconSize} data-testid="assignment-icon" />
    case 'quiz':
      return <IconQuizLine size={iconSize} data-testid="quiz-icon" />
    case 'discussion':
      return <IconDiscussionLine size={iconSize} data-testid="discussion-icon" />
    default:
      return <IconDocumentLine size={iconSize} data-testid="document-icon" />
  }
}
