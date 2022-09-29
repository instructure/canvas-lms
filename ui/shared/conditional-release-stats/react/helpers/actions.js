/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

export function typeNameToFuncName(typeName) {
  const parts = typeName.split('_')
  return parts
    .map((part, i) => {
      if (i !== 0 && part.length) {
        return part.charAt(0).toUpperCase() + part.slice(1).toLowerCase()
      } else {
        return part.toLowerCase()
      }
    })
    .join('')
}

export function createAction(actionType) {
  const actionCreator = payload => ({
    type: actionType,
    payload,
  })

  actionCreator.type = actionType
  actionCreator.toString = () => actionType
  return actionCreator
}

export function createActions(actionDefs) {
  const actionTypes = {}
  const actions = {}

  actionDefs.forEach(actionDef => {
    const action = createAction(actionDef)
    const funcName = typeNameToFuncName(action.type)
    actions[funcName] = action
    actionTypes[action.type] = action.type
  })

  return {actionTypes, actions}
}
