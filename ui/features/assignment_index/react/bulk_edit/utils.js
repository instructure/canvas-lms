/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

export function originalDateField(dateField) {
  return `original_${dateField}`
}

export async function extractFetchErrorMessage(err, fallback) {
  if (!err.response) return err.message
  const errorJson = await err.response.json()
  if (errorJson?.errors?.length) return errorJson.errors[0].message
  return fallback
}

export function canEditAll(assignment) {
  return assignment.can_edit && assignment.all_dates.every(override => override.can_edit)
}
