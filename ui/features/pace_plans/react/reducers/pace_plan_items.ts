/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {PacePlanItem, Module} from '../types'
import {Constants as PacePlanItemConstants, PacePlanItemAction} from '../actions/pace_plan_items'

/* Reducers */

const itemsReducer = (state: PacePlanItem[], action: PacePlanItemAction): PacePlanItem[] => {
  switch (action.type) {
    case PacePlanItemConstants.SET_PLAN_ITEM_DURATION:
      return state.map(item => {
        return item.module_item_id === action.payload.planItemId
          ? {...item, duration: action.payload.duration}
          : item
      })
    default:
      return state
  }
}

// Modules are read-only currently, so this is just deferring to the itemsReducer for
// each  module's item.
export default (state: Module[], action: PacePlanItemAction): Module[] => {
  if (!state) return state
  return state.map(module => ({...module, items: itemsReducer(module.items, action)}))
}
