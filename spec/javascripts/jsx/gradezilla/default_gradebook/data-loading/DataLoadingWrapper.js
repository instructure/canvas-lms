/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import DataLoader from 'jsx/gradezilla/DataLoader'

export default class DataLoadingWrapper {
  setup() {
    sinon.stub(DataLoader, 'loadGradebookData').callsFake(options => {
      this._dataLoaderOptions = options
      this._dataLoaderPromises = {
        gotAssignmentGroups: $.Deferred(),
        gotContextModules: $.Deferred(),
        gotCustomColumnData: $.Deferred(),
        gotCustomColumns: $.Deferred(),
        gotGradingPeriodAssignments: options.getGradingPeriodAssignments ? $.Deferred() : null,
        gotStudentIds: $.Deferred(),
        gotStudents: $.Deferred(),
        gotSubmissions: $.Deferred()
      }
      return this._dataLoaderPromises
    })
  }

  teardown() {
    DataLoader.loadGradebookData.restore()
  }

  loadAssignmentGroups(assignmentGroups) {
    this._dataLoaderPromises.gotAssignmentGroups.resolve(assignmentGroups)
  }

  loadContextModules(contextModules = []) {
    this._dataLoaderPromises.gotContextModules.resolve(contextModules)
  }

  loadCustomColumns(customColumns = []) {
    this._dataLoaderPromises.gotCustomColumns.resolve(customColumns)
  }

  loadCustomColumnData() {}

  loadGradingPeriodAssignments(gradingPeriodAssignments) {
    if (this._dataLoaderPromises.gotGradingPeriodAssignments) {
      this._dataLoaderPromises.gotGradingPeriodAssignments.resolve({
        grading_period_assignments: gradingPeriodAssignments
      })
    }
  }

  loadStudentIds(studentIds) {
    this._dataLoaderPromises.gotStudentIds.resolve({user_ids: studentIds})
  }

  loadStudents(students) {
    this._dataLoaderOptions.studentsPageCb(students)
  }

  loadSubmissions(submissions) {
    this._dataLoaderOptions.submissionsChunkCb(submissions)
  }

  finishLoadingCustomColumnData() {
    this._dataLoaderPromises.gotCustomColumnData.resolve()
  }

  finishLoadingStudents() {
    this._dataLoaderPromises.gotStudents.resolve()
  }

  finishLoadingSubmissions() {
    this._dataLoaderPromises.gotSubmissions.resolve()
  }
}
