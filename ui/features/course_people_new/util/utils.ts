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
import {
  NO_PERMISSIONS,
  ACCOUNT_MEMBERSHIP,
  TEACHER_ENROLLMENT,
  STUDENT_ENROLLMENT,
  TA_ENROLLMENT,
  OBSERVER_ENROLLMENT,
  DESIGNER_ENROLLMENT,
  ACCOUNT_ADMIN,
  TEACHER_ROLE,
  STUDENT_ROLE,
  TA_ROLE,
  OBSERVER_ROLE,
  DESIGNER_ROLE
} from './constants'
import {EnvRole, SisRole} from '../types'
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

// for custom roles sis_role is the role name
// for built-in roles, sis_role is mapped from enrollment type in Enrollment::SIS_TYPES
export const getRoleName = (sisRole: SisRole | string) => {
  const SIS_ROLE: Partial<Record<SisRole, string>> = {
    [TEACHER_ROLE]: I18n.t('Teacher'),
    [STUDENT_ROLE]: I18n.t('Student'),
    [TA_ROLE]: I18n.t('TA'),
    [OBSERVER_ROLE]: I18n.t('Observer'),
    [DESIGNER_ROLE]: I18n.t('Designer')
  }

  // Custom roles are returned as named
  return SIS_ROLE[sisRole as SisRole] || sisRole
}

export const screenreaderMessageHolderId = 'flash_screenreader_holder'

export const getLiveRegion = (): HTMLDivElement => {
  let liveRegion = document.getElementById(screenreaderMessageHolderId)
  if (!liveRegion) {
    liveRegion = document.createElement('div')
    liveRegion.id = screenreaderMessageHolderId
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  }
  return liveRegion as HTMLDivElement
}

//   Roles are ordered by base_role_type then alphabetically within those
//   base role types. The order that these base role types live is defined
//   by the sortOrder array. There is a special case however. AccountAdmin
//   role always goes first. This uses the index of the sortOrder to ensure
//   the correct order since comparator is just using _.sort in it's
//   underlining implementation which is just ordering based on alphabetical
//   correctness.
export const sortRoles = (roles: EnvRole[]) => {
  const sortOrder = [
    NO_PERMISSIONS,
    ACCOUNT_MEMBERSHIP,
    STUDENT_ENROLLMENT,
    TA_ENROLLMENT,
    TEACHER_ENROLLMENT,
    DESIGNER_ENROLLMENT,
    OBSERVER_ENROLLMENT
  ]

  const comparator = (role: EnvRole) => {
    const {base_role_name, name: role_name} = role
    const index = sortOrder.indexOf(base_role_name)

    let position_string = `${index}_${base_role_name}_${role_name}`

    if (base_role_name === role_name) {
      position_string = `${index}_${base_role_name}`
    }
    if (role_name === ACCOUNT_ADMIN) {
      position_string = `0_${base_role_name}`
    }

    return position_string
  }

  return roles.sort((a, b) => comparator(a).toLowerCase().localeCompare(comparator(b).toLowerCase()))
}
