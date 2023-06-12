// @ts-nocheck
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

import {Enrollments, Enrollment, StoreState, Section} from '../types'
import {createSelector} from 'reselect'
import natcompare from '@canvas/util/natcompare'

export const enrollmentsInitialState: Enrollments = (window.ENV.ENROLLMENTS || []) as Enrollments

/* Selectors */

export const getEnrollments = (state: StoreState): Enrollments => state.enrollments
export const getEnrollment = (state: StoreState, id: number): Enrollment => state.enrollments[id]
export const getEnrolledSection = (state: StoreState, id: number): Section | null => {
  if (!id) return null
  const sectionId = state.enrollments[id]?.section_id
  return sectionId && state.sections[sectionId]
}

export const getSortedEnrollments = createSelector(
  getEnrollments,
  (enrollments: Enrollments): Enrollment[] => {
    const sortedEnrollments = Object.values(enrollments)
    sortedEnrollments.sort(natcompare.byKey('sortable_name'))
    return sortedEnrollments
  }
)

/* Reducers */

export const enrollmentsReducer = (state = enrollmentsInitialState, action: any): Enrollments => {
  switch (action.type) {
    default:
      return state
  }
}
