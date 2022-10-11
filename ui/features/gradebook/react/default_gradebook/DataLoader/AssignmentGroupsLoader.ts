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

import type Gradebook from '../Gradebook'
import type {RequestDispatch} from '@canvas/network'
import type PerformanceControls from '../PerformanceControls'
import {maxAssignmentCount, otherGradingPeriodAssignmentIds} from '../Gradebook.utils'
import type {AssignmentGroup, SubmissionType} from '../../../../../api.d'

type AssignmentLoaderParams = {
  include: string[]
  override_assignment_dates: boolean
  exclude_response_fields: string[]
  exclude_assignment_submission_types: SubmissionType[]
  per_page: number
  assignment_ids?: string
}

export default class AssignmentGroupsLoader {
  _gradebook: Gradebook

  _dispatch: RequestDispatch

  _performanceControls: PerformanceControls

  requestCharacterLimit?: number

  constructor({
    dispatch,
    gradebook,
    performanceControls,
    requestCharacterLimit,
  }: {
    dispatch: RequestDispatch
    gradebook: Gradebook
    performanceControls: PerformanceControls
    requestCharacterLimit?: number
  }) {
    this._dispatch = dispatch
    this._gradebook = gradebook
    this._performanceControls = performanceControls
    if (requestCharacterLimit) {
      this.requestCharacterLimit = requestCharacterLimit
    }
  }

  loadAssignmentGroups() {
    const includes = [
      'assignment_group_id',
      'assignment_visibility',
      'assignments',
      'grades_published',
      'post_manually',
    ]

    if (this._gradebook.options.has_modules) {
      includes.push('module_ids')
    }

    // Careful when adding new params here. If the param content is too long,
    // you can end up triggering a '414 Request URI Too Long' from Apache.
    const params: AssignmentLoaderParams = {
      exclude_assignment_submission_types: ['wiki_page'],
      exclude_response_fields: [
        'description',
        'in_closed_grading_period',
        'needs_grading_count',
        'rubric',
      ],
      include: includes,
      override_assignment_dates: false,
      per_page: this._performanceControls.assignmentGroupsPerPage,
    }

    const periodId = this._gradingPeriodId()
    if (periodId) {
      return this._loadAssignmentGroupsForGradingPeriods(params, periodId)
    }

    return this._getAssignmentGroups(params)
  }

  // If we're filtering by grading period in Gradebook, send two requests for assignments:
  // one for assignments in the selected grading period, and one for the rest.
  _loadAssignmentGroupsForGradingPeriods(params: AssignmentLoaderParams, selectedPeriodId: string) {
    const gradingPeriodAssignments = this._gradebook.courseContent.gradingPeriodAssignments
    const selectedAssignmentIds = this._gradebook.getGradingPeriodAssignments(selectedPeriodId)

    const {otherAssignmentIds, otherGradingPeriodIds} = otherGradingPeriodAssignmentIds(
      gradingPeriodAssignments,
      selectedAssignmentIds,
      selectedPeriodId
    )

    const maxAssignments = maxAssignmentCount(
      params,
      `/api/v1/courses/${this._gradebook.course.id}/assignment_groups`,
      this.requestCharacterLimit
    )

    // If our assignment_ids param is going to put us over Apache's max URI length,
    // we fall back to requesting all assignments in one query, excluding the
    // assignment_ids param entirely
    if (
      selectedAssignmentIds.length > maxAssignments ||
      otherAssignmentIds.length > maxAssignments
    ) {
      return this._getAssignmentGroups(params)
    }

    // If there are no assignments in the selected grading period, request all
    // assignments in a single query
    if (selectedAssignmentIds.length === 0) {
      return this._getAssignmentGroups(params)
    }

    const gotGroups = this._getAssignmentGroups(
      {...params, assignment_ids: selectedAssignmentIds.join()},
      [selectedPeriodId]
    )

    this._getAssignmentGroups(
      {...params, assignment_ids: otherAssignmentIds.join()},
      otherGradingPeriodIds
    )

    return gotGroups
  }

  _getAssignmentGroups(params: AssignmentLoaderParams, gradingPeriodIds?: string[]) {
    const pathName = `/api/v1/courses/${this._gradebook.course.id}/assignment_groups`

    return this._dispatch
      .getDepaginated<AssignmentGroup[]>(pathName, params)
      .then(assignmentGroups => {
        this._gradebook.updateAssignmentGroups(assignmentGroups, gradingPeriodIds)
      })
  }

  _gradingPeriodId() {
    const periodId = this._gradebook.gradingPeriodId
    return periodId === '0' ? null : periodId
  }
}
