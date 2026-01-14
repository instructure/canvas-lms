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

import type {GradingSchemeDataRow} from '@instructure/grading-utils'

export const gradingSchemeIsValid = (gradingSchemeFormData: {
  data: {name: string; value: number}[]
  scalingFactor: number
  pointsBased: boolean
  title: string
}): boolean => {
  return (
    gradingSchemeFormData.title?.trim().length > 0 &&
    rowDataIsValidNumbers(gradingSchemeFormData) &&
    rowDataIsValid(gradingSchemeFormData) &&
    rowNamesAreValid(gradingSchemeFormData)
  )
}

export const rowDataIsValidNumbers = (gradingSchemeFormData: {
  title: string
  data: GradingSchemeDataRow[]
  scalingFactor: number
  pointsBased: boolean
}): boolean => {
  if (
    Number.isNaN(gradingSchemeFormData.scalingFactor) ||
    gradingSchemeFormData.scalingFactor < 0
  ) {
    return false
  }
  if (gradingSchemeFormData.pointsBased && gradingSchemeFormData.scalingFactor > 100) {
    return false
  }
  if (!gradingSchemeFormData.pointsBased && gradingSchemeFormData.scalingFactor !== 1.0) {
    return false
  }
  return (
    gradingSchemeFormData.data.filter(dataRow => {
      // filter out the rows with invalid minRanges
      return !Number.isNaN(dataRow.value) && dataRow.value >= 0 && dataRow.value <= 1.0
    }).length === gradingSchemeFormData.data.length
  )
}

export const rowDataIsValid = (gradingSchemeFormData: {
  title: string
  data: GradingSchemeDataRow[]
}): boolean => {
  if (gradingSchemeFormData.data.length <= 1) return true
  const rowValues = gradingSchemeFormData.data.map(dataRow => String(dataRow.value).trim())
  const sanitizedRowValues = [...new Set(rowValues.filter(v => v))] // get the unique set of only truthy values
  if (sanitizedRowValues.length !== gradingSchemeFormData.data.length) return false

  return gradingSchemeFormData.data.every((dataRow, idx, rows) => {
    if (idx === 0) return true
    const thisMinRange = dataRow.value
    const priorRowMinRange = rows[idx - 1].value
    return thisMinRange < priorRowMinRange
  })
}

export const rowNamesAreValid = (gradingSchemeFormData: {
  title: string
  data: GradingSchemeDataRow[]
}): boolean => {
  const rowValues = gradingSchemeFormData.data.map(dataRow => String(dataRow.name).trim())
  const sanitizedRowNames = [...new Set(rowValues.filter(v => v))] // get the unique set of only truthy values
  return sanitizedRowNames.length === gradingSchemeFormData.data.length
}
