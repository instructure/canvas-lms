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
import {IconCalendarClockLine, IconCheckMarkLine, IconWarningLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {startOfToday, getTomorrow} from '../../../utils/dateUtils'

const I18n = createI18nScope('widget_dashboard')
export interface SubmissionStatus {
  type: 'submitted' | 'late' | 'missing' | 'pending_review' | 'due_soon' | 'not_submitted'
  label: string
  color: {background: string; textColor: string}
  icon?: any
  iconColor?: string
}

function dueDateTime(dueDate: Date, day: string): string {
  return I18n.t('%{day} %{time}', {
    day,
    time: dueDate.toLocaleTimeString([], {hour: 'numeric', minute: '2-digit'}),
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
    return dueDateTime(dueDate, I18n.t('Today'))
  }
  if (dueTomorrow) {
    return dueDateTime(dueDate, I18n.t('Tomorrow'))
  }
  return I18n.t('%{date} %{time}', {
    date: dueDate.toLocaleDateString(),
    time: dueDate.toLocaleTimeString([], {hour: '2-digit', minute: '2-digit'}),
  })
}

interface SubmissionStatusColors {
  [key: string]: {
    background: string
    textColor: string
  }
}

const SUBMISSION_STATUS_COLORS: SubmissionStatusColors = {
  blue: {background: '#E0EBF5', textColor: '#1A5A8E'},
  red: {background: '#FCE4E5', textColor: '#E62429'},
  orange: {background: '#FCE5D9', textColor: '#CF4A00'},
  green: {background: '#DCEEE4', textColor: '#03893D'},
  grey: {background: '#E8EAEC', textColor: '#6A7883'},
}

export function getSubmissionStatus(
  late: boolean,
  missing: boolean,
  state: string,
  dueAt: string | null,
): SubmissionStatus {
  if (missing) {
    return {
      type: 'missing',
      label: I18n.t('Missing'),
      color: SUBMISSION_STATUS_COLORS.red,
      icon: IconWarningLine,
      iconColor: 'error',
    }
  }

  if (late) {
    return {
      type: 'late',
      label: I18n.t('Late'),
      color: SUBMISSION_STATUS_COLORS.orange,
      icon: IconWarningLine,
      iconColor: 'warning',
    }
  }

  if (state === 'pending_review') {
    return {
      type: 'pending_review',
      label: I18n.t('Pending Review'),
      color: SUBMISSION_STATUS_COLORS.orange,
    }
  }

  if (state === 'submitted' || state === 'graded') {
    return {
      type: 'submitted',
      label: I18n.t('Submitted'),
      color: SUBMISSION_STATUS_COLORS.green,
      icon: IconCheckMarkLine,
      iconColor: 'success',
    }
  }

  if (dueAt) {
    return {
      type: 'due_soon',
      label: formatDueDate(dueAt),
      color: SUBMISSION_STATUS_COLORS.blue,
      icon: IconCalendarClockLine,
      iconColor: 'brand',
    }
  }

  return {
    type: 'not_submitted',
    label: I18n.t('Not Submitted'),
    color: SUBMISSION_STATUS_COLORS.grey,
  }
}
