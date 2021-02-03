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

export default class AssignmentGroupsLoader {
  constructor({
    dispatch,
    gradebook,
    performanceControls,
    loadAssignmentsByGradingPeriod,
    requestCharacterLimit
  }) {
    this._dispatch = dispatch
    this._gradebook = gradebook
    this._performanceControls = performanceControls
    this.loadAssignmentsByGradingPeriod = loadAssignmentsByGradingPeriod
    this.requestCharacterLimit = requestCharacterLimit
    this.pathName = `/api/v1/courses/${this._gradebook.course.id}/assignment_groups`
  }

  loadAssignmentGroups() {
    const includes = [
      'assignment_group_id',
      'assignment_visibility',
      'assignments',
      'grades_published',
      'post_manually'
    ]

    if (this._gradebook.options.has_modules) {
      includes.push('module_ids')
    }

    // Careful when adding new params here. If the param content is too long,
    // you can end up triggering a '414 Request URI Too Long' from Apache.
    const params = {
      exclude_assignment_submission_types: ['wiki_page'],
      exclude_response_fields: [
        'description',
        'in_closed_grading_period',
        'needs_grading_count',
        'rubric'
      ],
      include: includes,
      override_assignment_dates: false,
      per_page: this._performanceControls.assignmentGroupsPerPage
    }

    const periodId = this._gradingPeriodId()
    if (periodId && this.loadAssignmentsByGradingPeriod) {
      return this._loadAssignmentGroupsForGradingPeriods(params, periodId)
    }

    return this._getAssignmentGroups(params)
  }

  _maxAssignmentCount(params) {
    const createQueryString = ([key, val]) => {
      if (Array.isArray(val)) {
        return val.map(v => createQueryString([`${key}[]`, v])).join('&')
      }

      return `${encodeURIComponent(key)}=${encodeURIComponent(val)}`
    }

    const queryString = Object.entries(params)
      .map(createQueryString)
      .join('&')
    const currentURI = `${window.location.hostname}${this.pathName}?${queryString}`
    const charsAvailable = this.requestCharacterLimit - `${currentURI}&assignment_ids=`.length
    const globalIdLength = 8
    const assignmentParam = encodeURIComponent(`${'0'.repeat(globalIdLength)},`)

    return Math.floor(charsAvailable / assignmentParam.length)
  }

  // If we're filtering by grading period in Gradebook, send two requests for assignments:
  // one for assignments in the selected grading period, and one for the rest.
  _loadAssignmentGroupsForGradingPeriods(params, periodId) {
    const assignmentIdsByGradingPeriod = this._gradingPeriodAssignmentIds(periodId)
    const maxAssignments = this._maxAssignmentCount(params)

    // If our assignment_ids param is going to put us over Apache's max URI length,
    // we fall back to requesting all assignments in one query, excluding the
    // assignment_ids param entirely
    if (
      assignmentIdsByGradingPeriod.selected.length > maxAssignments ||
      assignmentIdsByGradingPeriod.rest.ids.length > maxAssignments
    ) {
      return this._getAssignmentGroups(params)
    }

    // If there are no assignments in the selected grading period, request all
    // assignments in a single query
    if (assignmentIdsByGradingPeriod.selected.length === 0) {
      return this._getAssignmentGroups(params)
    }

    const gotGroups = this._getAssignmentGroups(
      {...params, assignment_ids: assignmentIdsByGradingPeriod.selected.join()},
      [periodId]
    )

    this._getAssignmentGroups(
      {...params, assignment_ids: assignmentIdsByGradingPeriod.rest.ids.join()},
      assignmentIdsByGradingPeriod.rest.gradingPeriodIds
    )

    return gotGroups
  }

  _getAssignmentGroups(params, gradingPeriodIds) {
    return this._dispatch.getDepaginated(this.pathName, params).then(assignmentGroups => {
      this._gradebook.updateAssignmentGroups(assignmentGroups, gradingPeriodIds)
    })
  }

  _gradingPeriodAssignmentIds(selectedPeriodId) {
    const gpAssignments = this._gradebook.courseContent.gradingPeriodAssignments
    const selectedIds = this._gradebook.getGradingPeriodAssignments(selectedPeriodId)
    const restIds = Object.values(gpAssignments)
      .flat()
      .filter(id => !selectedIds.includes(id))

    return {
      selected: selectedIds,
      rest: {
        ids: [...new Set(restIds)],
        gradingPeriodIds: Object.keys(gpAssignments).filter(gpId => gpId !== selectedPeriodId)
      }
    }
  }

  _gradingPeriodId() {
    const periodId = this._gradebook.gradingPeriodId
    return periodId === '0' ? null : periodId
  }
}
