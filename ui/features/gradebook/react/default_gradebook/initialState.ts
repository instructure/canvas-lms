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

import studentRowHeaderConstants from './constants/studentRowHeaderConstants'
import StudentDatastore from './stores/StudentDatastore'
import type {InitialActionStates, CourseContent, ContentLoadStates} from './gradebook.d'
import type {GridDisplaySettings} from './grid.d'
import {camelize} from 'convert-case'

export function getInitialGradebookContent(options) {
  return {
    customColumns: options.teacher_notes ? [options.teacher_notes] : []
  }
}

export function getInitialGridDisplaySettings(settings, colors): GridDisplaySettings {
  const selectedPrimaryInfo = studentRowHeaderConstants.primaryInfoKeys.includes(
    settings.student_column_display_as
  )
    ? settings.student_column_display_as
    : studentRowHeaderConstants.defaultPrimaryInfo
  const selectedSecondaryInfo = settings.student_column_secondary_info
  const sortRowsByColumnId = settings.sort_rows_by_column_id || 'student'
  const sortRowsBySettingKey = settings.sort_rows_by_setting_key || 'sortable_name'
  const sortRowsByDirection = settings.sort_rows_by_direction || 'ascending'
  const filterColumnsBy = {
    assignmentGroupId: null,
    contextModuleId: null,
    gradingPeriodId: null
  }
  if (settings.filter_columns_by != null) {
    Object.assign(filterColumnsBy, camelize(settings.filter_columns_by))
  }
  const filterRowsBy = {
    sectionId: null,
    studentGroupId: null
  }
  if (settings.filter_rows_by != null) {
    Object.assign(filterRowsBy, camelize(settings.filter_rows_by))
  }
  return {
    colors,
    enterGradesAs: settings.enter_grades_as || {},
    filterColumnsBy,
    filterRowsBy,
    hideAssignmentGroupTotals: settings.hide_assignment_group_totals === 'true',
    selectedPrimaryInfo,
    selectedSecondaryInfo,
    selectedViewOptionsFilters: settings.selected_view_options_filters || [],
    showEnrollments: {
      concluded: false,
      inactive: false
    },
    sortRowsBy: {
      columnId: sortRowsByColumnId, // the column controlling the sort
      settingKey: sortRowsBySettingKey, // the key describing the sort criteria
      direction: sortRowsByDirection // the direction of the sort
    },
    submissionTray: {
      open: false,
      studentId: null,
      assignmentId: null,
      comments: [],
      commentsLoaded: false,
      commentsUpdating: false,
      editedCommentId: null
    },
    showUnpublishedAssignments: settings.show_unpublished_assignments === 'true',
    showSeparateFirstLastNames: settings.show_separate_first_last_names === 'true',
    viewUngradedAsZero: settings.view_ungraded_as_zero === 'true'
  }
}

export function getInitialContentLoadStates(options): ContentLoadStates {
  return {
    assignmentGroupsLoaded: false,
    contextModulesLoaded: !options.has_modules,
    assignmentsLoaded: {all: false, gradingPeriod: {}},
    customColumnsLoaded: false,
    gradingPeriodAssignmentsLoaded: false,
    overridesColumnUpdating: false,
    studentIdsLoaded: false,
    studentsLoaded: false,
    submissionsLoaded: false,
    teacherNotesColumnUpdating: false
  }
}

export function getInitialCourseContent(options): CourseContent {
  const courseGradingScheme = options.grading_standard
    ? {
        data: options.grading_standard
      }
    : null
  const defaultGradingScheme = options.default_grading_standard
    ? {
        data: options.default_grading_standard
      }
    : null
  return {
    contextModules: [],
    courseGradingScheme,
    defaultGradingScheme,
    gradingSchemes: options.grading_schemes.map(camelize),
    gradingPeriodAssignments: {},
    assignmentStudentVisibility: {},
    latePolicy: options.late_policy ? camelize(options.late_policy) : undefined,
    students: new StudentDatastore({}, {}),
    modulesById: {}
  }
}

export function getInitialActionStates(): InitialActionStates {
  return {
    pendingGradeInfo: []
  }
}

export const columnWidths = {
  assignment: {
    min: 10,
    default_max: 200,
    max: 400
  },
  assignmentGroup: {
    min: 35,
    default_max: 200,
    max: 400
  },
  total: {
    min: 95,
    max: 400
  },
  total_grade_override: {
    min: 95,
    max: 400
  }
}
