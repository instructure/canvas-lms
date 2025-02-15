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

const {floor} = Math
import type {Enrollment} from '../types'
import I18nObj, {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('course_people')

const pad = function (duration: number) {
  const padding = duration >= 0 && duration < 10 ? '0' : ''
  return padding + duration.toFixed()
}

// Format a duration given in seconds into a stopwatch-style timer, e.g:
//
//   1 second      => 00:01
//   30 seconds    => 00:30
//   84 seconds    => 01:24
//   7230 seconds  => 02:00:30
//   7530 seconds  => 02:05:30
export const secondsToTime = (seconds: number) => {
  if (seconds >= 3600) {
    const hh = floor(seconds / 3600)
    const mm = floor((seconds - hh * 3600) / 60)
    const ss = seconds % 60
    return `${pad(hh)}:${pad(mm)}:${pad(ss)}`
  } else {
    return `${pad(floor(seconds / 60))}:${pad(floor(seconds % 60))}`
  }
}

// convert an event date and time to a string using the given date and time format specifiers
export const timeEventToString = (date: string = '', i18n_date_format: string = 'short', i18n_time_format: string = 'tiny') => {
  if (date) {
    return I18nObj.t('time.event', {
      defaultValue: '%{date} at %{time}',
      date: I18nObj.l(`date.formats.${i18n_date_format}`, date),
      time: I18nObj.l(`time.formats.${i18n_time_format}`, date),
    })
  }
}

export const totalActivity = (enrollments: Enrollment[]) => {
  const times = enrollments.map(e => e.totalActivityTime || 0)
  const maxTime = Math.max(...times)
  return (maxTime && maxTime > 0) ? secondsToTime(maxTime) : ''
}

export enum EnrollmentTypes {
  StudentEnrollment,
  TeacherEnrollment,
  TaEnrollment,
  ObserverEnrollment,
  DesignerEnrollment
}

export const getRoleName = (role: EnrollmentTypes | string) => {
  const TYPES = {
    TeacherEnrollment: I18n.t('Teacher'),
    StudentEnrollment: I18n.t('Student'),
    TaEnrollment: I18n.t('TA'),
    ObserverEnrollment: I18n.t('Observer'),
    DesignerEnrollment: I18n.t('Designer')
  }

  // Custom roles return as named
  // @ts-expect-error
  return TYPES[role] || role
}
