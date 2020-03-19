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

import $ from 'jquery'

import OldDataLoader from '../../DataLoader'

export default class DataLoader {
  constructor(gradebook) {
    this._gradebook = gradebook
  }

  loadInitialData() {
    const gradebook = this._gradebook
    const {options} = gradebook

    gradebook.setAssignmentGroupsLoaded(false)
    gradebook.setStudentsLoaded(false)
    gradebook.setSubmissionsLoaded(false)

    const promises = OldDataLoader.loadGradebookData({
      gradebook,

      courseId: options.context_id,
      perPage: options.api_max_per_page,

      getGradingPeriodAssignments: gradebook.gradingPeriodSet != null,
      loadedStudentIds: [],

      assignmentGroupsURL: options.assignment_groups_url,
      assignmentGroupsParams: {
        exclude_response_fields: ['description', 'in_closed_grading_period', 'needs_grading_count'],
        include: ['assignment_group_id', 'grades_published', 'module_ids', 'post_manually']
      },

      contextModulesURL: options.context_modules_url,
      customColumnsURL: options.custom_columns_url,
      sectionsURL: options.sections_url,

      studentsURL: options.students_stateless_url,
      studentsPageCb: gradebook.gotChunkOfStudents,
      studentsParams: gradebook.studentsParams(),

      submissionsURL: options.submissions_url,
      submissionsChunkCb: gradebook.gotSubmissionsChunk,
      submissionsChunkSize: options.chunk_size,

      customColumnDataURL: options.custom_column_data_url,
      customColumnDataPageCb: gradebook.gotCustomColumnDataChunk,
      customColumnDataParams: {include_hidden: true}
    })

    promises.gotStudentIds.then(response => {
      gradebook.courseContent.students.setStudentIds(response.user_ids)
      gradebook.buildRows()
    })

    if (promises.gotGradingPeriodAssignments != null) {
      promises.gotGradingPeriodAssignments.then(gradebook.gotGradingPeriodAssignments)
    }

    promises.gotAssignmentGroups.then(gradebook.gotAllAssignmentGroups)
    promises.gotCustomColumns.then(gradebook.gotCustomColumns)
    promises.gotStudents.then(gradebook.gotAllStudents)

    promises.gotStudents.then(() => {
      gradebook.setStudentsLoaded(true)
      gradebook.updateColumnHeaders()
      gradebook.renderFilters()
    })

    promises.gotAssignmentGroups.then(() => {
      gradebook.contentLoadStates.assignmentsLoaded = true
      gradebook.renderViewOptionsMenu()
      gradebook.updateColumnHeaders()
    })

    promises.gotContextModules.then(contextModules => {
      gradebook.setContextModules(contextModules)
      gradebook.contentLoadStates.contextModulesLoaded = true
      gradebook.renderViewOptionsMenu()
      gradebook.renderFilters()
    })

    promises.gotSubmissions.then(() => {
      gradebook.setSubmissionsLoaded(true)
      gradebook.updateColumnHeaders()
      gradebook.renderFilters()
    })

    /*
     * With post policies, the "total grade" column needs to be re-rendered
     * after loading students and submissions so we can indicate there are
     * hidden submissions
     */
    $.when(promises.gotStudents, promises.gotSubmissions).then(() => {
      gradebook.updateTotalGradeColumn()
    })

    gradebook.renderedGrid = $.when(
      promises.gotStudentIds,
      promises.gotContextModules,
      promises.gotCustomColumns,
      promises.gotAssignmentGroups,
      promises.gotGradingPeriodAssignments
    ).then(() => {
      gradebook.finishRenderingUI()
    })
  }

  loadCustomColumnData(customColumnId) {
    const gradebook = this._gradebook
    const {options} = gradebook

    OldDataLoader.getDataForColumn(
      customColumnId,
      options.custom_column_data_url,
      {},
      gradebook.gotCustomColumnDataChunk
    )
  }

  loadOverridesForSIS() {
    const gradebook = this._gradebook
    const {options} = gradebook

    const assignmentGroupsURL = options.assignment_groups_url.replace(
      '&include%5B%5D=assignment_visibility',
      ''
    )

    const promises = OldDataLoader.loadGradebookData({
      assignmentGroupsURL,

      assignmentGroupsParams: {
        exclude_response_fields: ['description', 'needs_grading_count', 'in_closed_grading_period'],
        include: ['overrides']
      },

      onlyLoadAssignmentGroups: true
    })

    $.when(promises.gotAssignmentGroups).then(gradebook.addOverridesToPostGradesStore)
  }

  reloadStudentDataForEnrollmentFilterChange() {
    this._reloadStudentData({
      getGradingPeriodAssignments: true
    })
  }

  reloadStudentDataForSectionFilterChange() {
    this._reloadStudentData({
      getGradingPeriodAssignments: false
    })
  }

  reloadStudentDataForStudentGroupFilterChange() {
    this._reloadStudentData({
      getGradingPeriodAssignments: false
    })
  }

  // PRIVATE

  _reloadStudentData(loadOptions) {
    const gradebook = this._gradebook
    const {options} = gradebook

    gradebook.setStudentsLoaded(false)
    gradebook.setSubmissionsLoaded(false)
    gradebook.renderFilters()

    const promises = OldDataLoader.loadGradebookData({
      gradebook,

      courseId: options.context_id,
      perPage: options.api_max_per_page,

      getGradingPeriodAssignments:
        loadOptions.getGradingPeriodAssignments && gradebook.gradingPeriodSet != null,

      loadedStudentIds: gradebook.courseContent.students.listStudentIds(),
      studentsURL: options.students_stateless_url,
      studentsPageCb: gradebook.gotChunkOfStudents,
      studentsParams: gradebook.studentsParams(),

      submissionsURL: options.submissions_url,
      submissionsChunkCb: gradebook.gotSubmissionsChunk,
      submissionsChunkSize: options.chunk_size,

      customColumnIds: gradebook.gradebookContent.customColumns.map(column => column.id),
      customColumnDataURL: options.custom_column_data_url,
      customColumnDataPageCb: gradebook.gotCustomColumnDataChunk,
      customColumnDataParams: {include_hidden: true}
    })

    if (promises.gotGradingPeriodAssignments != null) {
      promises.gotGradingPeriodAssignments.then(response => {
        gradebook.gotGradingPeriodAssignments(response)
        gradebook.updateColumns()
      })
    }

    promises.gotStudentIds.then(response => {
      gradebook.courseContent.students.setStudentIds(response.user_ids)
      gradebook.assignmentStudentVisibility = {}
      gradebook.buildRows()
    })

    promises.gotStudents.then(() => {
      gradebook.setStudentsLoaded(true)
      gradebook.updateColumnHeaders()
      gradebook.renderFilters()
    })

    promises.gotSubmissions.then(() => {
      gradebook.setSubmissionsLoaded(true)
      gradebook.updateColumnHeaders()
      gradebook.renderFilters()
    })

    /*
     * With post policies, the "total grade" column needs to be re-rendered
     * after loading students and submissions so we can indicate there are
     * hidden submissions
     */
    $.when(promises.gotStudents, promises.gotSubmissions).then(() => {
      gradebook.updateTotalGradeColumn()
    })
  }
}
