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

import {
  assignmentSearchMatcher,
  doesSubmissionNeedGrading,
  doFiltersMatch,
  isGradedOrExcusedSubmissionUnposted,
  maxAssignmentCount,
  otherGradingPeriodAssignmentIds,
} from '../Gradebook.utils'
import type {FilterPreset} from '../gradebook.d'
import type {Submission} from '../../../../../api.d'

// @ts-expect-error
const unsubmittedSubmission: Submission = {
  anonymous_id: 'dNq5T',
  assignment_id: '32',
  attempt: 1,
  cached_due_date: null,
  custom_grade_status_id: null,
  drop: undefined,
  entered_grade: null,
  entered_score: null,
  excused: false,
  grade_matches_current_submission: true,
  grade: null,
  graded_at: null,
  gradeLocked: false,
  grading_period_id: '2',
  grading_type: 'points',
  gradingType: 'points',
  has_originality_report: false,
  has_postable_comments: false,
  hidden: false,
  id: '160',
  late_policy_status: null,
  late: false,
  missing: false,
  points_deducted: null,
  posted_at: null,
  provisional_grade_id: '3',
  rawGrade: null,
  redo_request: false,
  score: null,
  seconds_late: 0,
  similarityInfo: null,
  submission_comments: [],
  submission_type: 'online_text_entry',
  submitted_at: new Date(),
  url: null,
  user_id: '28',
  word_count: null,
  workflow_state: 'unsubmitted',
  updated_at: new Date().toString(),
}

const ungradedSubmission: Submission = {
  ...unsubmittedSubmission,
  attempt: 1,
  workflow_state: 'submitted',
}

const zeroGradedSubmission: Submission = {
  ...unsubmittedSubmission,
  attempt: 1,
  entered_grade: '0',
  entered_score: 0,
  grade: '0',
  grade_matches_current_submission: true,
  rawGrade: '0',
  score: 0,
  workflow_state: 'graded',
}

const gradedSubmission: Submission = {
  ...unsubmittedSubmission,
  attempt: 1,
  entered_grade: '5',
  entered_score: 5,
  grade: '5',
  grade_matches_current_submission: true,
  rawGrade: '5',
  score: 5,
  workflow_state: 'graded',
}

const gradedPostedSubmission: Submission = {
  ...gradedSubmission,
  posted_at: new Date(),
}

describe('doFiltersMatch', () => {
  const filterPreset: FilterPreset[] = [
    {
      id: '1',
      name: 'Filter 1',
      filters: [
        {id: '1', type: 'module', value: '1', created_at: ''},
        {id: '2', type: 'assignment-group', value: '2', created_at: ''},
        {id: '3', type: 'assignment-group', value: '7', created_at: ''},
        {id: '4', type: 'module', value: '3', created_at: ''},
      ],
      created_at: '2019-01-01T00:00:00Z',
      updated_at: '2019-01-01T00:00:00Z',
    },
    {
      id: '2',
      name: 'Filter 2',
      filters: [
        {id: '1', type: 'module', value: '4', created_at: ''},
        {id: '2', type: 'assignment-group', value: '5', created_at: ''},
        {id: '3', type: 'module', value: '6', created_at: ''},
      ],
      created_at: '2019-01-01T00:00:01Z',
      updated_at: '2019-01-01T00:00:00Z',
    },
    {
      id: '3',
      name: 'Filter 3',
      filters: [
        {id: '1', type: 'module', value: '4', created_at: ''},
        {id: '2', type: 'assignment-group', value: '5', created_at: ''},
        {id: '3', type: 'module', value: '6', created_at: ''},
      ],
      created_at: '2019-01-01T00:00:01Z',
      updated_at: '2019-01-01T00:00:00Z',
    },
  ]

  it('returns false if filter conditions are different', () => {
    expect(doFiltersMatch(filterPreset[0].filters, filterPreset[1].filters)).toStrictEqual(false)
  })

  it('returns true if filter conditions are the same', () => {
    expect(doFiltersMatch(filterPreset[1].filters, filterPreset[2].filters)).toStrictEqual(true)
  })
})

describe('doesSubmissionNeedGrading', () => {
  it('unsubmitted submission does not need grading', () => {
    expect(doesSubmissionNeedGrading(unsubmittedSubmission)).toStrictEqual(false)
  })

  it('submitted but ungraded submission needs grading', () => {
    expect(doesSubmissionNeedGrading(ungradedSubmission)).toStrictEqual(true)
  })

  it('zero-graded submission does not need grading', () => {
    expect(doesSubmissionNeedGrading(zeroGradedSubmission)).toStrictEqual(false)
  })

  it('none-zero graded submission does not needs grading', () => {
    expect(doesSubmissionNeedGrading(gradedSubmission)).toStrictEqual(false)
  })
})

describe('assignmentSearchMatcher', () => {
  it('returns true if the search term is a substring of the assignment name (case insensitive)', () => {
    const option = {id: '122', label: 'Science Lab II'}
    expect(assignmentSearchMatcher(option, 'lab')).toStrictEqual(true)
  })

  test('returns false if the search term is not a substring of the assignment name', () => {
    const option = {id: '122', label: 'Science Lab II'}
    expect(assignmentSearchMatcher(option, 'Lib')).toStrictEqual(false)
  })

  test('does not treat the search term as a regular expression', () => {
    const option = {id: '122', label: 'Science Lab II'}
    expect(assignmentSearchMatcher(option, 'Science.*II')).toStrictEqual(false)
  })
})

describe('maxAssignmentCount', () => {
  it('computes max number of assignments that can be made in a request', () => {
    expect(
      maxAssignmentCount(
        {
          include: ['a', 'b'],
          override_assignment_dates: true,
          exclude_response_fields: ['c', 'd'],
          exclude_assignment_submission_types: ['on_paper', 'discussion_topic'],
          per_page: 10,
          assignment_ids: '1,2,3',
        },
        'courses/1/long/1/url',
      ),
    ).toStrictEqual(698)
  })
})

describe('otherGradingPeriodAssignmentIds', () => {
  it('computes max number of assignments that can be made in a request', () => {
    const gradingPeriodAssignments = {
      1: ['1', '2', '3', '4', '5'],
      2: ['6', '7', '8', '9', '10'],
    }
    const selectedAssignmentIds = ['1', '2']
    const selectedPeriodId = '1'
    expect(
      otherGradingPeriodAssignmentIds(
        gradingPeriodAssignments,
        selectedAssignmentIds,
        selectedPeriodId,
      ),
    ).toStrictEqual({
      otherGradingPeriodIds: ['2'],
      otherAssignmentIds: ['3', '4', '5', '6', '7', '8', '9', '10'],
    })
  })
})

describe('isGradedOrExcusedSubmissionUnposted', () => {
  it('returns true if submission is graded or excused but not posted', () => {
    expect(isGradedOrExcusedSubmissionUnposted(gradedSubmission)).toStrictEqual(true)
  })

  it('returns false if submission is graded or excused and posted', () => {
    expect(isGradedOrExcusedSubmissionUnposted(gradedPostedSubmission)).toStrictEqual(false)
  })

  it('returns false if submission is ungraded', () => {
    expect(isGradedOrExcusedSubmissionUnposted(ungradedSubmission)).toStrictEqual(false)
  })
})
