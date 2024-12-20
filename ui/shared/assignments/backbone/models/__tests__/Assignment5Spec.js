/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import 'jquery-migrate'
import '@canvas/jquery/jquery.ajaxJSON'
import Assignment from '../Assignment'

QUnit.module('Assignment#canDuplicate')

test('returns true if record can be duplicated', () => {
  const assignment = new Assignment({
    name: 'foo',
    can_duplicate: true,
  })
  equal(assignment.canDuplicate(), true)
})

test('returns false if record cannot be duplicated', () => {
  const assignment = new Assignment({
    name: 'foo',
    can_duplicate: false,
  })
  equal(assignment.canDuplicate(), false)
})

QUnit.module('Assignment#isDuplicating')

test('returns true if record is duplicating', () => {
  const assignment = new Assignment({
    name: 'foo',
    workflow_state: 'duplicating',
  })
  equal(assignment.isDuplicating(), true)
})

test('returns false if record is not duplicating', () => {
  const assignment = new Assignment({
    name: 'foo',
    workflow_state: 'published',
  })
  equal(assignment.isDuplicating(), false)
})

QUnit.module('Assignment#failedToDuplicate')

test('returns true if record failed to duplicate', () => {
  const assignment = new Assignment({
    name: 'foo',
    workflow_state: 'failed_to_duplicate',
  })
  equal(assignment.failedToDuplicate(), true)
})

test('returns false if record did not fail to duplicate', () => {
  const assignment = new Assignment({
    name: 'foo',
    workflow_state: 'published',
  })
  equal(assignment.failedToDuplicate(), false)
})

QUnit.module('Assignment#originalAssignmentID')

test('returns the original assignment id', () => {
  const originalAssignmentID = '42'
  const assignment = new Assignment({
    name: 'foo',
    original_assignment_id: originalAssignmentID,
  })
  equal(assignment.originalAssignmentID(), originalAssignmentID)
})

QUnit.module('Assignment#originalCourseID')

// eslint-disable-next-line jest/no-identical-title
test('returns the original assignment id', () => {
  const originalCourseID = '42'
  const assignment = new Assignment({
    name: 'foo',
    original_course_id: originalCourseID,
  })
  equal(assignment.originalCourseID(), originalCourseID)
})

QUnit.module('Assignment#originalAssignmentName')

test('returns the original assignment name', () => {
  const originalAssignmentName = 'Original Assignment'
  const assignment = new Assignment({
    name: 'foo',
    original_assignment_name: originalAssignmentName,
  })
  equal(assignment.originalAssignmentName(), originalAssignmentName)
})

QUnit.module('Assignment#isQuizLTIAssignment')

test('returns true if record uses quizzes 2', () => {
  const assignment = new Assignment({
    name: 'foo',
    is_quiz_lti_assignment: true,
  })
  equal(assignment.isQuizLTIAssignment(), true)
})

test('returns false if record does not use quizzes 2', () => {
  const assignment = new Assignment({
    name: 'foo',
    is_quiz_lti_assignment: false,
  })
  equal(assignment.isQuizLTIAssignment(), false)
})

QUnit.module('Assignment#canFreeze')

test('returns true if record is not frozen', () => {
  const assignment = new Assignment({
    name: 'foo',
    frozen_attributes: [],
  })
  equal(assignment.canFreeze(), true)
})

test('returns false if record is frozen', () => {
  const assignment = new Assignment({
    name: 'foo',
    frozen_attributes: [],
    frozen: true,
  })
  equal(assignment.canFreeze(), false)
})

test('returns false if record uses quizzes 2', () => {
  const assignment = new Assignment({
    name: 'foo',
    frozen_attributes: [],
  })
  sandbox.stub(assignment, 'isQuizLTIAssignment').returns(true)
  equal(assignment.canFreeze(), false)
})

QUnit.module('Assignment#submissionTypesFrozen')

test('returns false if submission types are not in frozenAttributes', () => {
  const assignment = new Assignment({frozen_attributes: ['foo']})
  equal(assignment.submissionTypesFrozen(), false)
})

test('returns true if submission_types are in frozenAttributes', () => {
  const assignment = new Assignment({frozen_attributes: ['submission_types']})
  equal(assignment.submissionTypesFrozen(), true)
})

QUnit.module('Assignment#duplicate_failed')

test('make ajax call with right url when duplicate_failed is called', () => {
  const assignmentID = '200'
  const originalAssignmentID = '42'
  const courseID = '123'
  const originalCourseID = '234'
  const assignment = new Assignment({
    name: 'foo',
    id: assignmentID,
    original_assignment_id: originalAssignmentID,
    course_id: courseID,
    original_course_id: originalCourseID,
  })
  const spy = sandbox.spy($, 'ajaxJSON')
  assignment.duplicate_failed()
  ok(
    spy.withArgs(
      `/api/v1/courses/${originalCourseID}/assignments/${originalAssignmentID}/duplicate?target_assignment_id=${assignmentID}&target_course_id=${courseID}`
    ).calledOnce
  )
})
