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

import {BlackoutDate, createAction, type ActionsUnion} from '../shared/types'
import {AssignmentWeightening, CoursePace} from '../types'

export enum Constants {
  SET_PACE_ITEM_DURATION = 'COURSE_PACE_ITEMS/SET_PACE_ITEM_DURATION',
  SET_PACE_ITEMS_DURATION_FROM_TIME_TO_COMPLETE = 'COURSE_PACE_ITEMS/SET_PACE_ITEMS_DURATION_FROM_TIME_TO_COMPLETE'
}

/* Action creators */

export const actions = {
  setPaceItemDuration: (paceItemId: string, duration: number) =>
    createAction(Constants.SET_PACE_ITEM_DURATION, {paceItemId, duration}),
  setPaceItemsDurationFromTimeToComplete: (coursePace: CoursePace, blackOutDays: BlackoutDate[], calendarDays: number) =>
    createAction(Constants.SET_PACE_ITEMS_DURATION_FROM_TIME_TO_COMPLETE, {coursePace, blackOutDays, calendarDays})
}

export type CoursePaceItemAction = ActionsUnion<typeof actions>
