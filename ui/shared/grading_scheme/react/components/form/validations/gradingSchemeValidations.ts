/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {GradingSchemeFormDataWithUniqueRowIds} from '../GradingSchemeInput'
import {roundToTwoDecimalPlaces} from '../../../helpers/roundToTwoDecimalPlaces'

export const gradingSchemeIsValid = (
  gradingSchemeFormData: GradingSchemeFormDataWithUniqueRowIds
): boolean => {
  return (
    gradingSchemeFormData.title?.trim().length > 0 &&
    rowDataIsValidNumber(gradingSchemeFormData) &&
    rowDataIsValid(gradingSchemeFormData) &&
    rowNamesAreValid(gradingSchemeFormData)
  )
}

export const rowDataIsValidNumber = (
  gradingSchemeFormData: GradingSchemeFormDataWithUniqueRowIds
): boolean => {
  return gradingSchemeFormData.data.filter(data => data.minRangeNotValidNumber).length === 0
}

export const rowDataIsValid = (
  gradingSchemeFormData: GradingSchemeFormDataWithUniqueRowIds
): boolean => {
  if (gradingSchemeFormData.data.length <= 1) return true
  const rowValues = gradingSchemeFormData.data.map(dataRow => String(dataRow.value).trim())
  const sanitizedRowValues = [...new Set(rowValues.filter(v => v))] // get the unique set of only truthy values
  if (sanitizedRowValues.length !== gradingSchemeFormData.data.length) return false

  return gradingSchemeFormData.data.every((dataRow, idx, rows) => {
    if (idx === 0) return true
    const thisMinScore = roundToTwoDecimalPlaces(dataRow.value)
    const priorRowMinScore = roundToTwoDecimalPlaces(rows[idx - 1].value)
    return thisMinScore < priorRowMinScore
  })
}

export const rowNamesAreValid = (
  gradingSchemeFormData: GradingSchemeFormDataWithUniqueRowIds
): boolean => {
  const rowValues = gradingSchemeFormData.data.map(dataRow => String(dataRow.name).trim())
  const sanitizedRowNames = [...new Set(rowValues.filter(v => v))] // get the unique set of only truthy values
  return sanitizedRowNames.length === gradingSchemeFormData.data.length
}
