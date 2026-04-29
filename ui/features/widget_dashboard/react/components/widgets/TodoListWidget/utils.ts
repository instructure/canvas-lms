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
import type {PlannableType} from './types'

const I18n = createI18nScope('planner')

export function formatDate(dateString: string | undefined): string {
  if (!dateString) return ''

  const date = new Date(dateString)
  const now = new Date()
  const diffInMs = date.getTime() - now.getTime()
  const diffInHours = Math.floor(diffInMs / (1000 * 60 * 60))
  const diffInDays = Math.floor(diffInMs / (1000 * 60 * 60 * 24))

  if (diffInMs < 0) {
    return I18n.t('Overdue')
  } else if (diffInHours < 24) {
    if (diffInHours === 0) {
      return I18n.t('Due soon')
    }
    return I18n.t('Due in %{count} hours', {count: diffInHours})
  } else if (diffInDays < 7) {
    const dateOptions: Intl.DateTimeFormatOptions = {
      weekday: 'long',
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    }
    return I18n.t('Due %{date}', {date: date.toLocaleDateString('en-US', dateOptions)})
  } else {
    const dateOptions: Intl.DateTimeFormatOptions = {
      weekday: 'long',
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    }
    return I18n.t('Due %{date}', {date: date.toLocaleDateString('en-US', dateOptions)})
  }
}

export function formatAnnouncementDate(dateString: string | undefined): string {
  if (!dateString) return ''
  const date = new Date(dateString)
  const dateOptions: Intl.DateTimeFormatOptions = {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }
  return I18n.t('Posted %{date}', {date: date.toLocaleDateString(undefined, dateOptions)})
}

export function getPlannableTypeLabel(type: PlannableType): string {
  switch (type) {
    case 'assignment':
      return I18n.t('Assignment')
    case 'quiz':
      return I18n.t('Quiz')
    case 'discussion_topic':
      return I18n.t('Discussion')
    case 'announcement':
      return I18n.t('Announcement')
    case 'wiki_page':
      return I18n.t('Page')
    case 'calendar_event':
      return I18n.t('Event')
    case 'planner_note':
      return I18n.t('To Do')
    case 'assessment_request':
      return I18n.t('Peer Review')
    case 'discussion_topic_checkpoint':
      return I18n.t('Discussion Checkpoint')
    default:
      return I18n.t('Item')
  }
}

export function isOverdue(dateString: string | undefined): boolean {
  if (!dateString) return false
  const date = new Date(dateString)
  const now = new Date()
  return date < now
}
