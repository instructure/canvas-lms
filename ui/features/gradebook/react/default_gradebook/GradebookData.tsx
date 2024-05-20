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
import {camelizeProperties} from '@canvas/convert-case'
import PostGradesStore from '../SISGradePassback/PostGradesStore'
import Gradebook from './Gradebook'
import {findFilterValuesOfType} from './Gradebook.utils'
import type {GradebookOptions} from './gradebook.d'
import PerformanceControls from './PerformanceControls'
import {RequestDispatch} from '@canvas/network'
import useStore from './stores/index'

type Props = {
  actionMenuNode: HTMLSpanElement
  anonymousSpeedGraderAlertNode: HTMLSpanElement
  applyScoreToUngradedModalNode: HTMLElement
  currentUserId: string
  enhancedActionMenuNode: HTMLSpanElement
  flashMessageContainer: HTMLElement
  gradebookEnv: GradebookOptions
  gradebookGridNode: HTMLElement
  gradebookMenuNode: HTMLElement
  gradebookSettingsModalContainer: HTMLSpanElement
  gridColorNode: HTMLElement
  locale: string
  settingsModalButtonContainer: HTMLElement
  viewOptionsMenuNode: HTMLElement
}

export default function GradebookData(props: Props) {
  const performanceControls = useRef(
    new PerformanceControls(camelizeProperties(props.gradebookEnv.performance_controls))
  )
  const dispatch = useRef(
    new RequestDispatch({
      activeRequestLimit: performanceControls.current.activeRequestLimit,
    })
  )
  const postGradesStore = useRef(
    PostGradesStore({
      course: {id: props.gradebookEnv.context_id, sis_id: props.gradebookEnv.context_sis_id},
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
  const loadStudentData = useStore(state => state.loadStudentData)
  const isStudentDataLoaded = useStore(state => state.isStudentDataLoaded)
  const isSubmissionDataLoaded = useStore(state => state.isSubmissionDataLoaded)
  const totalSubmissionsLoaded = useStore(state => state.totalSubmissionsLoaded)
  const totalStudentsToLoad = useStore(state => state.totalStudentsToLoad)

  const sisOverrides = useStore(state => state.sisOverrides)
  const fetchSisOverrides = useStore(state => state.fetchSisOverrides)

  const gradingPeriodAssignments = useStore(state => state.gradingPeriodAssignments)
  const fetchGradingPeriodAssignments = useStore(state => state.fetchGradingPeriodAssignments)
  const loadAssignmentGroups = useStore(state => state.loadAssignmentGroups)
  const recentlyLoadedAssignmentGroups = useStore(state => state.recentlyLoadedAssignmentGroups)
  const assignmentMap = useStore(state => state.assignmentMap)

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
      props.gradebookEnv.settings.filter_columns_by || {},
      props.gradebookEnv.custom_grade_statuses_enabled
        ? props.gradebookEnv.custom_grade_statuses
        : [],
      props.gradebookEnv.multiselect_gradebook_filters_enabled
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
    props.gradebookEnv.custom_grade_statuses_enabled,
    props.gradebookEnv.custom_grade_statuses,
    props.gradebookEnv.multiselect_gradebook_filters_enabled,
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
      // eslint-disable-next-line promise/catch-or-return
      fetchGradingPeriodAssignments().then(() => {
        if (currentGradingPeriodId !== '0') {
          loadAssignmentGroups(props.gradebookEnv.hide_zero_point_quizzes, currentGradingPeriodId)
        }
      })
    } else {
      loadAssignmentGroups(props.gradebookEnv.hide_zero_point_quizzes)
    }
  }, [
    gradingPeriodSet,
    currentGradingPeriodId,
    fetchGradingPeriodAssignments,
    loadAssignmentGroups,
    props.gradebookEnv.hide_zero_point_quizzes,
  ])

  const reloadStudentData = useCallback(() => {
    loadStudentData()
  }, [loadStudentData])

  return (
    <Gradebook
      {...props}
      appliedFilters={appliedFilters}
      assignmentMap={assignmentMap}
      customColumns={customColumns}
      fetchFinalGradeOverrides={fetchFinalGradeOverrides}
      fetchGradingPeriodAssignments={fetchGradingPeriodAssignments}
      finalGradeOverrides={finalGradeOverrides}
      flashAlerts={flashMessages}
      gradingPeriodAssignments={gradingPeriodAssignments}
      isCustomColumnsLoaded={isCustomColumnsLoaded}
      isFiltersLoading={isFiltersLoading}
      isGridLoaded={false}
      isModulesLoading={isModulesLoading}
      isStudentDataLoaded={isStudentDataLoaded}
      isStudentIdsLoading={isStudentIdsLoading}
      loadDataForCustomColumn={loadDataForCustomColumn}
      isSubmissionDataLoaded={isSubmissionDataLoaded}
      modules={modules}
      postGradesStore={postGradesStore.current}
      recentlyLoadedAssignmentGroups={recentlyLoadedAssignmentGroups}
      recentlyLoadedCustomColumnData={recentlyLoadedCustomColumnData}
      recentlyLoadedStudents={recentlyLoadedStudents}
      recentlyLoadedSubmissions={recentlyLoadedSubmissions}
      reloadStudentData={reloadStudentData}
      reorderCustomColumns={reorderCustomColumns}
      sisOverrides={sisOverrides}
      totalSubmissionsLoaded={totalSubmissionsLoaded}
      studentIds={studentIds}
      totalStudentsToLoad={totalStudentsToLoad}
      updateColumnOrder={updateColumnOrder}
    />
  )
}
