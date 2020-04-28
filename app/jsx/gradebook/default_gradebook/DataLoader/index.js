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
import SisOverridesLoader from './SisOverridesLoader'
import StudentContentDataLoader from './StudentContentDataLoader'
import StudentIdsLoader from './StudentIdsLoader'

export default class DataLoader {
  constructor({gradebook, performanceControls}) {
    this._gradebook = gradebook

    const dispatch = new RequestDispatch({
      activeRequestLimit: performanceControls.activeRequestLimit
    })

    const loaderConfig = {
      dispatch,
      gradebook,
      performanceControls
    }

    this.assignmentGroupsLoader = new AssignmentGroupsLoader(loaderConfig)
    this.contextModulesLoader = new ContextModulesLoader(loaderConfig)
    this.customColumnsDataLoader = new CustomColumnsDataLoader(loaderConfig)
    this.customColumnsLoader = new CustomColumnsLoader(loaderConfig)
    this.gradingPeriodAssignmentsLoader = new GradingPeriodAssignmentsLoader(loaderConfig)
    this.sisOverridesLoader = new SisOverridesLoader(loaderConfig)
    this.studentContentDataLoader = new StudentContentDataLoader(loaderConfig)
    this.studentIdsLoader = new StudentIdsLoader(loaderConfig)
  }

  loadInitialData() {
    const gradebook = this._gradebook

    this.__loadGradebookData({
      dataLoader: this,
      gradebook,

      getAssignmentGroups: true,
      getContextModules: true,
      getCustomColumns: true,
      getGradingPeriodAssignments: gradebook.gradingPeriodSet != null
    })
  }

  loadCustomColumnData(customColumnId) {
    this.customColumnsDataLoader.loadCustomColumnsData([customColumnId])
  }

  loadOverridesForSIS() {
    this.sisOverridesLoader.loadOverrides()
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

  async __loadGradebookData(options) {
    const {dataLoader, gradebook} = options

    // Store currently-loaded student ids for diffing below.
    const loadedStudentIds = gradebook.courseContent.students.listStudentIds()

    // Begin loading Student IDs before any other data.
    const gotStudentIds = dataLoader.studentIdsLoader.loadStudentIds()

    if (options.getAssignmentGroups) {
      dataLoader.assignmentGroupsLoader.loadAssignmentGroups()
    }

    if (options.getGradingPeriodAssignments) {
      dataLoader.gradingPeriodAssignmentsLoader.loadGradingPeriodAssignments()
    }

    if (options.getCustomColumns) {
      dataLoader.customColumnsLoader.loadCustomColumns()
    }

    if (options.getContextModules) {
      dataLoader.contextModulesLoader.loadContextModules()
    }

    await gotStudentIds

    const studentIds = gradebook.courseContent.students.listStudentIds()
    const studentIdsToLoad = difference(studentIds, loadedStudentIds)

    await dataLoader.studentContentDataLoader.load(studentIdsToLoad)

    /*
     * Currently, custom columns data has the lowest priority for initial
     * data loading, so it waits until all students and submissions are
     * finished loading.
     */
    dataLoader.customColumnsDataLoader.loadCustomColumnsData()
  }
}
