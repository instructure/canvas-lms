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

QUnit.module('Assignment#retry_migration')

test('make ajax call with right url when retry_migration is called', () => {
  const assignmentID = '200'
  const originalQuizID = '42'
  const courseID = '123'
  const assignment = new Assignment({
    name: 'foo',
    id: assignmentID,
    original_quiz_id: originalQuizID,
    course_id: courseID,
  })
  const spy = sandbox.spy($, 'ajaxJSON')
  assignment.retry_migration()
  ok(
    spy.withArgs(
      `/api/v1/courses/${courseID}/content_exports?export_type=quizzes2&quiz_id=${originalQuizID}&failed_assignment_id=${assignmentID}&include[]=migrated_assignment`
    ).calledOnce
  )
})

QUnit.module('Assignment#pollUntilFinishedDuplicating', {
  setup() {
    this.clock = sinon.useFakeTimers()
    this.assignment = new Assignment({workflow_state: 'duplicating'})
    sandbox.stub(this.assignment, 'fetch').returns($.Deferred().resolve())
  },
  teardown() {
    this.clock.restore()
  },
})

test('polls for updates', function () {
  this.assignment.pollUntilFinishedDuplicating()
  this.clock.tick(2000)
  notOk(this.assignment.fetch.called)
  this.clock.tick(2000)
  ok(this.assignment.fetch.called)
})

test('stops polling when the assignment has finished duplicating', function () {
  this.assignment.pollUntilFinishedDuplicating()
  this.assignment.set({workflow_state: 'unpublished'})
  this.clock.tick(3000)
  ok(this.assignment.fetch.calledOnce)
  this.clock.tick(3000)
  ok(this.assignment.fetch.calledOnce)
})

QUnit.module('Assignment#pollUntilFinishedImporting', {
  setup() {
    this.clock = sinon.useFakeTimers()
    this.assignment = new Assignment({workflow_state: 'importing'})
    sandbox.stub(this.assignment, 'fetch').returns($.Deferred().resolve())
  },
  teardown() {
    this.clock.restore()
  },
})

// eslint-disable-next-line jest/no-identical-title
test('polls for updates', function () {
  this.assignment.pollUntilFinishedImporting()
  this.clock.tick(2000)
  notOk(this.assignment.fetch.called)
  this.clock.tick(2000)
  ok(this.assignment.fetch.called)
})

test('stops polling when the assignment has finished importing', function () {
  this.assignment.pollUntilFinishedImporting()
  this.assignment.set({workflow_state: 'unpublished'})
  this.clock.tick(3000)
  ok(this.assignment.fetch.calledOnce)
  this.clock.tick(3000)
  ok(this.assignment.fetch.calledOnce)
})

QUnit.module('Assignment#pollUntilFinishedMigrating', {
  setup() {
    this.clock = sinon.useFakeTimers()
    this.assignment = new Assignment({workflow_state: 'migrating'})
    sandbox.stub(this.assignment, 'fetch').returns($.Deferred().resolve())
  },
  teardown() {
    this.clock.restore()
  },
})

// eslint-disable-next-line jest/no-identical-title
test('polls for updates', function () {
  this.assignment.pollUntilFinishedMigrating()
  this.clock.tick(2000)
  notOk(this.assignment.fetch.called)
  this.clock.tick(2000)
  ok(this.assignment.fetch.called)
})

test('stops polling when the assignment has finished migrating', function () {
  this.assignment.pollUntilFinishedMigrating()
  this.assignment.set({workflow_state: 'unpublished'})
  this.clock.tick(3000)
  ok(this.assignment.fetch.calledOnce)
  this.clock.tick(3000)
  ok(this.assignment.fetch.calledOnce)
})

QUnit.module('Assignment#gradersAnonymousToGraders', hooks => {
  let assignment

  hooks.beforeEach(() => {
    assignment = new Assignment()
  })

  test('returns graders_anonymous_to_graders on the record if no arguments are passed', () => {
    assignment.set('graders_anonymous_to_graders', true)
    equal(assignment.gradersAnonymousToGraders(), true)
  })

  test('sets the graders_anonymous_to_graders value if an argument is passed', () => {
    assignment.set('graders_anonymous_to_graders', true)
    assignment.gradersAnonymousToGraders(false)
    equal(assignment.gradersAnonymousToGraders(), false)
  })
})

QUnit.module('Assignment#graderCommentsVisibleToGraders', hooks => {
  let assignment

  hooks.beforeEach(() => {
    assignment = new Assignment()
  })

  test('returns grader_comments_visible_to_graders on the record if no arguments are passed', () => {
    assignment.set('grader_comments_visible_to_graders', true)
    equal(assignment.graderCommentsVisibleToGraders(), true)
  })

  test('sets the grader_comments_visible_to_graders value if an argument is passed', () => {
    assignment.set('grader_comments_visible_to_graders', true)
    assignment.graderCommentsVisibleToGraders(false)
    equal(assignment.graderCommentsVisibleToGraders(), false)
  })
})

QUnit.module('Assignment#showGradersAnonymousToGradersCheckbox', hooks => {
  let assignment

  hooks.beforeEach(() => {
    assignment = new Assignment()
  })

  test('returns false if grader_comments_visible_to_graders is false', () => {
    assignment.set('grader_comments_visible_to_graders', false)
    equal(assignment.showGradersAnonymousToGradersCheckbox(), false)
  })

  test('returns false if moderated_grading is false', () => {
    assignment.set('moderated_grading', false)
    equal(assignment.showGradersAnonymousToGradersCheckbox(), false)
  })

  test('returns false if grader_comments_visible_to_graders is false and moderated_grading is true', () => {
    assignment.set('grader_comments_visible_to_graders', false)
    assignment.set('moderated_grading', true)
    equal(assignment.showGradersAnonymousToGradersCheckbox(), false)
  })

  test('returns false if grader_comments_visible_to_graders is true and moderated_grading is false', () => {
    assignment.set('grader_comments_visible_to_graders', true)
    assignment.set('moderated_grading', false)
    equal(assignment.showGradersAnonymousToGradersCheckbox(), false)
  })

  test('returns true if grader_comments_visible_to_graders is true and moderated_grading is true', () => {
    assignment.set('grader_comments_visible_to_graders', true)
    assignment.set('moderated_grading', true)
    equal(assignment.showGradersAnonymousToGradersCheckbox(), true)
  })
})
