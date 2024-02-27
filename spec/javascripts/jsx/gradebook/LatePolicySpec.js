/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {createGradebook} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'
import LatePolicyApplicator from 'ui/features/gradebook/react/LatePolicyApplicator'

QUnit.module('Gradebook#setLatePolicy', {
  setup() {
    this.gradebook = createGradebook()
  },
})

test('sets the late policy state', function () {
  const latePolicy = {lateSubmissionInterval: 'day'}
  this.gradebook.setLatePolicy(latePolicy)
  deepEqual(this.gradebook.courseContent.latePolicy, latePolicy)
})

QUnit.module('Gradebook#applyLatePolicy', {
  setup() {
    this.gradingStandard = [['A', 0]]
    this.gradebook = createGradebook({grading_standard: this.gradingStandard})
    this.gradebook.gradingPeriodSet = {
      gradingPeriods: [
        {id: 100, isClosed: true},
        {id: 101, isClosed: false},
      ],
    }
    this.latePolicyApplicator = sandbox
      .stub(LatePolicyApplicator, 'processSubmission')
      .returns(true)

    this.submission1 = {
      user_id: 10,
      assignment_id: 'assignment_1',
      grading_period_id: null,
    }

    this.submission2 = {
      user_id: 10,
      assignment_id: 'assignment_2',
      grading_period_id: 100,
    }

    this.submission3 = {
      user_id: 11,
      assignment_id: 'assignment_2',
      grading_period_id: 101,
    }

    this.submission4 = {
      user_id: 12,
      assignment_id: 'assignment_1',
      grading_period_id: null,
    }

    this.gradebook.assignments = {
      assignment_1: 'assignment1value',
      assignment_2: 'assignment2value',
    }
    this.gradebook.students = {
      10: {
        assignment_1: this.submission1,
        assignment_2: this.submission2,
      },
      11: {
        assignment_2: this.submission3,
      },
      12: {
        assignment_1: this.submission4,
        isConcluded: true,
      },
    }
    this.gradebook.courseContent.latePolicy = 'latepolicy'
  },
})

test('skips submissions for which assignments are not loaded', function () {
  this.gradebook.assignments = {assignment_2: 'assignment2value'}
  this.gradebook.applyLatePolicy()
  notOk(
    this.latePolicyApplicator.calledWith(
      this.submission1,
      'assignment1value',
      this.gradingStandard,
      'latepolicy'
    )
  )
})

test('does not affect submissions in closed grading periods', function () {
  this.gradebook.applyLatePolicy()
  notOk(
    this.latePolicyApplicator.calledWith(
      this.submission2,
      'assignment2value',
      this.gradingStandard,
      'latepolicy'
    )
  )
})

test('does not grade submissions for concluded students', function () {
  sinon.stub(this.gradebook, 'calculateStudentGrade')
  this.gradebook.applyLatePolicy()
  const gradesCalculated = this.gradebook.calculateStudentGrade.calledWith(
    this.gradebook.students[12]
  )
  strictEqual(gradesCalculated, false)
  this.gradebook.calculateStudentGrade.restore()
})

test('affects submissions that are not in a grading period', function () {
  this.gradebook.applyLatePolicy()
  ok(
    this.latePolicyApplicator.calledWith(
      this.submission1,
      'assignment1value',
      this.gradingStandard,
      'latepolicy'
    )
  )
})

test('affects submissions that are in not-closed grading periods', function () {
  this.gradebook.applyLatePolicy()
  ok(
    this.latePolicyApplicator.calledWith(
      this.submission3,
      'assignment2value',
      this.gradingStandard,
      'latepolicy'
    )
  )
})
