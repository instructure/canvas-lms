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

import {createAction} from 'redux-actions'

// @payload: string to filter assignments by name
export const FILTER_ASSIGNMENTS_BY_NAME = 'FILTER_BY_NAME'
export const filterAssignmentsByName = createAction(FILTER_ASSIGNMENTS_BY_NAME)

// @payload: string representing category id
export const FILTER_ASSIGNMENTS_BY_CATEGORY = 'FILTER_BY_CATEGORY'
export const filterAssignmentsByCategory = createAction(FILTER_ASSIGNMENTS_BY_CATEGORY)

// @payload: string representing assignment id
export const SELECT_ASSIGNMENT_IN_PICKER = 'SELECT_ASSIGNMENT_IN_PICKER'
export const selectAssignmentInPicker = createAction(SELECT_ASSIGNMENT_IN_PICKER)

// @payload: string representing assignment id
export const UNSELECT_ASSIGNMENT_IN_PICKER = 'UNSELECT_ASSIGNMENT_IN_PICKER'
export const unselectAssignmentInPicker = createAction(UNSELECT_ASSIGNMENT_IN_PICKER)

// @payload: range model instance
export const SET_ASSIGNMENT_PICKER_TARGET = 'SET_ASSIGNMENT_PICKER_TARGET'
export const setAssignmentPickerTarget = createAction(SET_ASSIGNMENT_PICKER_TARGET)

// @payload: none
export const OPEN_ASSIGNMENT_PICKER = 'OPEN_ASSIGNMENT_PICKER'
export const openAssignmentPicker = createAction(OPEN_ASSIGNMENT_PICKER)

// @payload: none
export const CLOSE_ASSIGNMENT_PICKER = 'CLOSE_ASSIGNMENT_PICKER'
export const closeAssignmentPicker = createAction(CLOSE_ASSIGNMENT_PICKER)
