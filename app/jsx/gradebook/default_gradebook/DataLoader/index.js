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

import {difference} from 'lodash'

import {RequestDispatch} from '../../../shared/network'
import AssignmentGroupsLoader from './AssignmentGroupsLoader'
import ContextModulesLoader from './ContextModulesLoader'
import CustomColumnsDataLoader from './CustomColumnsDataLoader'
import CustomColumnsLoader from './CustomColumnsLoader'
import GradingPeriodAssignmentsLoader from './GradingPeriodAssignmentsLoader'
import StudentContentDataLoader from './StudentContentDataLoader'
import StudentIdsLoader from './StudentIdsLoader'

export default class DataLoader {
  constructor({gradebook}) {
    this._gradebook = gradebook
    this.dispatch = new RequestDispatch({
      activeRequestLimit: gradebook.options.activeRequestLimit
    })

    const loaderConfig = {
      dispatch: this.dispatch,
      gradebook
    }

    this.assignmentGroupsLoader = new AssignmentGroupsLoader(loaderConfig)
    this.contextModulesLoader = new ContextModulesLoader(loaderConfig)
    this.customColumnsDataLoader = new CustomColumnsDataLoader(loaderConfig)
    this.customColumnsLoader = new CustomColumnsLoader(loaderConfig)
    this.gradingPeriodAssignmentsLoader = new GradingPeriodAssignmentsLoader(loaderConfig)
    this.studentContentDataLoader = new StudentContentDataLoader(loaderConfig)
    this.studentIdsLoader = new StudentIdsLoader(loaderConfig)
  }

  loadInitialData() {
    const gradebook = this._gradebook

    const promises = this.__loadGradebookData({
      dataLoader: this,
      gradebook,

      getAssignmentGroups: true,
      getContextModules: true,
      getCustomColumns: true,
      getGradingPeriodAssignments: gradebook.gradingPeriodSet != null
    })

    // TODO: In TALLY-769, remove this entire block.
    // eslint-disable-next-line promise/catch-or-return
    Promise.all([
      promises.gotStudentIds,
      promises.gotContextModules,
      promises.gotCustomColumns,
      promises.gotAssignmentGroups,
      promises.gotGradingPeriodAssignments
    ]).then(() => {
      gradebook.finishRenderingUI()
    })
  }

  loadCustomColumnData(customColumnId) {
    this.customColumnsDataLoader.loadCustomColumnsData([customColumnId])
  }

  loadOverridesForSIS() {
    const gradebook = this._gradebook
    const {options} = gradebook

    const url = `/api/v1/courses/${options.context_id}/assignment_groups`
    const params = {
      exclude_assignment_submission_types: ['wiki_page'],
      exclude_response_fields: ['description', 'in_closed_grading_period', 'needs_grading_count'],
      include: ['assignments', 'grades_published', 'overrides'],
      override_assignment_dates: false
    }

    this.dispatch.getDepaginated(url, params).then(gradebook.addOverridesToPostGradesStore)
  }

  reloadStudentDataForEnrollmentFilterChange() {
    this.__reloadStudentData({
      getGradingPeriodAssignments: true
    })
  }

  reloadStudentDataForSectionFilterChange() {
    this.__reloadStudentData({
      getGradingPeriodAssignments: false
    })
  }

  reloadStudentDataForStudentGroupFilterChange() {
    this.__reloadStudentData({
      getGradingPeriodAssignments: false
    })
  }

  // PRIVATE

  __reloadStudentData(loadOptions) {
    const gradebook = this._gradebook

    gradebook.updateStudentsLoaded(false)
    gradebook.updateSubmissionsLoaded(false)

    this.__loadGradebookData({
      dataLoader: this,
      gradebook,

      getGradingPeriodAssignments:
        loadOptions.getGradingPeriodAssignments && gradebook.gradingPeriodSet != null
    })
  }

  __loadGradebookData(opts) {
    const {dataLoader, gradebook} = opts

    // Store currently-loaded student ids for diffing below.
    const loadedStudentIds = gradebook.courseContent.students.listStudentIds()

    // Begin loading Student IDs before any other data.
    const gotStudentIds = dataLoader.studentIdsLoader.loadStudentIds()

    const gotAssignmentGroups = opts.getAssignmentGroups
      ? dataLoader.assignmentGroupsLoader.loadAssignmentGroups()
      : null

    const gotGradingPeriodAssignments = opts.getGradingPeriodAssignments
      ? dataLoader.gradingPeriodAssignmentsLoader.loadGradingPeriodAssignments()
      : null

    const gotCustomColumns = opts.getCustomColumns
      ? dataLoader.customColumnsLoader.loadCustomColumns()
      : null

    const gotContextModules = opts.getContextModules
      ? dataLoader.contextModulesLoader.loadContextModules()
      : null

    gotStudentIds
      .then(() => {
        const studentIds = gradebook.courseContent.students.listStudentIds()
        const studentIdsToLoad = difference(studentIds, loadedStudentIds)

        return dataLoader.studentContentDataLoader.load(studentIdsToLoad)
      })
      .then(() => {
        /*
         * Currently, custom columns data has the lowest priority for initial
         * data loading, so it waits until all students and submissions are
         * finished loading.
         */
        dataLoader.customColumnsDataLoader.loadCustomColumnsData()
      })

    return {
      gotAssignmentGroups,
      gotContextModules,
      gotCustomColumns,
      gotGradingPeriodAssignments,
      gotStudentIds
    }
  }
}
