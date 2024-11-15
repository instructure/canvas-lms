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

import type {
  AdjustDates,
  DateShifts,
  DateShiftsRequestBody,
  DaySub,
  MigrationCreateRequestBody,
  submitMigrationFormData,
} from '../components/types'

const convertDaySubstitutions = (dateShiftOptions: DateShifts): Record<string, string> => {
  const treated_subs: {[key: string]: string} = {}
  dateShiftOptions.day_substitutions.forEach((ds: DaySub) => {
    treated_subs[ds.from.toString()] = ds.to.toString()
  })
  return treated_subs
}

const convertDateOperation = (
  adjustDates: AdjustDates
): {} | {shift_dates: boolean} | {remove_dates: boolean} => {
  if (!adjustDates.enabled) {
    return {}
  }
  const operation = adjustDates.operation
  if (operation === 'shift_dates') {
    return {shift_dates: true}
  }
  if (operation === 'remove_dates') {
    return {remove_dates: true}
  }
  return {}
}

const convertDateShiftOptions = (
  formDateShiftOptions: submitMigrationFormData
): DateShiftsRequestBody => {
  return {
    old_start_date: formDateShiftOptions.date_shift_options.old_start_date,
    new_start_date: formDateShiftOptions.date_shift_options.new_start_date,
    old_end_date: formDateShiftOptions.date_shift_options.old_end_date,
    new_end_date: formDateShiftOptions.date_shift_options.new_end_date,
    day_substitutions: convertDaySubstitutions(formDateShiftOptions.date_shift_options),
    ...convertDateOperation(formDateShiftOptions.adjust_dates),
  }
}

export const convertFormDataToMigrationCreateRequest = (
  formData: submitMigrationFormData,
  courseId: string,
  chosenMigrator: string
): MigrationCreateRequestBody => {
  return {
    course_id: courseId,
    migration_type: chosenMigrator,
    date_shift_options: convertDateShiftOptions(formData),
    selective_import: formData.selective_import,
    settings: formData.settings,
    pre_attachment: formData.pre_attachment,
  }
}
