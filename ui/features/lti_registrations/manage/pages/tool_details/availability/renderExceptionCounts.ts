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

const I18n = createI18nScope('lti_registrations')

export const renderExceptionCounts = ({
  child_control_count,
  course_count,
  subaccount_count,
}: {
  child_control_count: number
  course_count: number
  subaccount_count: number
}) => {
  return [
    child_control_count > 0
      ? I18n.t(
          'context_control_exception',
          {
            one: '1 exception',
            other: '%{count} exceptions',
          },
          {
            count: child_control_count,
          },
        )
      : undefined,
    subaccount_count > 0
      ? I18n.t(
          {
            one: '1 child sub-account',
            other: '%{count} child sub-accounts',
          },
          {
            count: subaccount_count,
          },
        )
      : undefined,
    course_count > 0
      ? I18n.t(
          {
            one: '1 child course',
            other: '%{count} child courses',
          },
          {
            count: course_count,
          },
        )
      : undefined,
  ]
    .filter(text => text !== undefined)
    .join(' · ')
}
