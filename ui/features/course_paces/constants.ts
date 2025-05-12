/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

const I18n = createI18nScope('course_paces_projected_dates')

export const WORK_WEEK_DAYS_MENU_OPTIONS = [
  {value: 'mon', label: 'Mondays'},
  {value: 'tue', label: 'Tuesdays'},
  {value: 'wed', label: 'Wednesdays'},
  {value: 'thu', label: 'Thursdays'},
  {value: 'fri', label: 'Fridays'},
  {value: 'sat', label: 'Saturdays'},
  {value: 'sun', label: 'Sundays'},
]

export const WEEK_DAYS_VALUES = WORK_WEEK_DAYS_MENU_OPTIONS.slice(0, 5).map(({value}) => value)

export const START_DATE_CAPTIONS = {
  enrollment: I18n.t('Student enrollment date'),
  enrollment_time_selection: I18n.t('Determined by student enrollment date'),
  course: I18n.t(
    'Determined by course start date. Changing this date will not save, but you can view the effects of a new start date by changing the date here.',
  ),
  section: I18n.t(
    'Determined by section start date. Changing this date will not save, but you can view the effects of a new start date by changing the date here.',
  ),
  empty: I18n.t(
    "Determined by today's date. Changing this date will not save, but you can view the effects of a new start date by changing the date here.",
  ),
}

export const END_DATE_CAPTIONS = {
  default: I18n.t('Determined by course pace'),
  course: I18n.t('Determined by course end date'),
  section: I18n.t('Determined by section end date'),
  empty: I18n.t('Determined by course pace'),
}
