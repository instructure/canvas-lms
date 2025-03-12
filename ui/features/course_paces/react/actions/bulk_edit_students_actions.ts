/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import * as Api from '../api/pace_contexts_api'
import type {Dispatch} from 'redux'
import type {BulkEditStudentsState, SortableColumn, OrderType, Section, BulkStudentsApiResponse, Student, CoursePace} from '../types'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('bulk_edit_students_actions')

export const SET_SEARCH_TERM = 'bulkEditStudents/SET_SEARCH_TERM'
export const SET_FILTER_SECTION = 'bulkEditStudents/SET_FILTER_SECTION'
export const SET_FILTER_PACE_STATUS = 'bulkEditStudents/SET_FILTER_PACE_STATUS'
export const SET_SORT = 'bulkEditStudents/SET_SORT'
export const SET_PAGE = 'bulkEditStudents/SET_PAGE'
export const SET_LOADING = 'bulkEditStudents/SET_LOADING'
export const SET_ERROR = 'bulkEditStudents/SET_ERROR'
export const SET_STUDENTS = 'bulkEditStudents/SET_STUDENTS'
export const SET_SECTIONS = 'bulkEditStudents/SET_SECTIONS'
export const SET_PAGE_COUNT = 'bulkEditStudents/SET_PAGE_COUNT'
export const RESET_BULK_EDIT_STATE = 'bulkEditStudents/RESET_BULK_EDIT_STATE'

export const setSearchTerm = (term: string) => ({
  type: SET_SEARCH_TERM,
  payload: term,
})

export const setFilterSection = (section: string) => ({
  type: SET_FILTER_SECTION,
  payload: section,
})

export const setFilterPaceStatus = (status: string) => ({
  type: SET_FILTER_PACE_STATUS,
  payload: status,
})

export const setSort = (sortBy: SortableColumn, orderType: OrderType) => ({
  type: SET_SORT,
  payload: { sortBy, orderType },
})

export const setPage = (page: number) => ({
  type: SET_PAGE,
  payload: page,
})

export const setLoading = (isLoading: boolean) => ({
  type: SET_LOADING,
  payload: isLoading,
})

export const setError = (errorMsg: string) => ({
  type: SET_ERROR,
  payload: errorMsg,
})

export const setStudents = (students: Student[]) => ({
  type: SET_STUDENTS,
  payload: students,
})

export const setSections = (sections: Section[]) => ({
  type: SET_SECTIONS,
  payload: sections,
})

export const setPageCount = (pageCount: number) => ({
  type: SET_PAGE_COUNT,
  payload: pageCount,
})

export const resetBulkEditState = () => ({
  type: RESET_BULK_EDIT_STATE
})

export const fetchStudents = () => {
  return async (dispatch: Dispatch, getState: () => { bulkEditStudents: BulkEditStudentsState, coursePace: CoursePace }) => {
    try {
      dispatch(setLoading(true))
      dispatch(setError(''))
      const {
        searchTerm,
        filterSection,
        filterPaceStatus,
        sortBy,
        orderType,
        page,
      } = getState().bulkEditStudents
      const courseId = getState().coursePace.course_id
      const response = await Api.getStudentBulkPaceEditView({
        courseId,
        page,
        entriesPerRequest: 10,
        searchTerm,
        sortBy,
        orderType,
        filterPaceStatus,
        filterSection
      }) as BulkStudentsApiResponse
      const allSectionsOption: Section = { id: 'all', course_id: '', name: I18n.t('All Sections') }
      const sectionsWithAll = [allSectionsOption, ...response.sections]

      dispatch(setStudents(response.students))
      dispatch(setSections(sectionsWithAll))
      dispatch(setPageCount(response.pages))
    } catch (err) {
      dispatch(setError(I18n.t('Something went wrong fetching students.')))
    } finally {
      dispatch(setLoading(false))
    }
  }
}

