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

import {Enrollments, Enrollment, StoreState} from '../types'
import {createSelector} from 'reselect'

export const enrollmentsInitialState: Enrollments = (window.ENV.ENROLLMENTS || []) as Enrollments

/* Selectors */

export const getEnrollments = (state: StoreState): Enrollments => state.enrollments
export const getEnrollment = (state: StoreState, id: number): Enrollment => state.enrollments[id]

export const getSortedEnrollments = createSelector(
  getEnrollments,
  (enrollments: Enrollments): Enrollment[] => {
    const sortedIds = Object.keys(enrollments).sort((a, b) => {
      const enrollmentA: Enrollment = enrollments[a]
      const enrollmentB: Enrollment = enrollments[b]
      if (enrollmentA.sortable_name > enrollmentB.sortable_name) {
        return 1
      } else if (enrollmentA.sortable_name < enrollmentB.sortable_name) {
        return -1
      } else {
        return 0
      }
    })

    return sortedIds.map(id => enrollments[id])
  }
)

/* Reducers */

export const enrollmentsReducer = (state = enrollmentsInitialState, action: any): Enrollments => {
  switch (action.type) {
    default:
      return state
  }
}
