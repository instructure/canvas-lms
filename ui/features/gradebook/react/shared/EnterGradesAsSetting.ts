// @ts-nocheck
/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

const gradingTypeOptionMap = {
  gpa_scale: ['points', 'percent', 'gradingScheme'],
  letter_grade: ['points', 'percent', 'gradingScheme'],
  pass_fail: ['passFail'],
  percent: ['points', 'percent'],
  points: ['points', 'percent'],
}

const gradingTypeDefaultOptionMap = {
  gpa_scale: 'gradingScheme',
  letter_grade: 'gradingScheme',
  pass_fail: 'passFail',
  percent: 'percent',
  points: 'points',
}

export function defaultOptionForGradingType(gradingType: string) {
  return gradingTypeDefaultOptionMap[gradingType] || null
}

export function optionsForGradingType(gradingType: string) {
  return gradingTypeOptionMap[gradingType] || []
}
