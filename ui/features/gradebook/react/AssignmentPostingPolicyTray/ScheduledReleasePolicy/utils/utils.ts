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

import {isEqual} from 'es-toolkit/compat'
import {useScope as createI18nScope} from '@canvas/i18n'
import {FormMessage} from 'features/account_admin_tools/react/CommMessages/types'
import {ScheduledRelease} from '../ScheduledReleasePolicy'

const I18n = createI18nScope('assignment_posting_policy_tray')

export type ErrorMessages = {
  grades: FormMessage[]
  comments: FormMessage[]
}

type ScheduledPostData = {
  postCommentsAt: string | null
  postGradesAt: string | null
}

function datesStringsAreEqual(
  date1: string | null | undefined,
  date2: string | null | undefined,
): boolean {
  if (date1 == null && date2 == null) {
    return true
  }

  if (date1 == null || date2 == null) {
    return false
  }

  return new Date(date1).getTime() === new Date(date2).getTime()
}

export function hasScheduledReleaseChanged(
  updatedScheduledPost: ScheduledRelease | null,
  originalScheduledPost: ScheduledPostData | null | undefined,
): boolean {
  return !isEqual(
    {
      postCommentsAt: updatedScheduledPost?.postCommentsAt ?? null,
      postGradesAt: updatedScheduledPost?.postGradesAt ?? null,
    },
    {
      postCommentsAt: originalScheduledPost?.postCommentsAt ?? null,
      postGradesAt: originalScheduledPost?.postGradesAt ?? null,
    },
  )
}

export function validateRelease(
  scheduledRelease: ScheduledRelease | null,
  originalScheduledPost: ScheduledPostData | null | undefined,
  validateOnSubmit = false,
): ErrorMessages {
  const errorMessages: ErrorMessages = {grades: [], comments: []}

  if (!scheduledRelease?.scheduledPostMode) {
    return errorMessages
  }

  const {postGradesAt, postCommentsAt, scheduledPostMode} = scheduledRelease
  const gradesDate = postGradesAt ? new Date(postGradesAt) : null
  const commentsDate = postCommentsAt ? new Date(postCommentsAt) : null
  const now = new Date()

  const gradesChanged = !datesStringsAreEqual(postGradesAt, originalScheduledPost?.postGradesAt)

  // Validate grades: check for missing on change or submit, check for past only on change
  if (gradesChanged || validateOnSubmit) {
    if (!postGradesAt) {
      errorMessages.grades.push({
        text: I18n.t('Please enter a valid grades release date'),
        type: 'error',
      })
    } else if (gradesChanged && gradesDate && gradesDate < now) {
      errorMessages.grades.push({text: I18n.t('Date must be in the future'), type: 'error'})
    }
  }

  // Validate comments date (only for separate mode)
  if (scheduledPostMode === 'separate') {
    const commentsChanged = !datesStringsAreEqual(
      postCommentsAt,
      originalScheduledPost?.postCommentsAt,
    )

    // Validate comments: check for missing on change or submit, check for past only on change
    if (commentsChanged || validateOnSubmit) {
      if (!postCommentsAt) {
        errorMessages.comments.push({
          text: I18n.t('Please enter a valid comments release date'),
          type: 'error',
        })
      } else if (commentsChanged && commentsDate && commentsDate < now) {
        errorMessages.comments.push({text: I18n.t('Date must be in the future'), type: 'error'})
      }
    }

    // Validate relationship between dates (only if at least one has changed)
    if (gradesDate && commentsDate && gradesDate < commentsDate) {
      errorMessages.grades.push({
        text: I18n.t(
          'Grades release date and time must be the same or after comments release date',
        ),
        type: 'error',
      })
      errorMessages.comments.push({
        text: I18n.t(
          'Comments release date and time must be the same or before grades release date',
        ),
        type: 'error',
      })
    }
  }

  return errorMessages
}

export const combineDateTime = (
  dateString: string | null | undefined,
  timeString: string | null | undefined,
): string | undefined => {
  if (!dateString && !timeString) {
    return undefined
  }

  if (!dateString) {
    dateString = new Date().toISOString()
  }

  if (!timeString) {
    const now = new Date()
    timeString = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString()
  }

  const dateToCombine = new Date(dateString)
  const timeToCombine = new Date(timeString)

  const combined = new Date(
    dateToCombine.getFullYear(),
    dateToCombine.getMonth(),
    dateToCombine.getDate(),
    timeToCombine.getHours(),
    timeToCombine.getMinutes(),
    timeToCombine.getSeconds(),
  )

  return combined.toISOString()
}
