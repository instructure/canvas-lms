/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

// beause isNan is not the same as Number.isNaN
/* eslint-disable no-restricted-globals */
export const isPointsValid = value => {
  const strValue = `${value}`
  if (!strValue) return false // it's required
  if (isNaN(strValue)) return false // must be a number
  return parseFloat(strValue) >= 0 // must be non-negative
}
/* eslint-enable no-restricted-globals */

export const isNameValid = value => !!value && value.trim().length > 0

const validators = {
  pointsPossible: isPointsValid,
  name: isNameValid
}

export const validate = (path, value) => (validators[path] ? validators[path](value) : true)

export default validators
