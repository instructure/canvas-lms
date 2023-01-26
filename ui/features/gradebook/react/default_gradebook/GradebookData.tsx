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

import React, {useRef, useEffect, useCallback} from 'react'
import shallow from 'zustand/shallow'
import {camelize} from 'convert-case'
import Gradebook from './Gradebook'
import {findFilterValuesOfType} from './Gradebook.utils'
import type {GradebookOptions} from './gradebook.d'
import PerformanceControls from './PerformanceControls'
import {RequestDispatch} from '@canvas/network'
import useStore from './stores/index'

type Props = {
  applyScoreToUngradedModalNode: HTMLElement
  currentUserId: string
  filterNavNode: HTMLElement
  flashMessageContainer: HTMLElement
  gradebookEnv: GradebookOptions
  gradebookGridNode: HTMLElement
  gradebookMenuNode: HTMLElement
  gradingPeriodsFilterContainer: HTMLElement
  gridColorNode: HTMLElement
  hideGrid?: false
  locale: string
  settingsModalButtonContainer: HTMLElement
  viewOptionsMenuNode: HTMLElement
}

export default function GradebookData(props: Props) {
  const performanceControls = useRef(
    new PerformanceControls(camelize(props.gradebookEnv.performance_controls))
  )
  const dispatch = useRef(
    new RequestDispatch({
      activeRequestLimit: performanceControls.current.activeRequestLimit,
    })
  )
  const courseId = props.gradebookEnv.context_id
  const flashMessages = useStore(state => state.flashMessages)

  const appliedFilters = useStore(state => state.appliedFilters, shallow)
  const isFiltersLoading = useStore(state => state.isFiltersLoading)
  const initializeAppliedFilters = useStore(state => state.initializeAppliedFilters)
  const initializeStagedFilters = useStore(state => state.initializeStagedFilters)
  const fetchFilters = useStore(state => state.fetchFilters)

  const modules = useStore(state => state.modules)
  const isModulesLoading = useStore(state => state.isModulesLoading)
  const fetchModules = useStore(state => state.fetchModules)

  const customColumns = useStore(state => state.customColumns, shallow)
  const isCustomColumnsLoaded = useStore(state => state.isCustomColumnsLoaded)
  const fetchCustomColumns = useStore(state => state.fetchCustomColumns)
  const loadDataForCustomColumn = useStore(state => state.loadDataForCustomColumn)
  const recentlyLoadedCustomColumnData = useStore(state => state.recentlyLoadedCustomColumnData)
  const reorderCustomColumns = useStore(state => state.reorderCustomColumns)
  const updateColumnOrder = useStore(state => state.updateColumnOrder)

  const finalGradeOverrides = useStore(state => state.finalGradeOverrides)
  const fetchFinalGradeOverrides = useStore(state => state.fetchFinalGradeOverrides)

  const studentIds = useStore(state => state.studentIds, shallow)
  const isStudentIdsLoading = useStore(state => state.isStudentIdsLoading)
  const recentlyLoadedStudents = useStore(state => state.recentlyLoadedStudents)
  const recentlyLoadedSubmissions = useStore(state => state.recentlyLoadedSubmissions)
  const fetchStudentIds = useStore(state => state.fetchStudentIds)
  const loadStudentData = useStore(state => state.loadStudentData)
  const isStudentDataLoaded = useStore(state => state.isStudentDataLoaded)
  const isSubmissionDataLoaded = useStore(state => state.isSubmissionDataLoaded)

  const sisOverrides = useStore(state => state.sisOverrides)
  const fetchSisOverrides = useStore(state => state.fetchSisOverrides)

  const gradingPeriodAssignments = useStore(state => state.gradingPeriodAssignments)
  const isGradingPeriodAssignmentsLoading = useStore(
    state => state.isGradingPeriodAssignmentsLoading
  )
  const fetchGradingPeriodAssignments = useStore(state => state.fetchGradingPeriodAssignments)
  const loadAssignmentGroups = useStore(state => state.loadAssignmentGroups)
  const recentlyLoadedAssignmentGroups = useStore(state => state.recentlyLoadedAssignmentGroups)

  const currentGradingPeriodId = findFilterValuesOfType('grading-period', appliedFilters)[0]
  const gradingPeriodSet = props.gradebookEnv.grading_period_set

  // Initial state
  useEffect(() => {
    useStore.setState({
      courseId,
      dispatch: dispatch.current,
      performanceControls: performanceControls.current,
      hasModules: props.gradebookEnv.has_modules,
      allowFinalGradeOverride: props.gradebookEnv.course_settings.allow_final_grade_override,
      reorderCustomColumnsUrl: props.gradebookEnv.reorder_custom_columns_url,
    })
    initializeAppliedFilters(
      props.gradebookEnv.settings.filter_rows_by || {},
      props.gradebookEnv.settings.filter_columns_by || {}
    )
  }, [
    courseId,
    props.gradebookEnv.enhanced_gradebook_filters,
    props.gradebookEnv.settings.filter_rows_by,
    props.gradebookEnv.settings.filter_columns_by,
    props.gradebookEnv.has_modules,
    props.gradebookEnv.course_settings.allow_final_grade_override,
    props.gradebookEnv.reorder_custom_columns_url,
    initializeAppliedFilters,
  ])

  // Data loading logic goes here
  useEffect(() => {
    if (props.gradebookEnv.enhanced_gradebook_filters) {
      fetchFilters()
    }
    if (props.gradebookEnv.has_modules) {
      fetchModules()
    }
    if (props.gradebookEnv.course_settings.allow_final_grade_override) {
      fetchFinalGradeOverrides()
    }
    if (props.gradebookEnv.post_grades_feature) {
      fetchSisOverrides()
    }
    fetchCustomColumns()
    loadStudentData()
  }, [
    fetchCustomColumns,
    fetchFilters,
    fetchFinalGradeOverrides,
    fetchModules,
    loadStudentData,
    fetchSisOverrides,
    initializeStagedFilters,
    props.gradebookEnv.course_settings.allow_final_grade_override,
    props.gradebookEnv.enhanced_gradebook_filters,
    props.gradebookEnv.has_modules,
    props.gradebookEnv.post_grades_feature,
    props.gradebookEnv.settings.filter_columns_by,
    props.gradebookEnv.settings.filter_rows_by,
  ])

  useEffect(() => {
    if (gradingPeriodSet) {
      fetchGradingPeriodAssignments()
        .then(() => {
          if (currentGradingPeriodId !== '0') {
            loadAssignmentGroups(currentGradingPeriodId)
          }
        })
        .catch(error => {
          throw new Error('Failed to load grading period assignments', error)
        })
    } else {
      loadAssignmentGroups().catch(error => {
        throw new Error('Failed to load assignment groups', error)
      })
    }
  }, [
    gradingPeriodSet,
    currentGradingPeriodId,
    fetchGradingPeriodAssignments,
    loadAssignmentGroups,
  ])

  const reloadStudentData = useCallback(() => {
    loadStudentData()
  }, [loadStudentData])

  return (
    <Gradebook
      {...props}
      appliedFilters={appliedFilters}
      customColumns={customColumns}
      loadDataForCustomColumn={loadDataForCustomColumn}
      recentlyLoadedCustomColumnData={recentlyLoadedCustomColumnData}
      fetchFinalGradeOverrides={fetchFinalGradeOverrides}
      fetchGradingPeriodAssignments={fetchGradingPeriodAssignments}
      fetchStudentIds={fetchStudentIds}
      flashAlerts={flashMessages}
      gradingPeriodAssignments={gradingPeriodAssignments}
      hideGrid={false}
      isCustomColumnsLoaded={isCustomColumnsLoaded}
      isFiltersLoading={isFiltersLoading}
      isGradingPeriodAssignmentsLoading={isGradingPeriodAssignmentsLoading}
      isModulesLoading={isModulesLoading}
      isStudentIdsLoading={isStudentIdsLoading}
      isStudentDataLoaded={isStudentDataLoaded}
      isSubmissionDataLoaded={isSubmissionDataLoaded}
      finalGradeOverrides={finalGradeOverrides}
      modules={modules}
      recentlyLoadedAssignmentGroups={recentlyLoadedAssignmentGroups}
      sisOverrides={sisOverrides}
      recentlyLoadedStudents={recentlyLoadedStudents}
      recentlyLoadedSubmissions={recentlyLoadedSubmissions}
      reloadStudentData={reloadStudentData}
      reorderCustomColumns={reorderCustomColumns}
      studentIds={studentIds}
      // when the rest of DataLoader is moved we can remove these
      performanceControls={performanceControls.current}
      dispatch={dispatch.current}
      updateColumnOrder={updateColumnOrder}
    />
  )
}
