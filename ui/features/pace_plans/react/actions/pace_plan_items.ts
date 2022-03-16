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

import {createAction, ActionsUnion} from '../shared/types'

export enum Constants {
  SET_PLAN_ITEM_DURATION = 'PACE_PLAN_ITEMS/SET_PLAN_ITEM_DURATION'
}

/* Action creators */

export const actions = {
  setPlanItemDuration: (planItemId: string, duration: number) =>
    createAction(Constants.SET_PLAN_ITEM_DURATION, {planItemId, duration})
}

export type PacePlanItemAction = ActionsUnion<typeof actions>
