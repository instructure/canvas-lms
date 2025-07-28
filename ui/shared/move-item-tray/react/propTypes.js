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

import {string, shape, arrayOf, oneOfType, bool} from 'prop-types'

export const ErrorPropType = (props, propName, componentName) => {
  if (props[propName] != null && !(props[propName] instanceof Error)) {
    return new Error(
      `Invalid prop '${propName}' supplied to '${componentName}'. Expected an Error object.`,
    )
  }
  return null
}

export const itemShape = shape({
  id: string.isRequired,
  title: string.isRequired,
  groupId: string,
})

export const groupShape = shape({
  id: string.isRequired,
  title: string.isRequired,
  items: oneOfType([arrayOf(itemShape), bool]),
})

export const siblingPropType = oneOfType([arrayOf(itemShape), ErrorPropType])

export const moveOptionsType = oneOfType([
  shape({
    siblings: siblingPropType,
  }),
  shape({
    groupsLabel: string.isRequired,
    groups: arrayOf(groupShape).isRequired,
    excludeCurrent: bool,
  }),
])
